import 'dart:async';

import 'package:campus_mobile_experimental/app_constants.dart';
import 'package:campus_mobile_experimental/app_styles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NetworkHelper {
  ///TODO: inside each service that file place a switch statement to handle all
  ///TODO: different errors thrown by the Dio client DioErrorType.RESPONSE


  // private constructor to show that this class should not be instantiated
  const NetworkHelper._();

  static const int SSO_REFRESH_MAX_RETRIES = 3;
  static const int SSO_REFRESH_RETRY_INCREMENT = 5000;
  static const int SSO_REFRESH_RETRY_MULTIPLIER = 3;
  static final int DEFAULT_TIMEOUT = int.parse(dotenv.get('DEFAULT_TIMEOUT'));

  static Future<dynamic> fetchData(String url) async {
    Dio dio = new Dio();
    dio.options.connectTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.receiveTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.responseType = ResponseType.plain;
    try {
      final _response = await dio.get(url);
      if (_response.statusCode == 200) {
        return _response.data;
      } else {
        String message = _response.data is Map ? (_response.data['message'] ?? _response.statusMessage ?? 'unknown error') : (_response.statusMessage ?? 'unknown error');
        throw Exception('Failed to fetch data: HTTP ${_response.statusCode}: $message');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        String message = e.response!.data is Map ? (e.response!.data['message'] ?? e.response!.statusMessage ?? 'Server error') : (e.response!.statusMessage ?? 'Server error');
        throw Exception('Failed to fetch data: HTTP ${e.response!.statusCode}: $message');
      } else {
        throw Exception('Failed to fetch data: ${e.message ?? "Network error"}');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: Unexpected error: $e');
    }
  }

  static Future<dynamic> authorizedFetch(
      String url, Map<String, String> headers) async {
    Dio dio = new Dio();
    dio.options.connectTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.receiveTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.responseType = ResponseType.plain;
    dio.options.headers = headers;
    try {
      final _response = await dio.get(url);
      if (_response.statusCode == 200) {
        return _response.data;
      } else {
        String message = _response.data is Map ? (_response.data['message'] ?? _response.statusMessage ?? 'unknown error') : (_response.statusMessage ?? 'unknown error');
        throw Exception('Failed to fetch data: HTTP ${_response.statusCode}: $message');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        String message = e.response!.data is Map ? (e.response!.data['message'] ?? e.response!.statusMessage ?? 'Server error') : (e.response!.statusMessage ?? 'Server error');
        throw Exception('Failed to fetch data: HTTP ${e.response!.statusCode}: $message');
      } else {
        throw Exception('Failed to fetch data: ${e.message ?? "Network error"}');
      }
    } catch (e) {
      throw Exception('Failed to fetch data: Unexpected error: $e');
    }
  }

  static Widget getSilentLoginDialog() {
    return AlertDialog(
      title: const Text(LoginConstants.silentLoginFailedTitle),
      content: const Text(LoginConstants.silentLoginFailedDesc),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ucLabelColor,
          ),
          onPressed: () {
            Get.back(closeOverlays: true);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  // method for implementing exponential backoff for silentLogin
  // mimicking existing code from React Native versions of campus-mobile
  static Future<dynamic> authorizedPublicPost(
      String url, Map<String, String> headers, dynamic body) async {
    int retries = 0;
    int waitTime = 0;
    try {
      var response = await authorizedPost(url, headers, body);
      return response;
    } catch (e) {
      // exponential backoff here
      retries++;
      waitTime = SSO_REFRESH_RETRY_INCREMENT;
      while (retries <= SSO_REFRESH_MAX_RETRIES) {
        // wait for the wait time to elapse
        await Future.delayed(Duration(milliseconds: waitTime));

        // calculate new wait time (not exponential for now, mimicking previous code)
        waitTime *= SSO_REFRESH_RETRY_MULTIPLIER;
        // try to log in again
        try {
          var response = await authorizedPost(url, headers, body);

          // no exception thrown, success, return response
          return response;
        } catch (e) {
          // still raising an exception, increment retries and try again
          retries++;
        }
      }
    }
    // if here, silent login has failed
    // throw exception to inform caller
    await Get.dialog(getSilentLoginDialog());
    throw new Exception(ErrorConstants.silentLoginFailed);
  }

  static Future<dynamic> authorizedPost(
      String url, Map<String, String>? headers, dynamic body) async {
    Dio dio = new Dio();
    dio.options.connectTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.receiveTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.headers = headers;
    try {
      final _response = await dio.post(url, data: body);
      // Successful responses (2xx) generally don't throw exceptions,
      // but Dio can be configured to throw for non-2xx codes.
      // Assuming default behavior where 2xx are not exceptions:
      if (_response.statusCode == 200 || _response.statusCode == 201) {
        return _response.data;
      } else {
        // This else block might be redundant if Dio throws for non-2xx.
        // For safety, keeping a generic error for unexpected status codes not caught by DioException.
        String message = _response.data is Map ? (_response.data['message'] ?? _response.statusMessage ?? 'unknown error') : (_response.statusMessage ?? 'unknown error');
        throw Exception('${ErrorConstants.authorizedPostErrors}HTTP ${_response.statusCode}: $message');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // We have a response from the server, even if it's an error code
        String message = e.response!.data is Map ? (e.response!.data['message'] ?? e.response!.statusMessage ?? 'Server error') : (e.response!.statusMessage ?? 'Server error');
        if (e.response!.statusCode == 400) {
          throw Exception(ErrorConstants.authorizedPostErrors + message);
        } else if (e.response!.statusCode == 401) {
          throw Exception(ErrorConstants.authorizedPostErrors + ErrorConstants.invalidBearerToken);
        } else if (e.response!.statusCode == 404) {
          throw Exception(ErrorConstants.authorizedPostErrors + message);
        } else if (e.response!.statusCode == 500) {
          throw Exception(ErrorConstants.authorizedPostErrors + message);
        } else if (e.response!.statusCode == 409) {
          throw Exception(ErrorConstants.duplicateRecord + message);
        } else {
          throw Exception('${ErrorConstants.authorizedPostErrors}HTTP ${e.response!.statusCode}: $message');
        }
      } else {
        // Error without a response (network error, timeout, etc.)
        throw Exception('${ErrorConstants.authorizedPostErrors}${e.message ?? "Network error"}');
      }
    } catch (e) {
      // Catch-all for non-Dio exceptions
      throw Exception('${ErrorConstants.authorizedPostErrors}Unexpected error: $e');
    }
  }

  static Future<dynamic> authorizedPut(
      String url, Map<String, String> headers, dynamic body) async {
    Dio dio = new Dio();
    dio.options.connectTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.receiveTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.headers = headers;
    try {
      final _response = await dio.put(url, data: body);
      if (_response.statusCode == 200 || _response.statusCode == 201) {
        return _response.data;
      } else {
        String message = _response.data is Map ? (_response.data['message'] ?? _response.statusMessage ?? 'unknown error') : (_response.statusMessage ?? 'unknown error');
        throw Exception('${ErrorConstants.authorizedPutErrors}HTTP ${_response.statusCode}: $message');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        String message = e.response!.data is Map ? (e.response!.data['message'] ?? e.response!.statusMessage ?? 'Server error') : (e.response!.statusMessage ?? 'Server error');
        if (e.response!.statusCode == 400) {
          throw Exception(ErrorConstants.authorizedPutErrors + message);
        } else if (e.response!.statusCode == 401) {
          throw Exception(ErrorConstants.authorizedPutErrors + ErrorConstants.invalidBearerToken);
        } else if (e.response!.statusCode == 404) {
          throw Exception(ErrorConstants.authorizedPutErrors + message);
        } else if (e.response!.statusCode == 500) {
          throw Exception(ErrorConstants.authorizedPutErrors + message);
        } else {
          throw Exception('${ErrorConstants.authorizedPutErrors}HTTP ${e.response!.statusCode}: $message');
        }
      } else {
        throw Exception('${ErrorConstants.authorizedPutErrors}${e.message ?? "Network error"}');
      }
    } catch (e) {
      throw Exception('${ErrorConstants.authorizedPutErrors}Unexpected error: $e');
    }
  }

  static Future<dynamic> authorizedDelete(
      String url, Map<String, String> headers) async {
    Dio dio = new Dio();
    dio.options.connectTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.receiveTimeout = Duration(milliseconds: DEFAULT_TIMEOUT);
    dio.options.headers = headers;
    try {
      final _response = await dio.delete(url);
      if (_response.statusCode == 200) {
        return _response.data;
      } else {
        // This else block might be redundant if Dio throws for non-2xx.
        String message = _response.data is Map ? (_response.data['message'] ?? _response.statusMessage ?? 'unknown error') : (_response.statusMessage ?? 'unknown error');
        throw Exception('Failed to delete data: HTTP ${_response.statusCode}: $message');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        String message = e.response!.data is Map ? (e.response!.data['message'] ?? e.response!.statusMessage ?? 'Server error') : (e.response!.statusMessage ?? 'Server error');
        throw Exception('Failed to delete data: HTTP ${e.response!.statusCode}: $message');
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout) {
        print('Timeout error during delete: ${e.message}');
        throw Exception('Failed to delete data: Timeout');
      } else {
        print('Network error during delete: ${e.message}');
        throw Exception('Failed to delete data: Network error');
      }
    } on TimeoutException catch (err) { // Should be caught by DioException with timeout types, but kept for safety.
      print('TimeoutException during delete: $err');
      throw Exception('Failed to delete data: Timeout');
    } catch (err) { // Catch-all for non-Dio exceptions
      print('Generic error during delete: $err');
      throw Exception('Failed to delete data: $err');
    }
  }

  static Future<bool> getNewToken(Map<String, String> headers) async {
    final String tokenEndpoint = dotenv.get('NEW_TOKEN_ENDPOINT');
    final Map<String, String> tokenHeaders = {
      "content-type": 'application/x-www-form-urlencoded',
      "Authorization": dotenv.get('MOBILE_APP_PUBLIC_DATA_KEY')
    };
    try {
      var response = await authorizedPost(
          tokenEndpoint, tokenHeaders, "grant_type=client_credentials");
      headers["Authorization"] = "Bearer " + response["access_token"];
      return true;
    } catch (e) {
      return false;
    }
  }
}
