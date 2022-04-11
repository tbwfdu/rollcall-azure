// ignore_for_file: avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables, prefer_final_fields

import 'package:fluent_ui/fluent_ui.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pluto_grid/pluto_grid.dart';
import 'package:flutter/material.dart' as material;
import 'package:shared_preferences/shared_preferences.dart';

const Widget spacer = SizedBox(height: 5.0);

class DirectoriesPage extends StatefulWidget {
  const DirectoriesPage({Key? key}) : super(key: key);
  @override
  _DirectoriesPageState createState() => _DirectoriesPageState();
}

class _DirectoriesPageState extends State<DirectoriesPage> {
  bool _showSuccess = false;
  bool _showWarning = false;
  bool _showError = false;
  bool _infobar = false;
  String message = '';
  String apiurl = '';
  String apiuser = '';
  String apipass = '';

  bool loading = false;
  bool needsBuild = false;
  bool visible = true;

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

  _checkError() {
    if (dirs.isNotEmpty) {
      setState(() {
        hasError = false;
      });
    } else {
      setState(() {
        hasError = true;
      });
    }
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

  final FlyoutController controller = FlyoutController();
  final FlyoutController dpController = FlyoutController();
  late PlutoGridStateManager stateManager;

  void _bigHammer() async {
    setState(() {
      needsBuild = true;
      rows = [];
      dirs = [];
    });
    Timer(Duration(seconds: 3), () {
      setState(() {
        needsBuild = false;
      });
    });
  }

  _confirmAddDialog(context) {
    if (_friendlyName.text == '' || _domainName.text == '') {
      showDialog(
          context: context,
          builder: (context) {
            return ContentDialog(
              title: Text('Create Directory'),
              content: Text(
                  'You have not entered a valid Directory Name or Domain Name'),
              actions: [
                FilledButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
              ],
            );
          });
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              return ContentDialog(
                title: Text('Create Directory'),
                content: Column(
                  children: [
                    Visibility(
                      visible: !loading,
                      child: Text('You are about to add ' +
                          _domainName.text +
                          ' to Workspace ONE Access. ' +
                          'Are you sure?'),
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
                          _bigHammer();
                          setState(() {
                            loading = true;
                          });
                          await addDirectory();

                          Timer(Duration(seconds: 1), () {
                            setState(() {
                              Navigator.pop(context);

                              Timer(Duration(seconds: 1), () {
                                loading = false;
                                _friendlyName.clear();
                                _domainName.clear();
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
  }

  _confirmDeleteDialog(context) {
    if (_deleteDirID.text == '' || _deleteDirType.text == '') {
      showDialog(
          context: context,
          builder: (context) {
            return ContentDialog(
              title: Text('Create Directory'),
              content: Text(
                  'You have not entered a valid Directory ID and Type to delete the domain.'),
              actions: [
                FilledButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
              ],
            );
          });
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(builder: (context, setState) {
              return ContentDialog(
                title: Text('You\'re about to delete a directory'),
                content: Column(
                  children: [
                    Visibility(
                      visible: !loading,
                      child: Column(children: [
                        Text(
                            'You are about to remove directory ID ${_deleteDirID.text} and all its users. If this is correct, confirm below.'),
                        TextFormBox(
                            controller: _confirm, placeholder: 'CONFIRM')
                      ]),
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
                          _bigHammer();
                          if (_confirm.text != '') {
                            setState(() {
                              loading = true;
                            });
                            await deleteDirectory();

                            Timer(Duration(seconds: 1), () {
                              setState(() {
                                Navigator.pop(context);

                                Timer(Duration(seconds: 1), () {
                                  loading = false;

                                  _friendlyName.clear();
                                  _domainName.clear();
                                });
                              });
                            });
                          }
                        }),
                  if (loading) Text('')
                ],
              );
            });
          });
    }
  }

  deleteDirectory() async {
    Map data = {
      'id': _deleteDirID.text.toString(),
    };

    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    http.Response response = await http.delete(
        Uri.parse(
          apiurl + '/deletedir',
        ),
        headers: {
          HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
          "Authorization": _basicAuth
        },
        body: data);

    var res = jsonDecode(response.body);

    _deleteDirID.clear();
    _confirm.clear();
    _deleteDirType.clear();
    return res;
  }

  addDirectory() async {
    Map data = {
      'type': 'OTHER_DIRECTORY',
      'domains': _domainName.text.toString(),
      'name': _friendlyName.text.toString()
    };
    String strAuth = apiuser + ':' + apipass;
    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));
    http.Response response = await http.post(
        Uri.parse(
          apiurl + '/createdir',
        ),
        headers: {
          HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
          "Authorization": _basicAuth
        },
        body: data);

    // var res = jsonDecode(response.body);

    _domainName.clear();
    _friendlyName.clear();

    return 'ok';
  }

  final List<PlutoColumn> columns = [
    PlutoColumn(
      readOnly: true,
      width: 220,
      title: 'Name',
      field: 'column1',
      type: PlutoColumnType.text(),
      //  enableRowDrag: true,
      enableRowChecked: false,
    ),
    PlutoColumn(
      readOnly: true,
      width: 200,
      title: 'Type',
      field: 'column2',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      readOnly: true,
      width: 350,
      title: 'ID',
      field: 'column3',
      type: PlutoColumnType.text(),
    ),
  ];
  List dirs = [];
  List<PlutoRow> rows = [];

  final _friendlyName = TextEditingController();
  final _domainName = TextEditingController();
  final _deleteDirID = TextEditingController();
  final _deleteDirType = TextEditingController();
  final _confirm = TextEditingController();

  String dirid = '';
  bool? hasError = true;

  Future getDirs() async {
    await _getPrefs();

    // String _basicAuth = 'Basic ' +
    //     base64Encode(utf8.encode('mTahRV!TM*3oi9i8:#66Va%MYVFR@zx2!'));
    String strAuth = apiuser + ':' + apipass;

    String _basicAuth = 'Basic ' + base64Encode(utf8.encode(strAuth));

    final response = await http.get(
      Uri.parse(apiurl + '/accessdirs'),
      // Send authorization headers to the backend.
      headers: {
        HttpHeaders.allowHeader: 'Access-Control-Allow-Origin: *',
        //HttpHeaders.acceptHeader: 'Accept: application/json',
        "Authorization": _basicAuth
      },
    );
    var json = jsonDecode(response.body);

    dirs = json['items'];

    for (var i = 0; i < dirs.length; i++) {
      PlutoRow row = PlutoRow(
        //   sortIdx: dirs[i],
        cells: {
          'column1': PlutoCell(value: dirs[i]["name"]),
          'column2': PlutoCell(value: dirs[i]["type"]),
          'column3': PlutoCell(value: dirs[i]["directoryId"]),
        },
      );
      rows.add(row);
    }

    return 'ok';
  }

  Widget list() {
    return FutureBuilder(
      future: getDirs(), // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        List<Widget> children;
        if (snapshot.hasData) {
          children = <Widget>[
            SingleChildScrollView(
              child: SizedBox(
                  width: 800,
                  height: 300,
                  // child: _gGroups(snapshot.data),
                  child: material.Material(
                      child: PlutoGrid(
                    columns: columns,
                    rows: rows,
                    onLoaded: (PlutoGridOnLoadedEvent event) {
                      event.stateManager
                          .setSelectingMode(PlutoGridSelectingMode.row);
                      stateManager = event.stateManager;
                    },
                    createFooter: (stateManager) {
                      stateManager.setPageSize(10,
                          notify: false); // Can be omitted. (Default 40)
                      return PlutoPagination(stateManager);
                    },
                    configuration: PlutoGridConfiguration(
                      cellTextStyle: material.TextStyle(
                        overflow: TextOverflow.fade,
                        fontFamily: 'SegoeUI',
                        fontSize: 14,
                      ),
                      columnTextStyle: material.TextStyle(
                        fontWeight: material.FontWeight.bold,
                        fontFamily: 'SegoeUI',
                        fontSize: 14,
                      ),
                      rowHeight: 30,
                      columnHeight: 34,
                    ),
                  ))),
            ),
          ];
        } else if (snapshot.hasError) {
          children = <Widget>[
            SizedBox(
                width: 800,
                height: 100,
                // child: _gGroups(snapshot.data),
                child: Icon(
                  FluentIcons.error,
                  color: Colors.errorPrimaryColor,
                  size: 30,
                )),
          ];
        } else {
          children = const <Widget>[
            SizedBox(
                width: 800, height: 300, child: Center(child: ProgressRing())),
          ];
        }
        return Column(
          children: children,
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  initState() {
    _getPrefs();
    super.initState();
    Timer(Duration(seconds: 2), (() {
      _checkError();
    }));
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
                  'Directories',
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
                    'View, Create and Delete Directories in your Workspace ONE Access tenant that are used for provisioning Users and Groups.',
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InfoLabel(
                    labelStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SegoeUI'),
                    label: 'Existing Directories',
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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Column(
                      children: [
                        !needsBuild
                            ? list()
                            : SizedBox(
                                width: 800,
                                height: 300,
                                child: Center(child: ProgressRing())),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: (hasError != true),
              child: Padding(
                padding: EdgeInsets.only(left: 30, top: 30),
                child: SizedBox(
                  width: 820,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                    label: 'Create New Directory',
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
                                    child: Text('Friendly Name'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: TextFormBox(
                                      maxLength: 40,
                                      controller: _friendlyName,
                                      placeholder:
                                          'eg. \'My Company Directory\'',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: Text('Domain Name'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: TextFormBox(
                                      maxLength: 40,
                                      controller: _domainName,
                                      placeholder: 'eg. \'company.com\'',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Button(
                                      child: Text('Clear'),
                                      onPressed: () {
                                        _friendlyName.clear();
                                        _domainName.clear();
                                      }),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  FilledButton(
                                      child: Text('Submit'),
                                      onPressed: () {
                                        _confirmAddDialog(context);
                                      })
                                ],
                              ),
                            ]),
                          ),
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
                                    label: 'Delete Directory',
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
                                    child: Text('Directory ID'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: TextFormBox(
                                      maxLength: 40,
                                      controller: _deleteDirID,
                                      placeholder: 'Access Dir ID',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: Text('Directory Type'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: TextFormBox(
                                      maxLength: 40,
                                      controller: _deleteDirType,
                                      placeholder: 'OTHER_DIRECTORY',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Button(
                                      child: Text('Clear'),
                                      onPressed: () {
                                        _deleteDirID.clear();
                                        _deleteDirType.clear();
                                      }),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  FilledButton(
                                      child: Text('Delete'),
                                      onPressed: () {
                                        setState(() {
                                          dirid = _deleteDirID.text.toString();
                                        });
                                        _confirmDeleteDialog(context);
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
          ],
        ),
      ),
      //  bottomBar: Padding(
      // padding: const EdgeInsets.all(15.0),
      // child: Row(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: [
      //     ClipOval(
      //       child: material.Material(
      //         color: Colors.blue, // Button color
      //         child: material.InkWell(
      //           splashColor: Color.fromARGB(178, 255, 255, 255), // Spcolor
      //           onTap: () async {
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
      //     ));
    );
  }
}
