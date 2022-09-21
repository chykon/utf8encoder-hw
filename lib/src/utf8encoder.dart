import 'package:rohd/rohd.dart';
import 'package:utf8encoder_hw/src/alternative_operators.dart';
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
      count.cassign(0),
      IfBlock([
        Iff(codepoint.logic.gte(0).band(codepoint.logic.lte(0x7F)), [
          bytes.logic.cassign(codepoint.logic.zeroExtend(32)),
          status.logic.cassign(UTF8Encoder.statusSuccess),
        ]),
        ElseIf(
          codepoint.logic.gte(0x80).band(codepoint.logic.lte(0x7FF)),
          [
            count.cassign(1),
            offset.cassign(0xC0),
          ],
        ),
        ElseIf(
          codepoint.logic.gte(0x800).band(codepoint.logic.lte(0xFFFF)),
          [
            count.cassign(2),
            offset.cassign(0xE0),
          ],
        ),
        ElseIf(
          codepoint.logic.gte(0x10000).band(codepoint.logic.lte(0x10FFFF)),
          [
            count.cassign(3),
            offset.cassign(0xF0),
          ],
        ),
        Else([
          status.logic.cassign(UTF8Encoder.statusFailure),
        ])
      ]),
      IfBlock([
        Iff(count.eq(0).bnot(), [
          byte.cassign(
            codepoint.logic
                .srl(count.zeroExtend(5).mul(6))
                .add(offset.zeroExtend(21))
                .slice(7, 0),
          ),
          // TODO(chykon): codepoint doesn't work correctly without this, https://github.com/intel/rohd/issues/158.
          debug1.cassign(codepoint.logic),
          bytes.logic.cassign(byte.zeroExtend(32)),
          temp.cassign(
            codepoint.logic.srl(count.sub(1).zeroExtend(4).mul(6)).slice(7, 0),
          ),
          byte.cassign(temp.band(0x3F).bor(0x80)),
          bytes.logic.cassign(bytes.logic.withSet(8, byte)),
          count.cassign(count.sub(1)),
          IfBlock([
            Iff(count.eq(0), [
              status.logic.cassign(UTF8Encoder.statusSuccess),
            ]),
            Else([
              temp.cassign(
                codepoint.logic
                    .srl(count.sub(1).zeroExtend(3).mul(6))
                    .slice(7, 0),
              ),
              byte.cassign(temp.band(0x3F).bor(0x80)),
              bytes.logic.cassign(bytes.logic.withSet(16, byte)),
              count.cassign(count.sub(1)),
              IfBlock([
                Iff(count.eq(0), [
                  status.logic.cassign(UTF8Encoder.statusSuccess),
                ]),
                Else([
                  temp.cassign(codepoint.logic.slice(7, 0)),
                  byte.cassign(temp.band(0x3F).bor(0x80)),
                  bytes.logic.cassign(bytes.logic.withSet(24, byte)),
                  status.logic.cassign(UTF8Encoder.statusSuccess),
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
