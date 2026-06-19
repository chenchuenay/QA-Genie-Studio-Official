import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/forensics/pipeline_observer.dart';

class TestPipelineObserver implements PipelineObserver {
  final events = <Map<String, dynamic>>[];
  final traces = <String>[];

  @override
  void onStageEvent(String category, Map<String, dynamic> data) {
    events.add({'category': category, 'data': data});
  }

  @override
  void onTraceEvent(String message) {
    traces.add(message);
  }
}

void main() {
  group('NoOpPipelineObserver', () {
    test('does nothing on onStageEvent', () {
      const observer = NoOpPipelineObserver();
      expect(
        () => observer.onStageEvent('test', {'key': 'value'}),
        returnsNormally,
      );
    });

    test('does nothing on onTraceEvent', () {
      const observer = NoOpPipelineObserver();
      expect(() => observer.onTraceEvent('message'), returnsNormally);
    });
  });

  group('PipelineForensics', () {
    setUp(() {
      PipelineForensics.setObserver(const NoOpPipelineObserver());
    });

    test('default instance is NoOpPipelineObserver', () {
      expect(PipelineForensics.instance, isA<NoOpPipelineObserver>());
    });

    test('setObserver changes the instance', () {
      final observer = TestPipelineObserver();
      PipelineForensics.setObserver(observer);
      expect(PipelineForensics.instance, same(observer));
    });

    test('custom observer receives stage events', () {
      final observer = TestPipelineObserver();
      PipelineForensics.setObserver(observer);
      PipelineForensics.instance.onStageEvent('parsing', {'count': 5});
      expect(observer.events, hasLength(1));
      expect(observer.events.first['category'], 'parsing');
      expect(observer.events.first['data'], {'count': 5});
    });

    test('custom observer receives trace events', () {
      final observer = TestPipelineObserver();
      PipelineForensics.setObserver(observer);
      PipelineForensics.instance.onTraceEvent('Processing started');
      expect(observer.traces, ['Processing started']);
    });

    test('multiple observers can be swapped', () {
      final first = TestPipelineObserver();
      final second = TestPipelineObserver();
      PipelineForensics.setObserver(first);
      PipelineForensics.instance.onTraceEvent('first');
      expect(first.traces, hasLength(1));

      PipelineForensics.setObserver(second);
      PipelineForensics.instance.onTraceEvent('second');
      expect(first.traces, hasLength(1));
      expect(second.traces, hasLength(1));
    });
  });
}
