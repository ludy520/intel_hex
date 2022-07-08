// Copyright (C) 2022 by domohuhn
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:test/test.dart';
import 'package:intel_hex/src/exceptions.dart';
import 'package:intel_hex/src/validation.dart';
import 'package:intel_hex/src/string_conversion.dart';

/// Tests for many error cases.

void main() {
  test('Validation of addresses', () {
    validateAddressAndLength(0x42, 0xFFFFF);
    expect(() => validateAddressAndLength(0xFFFFFFFF, 0xFFFFF),
        throwsA(TypeMatcher<IHexRangeError>()));
  });

  test('IHexRangeError', () {
    var err = IHexRangeError("text");
    expect(err.toString(), "IHexRangeError: text");
  });

  test('IHexValueError', () {
    var err = IHexValueError("text");
    expect(err.toString(), "IHexValueError: text");
  });

  test('IHexRecord no start token', () {
    expect(() => IHexRecord("text"), throwsA(TypeMatcher<IHexValueError>()));
  });

  test('IHexRecord read 4 bytes no payload', () {
    expect(() => IHexRecord(":00000001FF\n").startLinearAddress,
        throwsA(TypeMatcher<IHexValueError>()));
  });

  test('IHexRecord read 2 bytes no payload', () {
    expect(() => IHexRecord(":00000001FF\n").extendedLinearAddress,
        throwsA(TypeMatcher<IHexValueError>()));
  });
}
