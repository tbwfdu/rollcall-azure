// ignore_for_file: avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart' as material;
import 'package:shared_preferences/shared_preferences.dart';

final recurrence = ['Hourly', 'Daily', 'Weekly'];
final hour = [
  '01:00',
  '02:00',
  '03:00',
  '04:00',
  '05:00',
  '06:00',
  '07:00',
  '08:00',
  '09:00',
  '10:00',
  '11:00',
  '12:00',
  '13:00',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
  '18:00',
  '19:00',
  '20:00',
  '21:00',
  '22:00',
  '23:00',
  '00:00'
];
final day = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];
String? recurrenceValue;
String? dayValue;
String? timeValue;
String? doubleTime;

bool schedConfigured = false;
bool groupSyncConfigured = false;

bool needsBuild = false;
bool needsBuildGroup = false;
bool needsBuildBoth = false;

DateTime date = DateTime.now();

class SyncPage extends StatefulWidget {
  const SyncPage({Key? key}) : super(key: key);
  @override
  _SyncPageState createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool _showSuccess = false;
  bool _showWarning = false;
  bool _showError = false;
  bool _infobar = false;
  String message = '';
  String apiurl = '';
  String apiuser = '';
  String apipass = '';

  Future forceSync() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/forcesync'),
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

  void _bigHammer() async {
    getGroupSync();
    getSyncSchedule();
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

  _saveSchedule() async {
    String freq = '';
    String day = '';
    String time = '';
    if (recurrenceValue != null) {
      if (recurrenceValue == 'Daily') {
        freq = 'day';
      }
      if (recurrenceValue == 'Hourly') {
        freq = 'hour';
      }
      if (recurrenceValue == 'Weekly') {
        freq = 'week';
      }
    }
    if (dayValue != null) {
      day = dayValue.toString();
    }
    if (timeValue != null) {
      time = doubleTime.toString();
    }

    Map data = {
      'synctype': 'schedule',
      'syncvalues': '',
      'frequency': freq,
      'day': day,
      'time': time,
    };

    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));

    http.Response response = await http.post(
        Uri.parse(
          apiurl + '/savesyncschedule',
        ),
        headers: {
          HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
          "Authorization": _basicAuth
        },
        body: data);

    var json = jsonDecode(response.body);

    return json;
  }

  void _hideInfobar() {
    Timer(Duration(seconds: 5), (() {
      setState(() {
        _showSuccess = false;
        _showWarning = false;
        _showError = false;
      });
    }));
  }

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

  _showInfobar() {
    if (_showSuccess) {
      return _infobarSuccess();
    }
    if (_showWarning) {
      return _infobarWarning(message);
    }
    if (_showError) {
      return _infobarError(message);
    }
  }

  Widget _infobarSuccess() {
    return Column(children: [
      SizedBox(
        width: 500,
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

  bool loading = false;
  bool syncing = false;

  Future clearGroupConfig() async {
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.post(
      Uri.parse(apiurl + '/cleargroupconfig'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        "Authorization": _basicAuth
        //HttpHeaders.acceptHeader: 'Accept: application/json',
      },
    );
    var result = await jsonDecode(response.body);

    return result[0];
  }

  Future clearSyncConfig() async {
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.post(
      Uri.parse(apiurl + '/clearsyncconfig'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var result = await jsonDecode(response.body);

    return result[0];
  }

  Future getSyncSchedule() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/getsyncschedule'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );

    var json = jsonDecode(response.body);
    setState(() {
      needsBuild = false;
    });
    return json;
  }

  Future getGroupSync() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/getgroupsync'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var result = await jsonDecode(response.body);
    setState(() {
      needsBuildGroup = false;
    });
    return result;
  }

  _confirmClearSyncDialog(context) {
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
                        'You\'re about to delete your existing sync schedule.'),
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
                        clearSyncConfig();
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

  _confirmClearGroupDialog(context) {
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
                        'You\'re about to delete your Group Sync settings.'),
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
                        clearGroupConfig();
                        Timer(Duration(seconds: 1), () {
                          setState(() {
                            Navigator.pop(context);
                            Timer(Duration(seconds: 1), () {
                              needsBuildGroup = true;
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

  _syncingDialog(context) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ContentDialog(
              constraints: BoxConstraints(maxWidth: 250),
              content: Center(
                  child: Column(
                children: [
                  SizedBox(height: 50, width: 50, child: ProgressRing()),
                  SizedBox(
                    height: 10,
                  ),
                  Text('Starting Forced Sync')
                ],
              )),
            );
          });
        });
  }

  _confirmSaveSync(context) {
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
                        'You\'re about update your scheduled sync settings. Are you sure?'),
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
                          Text('Saving...')
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
                        _saveSchedule();
                        Timer(Duration(seconds: 1), () {
                          setState(() {
                            Navigator.pop(context);
                            Timer(Duration(seconds: 1), () {
                              needsBuildGroup = true;
                              loading = false;
                              recurrenceValue = null;
                              timeValue = null;
                              dayValue = null;
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Column(
          children: [
            Row(
              children: [
                Text(
                  'Synchronisation Settings',
                  style: TextStyle(
                    fontFamily: 'SegoeUI',
                  ),
                )
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'View saved Sync Schedule and the Google Group IDs that are to be synced with Workspace ONE Access. You can also clear saved settings and set up a new schedule if needed.',
                    style: TextStyle(
                        fontFamily: 'SegoeUI',
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          ],
        ),
        commandBar: Column(
          children: [
            FilledButton(
              child: Text('Force Sync'),
              onPressed: () async {
                if (schedConfigured && groupSyncConfigured) {
                  _syncingDialog(context);
                  await forceSync();
                  Timer(
                      Duration(seconds: 3),
                      (() => {
                            setState(() {
                              _showSuccess = true;
                            }),
                            Navigator.pop(context),
                            _hideInfobar()
                          }));
                }
              },
            ),
            SizedBox(
              height: 35,
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
                  label: 'Existing Settings',
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
                  height: 155,
                  child: Column(children: [
                    SizedBox(height: 50),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Mica(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Schedule',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  SizedBox(
                                      height: 100,
                                      width: 220,
                                      child: FutureBuilder(
                                        future:
                                            getSyncSchedule(), // a previously-obtained Future<String> or null
                                        builder: (BuildContext context,
                                            AsyncSnapshot snapshot) {
                                          if (needsBuild == true) {
                                            Timer(Duration(seconds: 1), () {
                                              getSyncSchedule();
                                            });
                                          }
                                          List<Widget> children;
                                          if (snapshot.hasData) {
                                            if (snapshot.data['synctype'] ==
                                                'schedule') {
                                              schedConfigured = true;

                                              String? freq;
                                              String? time;
                                              if (snapshot.data['frequency'] ==
                                                  'day') {
                                                freq = 'daily';
                                              } else {
                                                freq =
                                                    snapshot.data['frequency'];
                                              }

                                              if (snapshot.data['frequency'] ==
                                                  'hour') {
                                                time = '(on the hour)';
                                              } else {
                                                time = snapshot.data["time"]
                                                        .toString() +
                                                    ':00';
                                              }
                                              children = <Widget>[
                                                InfoBar(
                                                  title: Text('Configured'),
                                                  severity: InfoBarSeverity
                                                      .success, // optional. Default to InfoBarSeverity.info
                                                ),
                                                SizedBox(
                                                  height: 20,
                                                ),
                                                Row(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 80,
                                                          child: Text(
                                                            'Frequency: ',
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
                                                        Text(freq![0]
                                                                .toString()
                                                                .toUpperCase() +
                                                            freq
                                                                .toString()
                                                                .substring(1))
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 80,
                                                          child: Text(
                                                            'Time: ',
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
                                                        Text(time.toString())
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              ];
                                            } else {
                                              children = <Widget>[
                                                InfoBar(
                                                  title: Text('Not Configured'),
                                                  severity: InfoBarSeverity
                                                      .info, // optional. Default to InfoBarSeverity.info
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
                                            children = <Widget>[
                                              //  ProgressRing(),
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
                                      )),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Mica(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Syncing Groups',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  SizedBox(
                                    height: 100,
                                    width: 220,
                                    child: FutureBuilder(
                                      future:
                                          getGroupSync(), // a previously-obtained Future<String> or null
                                      builder: (BuildContext context,
                                          AsyncSnapshot snapshot) {
                                        if (needsBuildGroup == true) {
                                          getGroupSync();
                                        }
                                        List<Widget> children;
                                        if (snapshot.hasData) {
                                          if (snapshot.data['synctype'] ==
                                              'grouppartial') {
                                            groupSyncConfigured = true;
                                            children = <Widget>[
                                              InfoBar(
                                                title: Text('Configured'),
                                                severity: InfoBarSeverity
                                                    .success, // optional. Default to InfoBarSeverity.info
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 80,
                                                        child: Text(
                                                          'Details: ',
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
                                                      Row(
                                                        children: [
                                                          Text('Syncing ' +
                                                              (snapshot.data[
                                                                          "syncvalues"]
                                                                      .toString()
                                                                      .split(
                                                                          ',')
                                                                      .length)
                                                                  .toString() +
                                                              ' groups.')
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ];
                                          } else {
                                            children = <Widget>[
                                              InfoBar(
                                                title: Text('Not Configured'),
                                                severity: InfoBarSeverity
                                                    .info, // optional. Default to InfoBarSeverity.info
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
                        ],
                      ),
                    ),
                  ],
                ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                  padding: const EdgeInsets.only(left: 30, top: 20),
                  child: SizedBox(
                    width: 510,
                    child: Row(
                      children: [
                        Row(
                          children: [
                            FilledButton(
                              child: Text('Clear Schedule Settings'),
                              onPressed: () async {
                                if (schedConfigured) {
                                  _confirmClearSyncDialog(context);
                                }
                              },
                            ),
                            SizedBox(
                              width: 95,
                            ),
                            FilledButton(
                              child: Text('Clear Group Sync Settings'),
                              onPressed: () async {
                                if (groupSyncConfigured) {
                                  _confirmClearGroupDialog(context);
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  )),
            ],
          ),
          SizedBox(
            height: 50,
          ),
          Column(
            children: [
              InfoLabel(
                labelStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SegoeUI'),
                label: 'Configure Synchronisation Schedule',
              ),
              SizedBox(height: 10),
              Column(children: [
                Text(
                  'Select Schedule Recurrence ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: 200,
                  child: Combobox<String>(
                    placeholder: Text('Select Schedule'),
                    isExpanded: true,
                    items: recurrence
                        .map((e) => ComboboxItem<String>(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    value: recurrenceValue,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => recurrenceValue = value);
                      }
                    },
                  ),
                ),
              ]),
              Visibility(
                visible: recurrenceValue == 'Weekly',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Day ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: 200,
                        child: Combobox<String>(
                          placeholder: Text('Select Day'),
                          isExpanded: true,
                          items: day
                              .map((e) => ComboboxItem<String>(
                                    value: e,
                                    child: Text(e),
                                  ))
                              .toList(),
                          value: dayValue,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => dayValue = value);
                            }
                          },
                        ),
                      ),
                    ]),
              ),
              Visibility(
                visible:
                    recurrenceValue == 'Daily' || recurrenceValue == 'Weekly',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Time ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: 200,
                        child: Combobox<String>(
                          placeholder: Text('Select Time'),
                          isExpanded: true,
                          items: hour
                              .map((e) => ComboboxItem<String>(
                                    value: e,
                                    child: Text(e),
                                  ))
                              .toList(),
                          value: timeValue,
                          onChanged: (value) {
                            if (value != null) {
                              var init = value.toString()[0];
                              if (init == '1') {
                                setState(() {
                                  timeValue = value;
                                  doubleTime =
                                      value[0].toString() + value[1].toString();
                                });

                                // if (value.toString()[0] == '1') {
                                //   var time = value.toString()[0] +
                                //       value.toString()[1];
                                //   setState(() => timeValue = time);
                                // } else {
                                //   var time = value.toString()[1];
                                //   setState(() => timeValue = time);
                                // }
                              } else {
                                setState(() {
                                  timeValue = value;
                                  doubleTime = value[1].toString();
                                });
                              }
                            }
                            // if (value != null) {

                            // }
                          },
                        ),
                      ),
                    ]),
              ),
              Row(
                children: [
                  Padding(
                      padding: const EdgeInsets.only(left: 30, top: 20),
                      child: SizedBox(
                        width: 510,
                        child: Row(
                          children: [
                            Visibility(
                              visible: (recurrenceValue != null &&
                                      timeValue != null ||
                                  recurrenceValue == 'Hourly'),
                              child: Row(
                                children: [
                                  FilledButton(
                                    child: Text('Save'),
                                    onPressed: () async {
                                      _confirmSaveSync(context);
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Clear'),
                                    onPressed: () async {
                                      setState(() {
                                        recurrenceValue = null;
                                        timeValue = null;
                                        dayValue = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )),
                ],
              ),
            ],
          )
        ]),
      ),
      // bottomBar: Padding(
      //   padding: const EdgeInsets.all(15.0),
      //   child: Column(
      //     children: [
      //       Visibility(visible: _showSuccess, child: _infobarSuccess()),
      //       Row(
      //         mainAxisAlignment: MainAxisAlignment.end,
      //         children: [
      //           ClipOval(
      //             child: material.Material(
      //               color: Colors.blue, // Button color
      //               child: material.InkWell(
      //                 splashColor:
      //                     Color.fromARGB(178, 255, 255, 255), // Spcolor
      //                 onTap: () {
      //                   getGroupSync();
      //                 },
      //                 child: Tooltip(
      //                   message: 'Refresh',
      //                   child: SizedBox(
      //                       width: 45,
      //                       height: 45,
      //                       child: Icon(
      //                         FluentIcons.refresh,
      //                         color: Colors.white,
      //                       )),
      //                 ),
      //               ),
      //             ),
      //           ),
      //         ],
      //       ),
      //     ],
      //   ),
      // ));
    );
    // bottomBar: FilledButton(
    //   onPressed: () {},
    //   child: Icon(FluentIcons.refresh),
    //   style: ButtonStyle(
    //     shape: ButtonState.all(CircleBorder()),
    //     padding: ButtonState.all(EdgeInsets.all(20)),
    //     backgroundColor: ButtonState.all(Colors.blue), // <-- Button color
    //     foregroundColor: ButtonState.resolveWith<Color?>((states) {
    //       if (states.contains(ButtonStates.pressing)) {
    //         return Colors.magenta;
    //       }
    //       return null; // <-- Splash color
    //     }),
    //   ),
    // ));

    // bottomBar: _infobar ? _showInfobar() : null);
  }
}
