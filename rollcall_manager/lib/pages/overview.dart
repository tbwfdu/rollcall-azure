// ignore_for_file: avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_final_fields

import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart' as material;
import 'package:rollcall_manager/pages/sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Widget spacer = SizedBox(height: 5.0);

_errorDialog(context) {
  showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return ContentDialog(
            title: Text('Error'),
            content: Column(
              children: [
                Text('Error.'),
              ],
            ),
            actions: [
              FilledButton(
                  child: Text('OK'),
                  onPressed: () async {
                    setState(() {});

                    Timer(Duration(seconds: 3), () {
                      setState(() {
                        Navigator.pop(context);
                        Timer(Duration(seconds: 1), () {});
                      });
                    });
                  }),
            ],
          );
        });
      });
}

class OverviewPage extends StatefulWidget {
  const OverviewPage({Key? key}) : super(key: key);
  @override
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  void _bigHammer() async {
    rollcallSyncStatus();
    azureStatus();
    accessStatus();
    googleStatus();
    setState(() {
      needsBuild = true;
    });
    Timer(Duration(seconds: 1), () {
      setState(() {
        needsBuild = false;
      });
    });
  }

  bool _showSuccess = false;
  bool _showWarning = false;
  bool _showError = false;
  bool _infobar = false;
  String message = '';
  String apiurl = '';
  String apiuser = '';
  String apipass = '';
  String mode = '';

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

      mode = await prefs.getString('mode').toString();

      return 'ok';
    }
    return 'notok';
  }

  Future accessStatus() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;

    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/status'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );

    var result = await jsonDecode(response.body);

    return result;
  }

  Future googleStatus() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;

    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/status'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var result = await jsonDecode(response.body);

    return result;
  }

  Future azureStatus() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;

    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/status'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var result = await jsonDecode(response.body);

    return result;
  }

  Future rollcallSyncStatus() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/ping'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var result = await jsonDecode(response.body);

    return result;
  }

  bool accessError = false;
  bool googleError = false;

  _showInfobar() {
    if (_showSuccess) {
      return _infobarSuccess(message);
    }
    if (_showWarning) {
      return _infobarWarning(message);
    }
    if (_showError) {
      return _infobarError(message);
    }
  }

  _infobarSuccess(message) {
    return Column(children: [
      SizedBox(
        width: 800,
        child: InfoBar(
          title: Text('Success.'),
          content: Text(message), // optional
          severity: InfoBarSeverity
              .success, // optional. Default to InfoBarSeverity.info
        ),
      ),
      SizedBox(
        height: 20,
      )
    ]);
  }

  _infobarWarning(message) {
    return Column(children: [
      SizedBox(
        width: 800,
        child: InfoBar(
          title: Text('Success.'),
          content: Text(message), // optional
          severity: InfoBarSeverity
              .warning, // optional. Default to InfoBarSeverity.info
        ),
      ),
      SizedBox(
        height: 20,
      )
    ]);
  }

  _infobarError(message) {
    return Column(children: [
      SizedBox(
        width: 800,
        child: InfoBar(
          title: Text('Success.'),
          content: Text(message), // optional
          severity: InfoBarSeverity
              .error, // optional. Default to InfoBarSeverity.info
        ),
      ),
      SizedBox(
        height: 20,
      )
    ]);
  }

  final FlyoutController controller = FlyoutController();
  final FlyoutController dpController = FlyoutController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _getPrefs();
    _bigHammer();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        header: PageHeader(
          title: Text(
            mode == 'azure'
                ? 'Rollcall Manager for Azure Active Directory'
                : 'Rollcall Manager for Google Directory',
            style: TextStyle(
              fontFamily: 'SegoeUI',
            ),
          ),
        ),
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                      child: Text(
                    mode == 'azure'
                        ? 'Rollcall is a tool that allows Workspace ONE Administrators synchronise Users and Groups from Azure Active Directory.'
                        : 'Rollcall is a tool that allows Workspace ONE Administrators synchronise Users and Groups from a Google Directory.',
                  )),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 30, top: 50, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InfoLabel(
                    labelStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SegoeUI'),
                    label: 'Configuration Status',
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  ClipOval(
                    child: material.Material(
                      color: Colors.blue, // Button color
                      child: material.InkWell(
                        splashColor:
                            Color.fromARGB(65, 255, 255, 255), // Splash color
                        onTap: () {
                          _bigHammer();
                        },
                        child: Tooltip(
                          message: 'Refresh',
                          child: SizedBox(
                              width: 25,
                              height: 25,
                              child: Icon(
                                FluentIcons.refresh,
                                size: 10,
                                color: Colors.white,
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            // All The Statutes //
            needsBuild
                ? Column(children: [
                    SizedBox(height: 30),
                    Text('Loading'),
                    SizedBox(height: 5),
                    ProgressBar()
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
//Access Status

                          Mica(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Workspace ONE Access',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  SizedBox(
                                    height: 100,
                                    width: 220,
                                    child: FutureBuilder(
                                      future:
                                          accessStatus(), // a previously-obtained Future<String> or null
                                      builder: (BuildContext context,
                                          AsyncSnapshot snapshot) {
                                        List<Widget> children;
                                        if (snapshot.hasData) {
                                          if (snapshot.data['access'] ==
                                              'true') {
                                            children = <Widget>[
                                              InfoBar(
                                                title: Text('Success'),
                                                severity: InfoBarSeverity
                                                    .success, // optional. Default to InfoBarSeverity.info
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                  'Connectivity between Rollcall and Workspace ONE Access API.'),
                                            ];
                                          } else {
                                            children = <Widget>[
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 220,
                                                    child: InfoBar(
                                                      isLong: true,
                                                      title: Text('Error'),
                                                      content: Text(
                                                          'Tenant Details Configured?'),
                                                      severity: InfoBarSeverity
                                                          .error, // optional. Default to InfoBarSeverity.info
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ];
                                          }
                                        } else if (snapshot.hasError) {
                                          children = <Widget>[
                                            const Icon(
                                              FluentIcons.error,
                                              color: Colors.errorPrimaryColor,
                                              size: 30,
                                            ),
                                          ];
                                        } else {
                                          children = const <Widget>[
                                            ProgressRing(),
                                          ];
                                        }
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: children,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
//Google API Status
                          if (mode == 'azure')
                            Mica(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Azure AD API',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    SizedBox(
                                      height: 100,
                                      width: 220,
                                      child: FutureBuilder(
                                        future:
                                            azureStatus(), // a previously-obtained Future<String> or null
                                        builder: (BuildContext context,
                                            AsyncSnapshot snapshot) {
                                          List<Widget> children;
                                          if (snapshot.hasData) {
                                            if (snapshot.data['azure'] ==
                                                'true') {
                                              children = <Widget>[
                                                InfoBar(
                                                  title: Text('Success'),
                                                  severity: InfoBarSeverity
                                                      .success, // optional. Default to InfoBarSeverity.info
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                    'Connectivity between Rollcall and Azure Active Directory API.'),
                                              ];
                                            } else {
                                              children = <Widget>[
                                                const Icon(
                                                  FluentIcons.error,
                                                  color:
                                                      Colors.errorPrimaryColor,
                                                  size: 30,
                                                ),
                                              ];
                                            }
                                          } else if (snapshot.hasError) {
                                            children = <Widget>[
                                              const Icon(
                                                FluentIcons.error,
                                                color: Colors.errorPrimaryColor,
                                                size: 30,
                                              ),
                                            ];
                                          } else {
                                            children = const <Widget>[
                                              ProgressRing(),
                                            ];
                                          }
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: children,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
//Access Sync Service Status
                          SizedBox(
                            width: 20,
                          ),
                          if (mode == 'google')
                            Mica(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Google Directory API',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    SizedBox(
                                      height: 100,
                                      width: 220,
                                      child: FutureBuilder(
                                        future:
                                            googleStatus(), // a previously-obtained Future<String> or null
                                        builder: (BuildContext context,
                                            AsyncSnapshot snapshot) {
                                          List<Widget> children;
                                          if (snapshot.hasData) {
                                            if (snapshot.data['google'] ==
                                                'true') {
                                              children = <Widget>[
                                                InfoBar(
                                                  title: Text('Success'),
                                                  severity: InfoBarSeverity
                                                      .success, // optional. Default to InfoBarSeverity.info
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Text(
                                                    'Connectivity between Rollcall and Google Directory API.'),
                                              ];
                                            } else {
                                              children = <Widget>[
                                                const Icon(
                                                  FluentIcons.error,
                                                  color:
                                                      Colors.errorPrimaryColor,
                                                  size: 30,
                                                ),
                                              ];
                                            }
                                          } else if (snapshot.hasError) {
                                            children = <Widget>[
                                              const Icon(
                                                FluentIcons.error,
                                                color: Colors.errorPrimaryColor,
                                                size: 30,
                                              ),
                                            ];
                                          } else {
                                            children = const <Widget>[
                                              ProgressRing(),
                                            ];
                                          }
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: children,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
//Access Sync Service Status
                          SizedBox(
                            width: 20,
                          ),
                          Mica(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rollcall Service',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  SizedBox(
                                    height: 100,
                                    width: 220,
                                    child: FutureBuilder(
                                      future:
                                          rollcallSyncStatus(), // a previously-obtained Future<String> or null
                                      builder: (BuildContext context,
                                          AsyncSnapshot snapshot) {
                                        List<Widget> children;
                                        if (snapshot.hasData) {
                                          if (snapshot.data['status'] == 'ok') {
                                            children = <Widget>[
                                              InfoBar(
                                                title: Text('Success'),
                                                severity: InfoBarSeverity
                                                    .success, // optional. Default to InfoBarSeverity.info
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                  'Rollcall access-sync process running and communicating.'),
                                            ];
                                          } else {
                                            children = <Widget>[
                                              const Icon(
                                                FluentIcons.error,
                                                color: Colors.errorPrimaryColor,
                                                size: 30,
                                              ),
                                            ];
                                          }
                                        } else if (snapshot.hasError) {
                                          children = <Widget>[
                                            const Icon(
                                              FluentIcons.error,
                                              color: Colors.errorPrimaryColor,
                                              size: 30,
                                            ),
                                          ];
                                        } else {
                                          children = const <Widget>[
                                            ProgressRing(),
                                          ];
                                        }
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: children,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
        bottomBar: Padding(
          padding: const EdgeInsets.all(15.0),
          // child: Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     ClipOval(
          //       child: material.Material(
          //         color: Colors.blue, // Button color
          //         child: material.InkWell(
          //           splashColor:
          //               Color.fromARGB(178, 255, 255, 255), // Splash color
          //           onTap: () {
          //             _bigHammer();
          //           },
          //           child: Tooltip(
          //             message: 'Refresh',
          //             child: SizedBox(
          //                 width: 45,
          //                 height: 45,
          //                 child: Icon(
          //                   FluentIcons.refresh,
          //                   color: Colors.white,
          //                 )),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ));
  }
}
