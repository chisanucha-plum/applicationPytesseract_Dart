// config.dart
class Config {
  static String ipAddress = '172.16.0.236'; // Default IP address

  static void setIpAddress(String ip) {
    ipAddress = ip;
  }

  static String get ipAddressUrl => 'http://$ipAddress:5000';
}
