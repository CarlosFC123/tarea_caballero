import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:flutter/foundation.dart';

@JS('setupSpeechRecognition')
external dynamic _setupSpeechRecognition();

@JS('window.SpeechRecognition')
external dynamic get _speechRecognition;

@JS('window.webkitSpeechRecognition')
external dynamic get _webkitSpeechRecognition;

@JS('window')
external dynamic get _window;

class SpeechRecognitionService {
  dynamic _recognition;
  Function(String)? onResult;
  Function(String)? onError;

  Future<void> initialize() async {
    if (!kIsWeb) {
      throw Exception('Speech Recognition solo está disponible en Web');
    }

    try {
      // Primero intenta usar la función personalizada
      if (_isJSFunctionAvailable('setupSpeechRecognition')) {
        _recognition = _setupSpeechRecognition();
      } else {
        // Fallback: crear directamente el reconocedor
        _recognition = _createSpeechRecognition();
      }

      if (_recognition == null) {
        throw Exception('No se pudo crear el reconocedor de voz');
      }

      // Configurar propiedades
      setProperty(_recognition, 'lang', 'es-ES');
      setProperty(_recognition, 'interimResults', false);
      setProperty(_recognition, 'maxAlternatives', 1);
      setProperty(_recognition, 'continuous', false);
      
      // Configurar callbacks
      setProperty(_recognition, 'onresult', allowInterop((event) {
        try {
          final results = getProperty(event, 'results');
          if (results != null) {
            final result = getProperty(results, '0');
            if (result != null) {
              final alternative = getProperty(result, '0');
              if (alternative != null) {
                final transcript = getProperty(alternative, 'transcript');
                if (transcript != null) {
                  onResult?.call(transcript.toString());
                }
              }
            }
          }
        } catch (e) {
          onError?.call('Error al procesar el resultado: $e');
        }
      }));

      setProperty(_recognition, 'onerror', allowInterop((event) {
        final error = getProperty(event, 'error');
        onError?.call('Error en reconocimiento de voz: ${error ?? 'desconocido'}');
      }));

      setProperty(_recognition, 'onend', allowInterop((event) {
        // El reconocimiento terminó
      }));

    } catch (e) {
      throw Exception('No se pudo inicializar el reconocimiento de voz: $e');
    }
  }

  dynamic _createSpeechRecognition() {
    // Intenta crear directamente el objeto SpeechRecognition
    try {
      if (_speechRecognition != null) {
        return callConstructor(_speechRecognition, []);
      } else if (_webkitSpeechRecognition != null) {
        return callConstructor(_webkitSpeechRecognition, []);
      }
    } catch (e) {
      print('Error creando SpeechRecognition: $e');
    }
    return null;
  }

  bool _isJSFunctionAvailable(String functionName) {
    try {
      return getProperty(_window, functionName) != null;
    } catch (e) {
      return false;
    }
  }

  void startListening() {
    if (_recognition == null) {
      onError?.call('Reconocimiento de voz no inicializado');
      return;
    }
    
    try {
      callMethod(_recognition, 'start', []);
    } catch (e) {
      onError?.call('Error al iniciar reconocimiento: $e');
    }
  }

  void stopListening() {
    if (_recognition == null) return;
    
    try {
      callMethod(_recognition, 'stop', []);
    } catch (e) {
      print('Error al detener reconocimiento: $e');
    }
  }

  void dispose() {
    if (_recognition == null) return;
    
    try {
      callMethod(_recognition, 'abort', []);
    } catch (e) {
      print('Error al abortar reconocimiento: $e');
    }
    
    _recognition = null;
  }

  // Método para verificar si el reconocimiento de voz está disponible
  static bool isSupported() {
    if (!kIsWeb) return false;
    
    try {
      return getProperty(_window, 'SpeechRecognition') != null ||
             getProperty(_window, 'webkitSpeechRecognition') != null;
    } catch (e) {
      return false;
    }
  }
}