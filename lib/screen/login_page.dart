import 'package:attendancewithfingerprint/database/db_helper.dart';
import 'package:attendancewithfingerprint/screen/main_menu_page.dart';
import 'package:attendancewithfingerprint/utils/strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

enum LoginStatus { notSignIn, signIn, doubleCheck }

class _LoginPageState extends State<LoginPage> {
  LoginStatus _loginStatus = LoginStatus.notSignIn;
  late String email, pass, isLogged, getUrl, getKey;
  String statusLogged = 'logged';
  String getPath = '/api/login';
  final _key = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _secureText = true;

  // Progress dialog
  late ProgressDialog pr;

  // Database
  DbHelper dbHelper = DbHelper();

  @override
  void initState() {
    getSettings();
    super.initState();
    // First init
    // Check is user is logged, or not
  }

  // Function show or not the password
  showHide() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  // Check if all data is ok, will submit the form via API
  check() {
    final form = _key.currentState;
    if (form!.validate()) {
      form.save();
      login('clickButton');
    }
  }

  // Get settings data
  void getSettings() async {
    var getSettings = await dbHelper.getSettings(1);
    setState(() {
      getUrl = getSettings.url;
      getKey = getSettings.key;

      getPref();
    });
  }

  // Function communicate with the server via API
  login(String fromWhere) async {
    var urlLogin = getUrl + getPath;
    if (fromWhere == 'clickButton') pr.show();

    Dio dio = new Dio();
    FormData formData =
        new FormData.fromMap({"email": email, "password": pass});
    final response = await dio.post(urlLogin, data: formData);

    // Return the json data
    var data = response.data;

    // Get the message data from json
    String message = data['message'];

    // Check if success
    if (message == "success") {
      int role = data['user']['role'];
      if (role == 1 || role == 4) {
        setState(() {
          getSnackBar(login_wrong_role);
        });
      } else {
        isLogged = statusLogged;
        String email = data['user']['email'];
        int userId = data['user']['id'];

        setState(() {
          _loginStatus = LoginStatus.signIn;
          savePref(isLogged, email, pass, userId);
        });
      }
    } else {
      // Password and email wrong
      if (fromWhere == 'clickButton') {
        setState(() {
          getSnackBar(login_failed);
        });
      } else {
        // Before correct email and password, but maybe user change the email and password
        setState(() {
          getSnackBar(login_double_check);
          _loginStatus = LoginStatus.notSignIn;
          removePref();
        });
      }
    }

    // Hide the loading
    Future.delayed(Duration(seconds: 0)).then((value) {
      if (mounted) {
        setState(() {
          if (fromWhere == 'clickButton') pr.close();
        });
      }
    });
  }

  removePref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.remove("status");
    preferences.remove("email");
    preferences.remove("password");
    preferences.remove("id");
  }

  // Show snackBar
  void getSnackBar(String messageSnackBar) {
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(content: Text(messageSnackBar)),
    );
  }

  // Save the data from json data
  savePref(String getStatus, String getEmployeeId, String getPassword,
      int getUserId) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      preferences.setString("status", getStatus);
      preferences.setString("email", getEmployeeId);
      preferences.setString("password", getPassword);
      preferences.setInt("id", getUserId);
    });
  }

  // Check is there any data at Shared Preferences, is any data, means user logged
  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      var getStatusSp = preferences.getString("status");
      var getEmail = preferences.getString("email");
      var getPassword = preferences.getString("password");

      if (getStatusSp == statusLogged) {
        _loginStatus = LoginStatus.doubleCheck;
        // if user aleady login, will check again, if there is any change on web server
        // Like change the role, or the status
        email = getEmail!;
        pass = getPassword!;
        login('doubleCheck');
      } else {
        _loginStatus = LoginStatus.notSignIn;
      }
    });
  }

  @override
  // ignore: missing_return
  Widget build(BuildContext context) {
    switch (_loginStatus) {
      case LoginStatus.notSignIn:
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(login_title),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 30.0),
                    child: Image(
                      image: AssetImage('images/logo.png'),
                    ),
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  Container(
                    child: Text(
                      login_title,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
                  child: Form(
                    key: _key,
                    child: ListView(
                      padding: EdgeInsets.all(16.0),
                      children: <Widget>[
                        TextFormField(
                          validator: (e) {
                            var message;
                            if (e!.isEmpty) {
                              message = login_empty_email;
                            }
                            return message;
                          },
                          onSaved: (e) => email = e!,
                          decoration: InputDecoration(
                            labelText: login_label_email,
                          ),
                        ),
                        TextFormField(
                          validator: (e) {
                            var message;
                            if (e!.isEmpty) {
                              message = login_empty_password;
                            }
                            return message;
                          },
                          obscureText: _secureText,
                          onSaved: (e) => pass = e!,
                          decoration: InputDecoration(
                            labelText: login_label_password,
                            suffixIcon: IconButton(
                              onPressed: showHide,
                              icon: Icon(_secureText
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 20.0),
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              FocusScope.of(context).requestFocus(FocusNode());
                              // Show loading dialog before executing check()
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  content: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 20),
                                      Text('Loading...'),
                                    ],
                                  ),
                                ),
                              );
                              check().whenComplete(() {
                                // Close the loading dialog after check() completes
                                Navigator.of(context).pop();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue, // text color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                                side: BorderSide(color: Colors.blue),
                              ),
                            ),
                            child: Text(login_button),
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case LoginStatus.signIn:
        return MainMenuPage();
        break;
      case LoginStatus.doubleCheck:
        return Scaffold(
          backgroundColor: Colors.white,
          key: _scaffoldKey,
          body: Container(
            color: Colors.white,
            child: Center(
              child: Container(
                height: 100.0,
                width: 100.0,
                child: Image(
                  image: AssetImage('images/logo.png'),
                ),
              ),
            ),
          ),
        );
        break;
    }
  }
}
