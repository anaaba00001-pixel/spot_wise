import assert from 'node:assert/strict';
import { once } from 'node:events';
import test from 'node:test';
import { createPlacesServer } from './places-proxy.mjs';

test('requires a verified Firebase account, caps results and keeps Places content out of caches', async () => {
  const seen = [];
  const project = 'dalal-test';
  const origin = 'https://dalal.example';
  const claims = Buffer.from(JSON.stringify({
    aud: project,
    iss: `https://securetoken.google.com/${project}`,
  })).toString('base64url');
  const server = createPlacesServer({
    googleKey: 'test-google-key',
    firebaseKey: 'test-firebase-key',
    firebaseProject: project,
    allowedOrigins: [origin],
    fetcher: async (url, options) => {
      seen.push([String(url), options]);
      if (String(url).includes('accounts:lookup')) {
        if (JSON.parse(options.body).idToken.endsWith('.rejected')) {
          return Response.json({}, { status: 400 });
        }
        return Response.json({ users: [{ localId: 'user-1' }] });
      }
      return Response.json({ places: [{
        id: 'place-1', displayName: { text: 'مقهى' }, formattedAddress: 'حائل',
        attributions: [{ provider: 'Provider', providerUri: 'https://example.com' }],
        location: { latitude: 1, longitude: 2 },
      }] });
    },
  });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const url = `http://127.0.0.1:${server.address().port}/api/places/search`;
  const submit = (authorization, requestOrigin = origin, query = 'مقاهي في حائل') =>
    fetch(url, {
      method: 'POST',
      headers: { origin: requestOrigin, ...(authorization ? { authorization } : {}) },
      body: JSON.stringify({ query }),
    });
  try {
    assert.equal((await submit()).status, 401);
    assert.equal((await submit('', 'https://else.example')).status, 403);
    assert.equal((await submit(`Bearer e30.${claims}.ok`, origin, '1')).status, 400);
    assert.equal(seen.length, 0);
    assert.equal((await submit(`Bearer e30.${claims}.rejected`)).status, 401);
    assert.equal(seen.length, 1);
    const response = await submit(`Bearer e30.${claims}.ok`);
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('cache-control'), 'no-store');
    assert.equal(response.headers.get('access-control-allow-origin'), origin);
    assert.deepEqual(await response.json(), { places: [{
      id: 'place-1', name: 'مقهى', address: 'حائل',
      attributions: [{ name: 'Provider', url: 'https://example.com' }],
    }] });
    assert.equal(seen[2][1].headers['X-Goog-Api-Key'], 'test-google-key');
    assert.equal(JSON.parse(seen[2][1].body).pageSize, 12);
    for (let i = 0; i < 11; i++) assert.equal((await submit(`Bearer e30.${claims}.ok`)).status, 200);
    assert.equal((await submit(`Bearer e30.${claims}.ok`)).status, 429);
    assert.equal(seen.filter(([target]) => target.includes('places.googleapis.com')).length, 12);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});
