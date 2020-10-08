import 'package:flutter/material.dart';
import 'package:tutorial_project/pages/loading_screen.dart';
import 'package:tutorial_project/pages/home.dart';

void main() => runApp(
  MaterialApp(
    title: 'Employee Attendance App',
    routes:{
      '/' : (content) => Loading(),
      '/home' : (content) => Home(),
    }
  )
);