// ignore_for_file: avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart' as material;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class TenantPage extends StatefulWidget {
  const TenantPage({Key? key}) : super(key: key);
  @override
  _TenantPageState createState() => _TenantPageState();
}

class _TenantPageState extends State<TenantPage> {
  String message = '';
  bool _dangerZone = false;
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

      return apiurl;
    }
    return apiurl;
  }

  void _bigHammer() async {
    _getPrefs();
    getSecrets();
    setState(() {
      needsBuildBoth = true;
      //rows = [];
      // dirs = [];
    });
    Timer(Duration(seconds: 2), () {
      setState(() {
        needsBuildBoth = false;
      });
    });
  }

  final _tenantURL = TextEditingController();
  final _clientID = TextEditingController();
  final _clientSecret = TextEditingController();
  final _domain = TextEditingController();

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

  bool needsBuild = false;
  bool needsBuildBoth = false;
  bool loading = false;
  bool? accessUp;
  bool? hasSecrets;

  bool hasError = false;

  status() async {
    var result;
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    try {
      final response = await http.get(
        Uri.parse(apiurl + '/status'),
        // Send authorization headers to the backend.
        headers: {
          HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
          //HttpHeaders.  2´£acceptHeader: 'Accept: application/json',
          "Authorization": _basicAuth
        },
      );
      result = await jsonDecode(response.body);

      if (result['access'] == 'undefined') {
        setState(() {
          accessUp = false;
          hasError = true;
        });
      } else {
        setState(() {
          hasError = false;
        });
      }
    } on Exception catch (e) {
      // Anything else that is an exception
      print('Unknown exception: $e');

      setState(() {
        hasError = true;
      });
    } catch (e) {
      // No specified type, handles all
      print('Something really unknown: $e');

      result = true;
      setState(() {
        hasError = true;
      });
    }
    // Always clean up, even if case of exception

    return result;
  }

  Future getSecrets() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/secrets'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var json = jsonDecode(response.body);
    String url = json['url'];
    if (url.isNotEmpty) {
      setState(() {
        hasSecrets = true;
      });
    }
    return json;
  }

  Future<void> _clearPrefs() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove('api_url');
    await prefs.remove('api_user');
    await prefs.remove('api_pass');
  }

  saveCredentials() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));

    Map data = {
      'url': _tenantURL.text,
      'client_id': _clientID.text,
      'client_secret': _clientSecret.text,
      'domain': _domain.text
    };
    http.Response response = await http.post(
        Uri.parse(
          apiurl + '/saveconfig',
        ),
        headers: {
          HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
          "Authorization": _basicAuth
        },
        body: data);

    var json = jsonDecode(response.body);
    setState(() {
      needsBuild = false;
    });
    return 'done';
  }

  _confirmDeleteDialog(context) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ContentDialog(
              title: Text('Confirmation'),
              content: Column(
                children: [
                  Visibility(
                    visible: !loading,
                    child: Text(
                        'You\'re about clear your Workspace ONE Access tenant settings. Are you sure?'),
                  ),
                  Visibility(
                      visible: loading,
                      child: Center(
                        child: SizedBox(
                            child: Column(children: [
                          SizedBox(
                            height: 10,
                          ),
                          ProgressRing(),
                          SizedBox(
                            height: 10,
                          ),
                        ])),
                      ))
                ],
              ),
              actions: [
                if (!loading)
                  Button(
                      child: Text('Cancel'),
                      onPressed: () async {
                        Navigator.pop(context);
                      }),
                if (!loading)
                  FilledButton(
                      child: Text('OK'),
                      onPressed: () async {
                        setState(() {
                          loading = true;
                        });
                        await clearTenant();
                        await status();
                        Timer(Duration(seconds: 1), () {
                          setState(() {
                            Navigator.pop(context);
                            Timer(Duration(seconds: 1), () {
                              needsBuild = true;
                              loading = false;
                            });
                          });
                        });
                      }),
                if (loading) Text('')
              ],
            );
          });
        });
  }

  _confirmDangerDialog(context) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ContentDialog(
              title: Text('Danger Ahead'),
              content: Column(
                children: [
                  Visibility(
                    visible: !loading,
                    child: Text(
                        'You are about to enable access to some capabilities that are irreversable. Are you sure?'),
                  ),
                  Visibility(
                      visible: loading,
                      child: Center(
                        child: SizedBox(
                            child: Column(children: [
                          SizedBox(
                            height: 10,
                          ),
                          ProgressRing(),
                          SizedBox(
                            height: 10,
                          ),
                        ])),
                      ))
                ],
              ),
              actions: [
                if (!loading)
                  Button(
                      child: Text('Cancel'),
                      onPressed: () async {
                        Navigator.pop(context);
                      }),
                if (!loading)
                  FilledButton(
                      child: Text('OK'),
                      onPressed: () async {
                        setState(() {
                          loading = true;
                        });
                        Timer(Duration(seconds: 1), () {
                          setState(() {
                            Navigator.pop(context);
                            _dangerZone = true;
                            Timer(Duration(seconds: 1), () {
                              _dangerZone = true;
                              loading = false;
                            });
                          });
                        });
                      }),
                if (loading) Text('')
              ],
            );
          });
        });
  }

  _confirmMode(context) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ContentDialog(
              title: Text('Change Mode'),
              content: Column(
                children: [
                  Visibility(
                    visible: !loading,
                    child: Text(
                        'This will re-run the First Run setup again to allow you to change the Rollcall API URL. It will not delete any Rollcall API settings or Rollcall Manager Configurations.'),
                  ),
                  Visibility(
                      visible: loading,
                      child: Center(
                        child: SizedBox(
                            child: Column(children: [
                          SizedBox(
                            height: 10,
                          ),
                          ProgressRing(),
                          SizedBox(
                            height: 10,
                          ),
                        ])),
                      ))
                ],
              ),
              actions: [
                if (!loading)
                  Button(
                      child: Text('Cancel'),
                      onPressed: () async {
                        Navigator.pop(context);
                      }),
                if (!loading)
                  FilledButton(
                      child: Text('OK'),
                      onPressed: () async {
                        setState(() {
                          loading = true;
                        });
                        Timer(Duration(seconds: 1), () {
                          _clearPrefs();
                          Phoenix.rebirth(context);
                        });
                      }),
                if (loading) Text('')
              ],
            );
          });
        });
  }

  Future clearTenant() async {
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    http.Response response = await http.delete(
      Uri.parse(
        apiurl + '/cleartenant',
      ),
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        "Authorization": _basicAuth
      },
    );

    var res = jsonDecode(response.body);
    setState(() {
      needsBuild = false;
      hasSecrets = false;
      hasError = true;
    });
    return res;
  }

  _confirmAddTenantDetails(context) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ContentDialog(
              title: Text('Confirmation'),
              content: Column(
                children: [
                  Visibility(
                    visible: !loading,
                    child: Text(
                        'You\'re about to update your Workpace ONE Access Tenant details.'),
                  ),
                  Visibility(
                      visible: loading,
                      child: Center(
                        child: SizedBox(
                            child: Column(children: [
                          SizedBox(
                            height: 10,
                          ),
                          ProgressRing(),
                          SizedBox(
                            height: 10,
                          ),
                        ])),
                      ))
                ],
              ),
              actions: [
                if (!loading)
                  Button(
                      child: Text('Cancel'),
                      onPressed: () async {
                        Navigator.pop(context);
                      }),
                if (!loading)
                  FilledButton(
                      child: Text('OK'),
                      onPressed: () async {
                        setState(() {
                          loading = true;
                        });
                        await saveCredentials();
                        await status();
                        Timer(Duration(seconds: 1), () {
                          setState(() {
                            Navigator.pop(context);

                            Timer(Duration(seconds: 1), () {
                              needsBuild = true;
                              _clientID.clear();
                              _clientSecret.clear();
                              _tenantURL.clear();
                              _domain.clear();
                            });
                          });
                        });
                      }),
                if (loading) Text('')
              ],
            );
          });
        });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  initState() {
    status();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text(
          'Workspace ONE Tenant Settings',
          style: TextStyle(
            fontFamily: 'SegoeUI',
          ),
        ),
        commandBar: Row(
          children: [
            ToggleSwitch(
              checked: _dangerZone,
              onChanged: (v) => setState(() => _dangerZone = v),
              content: Text(_dangerZone
                  ? 'Disable Superadmin Mode'
                  : 'Enable Superadmin Mode'),
            )
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(children: [
          Padding(
            padding: EdgeInsets.only(left: 30, top: 30, right: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InfoLabel(
                  labelStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SegoeUI'),
                  label: 'Existing Configuration',
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
          // All The Statutes //
          needsBuildBoth
              ? SizedBox(
                  height: 250,
                  child: Column(children: [
                    SizedBox(height: 30),
                    Text('Loading'),
                    SizedBox(height: 5),
                    ProgressBar()
                  ]),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Mica(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tentant URL',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  SizedBox(
                                    height: 140,
                                    width: 500,
                                    child: FutureBuilder(
                                        future:
                                            getSecrets(), // a previously-obtained Future<String> or null
                                        builder: (BuildContext context,
                                            AsyncSnapshot snapshot) {
                                          if (needsBuild == true) {
                                            Timer(Duration(seconds: 1), () {
                                              getSecrets();
                                              status();
                                            });
                                          }
                                          List<Widget> children;
                                          if (snapshot.hasData) {
                                            children = <Widget>[
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 300,
                                                    child: InfoBar(
                                                      title: Text('Configured'),
                                                      severity: InfoBarSeverity
                                                          .success, // optional. Default to InfoBarSeverity.info
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Row(
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 120,
                                                        child: Text(
                                                          'URL: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(snapshot.data["url"])
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 120,
                                                        child: Text(
                                                          'Client ID: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(snapshot
                                                          .data["client_id"])
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 120,
                                                        child: Text(
                                                          'Client Secret: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text('****************')
                                                      //Text(snapshot.data["client_secret"])
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 120,
                                                        child: Text(
                                                          'Domain Name: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(snapshot
                                                          .data["domain"])
                                                    ],
                                                  ),
                                                ],
                                              )
                                            ];
                                          } else if (snapshot.hasError) {
                                            hasError = true;
                                            children = <Widget>[
                                              Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 300,
                                                        child: InfoBar(
                                                          title: Text(
                                                              'Error or Not Configured'),
                                                          severity: InfoBarSeverity
                                                              .error, // optional. Default to InfoBarSeverity.info
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 40,
                                                  )
                                                ],
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
                                        }),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          //Access Tenant Service Status
                        ],
                      ),
                    ),
                    Visibility(
                      visible: (hasSecrets == true),
                      child: Row(
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(left: 30, top: 0),
                              child: SizedBox(
                                width: 510,
                                child: Row(
                                  children: [
                                    Row(
                                      children: [
                                        FilledButton(
                                          child: Text(
                                              'Clear Tenant Configuration'),
                                          onPressed: () async {
                                            _confirmDeleteDialog(context);
                                          },
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: hasSecrets != true,
                      child: Padding(
                        padding: EdgeInsets.only(left: 30, top: 30),
                        child: SizedBox(
                          width: 820,
                          child: Row(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: Column(children: [
                                      Row(
                                        children: [
                                          InfoLabel(
                                            labelStyle: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'SegoeUI'),
                                            label: 'Add Tenant Details',
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 300,
                                            child: Text('Access Tenant URL'),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 300,
                                            child: TextFormBox(
                                              maxLength: 100,
                                              controller: _tenantURL,
                                              placeholder:
                                                  'eg. \'https://mytenant.vmwareidentity.com\'',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 300,
                                            child: Text('ClientID'),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 300,
                                            child: TextFormBox(
                                              maxLength: 100,
                                              controller: _clientID,
                                              placeholder:
                                                  'eg. \'accessclient\'',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 300,
                                            child: Text('Client Secret'),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 300,
                                            child: TextFormBox(
                                              maxLength: 100,
                                              controller: _clientSecret,
                                              placeholder:
                                                  'eg. \'mysuperlongclientsecret\'',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 300,
                                            child: Text('Domain'),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 300,
                                            child: TextFormBox(
                                              maxLength: 40,
                                              controller: _domain,
                                              placeholder:
                                                  'eg. \'mycompany.com\'',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Button(
                                              child: Text('Clear'),
                                              onPressed: () {
                                                _tenantURL.clear();
                                                _clientID.clear();
                                                _clientSecret.clear();
                                                _domain.clear();
                                              }),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          FilledButton(
                                              child: Text('Submit'),
                                              onPressed: () {
                                                _confirmAddTenantDetails(
                                                    context);
                                              })
                                        ],
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 80,
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 25, top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Mica(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rollcall Manager Mode',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  SizedBox(
                                    height: 50,
                                    width: 500,
                                    child: FutureBuilder(
                                        future:
                                            _getPrefs(), // a previously-obtained Future<String> or null
                                        builder: (BuildContext context,
                                            AsyncSnapshot snapshot) {
                                          List<Widget> children;
                                          if (snapshot.hasData) {
                                            children = <Widget>[
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                          width: 100,
                                                          child: Text('Mode:')),
                                                      if (apiurl.contains(
                                                          'localhost'))
                                                        SizedBox(
                                                            width: 300,
                                                            child: Text(
                                                                'localhost'))
                                                      else
                                                        SizedBox(
                                                            width: 300,
                                                            child:
                                                                Text('remote')),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                          width: 100,
                                                          child:
                                                              Text('Server:')),
                                                      SizedBox(
                                                          width: 300,
                                                          child: Text(
                                                              snapshot.data))
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ];
                                          } else if (snapshot.hasError) {
                                            hasError = true;
                                            children = <Widget>[
                                              Column(
                                                children: [
                                                  SizedBox(
                                                    width: 800,
                                                    height: 150,
                                                    child: Icon(
                                                      FluentIcons.error,
                                                      color: Colors
                                                          .errorPrimaryColor,
                                                      size: 30,
                                                    ),
                                                  ),
                                                ],
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
                                                  MainAxisAlignment.start,
                                              children: children,
                                            ),
                                          );
                                        }),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          //Access Tenant Service Status
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(left: 30, top: 0),
                            child: SizedBox(
                              width: 510,
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      FilledButton(
                                        child: Text('Reset Mode'),
                                        onPressed: () async {
                                          _confirmMode(context);
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )),
                      ],
                    ),
                    Visibility(
                      visible: _dangerZone,
                      child: Row(
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(left: 30, top: 20),
                              child: SizedBox(
                                width: 510,
                                child: Row(
                                  children: [
                                    Row(
                                      children: [
                                        Text('This is on my to-do list.')
                                      ],
                                    )
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                  ],
                ),
        ]),
      ),
      // bottomBar: Padding(
      //   padding: const EdgeInsets.all(15.0),
      //   child: Row(
      //     crossAxisAlignment: CrossAxisAlignment.end,
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [

      //       ClipOval(
      //         child: material.Material(
      //           color: Colors.blue, // Button color
      //           child: material.InkWell(
      //             splashColor: Color.fromARGB(178, 255, 255, 255), // Spcolor
      //             onTap: () {
      //               getSecrets();
      //             },
      //             child: Tooltip(
      //               message: 'Refresh',
      //               child: SizedBox(
      //                   width: 45,
      //                   height: 45,
      //                   child: Icon(
      //                     FluentIcons.refresh,
      //                     color: Colors.white,
      //                   )),
      //             ),
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ));
    );
  }
}
