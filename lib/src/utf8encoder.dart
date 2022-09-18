import 'package:rohd/rohd.dart';
import 'package:utf8encoder_hw/src/explicit_logic.dart';

/// A module for converting Unicode code points to UTF-8.
class UTF8Encoder extends Module {
  /// Create a new module instance.
  UTF8Encoder(
    InputLogic21 codepoint,
    OutputLogic1 status,
    OutputLogic32 bytes, {
    super.name = 'utf8encoder',
  }) {
    codepoint.logic = addInput('codepoint', codepoint.logic, width: 21);
    status.logic = addOutput('status');
    bytes.logic = addOutput('bytes', width: 32);

    final count = Logic(name: 'count', width: 2);
    final offset = Logic(name: 'offset', width: 8);
    final byte = Logic(name: 'byte', width: 8);
    final temp = Logic(name: 'temp', width: 8);

    final debug1 = Logic(name: 'debug_1', width: 21);

    Combinational([
      count < 0,
      IfBlock([
        Iff((codepoint.logic >= 0) & codepoint.logic.lte(0x7F), [
          bytes.logic < codepoint.logic.zeroExtend(32),
          status.logic < UTF8Encoder.statusSuccess
        ]),
        ElseIf(
          (codepoint.logic >= 0x80) & codepoint.logic.lte(0x7FF),
          [count < 1, offset < 0xC0],
        ),
        ElseIf(
          (codepoint.logic >= 0x800) & codepoint.logic.lte(0xFFFF),
          [count < 2, offset < 0xE0],
        ),
        ElseIf(
          (codepoint.logic >= 0x10000) & codepoint.logic.lte(0x10FFFF),
          [count < 3, offset < 0xF0],
        ),
        Else([status.logic < UTF8Encoder.statusFailure])
      ]),
      IfBlock([
        Iff(~count.eq(0), [
          byte <
              ((codepoint.logic >>>
                          (Const(6, width: 5) * count.zeroExtend(5))) +
                      offset.zeroExtend(21))
                  .slice(7, 0),
          // NOTE: Codepoint doesn't work correctly without this.
          debug1 < codepoint.logic,
          bytes.logic < byte.zeroExtend(32),
          temp <
              (codepoint.logic >>>
                      (Const(6, width: 4) * (count - 1).zeroExtend(4)))
                  .slice(7, 0),
          byte < Const(0x80, width: 8) | (temp & Const(0x3F, width: 8)),
          bytes.logic < bytes.logic.withSet(8, byte),
          count < count - 1,
          IfBlock([
            Iff(count.eq(0), [status.logic < UTF8Encoder.statusSuccess]),
            Else([
              temp <
                  (codepoint.logic >>>
                          (Const(6, width: 3) * (count - 1).zeroExtend(3)))
                      .slice(7, 0),
              byte < Const(0x80, width: 8) | (temp & Const(0x3F, width: 8)),
              bytes.logic < bytes.logic.withSet(16, byte),
              count < count - 1,
              IfBlock([
                Iff(count.eq(0), [status.logic < UTF8Encoder.statusSuccess]),
                Else([
                  temp < codepoint.logic.slice(7, 0),
                  byte < Const(0x80, width: 8) | (temp & Const(0x3F, width: 8)),
                  bytes.logic < bytes.logic.withSet(24, byte),
                  status.logic < UTF8Encoder.statusSuccess
                ])
              ])
            ])
          ])
        ])
      ])
    ]);
  }

  /// Output ready.
  static const statusSuccess = 0;

  /// An invalid code point was received. See ["The Unicode Standard",
  /// section 2.4 "Code Points and Characters"](https://www.unicode.org/versions/latest/ch02.pdf).
  static const statusFailure = 1;
}
