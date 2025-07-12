import 'dart:convert'; // Keep for potential future use if SpeedTestService returns JSON parts
import 'dart:io';     // Keep for Platform check

// Removed: import 'package:wifi_connection/WifiInfo.dart';
// No direct import for network_info_plus here, as this is a pure data model.
// The service will use network_info_plus and populate this model.

class SpeedTestModel {
  bool? isUCSDWifi;
  String? uploadUrl;
  String? downloadUrl;
  String? platform;
  String? ssid;          // Available from network_info_plus
  String? bssid;         // Available from network_info_plus
  String? ipAddress;     // Available from network_info_plus
  String? macAddress;    // Not directly available from network_info_plus, mark as nullable or remove
  String? linkSpeed;     // Not directly available, mark as nullable or remove
  String? signalStrength; // Not directly available, mark as nullable or remove
  String? frequency;     // Not directly available, mark as nullable or remove
  String? networkID;     // Not directly available, mark as nullable or remove
  String? isHiddenSSID;  // Not directly available, mark as nullable or remove
  String? routerIP;      // Available as Gateway IP from network_info_plus
  String? channel;       // Not directly available, mark as nullable or remove
  double? latitude;
  double? longitude;
  String? timeStamp;
  double? downloadSpeed;
  double? uploadSpeed;

  SpeedTestModel({
    this.isUCSDWifi,
    this.uploadUrl,
    this.downloadUrl,
    this.platform,
    this.ssid,
    this.bssid,
    this.ipAddress,
    this.macAddress,
    this.linkSpeed,
    this.signalStrength,
    this.frequency,
    this.networkID,
    this.isHiddenSSID,
    this.routerIP,
    this.channel,
    this.latitude,
    this.longitude,
    this.timeStamp,
    this.downloadSpeed,
    this.uploadSpeed,
  });

  // Factory constructor might be simplified or primarily populated by the service.
  // For now, let's make a basic one that primarily takes what's certain.
  // The SpeedTestService will be responsible for fetching WiFi details and then constructing this model.
  factory SpeedTestModel.fromService({
    required bool isUCSDWifi,
    required Map<String, dynamic>? downloadJson,
    required Map<String, dynamic>? uploadJson,
    String? ssid,
    String? bssid,
    String? ipAddress,
    String? routerIP, // Gateway IP
    // Nullable fields for data that might not be available:
    String? macAddress,
    String? linkSpeed,
    String? signalStrength,
    String? frequency,
    String? networkID,
    String? isHiddenSSID,
    String? channel,
  }) {
    return SpeedTestModel(
      isUCSDWifi: isUCSDWifi,
      uploadUrl: uploadJson?["signed_url"],
      downloadUrl: downloadJson?["signed_url"],
      platform: Platform.isAndroid ? "Android" : "iOS",
      ssid: ssid ?? "",
      bssid: bssid ?? "",
      ipAddress: ipAddress ?? "",
      macAddress: macAddress ?? "", // Will be null or empty if not found
      linkSpeed: linkSpeed ?? "",     // Will be null or empty if not found
      signalStrength: signalStrength ?? "", // Will be null or empty if not found
      frequency: frequency ?? "",     // Will be null or empty if not found
      networkID: networkID ?? "",     // Will be null or empty if not found
      isHiddenSSID: isHiddenSSID ?? "", // Will be null or empty if not found
      routerIP: routerIP ?? "",
      channel: channel ?? "",         // Will be null or empty if not found
      latitude: 0.0, // Default, to be populated by location provider
      longitude: 0.0, // Default, to be populated by location provider
      timeStamp: DateTime.now().toUtc().toIso8601String(),
      downloadSpeed: 0.0,
      uploadSpeed: 0.0,
    );
  }
}

// The old speedTestModelFromJson is no longer directly applicable
// as WifiInfo is removed. The SpeedTestService will handle creating the model.
