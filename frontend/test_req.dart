import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    final res = await dio.post('http://127.0.0.1:3000/api/v1/auth/register', data: {
      'role': 'TAILOR',
      'full_name': 'KHAN',
      'business_name': 'KHAN',
      'username': 'KHAN',
      'password': 'KHAN',
      'city': 'Karachi',
      'specializations': [],
      'price_min': null,
      'price_max': null,
    });
    print('SUCCESS: \${res.statusCode}');
  } catch (e) {
    if (e is DioException) {
      print('ERROR STATUS: \${e.response?.statusCode}');
      print('ERROR DATA: \${e.response?.data}');
    } else {
      print('OTHER ERROR: \$e');
    }
  }
}
