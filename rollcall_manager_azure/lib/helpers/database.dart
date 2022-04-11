import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DatabaseService {
  getStores() async {
    String _username = r'ctpkZkjVKkRbS';
    String _password = r'$%gUA3=4Y^tbd6SE';
    String _basicAuth =
        'Basic ' + base64Encode(utf8.encode('$_username:$_password'));
    var _apiUrl = r'http://localhost:8080';
    var response = await http.get(
      Uri.parse('$_apiUrl/api/stores'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.authorizationHeader: _basicAuth,
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
      },
    );

    return response.body;
  }

  // searchUsers(userName) async {
  //   var _bearer = await getToken();
  //   var _tenant = await AuthService().getTenant();
  //   if (_bearer != null && _tenant != null) {
  //     var response = await http.get(
  //       Uri.parse(
  //           'https://$_tenant/SAAS/jersey/manager/api/scim/Users?filter=userName+co+"$userName"'),
  //       // Send authorization headers to the backend.
  //       headers: {
  //         HttpHeaders.authorizationHeader: 'Bearer $_bearer',
  //         HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
  //         //HttpHeaders.acceptHeader: 'Accept: application/json',
  //       },
  //     );
  //     var responseJson = jsonDecode(response.body);

  //     return responseJson['Resources'];
  //   }
  //}
}
