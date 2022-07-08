// Copyright (C) 2022 by domohuhn
// 
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:typed_data';

/// Validates that the byte data read from an Intel Hex record is correct by computing the checksum.
bool validateChecksum(Iterable<int> data) {
  return _sumAllLSB(data)==0;
}

/// Computes the Intel HEX chesum for given [data]
int computeChecksum(Iterable<int> data) {
  int sum = _sumAllLSB(data);
  return (~sum + 1) & 0xFF;
}

/// Computes the sum of the LSB of all values in [data].
/// Returns the truncated LSB of the sum.
int _sumAllLSB(Iterable<int> data) {
  int sum = 0;
  for(int v in data) {
    sum += v & 0xFF;
  }
  return sum & 0xFF;
}

/// Appends the checksum to the given [data]
Uint8List appendChecksum(Uint8List data) {
  var checksum = computeChecksum(data);
  return Uint8List.fromList(data + <int>[checksum]);
}
