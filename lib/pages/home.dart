import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:http/http.dart' as http;


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _mobileNumber = '';
//  List<SimCard> _simCard = <SimCard>[];
  Future<bool> outTimeFuture;
  Future<bool> inTimeFuture;
  Future<UserDetails> user;

  @override
  void initState() {
    super.initState();
    MobileNumber.listenPhonePermission((isPermissionGranted) {
      if (isPermissionGranted) {
        initMobileNumberState();
      } else {}
    });

    initMobileNumberState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initMobileNumberState() async {
    if (!await MobileNumber.hasPhonePermission) {
      await MobileNumber.requestPhonePermission;
      return;
    }

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      _mobileNumber = await MobileNumber.mobileNumber;
//      _simCard = await MobileNumber.getSimCards;
    } on PlatformException catch (e) {
      debugPrint("Failed to get mobile number because of '${e.message}'");
    }

    setState((){});
  }

//  Widget fillCards() {
//    List<Widget> widgets = _simCard
//        .map((SimCard sim) => Text(
//        'Sim Card Number: (${sim.countryPhonePrefix}) - ${sim.number}\nCarrier Name: ${sim.carrierName}\nCountry Iso: ${sim.countryIso}\nDisplay Name: ${sim.displayName}\nSim Slot Index: ${sim.slotIndex}\n\n'))
//        .toList();
//    return Column(children: widgets);
//  }


  void outTime() async{
    print('outTime function called');
    outTimeFuture = sendRequest(_mobileNumber,"OUT");
    print(outTimeFuture);
    return;
  }

  void inTime() {
    print('outTime function called');
    inTimeFuture = sendRequest(_mobileNumber,"IN");
    return;
  }

  @override
  Widget build(BuildContext context) {
    user = getUserDataDummy(_mobileNumber);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Attendance App'),
        centerTitle: true,
      ),
      body: Column(
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
                            } else if (snapshot.hasError) {
                              return Text("${snapshot.error}");
                            }
                            return CircularProgressIndicator();
                          }
                      )
                    ],
                  ),
                  SizedBox(height: 60),
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
                              onPressed: () => outTime(),
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
                              onPressed: () => inTime(),
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
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> sendRequest(String mobileNumber, String state) async {
  print('inside sendRequest');
  final http.Response response = await http.post(
    'https://jsonplaceholder.typicode.com/albums',
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'mobileNumber': mobileNumber,
      'state' : state
    }),
  );

  if (response.statusCode == 201) {
    return true;
  } else {
    throw Exception('Failed to create album.');
  }
}

class UserDetails{
  final String name;
  final String centerName;
  final String mobileNo;

  UserDetails({this.name, this.centerName, this.mobileNo});

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      centerName: json['Center Name'],
      name: json['Name'],
      mobileNo: json['mobileNo'],
    );
  }
}

Future<UserDetails> getUserDataDummy(String mobileNo) async{
  print('inside getUserDataDummy');
  final dummyFuture = Future.delayed(
    Duration(seconds: 8),
        () => UserDetails(name: "Vivek Sengar", centerName: "Hyderabad", mobileNo: mobileNo),
  );

  return dummyFuture;
}

Future<UserDetails> getUserData(String mobileNo) async {
  print('inside getUserData');
  print(mobileNo);
  final http.Response response = await http.post(
    'http://career.nirdpr.in/Services/Service.svc/getemployeedetails',
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8'
    },
    body: jsonEncode(<String, String>{
      'mobileNo': '9013322645', // TODO: should be mobileNo
      'key': 'TmlyZHByQ0lDVDc4Ng=='
    }),
  );

  print(response.body);

  if (response.statusCode == 201 || response.statusCode == 200) {
    return UserDetails.fromJson(json.decode(response.body));
  } else {
    int val = response.statusCode;
    throw Exception('Request returned with status code : $val');
  }
}