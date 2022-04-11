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
List groups = [];
bool loading = false;

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  bool _showSuccess = false;
  bool _showWarning = false;
  bool _showError = false;
  bool _infobar = false;
  String message = '';
  String domain = '';

  bool needsBuildAzure = false;
  bool needsBuildAccess = false;

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

  final FlyoutController controller = FlyoutController();
  final FlyoutController dpController = FlyoutController();
  late PlutoGridStateManager stateManager;
  late PlutoGridStateManager stateManagerAccess;

  final List<PlutoColumn> columns = [
    PlutoColumn(
      readOnly: true,

      width: 220,
      title: 'Name',
      field: 'column1',
      type: PlutoColumnType.text(),
      //  enableRowDrag: true,
      enableRowChecked: true,
    ),
    PlutoColumn(
      readOnly: true,
      width: 290,
      title: 'Email',
      field: 'column2',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      width: 290,
      title: 'ID',
      field: 'column3',
      type: PlutoColumnType.text(),
    ),
    // PlutoColumn(
    //   readOnly: true,
    //   textAlign: PlutoColumnTextAlign.center,
    //   titleTextAlign: PlutoColumnTextAlign.center,
    //   title: 'Members',
    //   field: 'column4',
    //   type: PlutoColumnType.text(),
    // ),
  ];

  final List<PlutoColumn> accessColumns = [
    PlutoColumn(
      readOnly: true,

      width: 250,
      title: 'Name',
      field: 'column1',
      type: PlutoColumnType.text(),
      //  enableRowDrag: true,
      enableRowChecked: false,
    ),
    PlutoColumn(
      readOnly: true,
      width: 350,
      title: 'Access Group ID',
      field: 'column2',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      textAlign: PlutoColumnTextAlign.center,
      titleTextAlign: PlutoColumnTextAlign.center,
      title: 'Members',
      field: 'column3',
      type: PlutoColumnType.text(),
    ),
  ];
  var selectedGroups = [];
  List<PlutoRow> rows = [];
  List<PlutoRow> accessRows = [];
  bool isEmpty = true;
  bool needsBuild = false;

  Future getGroups() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/azure/groups'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var res = jsonDecode(response.body);
    var json = await res['value'];
    groups = json;
    for (var i = 0; i < groups.length; i++) {
      var mailVal = '';
      if (groups[i]["mail"] == null) {
        mailVal = ' ';
      } else {
        mailVal = groups[i]["mail"].toString();
      }
      PlutoRow row = PlutoRow(
        //   sortIdx: groups[i],
        cells: {
          'column1': PlutoCell(value: groups[i]["displayName"].toString()),
          'column2': PlutoCell(value: mailVal),
          'column3': PlutoCell(value: groups[i]["id"].toString()),
          // 'column4': PlutoCell(value: groups[i]["directMembersCount"]),
        },
      );

      // if (groups[i]["email"].contains(domain)) {
      rows.add(row);
      //  }
    }
    return json;
  }

  Future getAccessGroups() async {
    await _getPrefs();
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    final response = await http.get(
      Uri.parse(apiurl + '/allaccessgroups'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var json = jsonDecode(response.body);
    groups = json;

    for (var i = 0; i < groups.length; i++) {
      if (groups[i]["members"] != null) {
        PlutoRow row = PlutoRow(
          //   sortIdx: groups[i],
          cells: {
            'column1': PlutoCell(value: groups[i]["displayName"]),
            'column2': PlutoCell(value: groups[i]["id"]),
            'column3': PlutoCell(value: groups[i]["members"].length.toString())
          },
        );
        accessRows.add(row);
      } else {
        PlutoRow row = PlutoRow(
          //   sortIdx: groups[i],
          cells: {
            'column1': PlutoCell(value: groups[i]["displayName"]),
            'column2': PlutoCell(value: groups[i]["id"]),
            'column3': PlutoCell(value: '0')
          },
        );
        accessRows.add(row);
      }
    }
    return json;
  }

  saveSelectedGroups() async {
    await _getPrefs();
    var groups = selectedGroups.toString();
    var syncvalues = groups.substring(1, groups.length - 1);

    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));

    Map data = {
      'synctype': 'grouppartial',
      'syncvalues': syncvalues.replaceAll(' ', ''),
    };
    http.Response response = await http.post(
        Uri.parse(
          apiurl + '/savesyncgroups',
        ),
        headers: {
          HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
          "Authorization": _basicAuth
        },
        body: data);

    var json = jsonDecode(response.body);

    return json;
  }

  _confirmSaveDialog(context) {
    showDialog(
        context: context,
        builder: (context) {
          if (selectedGroups.isEmpty) {
            return ContentDialog(
              title: Text('Sync Selected Groups'),
              content: Text('You haven\'t selected any groups.'),
              actions: [
                FilledButton(
                    child: Text('OK'),
                    onPressed: () async {
                      Navigator.pop(context);
                    })
              ],
            );
          } else {
            return StatefulBuilder(builder: (context, setState) {
              return ContentDialog(
                title: Text('Sync Selected Groups'),
                content: Column(
                  children: [
                    Visibility(
                      visible: !loading,
                      child: Text(
                          'You\'re about to sync ${selectedGroups.length} groups and it\'s members.'),
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
                            Text(
                              'Loading',
                              style: TextStyle(
                                fontFamily: 'SegoeUI',
                                fontSize: 14,
                              ),
                            )
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
                          await saveSelectedGroups();
                          Timer(Duration(seconds: 3), () {
                            setState(() {
                              Navigator.pop(context);
                              Timer(Duration(seconds: 1), () {
                                loading = false;
                                needsBuild = true;
                              });
                            });
                          });
                        }),
                  if (loading) Text('...')
                ],
              );
            });
          }
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
    getSecrets();
  }

  void handleOnRowChecked(PlutoGridOnRowCheckedEvent event) {
    if (event.isRow) {
      var selected = event.row?.cells['column3']?.value;
      if (event.isChecked!) {
        if (selectedGroups.contains(selected)) {
        } else {
          selectedGroups.add(selected);
        }
      } else {
        if (selectedGroups.contains(selected)) {
          selectedGroups.remove(selected);
        }
      }
    } else {}
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
                  'Existing Groups',
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
                    'View user groups that exist in your Azure Active Directory as well as those also in Workspace ONE Acccess. Also, you can use this page to Synchronise groups from Azure to Workspace ONE Access by selecting the row in the Azure groups list and then pressing Sync Selected.',
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
                    label: 'Azure Active Directory Groups',
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
                            future: getGroups(),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              List<Widget> children;
                              if (snapshot.hasData) {
                                children = <Widget>[
                                  SingleChildScrollView(
                                    child: SizedBox(
                                      width: 900,
                                      height: 400,
                                      // child: _gGroups(snapshot.data),
                                      child: material.Material(
                                        child: PlutoGrid(
                                          createHeader: (stateManager) {
                                            return material.Padding(
                                              padding:
                                                  material.EdgeInsets.all(5),
                                              child: Row(
                                                  crossAxisAlignment: material
                                                      .CrossAxisAlignment
                                                      .center,
                                                  mainAxisAlignment: material
                                                      .MainAxisAlignment.end,
                                                  children: [
                                                    FilledButton(
                                                        child: Text(
                                                            'Sync Selected'),
                                                        onPressed: () async {
                                                          _confirmSaveDialog(
                                                              context);
                                                        }),
                                                  ]),
                                            );
                                          },
                                          columns: columns,
                                          rows: rows,
                                          onChanged: (PlutoGridOnChangedEvent
                                              event) {},
                                          onLoaded:
                                              (PlutoGridOnLoadedEvent event) {
                                            event.stateManager.setSelectingMode(
                                                PlutoGridSelectingMode.row);
                                            stateManager = event.stateManager;
                                          },
                                          onRowChecked: handleOnRowChecked,
                                          // configuration: PlutoConfiguration.dark(),
                                          createFooter: (stateManager) {
                                            stateManager.setPageSize(10,
                                                notify:
                                                    false); // Can be omitted. (Default 40)
                                            return PlutoPagination(
                                                stateManager);
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
                                  )
                                ];
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
                    label: 'Workspace ONE Access Groups',
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
                                getAccessGroups(), // a previously-obtained Future<String> or null
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              List<Widget> children;
                              if (snapshot.hasData) {
                                children = <Widget>[
                                  SingleChildScrollView(
                                    child: SizedBox(
                                      width: 900,
                                      height: 400,
                                      // child: _gGroups(snapshot.data),
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
                                  const Icon(
                                    FluentIcons.error,
                                    color: Colors.errorPrimaryColor,
                                    size: 30,
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
      //               getGroups();
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
