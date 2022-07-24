// Copyright (C) 2022 by domohuhn
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:typed_data';

/// Validates that the byte data read from an Intel Hex record is correct by computing the checksum
/// and comparing the result to a [target] value.
///
/// Returns true if the computed value matches the target value.
bool validateChecksum(Iterable<int> data, [int target=0]) {
  return _sumAllLSB(data) == target;
}

/// Computes a checksum for the given [data]. 
/// All values are summed with overflow and then
/// the ones or twos complement of the sum is 
/// selected, depending on [isTwosComplement].
int computeChecksum(Iterable<int> data, [bool isTwosComplement=true]) {
  int sum = _sumAllLSB(data);
  sum = ~sum;
  if(isTwosComplement) {
    sum += 1;
  }
  return sum & 0xFF;
}

/// Computes the sum of the LSB of all values in [data].
/// Returns the truncated LSB of the sum.
int _sumAllLSB(Iterable<int> data) {
  int sum = 0;
  for (int v in data) {
    sum += v & 0xFF;
  }
  return sum & 0xFF;
}

/// Appends the checksum to the given [data].
Uint8List appendChecksum(Uint8List data) {
  var checksum = computeChecksum(data);
  return Uint8List.fromList(data + <int>[checksum]);
}
