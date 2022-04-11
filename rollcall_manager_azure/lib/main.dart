// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:flutter/material.dart' as material;
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:rollcall_manager/pages/directories.dart';
import 'package:rollcall_manager/pages/groups.dart';
import 'package:rollcall_manager/pages/logs.dart';
import 'package:rollcall_manager/pages/sync.dart';
import 'package:rollcall_manager/pages/tenant.dart';
import 'package:rollcall_manager/pages/users.dart';

import 'pages/overview.dart';
import 'package:system_theme/system_theme.dart';

import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:window_manager/window_manager.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:url_launcher/link.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NavigationIndicators { sticky, end }

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle('hidden',
          windowButtonVisibility: true);
      await windowManager.setSize(const Size(1000, 800));
      await windowManager.setMinimumSize(const Size(1000, 800));
      await windowManager.center();
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }
  runApp(Phoenix(child: RollcallManagerApp()));
}

class RollcallManagerApp extends StatelessWidget {
  const RollcallManagerApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => AppTheme(),
        builder: (context, _) {
          final appTheme = context.watch<AppTheme>();
          return FluentApp(
            title: 'Rollcall Manager',
            theme: ThemeData(
              accentColor: Colors.blue,
              visualDensity: VisualDensity.standard,
              brightness: Brightness.light,
              typography: const Typography(
                caption: TextStyle(
                  fontFamily: 'SegoeUI',
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
                body: TextStyle(
                  fontFamily: 'SegoeUI',
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
                bodyStrong: TextStyle(
                  fontFamily: 'SegoeUI',
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
                title: TextStyle(
                  fontFamily: 'SegoeUI',
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // home: RollcallManagerHomePage(title: 'Rollcall'),
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (_) => RollcallManagerHomePage(
                    title: 'Rollcall Manager',
                  )
            },
            builder: (context, child) {
              return Directionality(
                textDirection: material.TextDirection.ltr,
                child: child!,
              );
            },
          );
        });
  }
}

class RollcallManagerHomePage extends StatefulWidget {
  const RollcallManagerHomePage({Key? key, required this.title})
      : super(key: key);

  final String title;

  @override
  State<RollcallManagerHomePage> createState() =>
      _RollcallManagerHomePageState();
}

class _RollcallManagerHomePageState extends State<RollcallManagerHomePage>
    with WindowListener, SingleTickerProviderStateMixin {
  final userMenuFlyout = FlyoutController();
  int cont = 0;
  int targetCount = 5;
  bool showsplash = true;
  String message = '';
  bool firstRun = true;
  int index = 0;
  final _rollcallURL = TextEditingController();
  final _rollcallAPI = TextEditingController();
  final _rollcallPASS = TextEditingController();

  bool _checked = false;
  bool loading = false;
  bool rollcallError = false;
  String apiurl = '';
  String apiuser = '';
  String apipass = '';
  final viewKey = GlobalKey();
  int stage = 0;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  _confirm(context) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ContentDialog(
              title: Text('Saving First Run Configuration'),
              content: Column(
                children: [
                  Visibility(
                      visible: !loading,
                      child: !_checked
                          ? Text(
                              'You\'re about to configure Rollcall Manager to use localhost.')
                          : Text(
                              'You\'re about to configure Rollcall Manager to use ' +
                                  _rollcallURL.text)),
                  material.SizedBox(height: 5),
                  Visibility(
                    visible: !loading,
                    child: Text('API Credentials Set.'),
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
                        await _setPrefs();
                        Timer(Duration(seconds: 3), () {
                          setState(() {
                            loading = false;

                            Navigator.pop(context);
                          });
                        });
                      }),
                if (loading) Text('')
              ],
            );
          });
        });
  }

  status() async {
    // ignore: prefer_typing_uninitialized_variables
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
          "Authorization": _basicAuth
        },
      );
      result = await jsonDecode(response.body);
      setState(() {
        rollcallError = false;
      });
    } on Exception catch (e) {
      // Anything else that is an exception
      print('Unknown exception: $e');

      setState(() {
        rollcallError = true;
      });
    } catch (e) {
      // No specified type, handles all
      print('Something really unknown: $e');

      result = true;
      setState(() {
        rollcallError = true;
      });
    }
    result = true;
    return result;
  }

  Future _setPrefs() async {
    final SharedPreferences prefs = await _prefs;
    if (_rollcallURL.text.isNotEmpty) {
      await prefs.setString('api_url', _rollcallURL.text);
      await prefs.setString('api_user', _rollcallAPI.text);
      await prefs.setString('api_pass', _rollcallPASS.text);
    } else {
      await prefs.setString('api_url', 'localhost');
      await prefs.setString('api_user', _rollcallAPI.text);
      await prefs.setString('api_pass', _rollcallPASS.text);
    }
    apiurl = _rollcallURL.text;
    Timer(Duration(seconds: 3), () {
      setState(() {
        firstRun = false;
      });
    });
    return 'ok';
  }

  Future<void> _clearPrefs() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove('api_url');
  }

  Future _getPrefs() async {
    final SharedPreferences prefs = await _prefs;

    var url = prefs.getString('api_url');
    if (url != null) {
      if (url == 'localhost') {
        apiurl = 'http://localhost:8080';
      } else {
        apiurl = url as String;
      }

      if (apiurl != '') {
        firstRun = false;
      }
      apiuser = prefs.getString('api_user').toString();
      apipass = prefs.getString('api_pass').toString();

      return 'ok';
    }
    return 'notok';
  }

  @override
  initState() {
    //_clearPrefs();
    _getPrefs();
    status();
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    userMenuFlyout.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      showDialog(
        context: context,
        builder: (_) {
          return ContentDialog(
            title: const Text('Confirm close'),
            content:
                const Text('Are you sure you want to close Rollcall Manager?'),
            actions: [
              FilledButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.pop(context);
                  windowManager.destroy();
                },
              ),
              Button(
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _mainBody() {
    return NavigationView(
        key: viewKey,
        appBar: NavigationAppBar(
          height: 80,
          title: MoveWindow(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 39),
                              child: Text(
                                'Rollcall Manager for Azure Active Directory',
                                style: TextStyle(
                                    fontFamily: 'SegoeUI',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]),
                    ],
                  ),
                  Row(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 28, 10, 0),
                            child: Icon(FluentIcons.info),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 39, 30, 0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'App Version: 1.0',
                                      style: TextStyle(
                                        fontFamily: 'SegoeUI',
                                        fontSize: 10,
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (apiurl.contains('localhost'))
                                      Text(
                                        'localhost mode',
                                        style: TextStyle(
                                          fontFamily: 'SegoeUI',
                                          fontSize: 10,
                                        ),
                                      )
                                    else
                                      Text(
                                        'remote mode',
                                        style: TextStyle(
                                          fontFamily: 'SegoeUI',
                                          fontSize: 10,
                                        ),
                                      )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          leading: Column(
            children: [
              SizedBox(height: 25),
              SizedBox(
                width: 50,
                height: 50,
                // child: Image.asset('assets/rollcall_logo_bw.png'),
                child: Icon(
                  material.Icons.campaign_outlined,
                  size: 35,
                ),
              ),
            ],
          ),
          // actions: Row(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: const [Spacer(), WindowButtons()],
          // ),
        ),
        pane: NavigationPane(
          selected: index,
          onChanged: (i) => setState(() => index = i),
          header: Container(
            height: kOneLineTileHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
          ),
          displayMode: PaneDisplayMode.compact,
          items: [
            // It doesn't look good when resizing from compact to open
            // PaneItemHeader(header: Text('User Interaction')),
            PaneItem(
              icon: const Icon(FluentIcons.diagnostic_data_viewer_app),
              title: const Text('Overview'),
            ),
            PaneItemHeader(header: Text('Tools')),
            PaneItem(
              icon: const Icon(FluentIcons.dom),
              title: const Text('Directories'),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.contact_card),
              title: const Text('Users'),
            ),
            PaneItem(
              icon: const Icon(FluentIcons.contact_list),
              title: const Text('Groups'),
            ),
            PaneItemHeader(header: Text('Rollcall')),
            PaneItem(
              icon: const Icon(FluentIcons.visio_diagram_sync),
              title: const Text('Sync Settings'),
            ),
            PaneItemHeader(header: Text('Workspace ONE Access')),
            PaneItem(
              icon: const Icon(FluentIcons.provisioning_package),
              title: const Text('Tenant Configuration'),
            ),
          ],
          footerItems: [
            PaneItemSeparator(),
            PaneItem(
              icon: const Icon(FluentIcons.device_bug),
              title: const Text('Logs'),
            ),
          ],
        ),
        content: NavigationBody(
          index: index,
          animationDuration: Duration(milliseconds: 500),
          children: [
            const OverviewPage(),
            const DirectoriesPage(),
            const UsersPage(),
            const GroupsPage(),
            const SyncPage(),
            const TenantPage(),
            const LogsPage()
          ],
        ));
  }

  Widget _splash() {
    Timer(Duration(seconds: 3), () {
      setState(() {
        showsplash = false;
      });
    });
    return material.Scaffold(
        body: Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/background.png"), fit: BoxFit.fill),
      ),
      child: Column(
        mainAxisAlignment: material.MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/rollcall_logo.png',
            scale: 3,
          ),
          material.SizedBox(
            height: 40,
            width: 120,
            child: ProgressBar(
              strokeWidth: 10,
              activeColor: Colors.white,
              backgroundColor: material.Color.fromARGB(33, 255, 255, 255),
            ),
          )
        ],
      ),
    ));
  }

  Widget _firstSetup() {
    return ScaffoldPage(
        content: Padding(
      padding: const EdgeInsets.only(top: 200, left: 185, right: 185),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLabel(
                labelStyle: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SegoeUI'),
                label: 'Welcome to Rollcall Manager',
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                InfoLabel(
                  labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SegoeUI'),
                  label: 'First Run Configuration',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Mica(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(15, 20, 15, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Please Set Your Rollcall API Server URL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                  width: 600,
                                  child: Text(
                                    'Leave as localhost to connect to the Rollcall API server running locally, or change to remote mode and enter the remote server address and port if applicable.',
                                    style: TextStyle(
                                        fontFamily: 'SegoeUI',
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                ToggleSwitch(
                                    checked: _checked,
                                    onChanged: (v) =>
                                        setState(() => _checked = v),
                                    content: Text(_checked
                                        ? 'Remote Mode'
                                        : 'Localhost Mode')),
                                SizedBox(
                                  height: 10,
                                ),
                                Visibility(
                                    visible: !_checked,
                                    child: Text(
                                      'Rollcall API is running on http://localhost:8080',
                                      style: TextStyle(color: Colors.grey[100]),
                                    )),
                                Visibility(
                                    visible: _checked,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Remote Server URL'),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        SizedBox(
                                          width: 300,
                                          child: TextFormBox(
                                            maxLength: 40,
                                            controller: _rollcallURL,
                                            placeholder:
                                                'eg. \'http://10.0.0.1:8080\' or \'https://rollcall\'',
                                          ),
                                        ),
                                      ],
                                    )),
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
          ),
          SizedBox(
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 5,
              ),
              FilledButton(
                  child: Text('Next'),
                  onPressed: () {
                    setState(() {
                      stage = 1;
                    });
                  })
            ],
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    ));
  }

  Widget _secondSetup() {
    return ScaffoldPage(
        content: Padding(
      padding: const EdgeInsets.only(top: 200, left: 185, right: 185),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLabel(
                labelStyle: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SegoeUI'),
                label: 'Welcome to Rollcall Manager',
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                InfoLabel(
                  labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SegoeUI'),
                  label: 'First Run Configuration',
                ),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Mica(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(15, 20, 15, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Configure your Rollcall API credentials.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                  width: 600,
                                  child: Text(
                                    'These credentials were generated automatically during initial Rollcall API Server deployment.',
                                    style: TextStyle(
                                        fontFamily: 'SegoeUI',
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                  width: 600,
                                  child: Text(
                                    'Contact the Rollcall administrator or you can find these again in default.json on the Rollcall Server.',
                                    style: TextStyle(
                                        fontFamily: 'SegoeUI',
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 300,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('API Username'),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          SizedBox(
                                            width: 250,
                                            child: TextFormBox(
                                              maxLength: 40,
                                              controller: _rollcallAPI,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 300,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('API Password'),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          SizedBox(
                                            width: 250,
                                            child: TextFormBox(
                                              maxLength: 40,
                                              controller: _rollcallPASS,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
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
          ),
          SizedBox(
            height: 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 5,
              ),
              FilledButton(
                  child: Text('Confirm'),
                  onPressed: () {
                    _confirm(context);
                  })
            ],
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      _mainBody();
    }
    if (showsplash) {
      return AnimatedSwitcher(
        duration: Duration(seconds: 1),
        child: _splash(),
      );
    }
    if (firstRun && stage == 0) {
      return AnimatedSwitcher(
        duration: Duration(seconds: 1),
        child: _firstSetup(),
      );
    }
    if (firstRun && stage == 1) {
      return AnimatedSwitcher(
        duration: Duration(seconds: 1),
        child: _secondSetup(),
      );
    } else {
      return AnimatedSwitcher(
        duration: Duration(seconds: 1),
        child: _mainBody(),
      );
    }
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    assert(debugCheckHasFluentLocalizations(context));
    final ThemeData theme = FluentTheme.of(context);
    final buttonColors = WindowButtonColors(
      iconNormal: theme.inactiveColor,
      iconMouseDown: theme.inactiveColor,
      iconMouseOver: theme.inactiveColor,
      mouseOver: ButtonThemeData.buttonColor(
          theme.brightness, {ButtonStates.hovering}),
      mouseDown: ButtonThemeData.buttonColor(
          theme.brightness, {ButtonStates.pressing}),
    );
    final closeButtonColors = WindowButtonColors(
      mouseOver: Colors.red,
      mouseDown: Colors.red.dark,
      iconNormal: theme.inactiveColor,
      iconMouseOver: Colors.red.basedOnLuminance(),
      iconMouseDown: Colors.red.dark.basedOnLuminance(),
    );
    return Row(children: [
      Tooltip(
        message: FluentLocalizations.of(context).minimizeWindowTooltip,
        child: MinimizeWindowButton(colors: buttonColors),
      ),
      Tooltip(
        message: FluentLocalizations.of(context).restoreWindowTooltip,
        child: WindowButton(
          colors: buttonColors,
          iconBuilder: (context) {
            if (appWindow.isMaximized) {
              return RestoreIcon(color: context.iconColor);
            }
            return MaximizeIcon(color: context.iconColor);
          },
          onPressed: appWindow.maximizeOrRestore,
        ),
      ),
      Tooltip(
        message: FluentLocalizations.of(context).closeWindowTooltip,
        child: CloseWindowButton(colors: closeButtonColors),
      ),
    ]);
  }
}

class AppTheme extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  set mode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  PaneDisplayMode _displayMode = PaneDisplayMode.auto;
  PaneDisplayMode get displayMode => _displayMode;
  set displayMode(PaneDisplayMode displayMode) {
    _displayMode = displayMode;
    notifyListeners();
  }

  NavigationIndicators _indicator = NavigationIndicators.sticky;
  NavigationIndicators get indicator => _indicator;
  set indicator(NavigationIndicators indicator) {
    _indicator = indicator;
    notifyListeners();
  }

  flutter_acrylic.WindowEffect _acrylicEffect =
      flutter_acrylic.WindowEffect.disabled;
  flutter_acrylic.WindowEffect get acrylicEffect => _acrylicEffect;
  set acrylicEffect(flutter_acrylic.WindowEffect acrylicEffect) {
    _acrylicEffect = acrylicEffect;
    notifyListeners();
  }

  TextDirection _textDirection = TextDirection.ltr;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection direction) {
    _textDirection = direction;
    notifyListeners();
  }
}
