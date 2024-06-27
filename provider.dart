//written by Pankaj Pande (pkjpande@gmail.com)

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart'; //can be ignored if not using it
import 'package:audioplayers/audioplayers.dart';  //can be ignored if not using
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SpeechProvider extends ChangeNotifier {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  String _transcription = '';
  String _botSpoke = '<Listening>';
  bool haveSomeSpeechData = false;
  Completer<void> _initializationCompleter = Completer<void>();
  bool _isDisposed = false; // Add this flag
  Completer<void>? _utteranceCompleter;
  int _restartWithoutDataCounter = 0;
  bool _isBoolListening = false;
  bool _isBoolPaused = false;
  bool _isBoolTalking = false;
  bool _isTTSinProgress = false;
  String get botSpoke => _botSpoke;
  stt.SpeechToText get speech => _speech;
  FlutterTts get tts => _flutterTts;
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isInitialized => _isInitialized;
  String get transcription => _transcription;
  bool get isListening => _isBoolListening;
  bool get isPaused => _isBoolPaused;
  bool get isTalking => _isBoolTalking;
  bool get isTTSProgress => _isTTSinProgress;

  SpeechProvider();

  Future<void> _setBool(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
    //printDebugStatement(
    //    'SharedPreferences set $key to $value'); // Add this line
    notifyListeners();
  }

  Future<bool> _getBool(String key, {bool defaultValue = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<void> _setString(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
    //printDebugStatement(
    //    'SharedPreferences set $key to $value'); // Add this line
    notifyListeners();
  }

  Future<String> _getString(String key, {String defaultValue = ''}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  Future<void> reset() async {
    _botSpoke = '<Listening>';
    _transcription = '';
    _isTTSinProgress = false;
    printDebugStatement('Reset called');
    await _setBool('shouldRestartListening', true);
    printDebugStatement(
        'Current _shouldRestartListening value in RESET: ${await _getBool('shouldRestartListening')}');
    _isBoolPaused = false;
    _isBoolListening = false;
    _isDisposed = false;
    _restartWithoutDataCounter = 0;
    haveSomeSpeechData = false;
    await _setBool('_isPaused', false);
    await _setBool('_isListening', false);
    await _setBool('isDisposed', false);
    await _setBool('isListening', false);
    await _setString('transcription', '');
    await _setBool('haveSomeSpeechData', false);
    await _setBool('ttsInProgress', false);
    await _setString('_botSpoke', '<listening>');
    await _setBool('_isTalking', false);
    await _setBool('isSystemPaused', false);
    _isBoolTalking = false;
    printDebugStatement('Reset done');
    notifyListeners();
  }

  Future<void> configureTTS() async {
    // Configure TTS
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.7);

    _flutterTts.setStartHandler(() async {
      printDebugStatement('TTS started');
      _isBoolTalking = true;
      await _setBool('_isTalking', true);
      if (!await _getBool('isDisposed')) notifyListeners();
    });

    _flutterTts.setCompletionHandler(() async {
      printDebugStatement('TTS completed');
      _isBoolTalking = false;

      try {
        await _setBool('_isTalking', false);
        printDebugStatement('_isTalking set to false');

        await _setBool('ttsInProgress', false);
        printDebugStatement('ttsInProgress set to false');

        await _setBool('shouldRestartListening', true);
        printDebugStatement('shouldRestartListening set to true');
      } catch (e) {
        printDebugStatement('Error setting SharedPreferences: $e');
      }

      if (_utteranceCompleter?.isCompleted == false) {
        _utteranceCompleter
            ?.complete(); // Complete the completer only if not completed
        printDebugStatement('Utterance completer completed');
      }

      if (!await _getBool('isDisposed')) notifyListeners();
    });

    _flutterTts.setCancelHandler(() async {
      printDebugStatement('TTS cancelled');
      _isBoolTalking = false;

      try {
        await _setBool('_isTalking', false);
        printDebugStatement('_isTalking set to false (cancel)');

        await _setBool('ttsInProgress', false);
        printDebugStatement('ttsInProgress set to false (cancel)');

        await _setBool('shouldRestartListening', true);
        printDebugStatement('shouldRestartListening set to true (cancel)');
      } catch (e) {
        printDebugStatement('Error setting SharedPreferences (cancel): $e');
      }

      if (_utteranceCompleter?.isCompleted == false) {
        _utteranceCompleter
            ?.complete(); // Complete the completer only if not completed
        printDebugStatement('Utterance completer completed (cancel)');
      }

      if (!await _getBool('isDisposed')) notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) async {
      printDebugStatement('TTS error: $msg');
      _isBoolTalking = false;

      try {
        await _setBool('_isTalking', false);
        printDebugStatement('_isTalking set to false (error)');

        await _setBool('ttsInProgress', false);
        printDebugStatement('ttsInProgress set to false (error)');

        await _setBool('shouldRestartListening', true);
        printDebugStatement('shouldRestartListening set to true (error)');
      } catch (e) {
        printDebugStatement('Error setting SharedPreferences (error): $e');
      }

      if (_utteranceCompleter?.isCompleted == false) {
        _utteranceCompleter?.completeError(
            Exception(msg)); // Complete the completer only if not completed
        printDebugStatement('Utterance completer completed with error');
      }

      if (!await _getBool('isDisposed')) notifyListeners();
    });
  }

  Future<void> initializeForMe() async {
    await reset();
    // Initialize speech and TTS
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();

    _isInitialized = await _speech.initialize(
      onStatus: (val) => _handleSpeechStatus(val),
      onError: (val) => _handleSpeechError(val.errorMsg, val.permanent),
    );

    await configureTTS();

    if (!_initializationCompleter.isCompleted) {
      _initializationCompleter.complete();
    }
    printDebugStatement('Starting to listen now quietly...');
    await listen();

    notifyListeners();
  }

  Future<void> stopAllAndPreventRestart() async {
    printDebugStatement(
        '(StopAll) Current _shouldRestartListening value: ${await _getBool('shouldRestartListening')}');
    await _setBool('shouldRestartListening', false);
    await _setBool('ttsInProgress', false);
    await _setBool('isSystemPaused', false);
    _restartWithoutDataCounter = 0;
    await _speech.stop();
    await _flutterTts.stop();
    printDebugStatement(
        '(StopAll) Current _shouldRestartListening value after set: ${await _getBool('shouldRestartListening')}');
    //await stopAll();
    _isDisposed = true; // Add this line
    await _setBool('isDisposed', true);
  }

  Future<void> stopAll() async {
    printDebugStatement('Stopping things before we move out...');
    await _speech.stop();
    await _flutterTts.stop();
    if (!await _getBool('isDisposed')) notifyListeners();
  }

  void _handleSpeechStatus(String status) async {
    if (_isDisposed) return; // Add this check
    if (_isBoolPaused) return;
    bool shouldRestartListening = await _getBool('shouldRestartListening');
    printDebugStatement(
        'Speech status : $status, shouldRestartListening:$shouldRestartListening');
    if (status == "done") {
     if (haveSomeSpeechData) {
        printDebugStatement('Processing data that we have...');
        //do something with speech data
        await _setBool('haveSomeSpeechData', false);
        haveSomeSpeechData = false;
        _restartWithoutDataCounter = 0;
      } else {
        _restartWithoutDataCounter++;
        if (_restartWithoutDataCounter >= 10) {
          // Pause the call when counter reaches 10
          printDebugStatement('No data received 10 times...');
          //do something since data has not been received for at least 10 times, we are wasting battery and othe resources
        }
      }

      while (await _getBool('ttsInProgress')) {
        await Future.delayed(
            Duration(milliseconds: 100)); // Wait for TTS to complete
        // printDebugStatement('tts in progress, cannot restart');
      }

      if (shouldRestartListening) {
        await _restartListening();
      }
    }
    if (!await _getBool('isDisposed')) notifyListeners();
  }

  void _handleSpeechError(String errorMsg, bool permanent) async {
    if (_isDisposed) return; // Add this check
    if (_isBoolPaused) return;
    bool shouldRestartListening = await _getBool('shouldRestartListening');
    printDebugStatement('Received error: $errorMsg');

    while (await _getBool('ttsInProgress')) {
      await Future.delayed(
          Duration(milliseconds: 100)); // Wait for TTS to complete
      //printDebugStatement('tts in progress, cannot restart');
    }

    if (shouldRestartListening) {
      await _restartListening();
    }

    if (!await _getBool('isDisposed')) notifyListeners();
  }

  Future<void> _restartListening() async {
    if (_isDisposed) return; // Add this check
    bool shouldRestartListening = await _getBool('shouldRestartListening');
    if (!shouldRestartListening) return;
    printDebugStatement('Restarting listening...');
    await _speech.stop();

    //let's restart the init itself, this can be ignored if you see success without it
    _isInitialized = await _speech.initialize(
      onStatus: (val) => _handleSpeechStatus(val),
      onError: (val) => _handleSpeechError(val.errorMsg, val.permanent),
    );

    _isBoolListening = false;
    await _setBool('_isListening', false);
    //await Future.delayed(Duration(milliseconds: 200));
    while (await _getBool('ttsInProgress')) {
      await Future.delayed(
          Duration(milliseconds: 100)); // Wait for TTS to complete
    }
    await listen();
    printDebugStatement('Listening restarted');
    if (!await _getBool('isDisposed')) notifyListeners();
  }

  Future<void> listen() async {
    if (_isDisposed) return; // Add this check

    if (!await _getBool('_isListening')) {
      printDebugStatement('starting speech yeahhh...');
      await _initializationCompleter.future; // Ensure initialization
      printDebugStatement('Init is also done for speech');
      _isBoolListening = true;
      await _setBool('_isListening', true);
      _botSpoke = '<listening...>';
      _speech.listen(
        onResult: (val) async {
          _isTTSinProgress = true;
          _transcription = val.recognizedWords;
          haveSomeSpeechData = val.recognizedWords.isNotEmpty;
          await _setString('transcription', val.recognizedWords);
          printDebugStatement('Words: ${await _getString('transcription')}');
          await _setBool('haveSomeSpeechData', val.recognizedWords.isNotEmpty);
          if (!await _getBool('isDisposed')) notifyListeners();
        },
      );
    }
  }

  @override //never going to use it therefore, you have to manually clean it up
  void dispose() {
    printDebugStatement('Calling dispose for the provider...');
    _setBool('isDisposed', true);
    stopAllAndPreventRestart();
    printDebugStatement('Calling dispose for the provider - DONE');
    super.dispose();
  }
}

void printDebugStatement(String msg) {
  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  String formatted = formatter.format(now);
  print(
      'Debug (provider page): $formatted : $msg'); // Print the formatted timestamp
}
