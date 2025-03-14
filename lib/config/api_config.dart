import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // News API configuration
  static String get newsApiKey => dotenv.env['NEWS_API_KEY'] ?? '';
  static String get newsBaseUrl => dotenv.env['NEWS_BASE_URL'] ?? 'https://newsapi.org/v2';

  // RapidAPI configuration for Google Places
  static String get rapidApiKey => dotenv.env['RAPID_API_KEY'] ?? '';
  static String get rapidApiHost => dotenv.env['RAPID_API_HOST'] ?? 'google-map-places-new-v2.p.rapidapi.com';

  // OpenRouteService configuration
  static String get openRouteKey => dotenv.env['OPEN_ROUTE_KEY'] ?? '';
  static String get openRouteBaseUrl => dotenv.env['OPEN_ROUTE_BASE_URL'] ?? 'https://api.openrouteservice.org';
}