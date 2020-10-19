import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:permission_handler/permission_handler.dart';


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
//  PermissionStatus _status;

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

  String _mobileNumber = '';
  String alertMessage_1 = "Do you wish to override your IN Time?";
  String errorMsg = "An error occurred while recording the attendance";
  String alertMessage_2 = "";
//  List<SimCard> _simCard = <SimCard>[];
  Future<bool> outTimeFuture;
  Future<bool> inTimeFuture;
  Future<UserDetails> user;

  Future<bool> userLocation;
  dynamic currentTime;
  String inTime = '';
  String outTime = '';

  @override
  void initState() {
    super.initState();
    _prefs.then((SharedPreferences prefs) {
      getVariables(prefs);
    });

//    getPhoneNumber();

//    MobileNumber.listenPhonePermission((isPermissionGranted) {
//      if (isPermissionGranted) {
//        initMobileNumberState();
//      } else {}
//    });
//
//    initMobileNumberState();

    getCurrentLocation();
  }
//
//  getPhoneNumber() async{
//    createPhoneNumberDialog(context).then((value) {
//      print(value);
//    });
//  }

  getVariables(SharedPreferences prefs) async{
    _inTimeEnabled = prefs.getBool('inTimeEnabled') ?? true;
    _outTimeEnabled = prefs.getBool('outTimeEnabled') ?? false;
    userLocationBool = prefs.getBool('userLocationBool') ?? false;
    inTimeOrOutTime = prefs.getBool('inTimeOrOutTime') ?? true;
    yesNo = prefs.getBool('yesNo') ?? false;
    String lastDate = prefs.getString('lastDate') ?? '';
    String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    if(lastDate == currentDate){
      inTime = prefs.getString('inTime') ?? '';
      outTime = prefs.getString('outTime') ?? '';
    }
    else{
      prefs.setString('lastDate', DateFormat('dd-MM-yyyy').format(DateTime.now()));
    }
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
  }

  setVariables() async{
    SharedPreferences prefs = await _prefs;
    prefs.setBool('inTimeEnabled', _inTimeEnabled);
    prefs.setBool('outTimeEnabled', _outTimeEnabled);
    prefs.setBool('userLocationBool', userLocationBool);
    prefs.setBool('inTimeOrOutTime', inTimeOrOutTime);
    prefs.setBool('yesNo', yesNo);
    prefs.setString('inTime', inTime);
    prefs.setString('outTime', outTime);
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
                bool success = await recordInTime();
                if(success){
                  fail=false;
                  setState(() {
                    inTime = DateFormat.jm().format(DateTime.now());
                    userLocationBool = false;
                    yesNo = true;
                  }
                  );
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
                  setState(() {
                    outTime = DateFormat.jm().format(DateTime.now());
                    userLocationBool = false;
                    yesNo = true;
                  }
                  );
                  print("Out time recorded $outTime");
                }
                else{
                  fail = true;
                }
              }
              setVariables();
              Navigator.of(context).pop();
            },
          ),
          MaterialButton(
            elevation: 5.0,
            child: Text("No"),
            onPressed: (){
              if(inTimeOrOutTime) {
                print("In-Time not updated $inTime");
                userLocationBool = false;
              }
              else {
                print("Out-Time not recorded $outTime");
                userLocationBool = false;
              }
              yesNo = false;
              setVariables();
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
        title: Text("Too far from Target"),
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

  dynamic getCurrentTime(){
    currentTime = DateFormat.jm().format(DateTime.now());
    return currentTime;
  }

  getCurrentLocation() async{
    final geoPosition = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userLocation = isValidLocation(geoPosition.latitude,geoPosition.longitude);
    print(userLocationBool);
    userLocationBool =  await userLocation;
    setVariables();
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

    if(_inTimeEnabled && isValidUser)
    {
      _onPressedInTime = () async {
        inTimeOrOutTime = true;
        alertMessage_1 = "Do you wish to override your IN Time?";
        await getCurrentLocation();
        if(userLocationBool)
        {
          if(inTime.isEmpty)
          {
            bool success = await recordInTime();
            if(success){
              setState(() {
                inTime = DateFormat.jm().format(DateTime.now());
              }
              );
              print("In time recorded $inTime");
              createTimeDialog(context);
            }
            else{
              createErrorDialog(context);
            }
          }
          else{
            await createAlertDialog(context);
            if(yesNo){
              if(fail){
                createErrorDialog(context);
              }
              else {
                createTimeDialog(context);
              }
            }
          }
          alertMessage_2 = "In-Time Updated Successfully $inTime";
          userLocationBool = false;
          _outTimeEnabled = true;
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
        alertMessage_1 = "Do you wish to override your OUT Time?";
        await getCurrentLocation();
        if(userLocationBool) {
          if (outTime.isEmpty) {
            bool success = await recordOutTime();
            if(success){
              setState(() {
                outTime = DateFormat.jm().format(DateTime.now());
              });
              print("Out time recorded $outTime");
              createTimeDialog(context);
            }
            else{
              createErrorDialog(context);
            }
          }
          else {
            await createAlertDialog(context);
            if(yesNo){
              if(fail){
                createErrorDialog(context);
              }
              else {
                createTimeDialog(context);
              }
            }
          }
          alertMessage_2 = "Out-Time Updated Successfully $outTime";
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
        title: const Text('Employee Attendance App'),
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
                        SizedBox(height: 30),
                        Text(
                          '${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
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
        ],
      ),
    );
  }

  Future<bool> recordInTime() async{
    print('inside recordInTime');
    final http.Response response = await http.post(
      'http://career.nirdpr.in/Services/Service.svc/markIntimeattendance',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(<String, String>{
        'jsonreq':'{\"latitude\":\"$lat\",\"longitude\":\"$lon\",\"phone\":\"$_mobileNumber\"}', // TODO:$_mobileNumber
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
      ValidLocation obj = ValidLocation.fromJson(json.decode(response.body));
      if(obj.res == 1) {
        print(obj.res);
        userLocationBool = true;
        return true;
      }
      else {
        print(obj.res);
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
//    if(_mobileNumber.isEmpty){
//      await
//    }
    http.Response response;
    try{
      response = await http.post(
        'http://career.nirdpr.in/Services/Service.svc/getemployeedetails',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(<String, String>{
          'mobileNo': _mobileNumber, //'9849298244' // TODO: _mobileNumber
          'key': 'TmlyZHByQ0lDVDc4Ng=='
        }),
      );
    }
    catch (_){
      throw Error();
    }

    print('reaches here');
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

class ValidLocation {
  int res;
  ValidLocation(
      {this.res}
      );
  factory ValidLocation.fromJson(Map<String, dynamic> json) {
    return ValidLocation(
      res: json['d'],
    );
  }
}

class UserDetails{
  String name;
  String centerName;
  String mobileNo;
  String d;

  UserDetails({this.name, this.centerName, this.mobileNo, this.d});

  void parseString(String mobileNo){
    this.mobileNo = mobileNo;
    name='';
    centerName='';
//    print(d);
    int i=0;
    while(i<d.length && d[i] != ':'){
      i++;
    }
    i+=2;
    while(i<d.length && d[i] != '"'){
      name+= d[i];
      i++;
    }
//    print(name);
    i+=3;

    while(i<d.length && d[i] != ':'){
      i++;
    }
    i+=2;
    while(i<d.length && d[i] != '"'){
      centerName += d[i];
      i++;
    }
//    print(centerName);
    i+=3;
  }

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      d: json['d'],
    );
  }
}

