// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_go_feature_flag/otel_go_feature_flag.dart';

/// Traces GO Feature Flag calls with OpenTelemetry.
///
/// `otel_go_feature_flag` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each GO Feature Flag call in
/// [tracedGoFeatureFlag]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'go-feature-flag-example');

  // Wraps a GO Feature Flag call in a CLIENT span.
  final goFeatureFlagId = await tracedGoFeatureFlag<String>(
    operation: 'variation.bool',
    invoke: () async {
      // Make the GO Feature Flag call here, then report what it returned.
      const id = 'go_feature_flag_8f3a2c';
      return const GoFeatureFlagCallResult(
          value: id,
          result: GoFeatureFlagResult(
              flagKey: 'orders/2026/inv-1042.pdf',
              valueType: 'BOOLEAN',
              variant: 'example',
              reason: 'STATIC',
              errorCode: 'PROVIDER_NOT_READY',
              retriever: 'http',
              exporter: 'example',
              cacheRefresh: true,
              requestId: 'request_8f3a2c',
              statusCode: 200));
    },
  );
  OTelLog.info('tracedGoFeatureFlag variation.bool returned $goFeatureFlagId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutGoFeatureFlagInstrumentationAsync.
  await runWithoutGoFeatureFlagInstrumentationAsync(
    () => tracedGoFeatureFlag<String>(
      operation: 'variation.bool',
      invoke: () async {
        const id = 'go_feature_flag_8f3a2c';
        return const GoFeatureFlagCallResult(
            value: id,
            result: GoFeatureFlagResult(
                flagKey: 'orders/2026/inv-1042.pdf',
                valueType: 'BOOLEAN',
                variant: 'example',
                reason: 'STATIC',
                errorCode: 'PROVIDER_NOT_READY',
                retriever: 'http',
                exporter: 'example',
                cacheRefresh: true,
                requestId: 'request_8f3a2c',
                statusCode: 200));
      },
    ),
  );

  await OTel.shutdown();
}
