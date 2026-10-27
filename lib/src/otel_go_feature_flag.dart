// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_go_feature_flag_suppression.dart';

const _tracerName = 'dartastic_otel_libs_go_feature_flag';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class GoFeatureFlagResult {
  /// Creates a result.
  const GoFeatureFlagResult({
    this.flagKey,
    this.valueType,
    this.variant,
    this.reason,
    this.errorCode,
    this.retriever,
    this.exporter,
    this.cacheRefresh,
    this.requestId,
    this.statusCode,
  });

  /// Flag key.
  final String? flagKey;

  /// `BOOLEAN` / `STRING` / `INTEGER` / `DOUBLE` / `JSON` — OpenFeature
  /// flag type that GO Feature Flag implements.
  final String? valueType;

  /// Variant returned.
  final String? variant;

  /// OpenFeature reason: `STATIC` / `DEFAULT` / `TARGETING_MATCH` /
  /// `SPLIT` / `DISABLED` / `UNKNOWN` / `ERROR` / `STALE`.
  final String? reason;

  /// OpenFeature error code (`PROVIDER_NOT_READY`, `FLAG_NOT_FOUND`,
  /// `PARSE_ERROR`, `TYPE_MISMATCH`, `TARGETING_KEY_MISSING`,
  /// `INVALID_CONTEXT`, `GENERAL`).
  final String? errorCode;

  /// `http` / `s3` / `gcs` / `kubernetes` / `file` / `github` /
  /// `gitlab` / `bitbucket` / `redis` / `mongodb` / `azureBlobStorage`
  /// — where flags are loaded from.
  final String? retriever;

  /// Active exporter (where evaluation events are shipped).
  final String? exporter;

  /// Whether the SDK reloaded config from the retriever this call.
  final bool? cacheRefresh;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class GoFeatureFlagCallResult<T> {
  /// Creates a call result.
  const GoFeatureFlagCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final GoFeatureFlagResult? result;
}

/// Wraps a GO Feature Flag call in a CLIENT span. [operation] is one
/// of `variation.bool`, `variation.string`, `variation.int`,
/// `variation.float`, `variation.object`, `variation.details`,
/// `all_flags`, `events.export`, `cache.refresh`, `retriever.fetch`,
/// `info`.
Future<T> tracedGoFeatureFlag<T>({
  required String operation,
  required Future<GoFeatureFlagCallResult<T>> Function() invoke,
}) async {
  if (goFeatureFlagInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'go_feature_flag',
    'rpc.method': operation,
    'go_feature_flag.operation': operation,
  };

  final span = _tracer().startSpan(
    'go_feature_flag $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.flagKey != null) {
        extras.add(OTelAPI.attributeString(
          'go_feature_flag.flag.key',
          r.result!.flagKey!,
        ));
      }
      if (r.result!.valueType != null) {
        extras.add(OTelAPI.attributeString(
          'go_feature_flag.value_type',
          r.result!.valueType!,
        ));
      }
      if (r.result!.variant != null) {
        extras.add(OTelAPI.attributeString(
          'go_feature_flag.variant',
          r.result!.variant!,
        ));
      }
      if (r.result!.reason != null) {
        extras.add(OTelAPI.attributeString(
          'go_feature_flag.reason',
          r.result!.reason!,
        ));
        if (r.result!.reason == 'ERROR') {
          span.setStatus(
            SpanStatusCode.Error,
            'GO Feature Flag reason=ERROR',
          );
        }
      }
      if (r.result!.errorCode != null) {
        extras.add(OTelAPI.attributeString(
          'go_feature_flag.error_code',
          r.result!.errorCode!,
        ));
      }
      if (r.result!.retriever != null) {
        extras.add(OTelAPI.attributeString(
          'go_feature_flag.retriever',
          r.result!.retriever!,
        ));
      }
      if (r.result!.exporter != null) {
        extras.add(OTelAPI.attributeString(
          'go_feature_flag.exporter',
          r.result!.exporter!,
        ));
      }
      if (r.result!.cacheRefresh != null) {
        extras.add(OTelAPI.attributeBool(
          'go_feature_flag.cache.refresh',
          r.result!.cacheRefresh!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'go_feature_flag.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'GO Feature Flag HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
