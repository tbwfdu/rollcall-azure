// ignore_for_file: avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:fluent_ui/fluent_ui.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({Key? key}) : super(key: key);
  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final FlyoutController controller = FlyoutController();
  final FlyoutController dpController = FlyoutController();
  final _logs = TextEditingController();
  String log = '';
  String console = '';

  String apiurl = '';
  String apiuser = '';
  String apipass = '';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Future _getPrefs() async {
    final SharedPreferences prefs = await _prefs;

    var url = prefs.getString('api_url');
    if (url != null) {
      if (url == 'localhost') {
        apiurl = 'http://localhost:8080';
      } else {
        apiurl = url as String;
      }

      apiuser = prefs.getString('api_user').toString();
      apipass = prefs.getString('api_pass').toString();

      return 'ok';
    }
    return 'notok';
  }

  reloadLogs() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/synclog'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    String res = response.body;

    setState(() {
      log = res;
    });
    return res;
  }

  reloadConsoleLogs() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));

    final response = await http.get(
      Uri.parse(apiurl + '/logs'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    String res = response.body;

    setState(() {
      console = res;
    });
    return res;
  }

  Timer? timer;
  Timer? timer2;

  @override
  void dispose() {
    timer?.cancel();
    timer2?.cancel();

    controller.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _getPrefs();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => reloadLogs());
    timer2 =
        Timer.periodic(Duration(seconds: 1), (Timer t) => reloadConsoleLogs());
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        header: PageHeader(
          title: const Text(
            'API Server Logs',
            style: TextStyle(
              fontFamily: 'SegoeUI',
            ),
          ),
        ),
        content: Wrap(spacing: 10, runSpacing: 10, children: [
          Padding(
            padding: EdgeInsets.only(left: 30),
            child: Row(
              children: [
                InfoLabel(
                  labelStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SegoeUI'),
                  label: 'Last Sync Log',
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 30,
            ),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey[20],
                  // border: Border.all(
                  //   color: Color.fromARGB(61, 0, 0, 0),
                  // ),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                    width: 600,
                    height: 250,
                    child: Text(
                      log,
                      maxLines: 20,
                      style: TextStyle(color: Colors.grey[130]),
                    )
                    //  child: TextBox(readOnly: true, maxLines: null, controller: _logs),
                    ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 30),
            child: Row(
              children: [
                InfoLabel(
                  labelStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SegoeUI'),
                  label: 'Console Log',
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 30,
            ),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey[20],
                  // border: Border.all(
                  //   color: Color.fromARGB(61, 0, 0, 0),
                  // ),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                    width: 600,
                    height: 250,
                    child: Text(
                      console,
                      maxLines: 20,
                      style: TextStyle(color: Colors.grey[130]),
                    )
                    //  child: TextBox(readOnly: true, maxLines: null, controller: _logs),
                    ),
              ),
            ),
          ),

          // Padding(
          //   padding: EdgeInsets.only(left: 30),
          //   child: SizedBox(
          //     width: 600,
          //     child: FutureBuilder(
          //       future:
          //           getSyncLog(), // a previously-obtained Future<String> or null
          //       builder: (BuildContext context, AsyncSnapshot snapshot) {
          //         List<Widget> children;
          //         if (snapshot.hasData) {
          //           _logs.text = snapshot.data;
          //           children = <Widget>[
          //             SizedBox(
          //               height: 300,
          //               child: SingleChildScrollView(
          //                 controller:
          //                     ScrollController(initialScrollOffset: 9000),
          //                 child: TextBox(
          //                     readOnly: true,
          //                     maxLines: null,
          //                     controller: _logs),
          //               ),
          //             ),
          //             SizedBox(height: 20),
          //             Row(
          //               children: [
          //                 FilledButton(
          //                   child: Text('Refresh'),
          //                   onPressed: () {
          //                     reloadLogs();
          //                   },
          //                 ),
          //               ],
          //             )
          //           ];
          //         } else if (snapshot.hasError) {
          //           children = <Widget>[
          //             const Icon(
          //               FluentIcons.error,
          //               color: Colors.errorPrimaryColor,
          //               size: 30,
          //             ),
          //           ];
          //         } else {
          //           children = const <Widget>[
          //             ProgressRing(),
          //           ];
          //         }
          //         return Center(
          //           child: Column(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: children,
          //           ),
          //         );
          //       },
          //     ),
          //   ),
          // ),
        ]));
  }
}
