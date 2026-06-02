import 'package:http/http.dart' as http;
const String baseUrl =
    'https://6a0e63031736097c3609c5f4.mockapi.io/api/v1/Product?page=1&limit=1000';

Future<String> skincareJsonData() async {
  final response = await http.get(Uri.parse(baseUrl));

  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to load products');
  }
}