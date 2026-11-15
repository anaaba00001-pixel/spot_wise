import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';

const searchPath = '/api/places/search';
const fields = 'places.id,places.displayName,places.formattedAddress,places.attributions';

function reply(response, status, body) {
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  response.end(JSON.stringify(body));
}

async function parseQuery(request) {
  let size = 0;
  const chunks = [];
  for await (const chunk of request.iterator({ destroyOnReturn: false })) {
    size += chunk.length;
    if (size > 2048) {
      request.resume();
      return null;
    }
    chunks.push(chunk);
  }
  try {
    const value = JSON.parse(Buffer.concat(chunks).toString('utf8'))?.query;
    const query = typeof value === 'string' ? value.trim() : '';
    return query.length >= 2 && query.length <= 150 ? query : null;
  } catch {
    return null;
  }
}

export function createPlacesServer({
  googleKey, firebaseKey, firebaseProject, allowedOrigins = [], fetcher = fetch,
}) {
  const origins = new Set(allowedOrigins);
  const requests = new Map();
  let minute;
  let day;
  let dailyCalls = 0;

  function take(key, limit) {
    const current = Math.floor(Date.now() / 60_000);
    if (current !== minute) {
      requests.clear();
      minute = current;
    }
    const count = (requests.get(key) ?? 0) + 1;
    if (count > limit) return false;
    requests.set(key, count);
    return true;
  }

  return createServer({ requestTimeout: 20_000 }, async (request, response) => {
    if (request.url !== searchPath) return reply(response, 404, { error: 'not_found' });
    const origin = request.headers.origin;
    if (origin) {
      if (!origins.has(origin)) return reply(response, 403, { error: 'origin_denied' });
      response.setHeader('Vary', 'Origin');
      response.setHeader('Access-Control-Allow-Origin', origin);
      response.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
      response.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    }
    if (request.method === 'OPTIONS') {
      response.writeHead(204).end();
      return;
    }
    if (request.method !== 'POST') return reply(response, 405, { error: 'method_not_allowed' });
    if (!take('all', 120)) return reply(response, 429, { error: 'limit' });

    const token = /^Bearer ([\w.-]{1,4096})$/.exec(request.headers.authorization ?? '')?.[1];
    if (!token) return reply(response, 401, { error: 'sign_in_required' });
    try {
      const claims = JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString());
      if (claims.aud !== firebaseProject || claims.iss !== `https://securetoken.google.com/${firebaseProject}`) {
        return reply(response, 401, { error: 'sign_in_required' });
      }
    } catch {
      return reply(response, 401, { error: 'sign_in_required' });
    }

    try {
      const query = await parseQuery(request);
      if (!query) return reply(response, 400, { error: 'invalid_query' });
      const authUrl = new URL('https://identitytoolkit.googleapis.com/v1/accounts:lookup');
      authUrl.searchParams.set('key', firebaseKey);
      const auth = await fetcher(authUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken: token }),
        signal: AbortSignal.timeout(6000),
      });
      if (auth.status === 400 || auth.status === 401 || auth.status === 403) {
        return reply(response, 401, { error: 'sign_in_required' });
      }
      if (!auth.ok) return reply(response, 502, { error: 'auth_unavailable' });
      const user = (await auth.json()).users?.[0];
      if (!user?.localId || user.disabled) return reply(response, 401, { error: 'sign_in_required' });

      const today = Math.floor(Date.now() / 86_400_000);
      if (today !== day) {
        day = today;
        dailyCalls = 0;
      }
      if (!take(`user:${user.localId}`, 12) || dailyCalls >= 300) {
        return reply(response, 429, { error: 'limit' });
      }
      dailyCalls++;
      const upstream = await fetcher('https://places.googleapis.com/v1/places:searchText', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': googleKey,
          'X-Goog-FieldMask': fields,
        },
        body: JSON.stringify({ textQuery: query, languageCode: 'ar', regionCode: 'SA', pageSize: 12 }),
        signal: AbortSignal.timeout(10_000),
      });
      if (upstream.status === 429) return reply(response, 429, { error: 'limit' });
      if (!upstream.ok) return reply(response, 502, { error: 'places_unavailable' });
      const data = await upstream.json();
      const places = (data.places ?? [])
        .filter((place) => place.id && place.displayName?.text)
        .map((place) => ({
          id: place.id,
          name: place.displayName.text,
          address: place.formattedAddress ?? '',
          attributions: (place.attributions ?? []).filter((item) => item.provider)
            .map((item) => ({ name: item.provider, url: item.providerUri ?? '' })),
        }));
      return reply(response, 200, { places });
    } catch {
      return reply(response, 502, { error: 'search_unavailable' });
    }
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const {
    GOOGLE_PLACES_API_KEY: googleKey,
    FIREBASE_API_KEY: firebaseKey,
    FIREBASE_PROJECT_ID: firebaseProject,
    DALAL_WEB_ORIGINS: origins = '',
    PORT = '8080',
  } = process.env;
  if (!googleKey || !firebaseKey || !firebaseProject) {
    console.error('Set GOOGLE_PLACES_API_KEY, FIREBASE_API_KEY and FIREBASE_PROJECT_ID.');
    process.exit(1);
  }
  const allowedOrigins = origins.split(',').map((origin) => origin.trim()).filter(Boolean);
  createPlacesServer({ googleKey, firebaseKey, firebaseProject, allowedOrigins })
    .listen(Number(PORT), '0.0.0.0', () => console.log(`Dalal Places proxy listening on port ${PORT}`));
}
