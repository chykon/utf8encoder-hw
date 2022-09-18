import 'dart:convert';
import 'dart:io';
import 'package:rohd/rohd.dart';
import 'package:utf8encoder_hw/utf8encoder_hw.dart';

Future<void> main() async {
  // Preparing inputs and outputs.
  final codepoint = Logic(width: 21);
  final status = OutputLogic1();
  final bytes = OutputLogic32();

  // Create and build module instance.
  final utf8encoder = UTF8Encoder(
    InputLogic21(codepoint),
    status,
    bytes,
  );
  await utf8encoder.build();

  // Generate SystemVerilog code.
  File('build/rohd/code.sv')
    ..createSync(recursive: true)
    ..writeAsStringSync(utf8encoder.generateSynth());

  // Prepare WaveDumper for simulation tracking. To view the file, you can use
  // https://vc.drom.io/
  WaveDumper(utf8encoder, outputPath: 'build/rohd/waves.vcd');

  // Prepare input and output.
  final codepoints = 'Hello, Мир 👋'.runes;
  final utf8Bytes = <int>[];

  // Run simulation.
  SimpleClockGenerator(10);
  await Simulator.tick();
  await Simulator.tick();
  for (final inputCodepoint in codepoints) {
    codepoint.inject(inputCodepoint);
    await Simulator.tick();
    await Simulator.tick();
    await Simulator.tick();
    for (var i = 0; i < 4; ++i) {
      final tempByte = (bytes.logic.value.toInt() >> (8 * i)) & 0xFF;
      if ((tempByte != 0) || (i == 0)) {
        utf8Bytes.add(tempByte);
      }
    }
  }
  codepoint.inject(0);
  await Simulator.tick();
  await Simulator.tick();

  // Print result.
  stdout.writeln(utf8.decode(utf8Bytes));
}
