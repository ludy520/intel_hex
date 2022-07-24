// Copyright (C) 2022 by domohuhn
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:intel_hex/src/checksum.dart';
import 'dart:typed_data';
import 'package:test/test.dart';

void main() {
  group('Checksum', () {
    final expectedChecksum = 0x1E;
    List<int> fullRecord = [];
    List<int> recordWithoutChecksum = [];
    setUp(() {
      recordWithoutChecksum = [];
      fullRecord = [];
      recordWithoutChecksum.add(0x03);
      recordWithoutChecksum.add(0x00);
      recordWithoutChecksum.add(0x30);
      recordWithoutChecksum.add(0x00);
      recordWithoutChecksum.add(0x02);
      recordWithoutChecksum.add(0x33);
      recordWithoutChecksum.add(0x7A);
      fullRecord.addAll(recordWithoutChecksum);
      fullRecord.add(0x1E);
    });

    test('Validate checksum', () {
      expect(validateChecksum(fullRecord), true);
    });

    test('Compute checksum', () {
      expect(computeChecksum(recordWithoutChecksum), expectedChecksum);
    });

    test('Append checksum', () {
      var full = appendChecksum(Uint8List.fromList(recordWithoutChecksum));
      expect(full, fullRecord);
    });

    test('Check all values', () {
      for(int i=0;i<256;++i) {
        final list = Uint8List(1);
        list[0] = i;
        final withSum = appendChecksum(list);
        print("${withSum[0]} <-> ${withSum[1]} : ${withSum[0]+withSum[1]}");
        expect(validateChecksum(withSum), true);
      }
    });
  });
}
