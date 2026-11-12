import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fake_latency_provider.g.dart';

/// Week 10 Day 3: how long every fake pretends the network takes.
///
/// Tests that drive the whole app override this one provider with
/// Duration.zero, instead of rebuilding each fake repository by hand.
@Riverpod(keepAlive: true)
Duration fakeLatency(Ref ref) => const Duration(milliseconds: 600);
