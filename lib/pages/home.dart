import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  double lat;
  double lon;
  bool _inTimeEnabled = true;
  bool _outTimeEnabled = false;
  bool userLocationBool = false;
  bool inTimeOrOutTime = true;
  bool yesNo = false;
  bool isValidUser = false;
  double testVar;
  bool fail=false;
  bool _isOnCompanyTour=false;

  String _mobileNumber = '';
  String alertMessage_1 = "Do you wish to override your IN Time?";
  String errorMsg = "An error occurred while recording the attendance";
  String alertMessage_2 = "";
  Future<UserDetails> user;

  String inTime = '';
  String outTime = '';
  String date = '';

  @override
  void initState() {
    super.initState();
    _prefs.then((SharedPreferences prefs) {
      getVariables(prefs);
    });

    getCurrentLocation();

//    getPhoneNumber();

//    MobileNumber.listenPhonePermission((isPermissionGranted) {
//      if (isPermissionGranted) {
//        initMobileNumberState();
//      } else {}
//    });
//
//    initMobileNumberState();

  }


  getVariables(SharedPreferences prefs) async{
//    userLocationBool = prefs.getBool('userLocationBool') ?? false;
    inTimeOrOutTime = prefs.getBool('inTimeOrOutTime') ?? true;
//    String lastDate = prefs.getString('lastDate') ?? '';
//    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
//    if(lastDate == currentDate){
//      inTime = prefs.getString('inTime') ?? '';
//      outTime = prefs.getString('outTime') ?? '';
//    }
//    else{
//      prefs.setString('lastDate', DateFormat('dd-MM-yyyy').format(DateTime.now()));
//    }
    _mobileNumber = prefs.getString('mobileNumber') ?? '';
    if(_mobileNumber.isEmpty){
      await createPhoneNumberDialog(context).then((value) {
        print(value);
        _mobileNumber = value;
        prefs.setString('mobileNumber', _mobileNumber);
      });
    }

    user = getUserData();
    setState(() {});
    UserDetails usr = await user;
    if(usr.inTime != null){
      date = DateFormat('dd-MM-yyyy').format(usr.inTime);
      inTime = DateFormat.jm().format(usr.inTime);
      _inTimeEnabled = false;
      _outTimeEnabled = true;
    }
    else{
      date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    }
    if(usr.outTime != null){
      outTime = DateFormat.jm().format(usr.outTime);
      _outTimeEnabled = false;
    }
    setState((){});
  }

  setVariables() async{
    SharedPreferences prefs = await _prefs;
    prefs.setBool('inTimeEnabled', _inTimeEnabled);
    prefs.setBool('outTimeEnabled', _outTimeEnabled);
//    prefs.setBool('userLocationBool', userLocationBool);
    prefs.setBool('inTimeOrOutTime', inTimeOrOutTime);
//    prefs.setString('inTime', inTime);
//    prefs.setString('outTime', outTime);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
//  Future<void> initMobileNumberState() async {
//    if (!await MobileNumber.hasPhonePermission) {
//      await MobileNumber.requestPhonePermission;
//      return;
//    }
//
//    // Platform messages may fail, so we use a try/catch PlatformException.
//    try {
//    _mobileNumber = await MobileNumber.mobileNumber;
//    print(_mobileNumber.length);
//    if(_mobileNumber.length < 10){
//      _mobileNumber = await createPhoneNumberDialog(context);
//    }
//    else{
//      String mobNo = '';
//      for(int i=_mobileNumber.length-1, j=0; i>=0 && j<10; i--, j++){
//        mobNo += _mobileNumber[i];
//      }
//      _mobileNumber = String.fromCharCodes(mobNo.codeUnits.reversed);
//    }
//    print(_mobileNumber);
//    } on PlatformException catch (e) {
//      print("Failed to get mobile number because of '${e.message}'");
//    }
//    user = getUserData();
//    setState((){});
//  }

  Future<String> createPhoneNumberDialog(BuildContext context){

    TextEditingController customController = TextEditingController();

    return   showDialog(context: context,builder: (context) {
      return AlertDialog(
        title : Text("Enter you registered Mobile Number"),
        content: TextField(
          controller: customController,
        ),
        actions: [
          MaterialButton(
            elevation: 5.0,
            child: Text("Submit"),
            onPressed: (){
              Navigator.of(context).pop(customController.text.toString());
            },
          )
        ],
      );
    });
  }

  createAlertDialog(BuildContext context) async{
    return   showDialog(context: context,builder: (context){
      return AlertDialog(
        title: Text(alertMessage_1),
        actions: [
          MaterialButton(
            elevation: 5.0,
            child: Text("Yes"),
            onPressed: () async {
              if(inTimeOrOutTime) {
                bool success;
                if(_isOnCompanyTour) {
                  success = await recordInTime(1);
                }
                else{
                  success = await recordInTime(0);
                }
                if(success){
                  fail=false;
                  _inTimeEnabled = false;
                  inTime = DateFormat.jm().format(DateTime.now());
                  print("In time recorded $inTime");
                }
                else{
                  fail = true;
                }
              }
              else
              {
                bool success = await recordOutTime();
                if(success) {
                  fail = false;
                  _outTimeEnabled = false;
                  outTime = DateFormat.jm().format(DateTime.now());
                  print("Out time recorded $outTime");
                }
                else{
                  fail = true;
                }
              }
              userLocationBool = false;
              yesNo = true;
              setState(() {});
              setVariables();
              Navigator.of(context).pop();
            },
          ),
          MaterialButton(
            elevation: 5.0,
            child: Text("No"),
            onPressed: (){
//              if(inTimeOrOutTime) {
//                print("In-Time not updated $inTime");
//                userLocationBool = false;
//              }
//              else {
//                print("Out-Time not recorded $outTime");
//                userLocationBool = false;
//              }
              userLocationBool = false;
              yesNo = false;
//              setVariables();
              Navigator.of(context).pop();
            },
          )
        ],
      );
    });
  }

  createErrorDialog(BuildContext context){
    return   showDialog(context: context,builder: (context){
      return AlertDialog(
        title: Text(errorMsg),
        actions: [
          MaterialButton(
            elevation: 5.0,
            child: Text("Close"),
            onPressed: (){
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }

  createTimeDialog(BuildContext context){
    return   showDialog(context: context,builder: (context){
      return AlertDialog(
        title: Text(alertMessage_2),
        actions: [
          MaterialButton(
            elevation: 5.0,
            child: Text("Close"),
            onPressed: (){
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }

  createLocationDialog(BuildContext context){
    return   showDialog(context: context,builder: (context){
      return AlertDialog(
        title: Text(
            "You are not in NIRD campus. If you are on official visit/tour tick check-box and try again."
        ),
        actions: [
          MaterialButton(
            elevation: 5.0,
            child: Text("Close"),
            onPressed: (){
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    });
  }

  getCurrentLocation() async{
    final geoPosition = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userLocationBool =  await isValidLocation(geoPosition.latitude,geoPosition.longitude);
//    setVariables();
    print(userLocationBool);
    setState(() {
      lat = geoPosition.latitude;
      lon = geoPosition.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    var _onPressedInTime;
    var _onPressedOutTime;
    print("_inTimeEnabled -  $_inTimeEnabled && isValidUser - $isValidUser");
    if(_inTimeEnabled && isValidUser)
    {
      _onPressedInTime = () async {
        inTimeOrOutTime = true;
        alertMessage_1 = "Once IN-Time is recorded, it can not be changed. Do you want to continue?";
//        alertMessage_1 = "Do you wish to override your IN Time?";
        if(!_isOnCompanyTour) {
          await getCurrentLocation();
        }
        else{
          userLocationBool=true;
        }
        if(userLocationBool)
        {
          if(inTime.isEmpty)
          {
            await createAlertDialog(context);
            if(yesNo){
              if(fail){
                createErrorDialog(context);
              }
              else {
                alertMessage_2 = "In-Time Updated Successfully $inTime";
                createTimeDialog(context);
                _inTimeEnabled = false;
                _outTimeEnabled = true;
              }
            }
//            if(yesNo){
//              bool success = await recordInTime();
//              if(success){
//                setState(() {
//                  inTime = DateFormat.jm().format(DateTime.now());
//                });
//                print("In time recorded $inTime");
//                createTimeDialog(context);
//              }
//              else{
//                createErrorDialog(context);
//              }
//            }
          }
          else{
            _inTimeEnabled = false;
            _outTimeEnabled = true;
//            await createAlertDialog(context);
//            if(yesNo){
//              if(fail){
//                createErrorDialog(context);
//              }
//              else {
//                createTimeDialog(context);
//              }
//            }
          }
          userLocationBool = false;
        }
        else {
          await createLocationDialog(context);
          print("you are not inside the target area");
        }
        //inTime();
        setVariables();
      };
    }

    if(_outTimeEnabled && isValidUser)
    {
      _onPressedOutTime = () async {
        inTimeOrOutTime = false;
        alertMessage_1 = "Once OUT-Time is recorded, it can not be changed. Do you want to continue?";
//        alertMessage_1 = "Do you wish to override your OUT Time?";
        UserDetails user = await getUserData();
        _isOnCompanyTour = user.isontour;
        if(!_isOnCompanyTour) {
          await getCurrentLocation();
        }
        else{
          userLocationBool=true;
        }
        if(userLocationBool) {
          if (outTime.isEmpty) {
            await createAlertDialog(context);
            if(yesNo){
              if(fail){
                createErrorDialog(context);
              }
              else {
                alertMessage_2 = "Out-Time Updated Successfully $outTime";
                createTimeDialog(context);
                _outTimeEnabled = false;
              }
            }
//            if(yesNo){
//              bool success = await recordOutTime();
//              if(success){
//                setState(() {
//                  outTime = DateFormat.jm().format(DateTime.now());
//                });
//                print("Out time recorded $outTime");
//                createTimeDialog(context);
//              }
//              else{
//                createErrorDialog(context);
//              }
//            }
          }
          else {
            _outTimeEnabled = false;
//            await createAlertDialog(context);
//            if(yesNo){
//              if(fail){
//                createErrorDialog(context);
//              }
//              else {
//                createTimeDialog(context);
//              }
//            }
          }
          userLocationBool = false;
        }
        else
        {
          createLocationDialog(context);
          print("you are not inside the target area");
        }
        setVariables();
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance App'),
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[ Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 2, 15, 0) ,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/logo.png'),
                      radius: 50,
                    ),
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Nation Institute of\nRural Development &\nPanchayati Raj',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
//          fillCards(),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 5, 15, 12),
              child: Center(
                child: Column(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        FutureBuilder<UserDetails>(
                            future: user,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
//                        return fillUserCard();
                                UserDetails _user = snapshot.data;
                                _user.parseString(_mobileNumber);
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 17,
                                            ),
                                            SizedBox(width: 2,),
                                            Text(
                                              "NAME",
                                              style: TextStyle(
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height:4),
                                        Text(
                                          "${_user.name}",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.business,
                                              size: 17,
                                            ),
                                            SizedBox(width: 2,),
                                            Text(
                                              "CENTER NAME",
                                              style: TextStyle(
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height:4),
                                        Text(
                                          "${_user.centerName}",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
//                                  Text("Center Name -  ${_user.centerName}"),
//                                  Text("Mobile No -  ${_user.mobileNo}"),
                                      ],
                                    ),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Icon(
                                              Icons.phone,
                                              size: 17,
                                            ),
                                            SizedBox(width: 2,),
                                            Text(
                                              "Mobile No",
                                              style: TextStyle(
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height:4),
                                        Text(
                                          "${_user.mobileNo}",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }
                              else if (snapshot.hasError) {
                                String error = snapshot.error.toString();
                                if(error.isNotEmpty){
                                  return Column(
                                    children: [
                                      Text (
                                      "Failed to validate Mobile No- $_mobileNumber",
                                      style: TextStyle(
                                          letterSpacing: 1.5,
                                          fontSize: 15
                                      )
                                      ),
                                    ],
                                  );
                                }
                                else{
                                  Text (
                                    "Failed to validate Mobile No",
                                    style: TextStyle(
                                      letterSpacing: 1.5,
                                      fontSize: 15
                                    )
                                  );
                                }
                              }
                              return CircularProgressIndicator();
                            }
                        )
                      ],
                    ),
                    SizedBox(height: 50),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        //fillCards()
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              height: 60,
                              width: 160,
                              child: RaisedButton(
                                onPressed: _onPressedInTime,      //Defined above
                                child: Text(
                                  'Record IN\nTime',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                color: Colors.lightGreen[500],
                              ),
                            ),
                            SizedBox(
                              height: 60,
                              width: 160,
                              child: RaisedButton(
                                onPressed: _onPressedOutTime,
                                child: Text(
                                  'Record OUT\nTime',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                color: Colors.deepOrangeAccent,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        CheckboxListTile(
                          value: _isOnCompanyTour,
                          onChanged: (value){
                            setState(() {
                              _isOnCompanyTour = value;
                            });
                          },
                          title: Text(
                            "Are you on official visit/tour?",
                            style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        SizedBox(height: 13),
                        Text(
                          '$date',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children : [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "In Time : ",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  "Out Time : ",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width:8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("$inTime",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text("$outTime",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
//          CheckboxListTile(
//            value: _isOnCompanyTour,
//            onChanged: (value){
//              setState(() {
//                _isOnCompanyTour = value;
//              });
//            },
//            title: Text(
//              "Are you On a Company Tour?",
//              style: TextStyle(
//                fontSize: 17,
//                fontWeight: FontWeight.bold,
//                letterSpacing: 1.1,
//              ),
//            ),
//            controlAffinity: ListTileControlAffinity.leading,
//          ),
        ],
      ),
    );
  }

  Future<bool> recordInTime(int isontour) async{
    print('inside recordInTime');
    final http.Response response = await http.post(
      'http://career.nirdpr.in/Services/Service.svc/markIntimeattendance',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(<String, String>{
        'jsonreq':'{\"latitude\":\"$lat\",\"longitude\":\"$lon\",\"phone\":\"$_mobileNumber\", \"isontour\" : \"$isontour\"}', // TODO:$_mobileNumber
        'key' : 'TmlyZHByQ0lDVDc4Ng='
      }),
    );

    print(response.body);

    if (response.statusCode == 200) {
      print("Status code is 200");
      Map<String, dynamic> result = jsonDecode(response.body);
      if(result['d'] == 'InTime attendance marked successfully'){
        return true;
      }
      else{
        return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> recordOutTime() async{
    print('inside recordOutTime');
    final http.Response response = await http.post(
      'http://career.nirdpr.in/Services/Service.svc/markOuttimeattendance',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(<String, String>{
      'mobileNo': _mobileNumber, //'9849298244' TODO:_mobileNumber
      'key': 'TmlyZHByQ0lDVDc4Ng=='
      }),
    );

    print(response.body);

    if (response.statusCode == 200) {
      print("Status code is 200");
      Map<String, dynamic> result = jsonDecode(response.body);
      if(result['d'] == 'OutTime attendance marked successfully'){
        return true;
      }
      else{
        return false;
      }
    } else {
      return false;
    }
  }

  Future<bool> isValidLocationDummy(double lat,double lon) async{
    print('inside isValidLocationDummy');
    final dummyFuture = Future.delayed(
      Duration(seconds: 2),
          () => true,
    );
    return dummyFuture;
  }

  Future<bool> isValidLocation(double lat,double lon) async{
    print('inside isValidLocation');
    final http.Response response = await http.post(
      'http://career.nirdpr.in/Services/Service.svc/islocationvalid',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(<String, String>{
        'lattitude': lat.toString(), // "29.130298" // TODO: lat.toString()
        'longitude': lon.toString(), // "75.729856" // TODO: lon.toString()
        'key': 'TmlyZHByQ0lDVDc4Ng==',
      }),
    );

    print(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      print("Status code is either 200 or 201");
      Map<String, dynamic> obj = jsonDecode(response.body);
      int res = obj['d'];
      if(res == 1) {
        print(res);
        userLocationBool = true;
        return true;
      }
      else {
        print(res);
        userLocationBool = false;
        return false;
      }
    } else {
      int val = response.statusCode;
      throw Exception('Request returned with status code : $val');
    }
  }


  Future<UserDetails> getUserData() async {
    print('inside getUserData');
    print(_mobileNumber);
    http.Response response;
    try{
      response = await http.post(
        'http://career.nirdpr.in/Services/Service.svc/getemployeedetails',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(<String, String>{
          'mobileNo': _mobileNumber, //'9849298244' '9013322645' // TODO: _mobileNumber
          'key': 'TmlyZHByQ0lDVDc4Ng=='
        }),
      );
    }
    catch (_){
      throw Error();
    }

    print(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      UserDetails user = UserDetails.fromJson(json.decode(response.body));
      user.parseString('');
      if(user.name.isNotEmpty){
        setState(() {
          isValidUser = true;
        });
      }
      return user;
    }
    else {
      int val = response.statusCode;
      throw Exception('Request returned with status code : $val');
    }
  }
}

class UserDetails{
  String name;
  String centerName;
  String mobileNo;
  DateTime inTime;
  DateTime outTime;
  String d;
  bool isontour;

  UserDetails({this.name, this.centerName, this.mobileNo, this.d});

  void parseString(String mobileNo){
    this.mobileNo = mobileNo;
    Map<String, dynamic> result = jsonDecode(d);

    if(result.containsKey('Name')){
      name = result['Name'];
    }
//    print(name);

    if(result.containsKey('Center')){
      centerName = result['Center'];
    }
//    print(centerName);

    if(result.containsKey('inTime')  && result['inTime'].isNotEmpty){
      inTime = DateTime.parse(result['inTime']);
    }
//    print(inTime);

    if(result.containsKey('outTime') && result['outTime'].isNotEmpty){
      outTime = DateTime.parse(result['outTime']);
    }
//    print(outTime);
    if(result.containsKey('isontour') && result['isontour'].isNotEmpty){
      String temp = result['isontour'];
      if(temp == "1"){
        isontour = true;
      }
      else{
        isontour = false;
      }
    }
  }

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      d: json['d'],
    );
  }
}

