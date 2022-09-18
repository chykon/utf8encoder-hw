import 'dart:convert';
import 'dart:io';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';
import 'package:utf8encoder_hw/utf8encoder_hw.dart';

Future<void> main() async {
  final codepoint = Logic(width: 21);
  final status = OutputLogic1();
  final bytes = OutputLogic32();
  final utf8encoder = UTF8Encoder(
    InputLogic21(codepoint),
    status,
    bytes,
  );
  await utf8encoder.build();

  test('Zero codepoint = zero bytes', () async {
    await Simulator.tick();
    await Simulator.tick();
    await Simulator.tick();
    codepoint.inject(0);
    await Simulator.tick();
    await Simulator.tick();
    await Simulator.tick();
    expect(status.logic.value.toInt(), UTF8Encoder.statusSuccess);
    expect(bytes.logic.value.toInt(), 0);
  });

  test('Invalid code points should throw an error', () async {
    codepoint.inject(0x110000);
    await Simulator.tick();
    await Simulator.tick();
    await Simulator.tick();
    expect(status.logic.value.toInt(), UTF8Encoder.statusFailure);
  });

  test('Example should work', () async {
    const string = 'Hello, Мир 👋';
    final codepoints = string.runes;
    final utf8Bytes = <int>[];
    for (final inputCodepoint in codepoints) {
      codepoint.inject(inputCodepoint);
      await Simulator.tick();
      await Simulator.tick();
      await Simulator.tick();
      expect(status.logic.value.toInt(), UTF8Encoder.statusSuccess);
      for (var i = 0; i < 4; ++i) {
        final tempByte = (bytes.logic.value.toInt() >> (8 * i)) & 0xFF;
        if ((tempByte != 0) || (i == 0)) {
          utf8Bytes.add(tempByte);
        }
      }
    }
    expect(utf8.decode(utf8Bytes), string);
  });

  test('Another example should work', () async {
    const string = '†† †† † †';
    final codepoints = string.runes;
    final utf8Bytes = <int>[];
    for (final inputCodepoint in codepoints) {
      codepoint.inject(inputCodepoint);
      await Simulator.tick();
      await Simulator.tick();
      await Simulator.tick();
      expect(status.logic.value.toInt(), UTF8Encoder.statusSuccess);
      for (var i = 0; i < 4; ++i) {
        final tempByte = (bytes.logic.value.toInt() >> (8 * i)) & 0xFF;
        if ((tempByte != 0) || (i == 0)) {
          utf8Bytes.add(tempByte);
        }
      }
    }
    expect(utf8.decode(utf8Bytes), string);
  });

  test('"utf8demo.txt" must be properly encoded', () async {
    final fileBytes = File('test/text/utf8demo.txt').readAsBytesSync();
    final string = utf8.decode(fileBytes);
    final codepoints = string.runes;
    final utf8Bytes = <int>[];
    for (final inputCodepoint in codepoints) {
      codepoint.inject(inputCodepoint);
      await Simulator.tick();
      await Simulator.tick();
      await Simulator.tick();
      expect(status.logic.value.toInt(), UTF8Encoder.statusSuccess);
      for (var i = 0; i < 4; ++i) {
        final tempByte = (bytes.logic.value.toInt() >> (8 * i)) & 0xFF;
        if ((tempByte != 0) || (i == 0)) {
          utf8Bytes.add(tempByte);
        }
      }
    }
    expect(utf8Bytes, fileBytes);
  });

  test('"utf8test.txt" must be properly encoded', () async {
    final fileBytes = File('test/text/utf8test.txt').readAsBytesSync();
    final string = utf8.decode(fileBytes, allowMalformed: true);
    final codepoints = string.runes;
    final utf8Bytes = <int>[];
    for (final inputCodepoint in codepoints) {
      codepoint.inject(inputCodepoint);
      await Simulator.tick();
      await Simulator.tick();
      await Simulator.tick();
      expect(status.logic.value.toInt(), UTF8Encoder.statusSuccess);
      for (var i = 0; i < 4; ++i) {
        final tempByte = (bytes.logic.value.toInt() >> (8 * i)) & 0xFF;
        if ((tempByte != 0) || (i == 0)) {
          utf8Bytes.add(tempByte);
        }
      }
    }
    expect(utf8Bytes, utf8.encode(string));
  });
}
