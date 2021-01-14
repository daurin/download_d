import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Download D"),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.file_download),
          onPressed: () async{
           
          },
        ),
      ),
    );
  }

  void test() {}
}
