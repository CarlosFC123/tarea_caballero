// speech_recognition.js
// Este archivo debe estar en la carpeta web/

// Verificar que la función se ejecute cuando se carga la página
console.log('Cargando speech_recognition.js...');

// Define la API de reconocimiento de voz para interoperabilidad
window.setupSpeechRecognition = function() {
  console.log('setupSpeechRecognition llamada');
  
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  
  if (!SpeechRecognition) {
    console.error('Speech Recognition API no disponible');
    throw new Error('Speech Recognition API no disponible');
  }
  
  console.log('Creando instancia de SpeechRecognition');
  const recognition = new SpeechRecognition();
  
  // Configuración básica
  recognition.lang = 'es-ES';
  recognition.interimResults = false;
  recognition.maxAlternatives = 1;
  recognition.continuous = false;
  
  console.log('SpeechRecognition configurado correctamente');
  return recognition;
};

// Verificar que la función esté disponible
console.log('setupSpeechRecognition disponible:', typeof window.setupSpeechRecognition);

// Verificar soporte de Speech Recognition
console.log('SpeechRecognition support:', !!(window.SpeechRecognition || window.webkitSpeechRecognition));