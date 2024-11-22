// ignore_for_file: unused_local_variable

import 'dart:developer';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:elearning_mobile_app/common/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

void InfoKioskMode(context) async {
  var kioskMode = await getKioskMode();

  if (kioskMode == KioskMode.enabled) {
    log('Kiosk mode enabled');
    return;
  } else {
    log('Kiosk mode disabled');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Peringatan!'),
          content: Text(
              'Kiosk Mode belum aktif, aktifkan kiosk mode terlebih dahulu untuk melanjutkan ujian'),
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
}

void enableKioskMode(context) async {
  await startKioskMode();
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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

  late WebViewController webController;
  int webProgress = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.top,
    ]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    enableKioskMode(context);
    WidgetsBinding.instance.addObserver(this);
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            log('Loading: $progress%');
            setState(() {
              webProgress = progress;
            });
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(Constants.baseUrl));
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

      InfoKioskMode(context);
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
        body: SafeArea(
            child: Column(
          children: [
            webProgress == 100
                ? SizedBox.shrink()
                : SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: webProgress / 100,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
            Expanded(child: WebViewWidget(controller: webController)),
          ],
        )),
      ),
    );
  }
}
