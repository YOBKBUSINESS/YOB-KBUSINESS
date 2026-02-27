class AppConstants {
  AppConstants._();

  static const String appName = 'YOB K Business';
  static const String appVersion = '0.1.0';

  // API
  static const String apiVersion = 'v1';
  static const String apiBasePath = '/api/$apiVersion';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const List<String> allowedDocExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
  ];

  // Financial thresholds
  static const double lowFundsThreshold = 500000; // FCFA
  static const double criticalFundsThreshold = 100000; // FCFA

  // Currency
  static const String currency = 'FCFA';
  static const String currencySymbol = 'FCFA';
}
