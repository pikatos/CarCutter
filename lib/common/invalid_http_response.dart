import 'package:http/http.dart' as http;

class InvalidHttpResponse implements Exception {
  final http.Response response;

  InvalidHttpResponse(this.response);

  @override
  String toString() {
    return 'InvalidHttpResponse: ${response.statusCode}';
  }
}
