import 'package:android_intent_plus/android_intent.dart';
import 'package:attendancewithfingerprint/screen/about_page.dart';
import 'package:attendancewithfingerprint/screen/attendance_page.dart';
import 'package:attendancewithfingerprint/screen/login_page.dart';
import 'package:attendancewithfingerprint/screen/report_page.dart';
import 'package:attendancewithfingerprint/screen/setting_page.dart';
import 'package:attendancewithfingerprint/utils/single_menu.dart';
import 'package:attendancewithfingerprint/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainMenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Menu();
  }
}

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  void initState() {
    _getPermission();
    super.initState();
  }

  void _getPermission() async {
    getPermissionAttendance();
    _checkGps();
  }

  void getPermissionAttendance() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
  }

  // Check the GPS is on
  Future _checkGps() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Can't get current location"),
              content:
                  const Text('Please make sure your enable GPS and try again.'),
              actions: <Widget>[
                TextButton(
                  child: Text('Ok'),
                  onPressed: () async {
                    final AndroidIntent intent = AndroidIntent(
                        action: 'android.settings.LOCATION_SOURCE_SETTINGS');

                    await intent.launch();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                )
              ],
            );
          },
        );
      }
    }
  }

  // Function sign out
  _signOut() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      preferences.remove("status");
      preferences.remove("email");
      preferences.remove("password");
      preferences.remove("id");

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            margin: EdgeInsets.only(bottom: 40.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 200.0,
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                        image: AssetImage('images/logo.png'),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SingleMenu(
                      icon: FontAwesomeIcons.userClock,
                      menuName: main_menu_check_in,
                      style: TextStyle(color: Colors.black),
                      color: Colors.orange,
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AttendancePage(
                            query: 'in',
                            title: main_menu_check_in_title,
                          ),
                        ),
                      ),
                    ),
                    SingleMenu(
                      icon: FontAwesomeIcons.solidClock,
                      menuName: main_menu_check_out,
                      color: Colors.teal,
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AttendancePage(
                            query: 'out',
                            title: main_menu_check_out_title,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14.0, // Adjust the font size as needed
                        color: Colors.black, // Adjust the text color as needed
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SingleMenu(
                      icon: FontAwesomeIcons.calendar,
                      menuName: main_menu_report,
                      color: Colors.yellow[700]!,
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ReportPage()),
                      ),
                      style: TextStyle(
                        fontSize: 14.0, // Adjust the font size as needed
                        color: Colors.black, // Adjust the text color as needed
                      ),
                    ),
                    SingleMenu(
                      icon: FontAwesomeIcons.gear,
                      menuName: main_menu_settings,
                      color: Colors.green,
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => SettingPage()),
                      ),
                      style: TextStyle(
                        fontSize: 14.0, // Customize the font size as needed
                        color: Colors.black, // Adjust the color as necessary
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SingleMenu(
                      icon: FontAwesomeIcons.userLarge,
                      menuName: main_menu_about,
                      color: Colors.purple,
                      action: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => AboutPage()),
                      ),
                      style: TextStyle(
                        fontSize: 14.0, // Adjust the font size as needed
                        color: Colors
                            .black, // Change the color to match your design
                      ),
                    ),
                    SingleMenu(
                      icon: FontAwesomeIcons.rightFromBracket,
                      menuName: 'Logout',
                      color: Colors.red,
                      action: () => _signOut(),
                      style: TextStyle(
                        fontSize: 14.0, // Adjust the font size as needed
                        color: Colors.black, // Set the text color as desired
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
