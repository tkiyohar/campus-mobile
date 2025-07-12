import 'dart:async';
import 'dart:io';
import 'package:campus_mobile_experimental/app_networking.dart';
import 'package:campus_mobile_experimental/core/models/speed_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart'; // Changed import
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpeedTestService {
  SpeedTestService();

  /// STATES
  bool _isLoading = false;
  String? _error;
  final Map<String, String> headers = {
    "accept": "application/json",
  };

  /// MODELS
  SpeedTestModel? _speedTestModel;

  /// SERVICES
  var deviceInfo = DeviceInfoPlugin();
  var _connectivity = Connectivity();

  Future<bool> checkSimulation() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        if (!androidInfo.isPhysicalDevice) {
          return true;
        }
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        if (!iosInfo.isPhysicalDevice) {
          return true;
        }
      }
    } catch (exception) {
      print(exception.toString());
    }
    return false;
  }

  Future<bool> fetchSignedUrls() async {
    _error = null; _isLoading = true;
    try {
      await NetworkHelper.getNewToken(headers);
      // Get download & upload urls
      String? _downloadResponse = await NetworkHelper.authorizedFetch(
          dotenv.get('SPEED_TEST_DOWNLOAD_ENDPOINT'), headers);
      String? _uploadResponse = await NetworkHelper.authorizedFetch(
          dotenv.get('SPEED_TEST_UPLOAD_ENDPOINT'), headers);

      /// parse data
      // Fetch WiFi details using network_info_plus
      String? ssid, bssid, ipAddress, gatewayIP;
      bool isUCSDWifi = false;

      var connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        final NetworkInfo networkInfo = NetworkInfo();
        try {
          ssid = await networkInfo.getWifiName();
          bssid = await networkInfo.getWifiBSSID();
          ipAddress = await networkInfo.getWifiIP();
          gatewayIP = await networkInfo.getWifiGatewayIP();

          // Example: Determine if it's UCSD WiFi based on SSID
          // This logic might need to be adjusted based on actual UCSD SSIDs
          if (ssid != null && (ssid.toLowerCase().contains('ucsd') || ssid.toLowerCase().contains('eduroam'))) {
            isUCSDWifi = true;
          }
        } catch (e) {
          print('Error fetching WiFi details: $e');
          // Keep default null/empty values for WiFi fields
        }
      }

      _speedTestModel = SpeedTestModel.fromService(
        isUCSDWifi: isUCSDWifi,
        downloadJson: _downloadResponse != null ? json.decode(_downloadResponse) : null,
        uploadJson: _uploadResponse != null ? json.decode(_uploadResponse) : null,
        ssid: ssid,
        bssid: bssid,
        ipAddress: ipAddress,
        routerIP: gatewayIP,
        // Other fields like macAddress, linkSpeed, etc., are not directly available
        // and will be null/empty as per SpeedTestModel.fromService defaults.
      );
      return true;
    } catch (exception) {
      // Occurs when there is no connection or other errors
       _speedTestModel = SpeedTestModel.fromService(
        isUCSDWifi: false,
        downloadJson: null,
        uploadJson: null,
      );
      _error = exception.toString();
      print('Error in fetchSignedUrls: $_error');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // fetchNetworkDiagnostics() is now integrated into fetchSignedUrls.

  /// SIMPLE GETTERS
  get isLoading => _isLoading;
  get error => _error;
  SpeedTestModel? get speedTestModel => _speedTestModel;
}
