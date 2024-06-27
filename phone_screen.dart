import 'package:google_fonts/google_fonts.dart'; // Add this for custom fonts
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'provider.dart'; // your provider file, make sure to change it.....
import 'package:shared_preferences/shared_preferences.dart';

class PhoneCallScreen extends StatefulWidget {
  const PhoneCallScreen({
    Key? key,
  }) : super(key: key);

  @override
  _PhoneCallScreenState createState() => _PhoneCallScreenState();
}

class _PhoneCallScreenState extends State<PhoneCallScreen> {
  SpeechProvider? _speechProvider;
  bool _isInitialized = false;
  Duration _callDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  void _startCallTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration += Duration(seconds: 1);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _speechProvider = Provider.of<SpeechProvider>(context, listen: false);
    if (!_isInitialized) {
      _initializeSpeechProvider();
      _isInitialized = true;
    }
  }

  Future<void> _initializeSpeechProvider() async {
    if (_speechProvider != null) {
      _startCallTimer();
      await _speechProvider!.initializeForMe(); //this will start everything
    }
  }


  @override
  void dispose() {
    printDebugStatement('Calling dispose for phone page..');
    super.dispose();
    printDebugStatement('Dispose ran for phone page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
            ),
            const SizedBox(height: 10),
            Text(
              widget.botName,
              style: GoogleFonts.lato(
                textStyle: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${_callDuration.inMinutes}:${(_callDuration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: GoogleFonts.lato(
                textStyle: TextStyle(color: Colors.black, fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            Consumer<SpeechProvider>(
              builder: (context, speechProvider, child) {
                return Text(
                  'Listening...',
                  style: GoogleFonts.lato(
                    textStyle: TextStyle(color: Colors.blue, fontSize: 24),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
