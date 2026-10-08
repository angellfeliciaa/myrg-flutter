import 'api_endpoints.dart';

class ApiClient {
  const ApiClient({this.baseUrl = ApiEndpoints.baseUrl});

  final String baseUrl;

  Uri uri(String path, {Map<String, dynamic>? queryParameters}) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}
