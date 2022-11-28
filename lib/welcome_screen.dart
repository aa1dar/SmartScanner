import 'package:flutter/material.dart';
import 'package:smart_scanner/detail_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Positioned.fill(
        child: Container(
            decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF525252), Color(0xFF3d72b4)]),
        )),
      ),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Hi!\nLet\'s start to scan))',
            textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 30.0)),
            SizedBox(
              height: 20.0,
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/camera', arguments: ScanMode.PhoneNumber);
                },
                child: Text(
                  'Scan Phone numbers',
                  style: TextStyle(color: Colors.white, fontSize: 20.0),
                )),
            ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/camera', arguments: ScanMode.Email);
                },
                child: Text(
                  'Scan emails',
                  style: TextStyle(color: Colors.white, fontSize: 20.0),
                ))
          ],
        ),
      )
    ]));
  }
}
