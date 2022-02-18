import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

import 'package:flutter/material.dart';

class CronometroPage extends StatefulWidget {
  const CronometroPage({Key? key}) : super(key: key);

  @override
  State<CronometroPage> createState() => _CronometroPageState();
}

class _CronometroPageState extends State<CronometroPage> {
  int _counter = 3;
  late Timer _timer;
  bool isExibirDialog = false;

  startTime() {
    _counter = 3;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_counter > 0) {
          _counter--;
        } else {
          //reproduzir som
          final player = AudioCache();
          player.play("som_01.wav");
          _timer.cancel();
          isExibirDialog = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            isExibirDialog
                ? AlertDialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          "$_counter",
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                  )
                : RotatedBox(
                    quarterTurns: 0,
                    child: SizedBox(
                      height: 150,
                      width: 250,
                      child: Image.asset(
                        "assets/gif_seta.gif",
                        color: const Color(0xFF161616),
                      ),
                    ),
                  ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isExibirDialog = true;
                  startTime();
                });
              },
              child: const Text("Go!"),
            ),
          ],
        ),
      ),
    );
  }
}
