import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/forensics/models/pipeline_event.dart';

void main() {
  group('PipelineEvent', () {
    test('creates event with all fields', () {
      final event = PipelineEvent(
        stage: 'parsing',
        action: 'parse',
        beforeCount: 10,
        afterCount: 8,
        traceId: 'TRACE-CORE-GEN-123-ABC123',
        timestamp: 1000,
        metadata: {'key': 'value'},
      );
      expect(event.stage, 'parsing');
      expect(event.action, 'parse');
      expect(event.beforeCount, 10);
      expect(event.afterCount, 8);
      expect(event.traceId, 'TRACE-CORE-GEN-123-ABC123');
      expect(event.timestamp, 1000);
      expect(event.metadata, {'key': 'value'});
    });

    test('toJson returns correct map', () {
      final event = PipelineEvent(
        stage: 'validation',
        action: 'validate',
        beforeCount: 5,
        afterCount: 3,
        traceId: 'TRACE-001',
        timestamp: 2000,
        metadata: {'profile': 'security'},
      );
      final json = event.toJson();
      expect(json['stage'], 'validation');
      expect(json['action'], 'validate');
      expect(json['beforeCount'], 5);
      expect(json['afterCount'], 3);
      expect(json['traceId'], 'TRACE-001');
      expect(json['timestamp'], 2000);
      expect(json['metadata'], {'profile': 'security'});
    });

    test('is const constructable', () {
      const event = PipelineEvent(
        stage: 's',
        action: 'a',
        beforeCount: 0,
        afterCount: 0,
        traceId: 't',
        timestamp: 0,
        metadata: {},
      );
      expect(event, isA<PipelineEvent>());
    });
  });
}
