@TestOn('vm')
library;


import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:test/test.dart';

void main() {
  const retryAfter429Seconds = 'https://httpbun.com/mix/s=429/h=retry-after:2';
  const retryAfter429Date = 'https://httpbun.com/mix/s=429/h=retry-after:';

  group('Retry-After header handling', () {
    late Dio dio;
    late RetryInterceptor interceptor;

    setUp(() {
      dio = Dio();
      interceptor = RetryInterceptor(
        dio: dio,
        retries: 1,
        logPrint: print,
        //This should be ignored for Retry-After
        retryDelays: const [Duration(seconds: 30)],
      );
      dio.interceptors.add(interceptor);
    });

    test('respects Retry-After with seconds format for 429', () async {
      final startTime = DateTime.now();
      var exceptionThrown = false;

      try {
        await dio.get<dynamic>(retryAfter429Seconds);
      } catch (_) {
        exceptionThrown = true;
      }
      final duration = DateTime.now().difference(startTime);
      expect(duration.inSeconds, greaterThanOrEqualTo(2));
      expect(exceptionThrown, true);
    });

    test('respects Retry-After with date format for 429', () async {
      final startTime = DateTime.now();
      var exceptionThrown = false;

      final futureDate = DateTime.now().toUtc().add(const Duration(seconds: 2));
      final httpDate = HttpDate.format(futureDate);

      try {
        await dio.get<dynamic>('$retryAfter429Date$httpDate');
      } catch (_) {
        exceptionThrown = true;
      }
      final duration = DateTime.now().difference(startTime);
      expect(duration.inSeconds, lessThanOrEqualTo(2));
      expect(exceptionThrown, true);
    });
  });
}