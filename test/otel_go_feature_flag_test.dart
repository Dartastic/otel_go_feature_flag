// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_go_feature_flag/otel_go_feature_flag.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_go_feature_flag-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('variation.bool records flag + reason + variant + retriever', () async {
    await tracedGoFeatureFlag<bool>(
      operation: 'variation.bool',
      invoke: () async => const GoFeatureFlagCallResult(
        value: true,
        result: GoFeatureFlagResult(
          flagKey: 'new-onboarding',
          valueType: 'BOOLEAN',
          variant: 'on',
          reason: 'TARGETING_MATCH',
          retriever: 's3',
          exporter: 'kafka',
          cacheRefresh: false,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('go_feature_flag variation.bool')!);
    expect(a['go_feature_flag.flag.key'], 'new-onboarding');
    expect(a['go_feature_flag.value_type'], 'BOOLEAN');
    expect(a['go_feature_flag.variant'], 'on');
    expect(a['go_feature_flag.reason'], 'TARGETING_MATCH');
    expect(a['go_feature_flag.retriever'], 's3');
    expect(a['go_feature_flag.exporter'], 'kafka');
    expect(a['go_feature_flag.cache.refresh'], false);
  });

  test('reason=ERROR marks span as error', () async {
    await tracedGoFeatureFlag<String>(
      operation: 'variation.string',
      invoke: () async => const GoFeatureFlagCallResult(
        value: 'default',
        result: GoFeatureFlagResult(
          flagKey: 'broken-flag',
          valueType: 'STRING',
          reason: 'ERROR',
          errorCode: 'FLAG_NOT_FOUND',
        ),
      ),
    );
    final s = spans.findSpanByName('go_feature_flag variation.string')!;
    final a = attrsOf(s);
    expect(a['go_feature_flag.error_code'], 'FLAG_NOT_FOUND');
    expect(s.status, SpanStatusCode.Error);
  });

  test('suppression skips spans', () async {
    await runWithoutGoFeatureFlagInstrumentationAsync(() async {
      await tracedGoFeatureFlag<String>(
        operation: 'all_flags',
        invoke: () async => const GoFeatureFlagCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('go_feature_flag '), isEmpty);
  });
}
