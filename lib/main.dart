import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_work/View/FirstPage.dart';

import 'View/SecondPage.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Тестовое задание',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirstPage(),
      getPages: [
        GetPage(name: '/page-two', page: () => SecondPage()),

      ],
    );
  }
}