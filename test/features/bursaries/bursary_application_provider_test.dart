import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/bursaries/data/bursary_repository_provider.dart';
import 'package:matric_compass/features/bursaries/data/fake_bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_application_provider.dart';

void main() {
  late FakeBursaryRepository fake;
  late ProviderContainer container;

  setUp(() {
    fake = FakeBursaryRepository(latency: Duration.zero);
    // A fresh container per test: shared containers leak state between tests.
    container = ProviderContainer.test(
      overrides: [bursaryRepositoryProvider.overrideWithValue(fake)],
      retry: (retryCount, error) => null,
    );
  });

  test('two screens asking for one id share one fetch', () async {
    final provider = bursaryApplicationProvider(Seed.nsfasId);
    container
      ..listen(provider, (_, _) {})
      ..listen(provider, (_, _) {});

    await container.read(provider.future);

    expect(fake.fetchCount, 1);
  });

  test('different ids keep separate state', () async {
    container
      ..listen(bursaryApplicationProvider(Seed.nsfasId), (_, _) {})
      ..listen(bursaryApplicationProvider(Seed.funzaId), (_, _) {});

    final nsfas = await container.read(
      bursaryApplicationProvider(Seed.nsfasId).future,
    );
    final funza = await container.read(
      bursaryApplicationProvider(Seed.funzaId).future,
    );

    expect(nsfas.funder, 'NSFAS');
    expect(funza.funder, 'Funza Lushaka');
  });

  test('an id that is not found is an error, not a crash', () async {
    final provider = bursaryApplicationProvider('not-a-real-id');
    container.listen(provider, (_, _) {});

    await expectLater(
      container.read(provider.future),
      throwsA(isA<BursaryNotFoundException>()),
    );
  });

  test('autoDispose: leave and come back, and it fetches again', () async {
    final provider = bursaryApplicationProvider(Seed.nsfasId);

    final first = container.listen(provider, (_, _) {});
    await container.read(provider.future);
    first.close();
    // Disposal happens after the frame, not the moment the listener goes.
    await container.pump();

    container.listen(provider, (_, _) {});
    await container.read(provider.future);

    expect(fake.fetchCount, 2);
  });
}
