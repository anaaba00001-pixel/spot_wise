import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_wise/models/enums.dart';
import 'package:spot_wise/models/spot.dart';
import 'package:spot_wise/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders the Dalal wordmark and icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppLogo())),
      ),
    );
    expect(find.text('دلال'), findsOneWidget);
    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<ResizeImage>().having(
        (image) => (image.imageProvider as AssetImage).assetName,
        'asset name',
        'assets/dalal-app-icon.png',
      ),
    );
  });

  test('Spot round-trips through JSON', () {
    final spot = Spot(
      id: 's1',
      name: 'Test Spot',
      description: 'A lovely place',
      country: 'Egypt',
      city: 'Cairo',
      categoryId: 'landmark',
      lat: 30.0,
      lng: 31.0,
      priceRange: PriceRange.budget,
      status: SpotStatus.approved,
      submittedBy: 'u1',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final restored = Spot.fromJson('s1', spot.toJson());

    expect(restored.name, 'Test Spot');
    expect(restored.city, 'Cairo');
    expect(restored.priceRange, PriceRange.budget);
    expect(restored.status, SpotStatus.approved);
    expect(restored.lat, 30.0);
  });
}
