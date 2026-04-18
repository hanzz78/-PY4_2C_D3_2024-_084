import 'package:flutter_test/flutter_test.dart';
// Sesuaikan path import di bawah ini dengan nama project kamu
import '../lib/counter_controller.dart'; 

void main() {
  group('CounterController 10 Test Cases', () {
    late CounterController controller;

    setUp(() {
      controller = CounterController();
    });

    // --- TEST MODULE: setStep ---
    test('TC01: Positif - change step value to 5', () {
      controller.setStep(5);
      expect(controller.step, 5);
    });

    test('TC02: Negatif - ignore negative step value', () {
      controller.setStep(-2);
      expect(controller.step, 1); // Harus tetap 1 (default)
    });

    // --- TEST MODULE: increment ---
    test('TC03: Positif - normal increase by 1', () {
      controller.increment();
      expect(controller.value, 1);
    });

    test('TC04: Positif - increase by custom step (2)', () {
      controller.setStep(2);
      controller.increment();
      expect(controller.value, 2);
    });

    // --- TEST MODULE: decrement (TARGET BUG) ---
    test('TC05: Positif - decrease counter based on step', () {
      controller.setStep(2);
      controller.increment(); // value = 2
      controller.decrement(); // Ekspektasi: 2 - 2 = 0
      
      // Ini akan FAILED karena bug: _counter = _step (Hasil aktual: 2)
      expect(controller.value, 0); 
    });

    test('TC06: Negatif - should not go below zero', () {
      controller.decrement();
      expect(controller.value, 0);
    });

    // --- TEST MODULE: reset ---
    test('TC07: Positif - reset to zero and clear history', () {
      controller.increment();
      controller.reset();
      expect(controller.value, 0);
      expect(controller.history.isEmpty, true);
    });

    // --- TEST MODULE: history ---
    test('TC08: Positif - record increment action', () {
      controller.increment();
      expect(controller.history.isNotEmpty, true);
      expect(controller.history[0].contains("TAMBAH"), true);
    });

    test('TC09: Positif - record decrement action', () {
      controller.increment(); // 1
      controller.decrement(); 
      expect(controller.history[0].contains("KURANG") || controller.history[0].contains("RESET"), true);
    });

    test('TC10: Negatif - limit history size to 5 items', () {
      for (int i = 0; i < 10; i++) {
        controller.increment();
      }
      expect(controller.history.length, 5);
    });
  });
}