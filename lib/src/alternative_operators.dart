// ignore_for_file: public_member_api_docs

import 'package:rohd/rohd.dart';

Logic _dynamicToLogic(Logic self, dynamic other) {
  if (other is Logic) {
    return other;
  } else {
    return Const(other, width: self.width);
  }
}

extension AlternativeOperators on Logic {
  void assign(dynamic other) {
    return this <= _dynamicToLogic(this, other);
  }

  ConditionalAssign cassign(dynamic other) {
    return this < other;
  }

  Logic bnot() {
    return ~this;
  }

  Logic band(dynamic other) {
    return this & _dynamicToLogic(this, other);
  }

  Logic bor(dynamic other) {
    return this | _dynamicToLogic(this, other);
  }

  Logic bxor(dynamic other) {
    return this ^ _dynamicToLogic(this, other);
  }

  Logic uand() {
    return and();
  }

  Logic uor() {
    return or();
  }

  Logic uxor() {
    return xor();
  }

  Logic sll(dynamic other) {
    // TODO(chykon): minimize the width of other.
    return this << _dynamicToLogic(this, other);
  }

  Logic srl(dynamic other) {
    // TODO(chykon): minimize the width of other.
    return this >>> _dynamicToLogic(this, other);
  }

  Logic sra(dynamic other) {
    // TODO(chykon): minimize the width of other.
    return this >> _dynamicToLogic(this, other);
  }

  Logic add(dynamic other) {
    return this + other;
  }

  Logic sub(dynamic other) {
    return this - other;
  }

  Logic mul(dynamic other) {
    return this * other;
  }

  Logic div(dynamic other) {
    return this / other;
  }

  Logic mod(dynamic other) {
    return this % _dynamicToLogic(this, other);
  }

  Logic gt(dynamic other) {
    return this > other;
  }

  Logic gte(dynamic other) {
    return this >= other;
  }
}
