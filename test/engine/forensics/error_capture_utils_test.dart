import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/forensics/error_capture_utils.dart';

void main() {
  group('ErrorCaptureUtils', () {
    group('extractNetworkErrorType', () {
      test('returns null for null error', () {
        expect(ErrorCaptureUtils.extractNetworkErrorType(null), isNull);
      });

      test('returns connection_refused for socket error', () {
        expect(
          ErrorCaptureUtils.extractNetworkErrorType('SocketException: failed'),
          'connection_refused',
        );
      });

      test('returns connection_refused for connection refused', () {
        expect(
          ErrorCaptureUtils.extractNetworkErrorType('Connection refused'),
          'connection_refused',
        );
      });

      test('returns timeout for timeout error', () {
        expect(
          ErrorCaptureUtils.extractNetworkErrorType('TimeoutException: timed out'),
          'timeout',
        );
      });

      test('returns dns_error for DNS error', () {
        expect(
          ErrorCaptureUtils.extractNetworkErrorType('dns lookup failed'),
          'dns_error',
        );
      });

      test('returns dns_error for host error', () {
        expect(
          ErrorCaptureUtils.extractNetworkErrorType('No host found'),
          'dns_error',
        );
      });

      test('returns tls_error for certificate error', () {
        expect(
          ErrorCaptureUtils.extractNetworkErrorType('Certificate verify failed'),
          'tls_error',
        );
      });

      test('returns null for unknown error', () {
        expect(
          ErrorCaptureUtils.extractNetworkErrorType('Some random error'),
          isNull,
        );
      });
    });

    group('extractHttpStatusCode', () {
      test('returns null for null error', () {
        expect(ErrorCaptureUtils.extractHttpStatusCode(null), isNull);
      });

      test('extracts status code from regex match', () {
        expect(
          ErrorCaptureUtils.extractHttpStatusCode('statusCode: 404'),
          404,
        );
      });

      test('extracts status code with different format', () {
        expect(
          ErrorCaptureUtils.extractHttpStatusCode('HTTP statusCode = 500'),
          500,
        );
      });

      test('returns 429 when string contains 429', () {
        expect(
          ErrorCaptureUtils.extractHttpStatusCode('Rate limited 429'),
          429,
        );
      });

      test('returns 503 when string contains 503', () {
        expect(
          ErrorCaptureUtils.extractHttpStatusCode('Service 503 unavailable'),
          503,
        );
      });

      test('returns 500 when string contains 500', () {
        expect(
          ErrorCaptureUtils.extractHttpStatusCode('Internal server error 500'),
          500,
        );
      });

      test('returns null when no status code found', () {
        expect(
          ErrorCaptureUtils.extractHttpStatusCode('Unknown error occurred'),
          isNull,
        );
      });
    });

    group('truncate', () {
      test('returns original string when under max length', () {
        expect(ErrorCaptureUtils.truncate('short', 100), 'short');
      });

      test('returns original when exactly max length', () {
        expect(ErrorCaptureUtils.truncate('exactly', 7), 'exactly');
      });

      test('returns truncated string with suffix', () {
        expect(ErrorCaptureUtils.truncate('longer than max', 6), 'longer...[truncated]');
      });
    });

    group('logError', () {
      test('executes without throwing', () {
        expect(
          () => ErrorCaptureUtils.logError(
            source: 'test',
            error: 'test error',
            stack: StackTrace.current,
            additionalInfo: 'info',
          ),
          returnsNormally,
        );
      });

      test('executes without stack trace', () {
        expect(
          () => ErrorCaptureUtils.logError(
            source: 'test',
            error: 'test error',
          ),
          returnsNormally,
        );
      });
    });
  });
}
