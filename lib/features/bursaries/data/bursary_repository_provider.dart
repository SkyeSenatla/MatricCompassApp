import 'package:matric_compass/features/bursaries/data/fake_bursary_repository.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bursary_repository_provider.g.dart';

/// Week 10 Day 2: the one place that names the bursary implementation.
@Riverpod(keepAlive: true)
BursaryRepository bursaryRepository(Ref ref) => FakeBursaryRepository();
