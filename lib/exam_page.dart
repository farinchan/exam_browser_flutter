// ignore_for_file: unused_local_variable

import 'dart:developer';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

void enableSecureScreen() async {
  await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
  await FlutterWindowManagerPlus.addFlags(
      FlutterWindowManagerPlus.FLAG_FULLSCREEN);
}

void enableKioskMode(context) async {
  await startKioskMode();
  watchKioskMode().listen((kioskMode) {
    if (kioskMode == KioskMode.enabled) {
      log('Kiosk mode enabled');
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Peringatan!'),
            content:
                Text('Kamu Belum Mengaktifkan Kiosk Mode, Silahkan Aktifkan'),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  await startKioskMode();
                  Navigator.of(context).pop();
                },
                child: Text('Aktifkan'),
              ),
            ],
          );
        },
      );
    }
  });
}

class _ExamPageState extends State<ExamPage> with WidgetsBindingObserver {
  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Konfirmasi"),
              content: Text("Anda yakin ingin keluar dari ujian?"),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: Text("Tidak"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await stopKioskMode();
                    SystemNavigator.pop();
                  },
                  child: Text("Yes"),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    enableSecureScreen();
    enableKioskMode(context);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      log('App is paused or inactive');
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Peringatan!',
          message: 'Kamu Terdeteksi melakukan tindakan curang saat ujian',
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        await _showExitConfirmation(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exam Page'),
        ),
        body: const Center(
          child: Text('This is the exam page'),
        ),
      ),
    );
  }
}
