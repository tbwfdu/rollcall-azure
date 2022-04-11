// ignore_for_file: avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pluto_grid/pluto_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Widget spacer = SizedBox(height: 5.0);
List users = [];
List accessUsers = [];

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final FlyoutController controller = FlyoutController();
  final FlyoutController dpController = FlyoutController();

  bool _showSuccess = false;
  bool _showWarning = false;
  bool _showError = false;
  bool _infobar = false;
  String message = '';
  String domain = '';
  String apiurl = '';
  String apiuser = '';
  String apipass = '';

  bool needsBuildAzure = false;
  bool needsBuildAccess = false;

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

  void _bigHammerAzure() async {
    setState(() {
      needsBuildAzure = true;
      rows = [];
    });
    Timer(Duration(seconds: 3), () {
      setState(() {
        needsBuildAzure = false;
      });
    });
  }

  void _bigHammerAccess() async {
    setState(() {
      needsBuildAccess = true;
      accessRows = [];
    });
    Timer(Duration(seconds: 3), () {
      setState(() {
        needsBuildAccess = false;
      });
    });
  }

  void getSecrets() async {
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
    var json = await jsonDecode(response.body);

    domain = json['domain'];
  }

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

  late PlutoGridStateManager stateManager;
  late PlutoGridStateManager stateManagerAccess;

  final List<PlutoColumn> columns = [
    PlutoColumn(
      frozen: PlutoColumnFrozen.left,
      readOnly: true,
      width: 200,
      title: 'Name',
      field: 'column1',
      type: PlutoColumnType.text(),
      //  enableRowDrag: true,
      // enableRowChecked: true,
    ),
    PlutoColumn(
      readOnly: true,
      width: 250,
      title: 'Username',
      field: 'column2',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      width: 200,
      title: 'ID',
      field: 'column3',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      title: 'Title',
      field: 'column4',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      title: 'Department',
      field: 'column5',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      title: 'Work Phone',
      field: 'column9',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      title: 'Active',
      field: 'column10',
      type: PlutoColumnType.text(),
    ),
  ];

  final List<PlutoColumn> accessColumns = [
    PlutoColumn(
      readOnly: true,
      width: 200,
      title: 'Name',
      field: 'column1',
      type: PlutoColumnType.text(),
      frozen: PlutoColumnFrozen.left,
      //  enableRowDrag: true,
      // enableRowChecked: true,
    ),
    PlutoColumn(
      readOnly: true,
      width: 200,
      title: 'Email Address',
      field: 'column2',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      width: 300,
      title: 'ID',
      field: 'column3',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      width: 200,
      title: 'Username',
      field: 'column4',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      width: 200,
      title: 'Title',
      field: 'column5',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      width: 200,
      title: 'Department',
      field: 'column6',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      width: 200,
      title: 'Phone',
      field: 'column8',
      type: PlutoColumnType.text(),
    ),
  ];
  var selectedUsers = [];
  List<PlutoRow> rows = [];
  List<PlutoRow> accessRows = [];
  bool isEmpty = true;

  Future getUsers() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/azure/users'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var res = jsonDecode(response.body);
    var json = await res['value'];
    late String name;
    late String mail;
    late String id;
    late String title;
    late String dept;
    late String workPhone;
    late String active;
    for (var i = 0; i < json.length; i++) {
      final user = json[i];

      name = user["displayName"].toString();
      mail = user["mail"].toString();
      active = user["accountEnabled"].toString();
      id = user["id"].toString();
      title = user["jobTitle"].toString();
      dept = user["department"].toString();
      workPhone = user["businessPhones"][0].toString();

      PlutoRow row = PlutoRow(
        cells: {
          'column1': PlutoCell(value: name),
          'column2': PlutoCell(value: mail),
          'column3': PlutoCell(value: id),
          'column4': PlutoCell(value: title),
          'column5': PlutoCell(value: dept),
          'column9': PlutoCell(value: workPhone),
          'column10': PlutoCell(value: active),
        },
      );
      if (mail.contains(domain)) {
        rows.add(row);
      }
    }
    return json;
  }

  Future getAccessUsers() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/allaccessusers'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var json = jsonDecode(response.body);
    late String name;
    late String email;
    late String id;
    late String username;
    late String title;
    late String dept;
    late String phone;

    accessUsers = json;
    for (var i = 0; i < accessUsers.length; i++) {
      name = accessUsers[i]["name"]["givenName"] +
          " " +
          accessUsers[i]["name"]["familyName"];
      email = accessUsers[i]["emails"][0]["value"];
      id = accessUsers[i]["id"];
      username = accessUsers[i]["userName"];
      title = '';
      dept = '';
      phone = '';

      if (accessUsers[i]["title"] != null) {
        title = accessUsers[i]["title"];
      }
      if (accessUsers[i]["urn:scim:schemas:extension:enterprise:1.0"] != null) {
        if (accessUsers[i]["urn:scim:schemas:extension:enterprise:1.0"]
                ["department"] !=
            null) {
          dept = accessUsers[i]["urn:scim:schemas:extension:enterprise:1.0"]
              ["department"];
        }
      }
      if (accessUsers[i]["phoneNumbers"] != null) {
        if (accessUsers[i]["phoneNumbers"][0]["value"] != null) {
          phone = accessUsers[i]["phoneNumbers"][0]["value"];
        }
      }
      PlutoRow row = PlutoRow(
        cells: {
          'column1': PlutoCell(value: name),
          'column2': PlutoCell(value: email),
          'column3': PlutoCell(value: id),
          'column4': PlutoCell(value: username),
          'column5': PlutoCell(value: title),
          'column6': PlutoCell(value: dept),
          'column8': PlutoCell(value: phone),
        },
      );
      accessRows.add(row);
    }
    return json;
  }

  saveSelectedUsers() async {
    var users = selectedUsers.toString();
    var syncvalues = users.substring(1, users.length - 1);
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));

    Map data = {
      'synctype': 'grouppartial',
      'syncvalues': syncvalues.replaceAll(' ', ''),
    };
    http.Response response = await http.post(
        Uri.parse(
          apiurl + '/savesyncusers',
        ),
        headers: {
          HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
          "Authorization": _basicAuth
        },
        body: data);

    var json = jsonDecode(response.body);

    return json;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    getSecrets();
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
                  'Existing Users',
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
                    'View users and their attributes that are in your Azure Active Directory and as well as those in Workspace ONE Access.',
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
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 30, top: 30, right: 30),
              child: Row(
                mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                children: [
                  InfoLabel(
                    labelStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SegoeUI'),
                    label: 'Azure Active Directory Users',
                  ),
                  ClipOval(
                    child: material.Material(
                      color: Colors.blue, // Button color
                      child: material.InkWell(
                        splashColor:
                            Color.fromARGB(65, 255, 255, 255), // Splash color
                        onTap: () {
                          _bigHammerAzure();
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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: needsBuildAzure
                        ? material.SizedBox(
                            height: 400,
                            child: Column(children: [
                              SizedBox(height: 180),
                              Text('Loading'),
                              SizedBox(height: 5),
                              ProgressBar()
                            ]),
                          )
                        : Column(
                            children: [
                              FutureBuilder(
                                future:
                                    getUsers(), // a previously-obtained Future<String> or null
                                builder: (BuildContext context,
                                    AsyncSnapshot snapshot) {
                                  List<Widget> children;
                                  if (snapshot.hasData) {
                                    children = <Widget>[
                                      SingleChildScrollView(
                                        child: SizedBox(
                                          width: 920,
                                          height: 400,
                                          // child: _gUsers(snapshot.data),
                                          child: material.Material(
                                            child: PlutoGrid(
                                              columns: columns,
                                              rows: rows,
                                              onChanged:
                                                  (PlutoGridOnChangedEvent
                                                      event) {},
                                              onLoaded: (PlutoGridOnLoadedEvent
                                                  event) {
                                                event.stateManager
                                                    .setSelectingMode(
                                                        PlutoGridSelectingMode
                                                            .row);
                                                stateManager =
                                                    event.stateManager;
                                              },

                                              // configuration: PlutoConfiguration.dark(),
                                              createFooter: (stateManager) {
                                                stateManager.setPageSize(10,
                                                    notify:
                                                        false); // Can be omitted. (Default 40)
                                                return PlutoPagination(
                                                    stateManager);
                                              },
                                              configuration:
                                                  PlutoGridConfiguration(
                                                cellTextStyle:
                                                    material.TextStyle(
                                                  overflow: TextOverflow.fade,
                                                  fontFamily: 'SegoeUI',
                                                  fontSize: 14,
                                                ),
                                                columnTextStyle:
                                                    material.TextStyle(
                                                  fontWeight:
                                                      material.FontWeight.bold,
                                                  fontFamily: 'SegoeUI',
                                                  fontSize: 14,
                                                ),
                                                rowHeight: 30,
                                                columnHeight: 34,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ];
                                  } else if (snapshot.hasError) {
                                    children = <Widget>[
                                      SizedBox(
                                        width: 800,
                                        height: 150,
                                        child: Icon(
                                          FluentIcons.error,
                                          color: Colors.errorPrimaryColor,
                                          size: 30,
                                        ),
                                      ),
                                    ];
                                  } else {
                                    children = const <Widget>[
                                      SizedBox(
                                          height: 400,
                                          child: Center(child: ProgressRing())),
                                    ];
                                  }
                                  return Column(
                                    children: children,
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 30, top: 30, right: 30),
              child: Row(
                mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                children: [
                  InfoLabel(
                    labelStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SegoeUI'),
                    label: 'Workspace ONE Access Users',
                  ),
                  ClipOval(
                    child: material.Material(
                      color: Colors.blue, // Button color
                      child: material.InkWell(
                        splashColor:
                            Color.fromARGB(65, 255, 255, 255), // Splash color
                        onTap: () {
                          _bigHammerAccess();
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
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: needsBuildAccess
                    ? material.SizedBox(
                        height: 400,
                        child: Column(children: [
                          SizedBox(height: 180),
                          Text('Loading'),
                          SizedBox(height: 5),
                          ProgressBar()
                        ]),
                      )
                    : Column(
                        children: [
                          FutureBuilder(
                            future:
                                getAccessUsers(), // a previously-obtained Future<String> or null
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              List<Widget> children;
                              if (snapshot.hasData) {
                                children = <Widget>[
                                  SingleChildScrollView(
                                    child: SizedBox(
                                      width: 920,
                                      height: 400,
                                      // child: _gUsers(snapshot.data),
                                      child: material.Material(
                                        child: PlutoGrid(
                                          columns: accessColumns,
                                          rows: accessRows,
                                          onChanged: (PlutoGridOnChangedEvent
                                              event) {},
                                          onLoaded:
                                              (PlutoGridOnLoadedEvent event) {
                                            event.stateManager.setSelectingMode(
                                                PlutoGridSelectingMode.row);
                                            stateManagerAccess =
                                                event.stateManager;
                                          },
                                          //onRowChecked: handleOnRowChecked,
                                          // configuration: PlutoConfiguration.dark(),
                                          createFooter: (stateManagerAccess) {
                                            stateManagerAccess.setPageSize(10,
                                                notify:
                                                    false); // Can be omitted. (Default 40)
                                            return PlutoPagination(
                                                stateManagerAccess);
                                          },
                                          configuration: PlutoGridConfiguration(
                                            cellTextStyle: material.TextStyle(
                                              overflow: TextOverflow.fade,
                                              fontFamily: 'SegoeUI',
                                              fontSize: 14,
                                            ),
                                            columnTextStyle: material.TextStyle(
                                              fontWeight:
                                                  material.FontWeight.bold,
                                              fontFamily: 'SegoeUI',
                                              fontSize: 14,
                                            ),
                                            rowHeight: 30,
                                            columnHeight: 34,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 80,
                                  )
                                ];
                              } else if (snapshot.hasError) {
                                children = <Widget>[
                                  SizedBox(
                                    width: 800,
                                    height: 150,
                                    child: Icon(
                                      FluentIcons.error,
                                      color: Colors.errorPrimaryColor,
                                      size: 30,
                                    ),
                                  ),
                                ];
                              } else {
                                children = const <Widget>[
                                  SizedBox(
                                      height: 130,
                                      child: Center(child: ProgressRing())),
                                ];
                              }
                              return Column(
                                children: children,
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      // bottomBar: Padding(
      //   padding: const EdgeInsets.all(15.0),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.end,
      //     children: [
      //       ClipOval(
      //         child: material.Material(
      //           color: Colors.blue, // Button color
      //           child: material.InkWell(
      //             splashColor: Color.fromARGB(178, 255, 255, 255), // Spcolor
      //             onTap: () {
      //               getUsers();
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
      // )
    );
  }
}

class UserModel {
  late String name;
  late String email;
  late String id;
  late String title;
  late String dept;
  late String type;
  late String manager;
  late String phone1;
  late String phone2;
  late String suspended;

  UserModel(
      {required this.name,
      required this.email,
      required this.id,
      required this.title,
      required this.dept,
      required this.type,
      required this.manager,
      required this.phone1,
      required this.phone2,
      required this.suspended});
}
