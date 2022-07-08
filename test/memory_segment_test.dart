// Copyright (C) 2022 by domohuhn
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:intel_hex/intel_hex.dart';
import 'package:intel_hex/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('Basic operations on segments', () {
    test('Create empty segment', () {
      var segment = MemorySegment(address: 0x42);
      expect(segment.address, 0x42);
      expect(segment.length, 0x00);
    });

    test('Create segment', () {
      var segment = MemorySegment(address: 0x42, length: 32);
      expect(segment.address, 0x42);
      expect(segment.length, 0x20);
    });

    test('Set line length', () {
      var segment = MemorySegment(address: 0x42);
      expect(
          () => segment.lineLength = 0, throwsA(TypeMatcher<IHexValueError>()));
      expect(() => segment.lineLength = 256,
          throwsA(TypeMatcher<IHexValueError>()));
    });

    test('Iterator error', () {
      var segment = MemorySegment(address: 0x42);
      var itr = segment.iterator;
      expect(() => itr.current, throwsA(TypeMatcher<IHexValueError>()));
    });

    test('Check if in segment', () {
      var segment = MemorySegment(address: 0x42, length: 32);
      expect(segment.isInRange(0x41, 1), false);
      expect(segment.isInRange(0x42, 1), true);
      expect(segment.isInRange(0x42, 32), true);
      expect(segment.isInRange(0x42 + 31, 1), true);
      expect(segment.isInRange(0x42 + 32, 1), false);
      expect(() => segment.byte(0xFF), throwsA(TypeMatcher<IHexRangeError>()));
      expect(() => segment.writeByte(0xFF, 42),
          throwsA(TypeMatcher<IHexRangeError>()));
    });

    test('Append byte to segment', () {
      var segment = MemorySegment(address: 0x42);
      segment.append(25);
      expect(segment.address, 0x42);
      expect(segment.length, 0x01);
      expect(segment.byte(0x42), 25);
      segment.append(26);
      expect(segment.address, 0x42);
      expect(segment.length, 0x02);
      expect(segment.byte(0x42), 25);
      expect(segment.byte(0x43), 26);
    });

    test('Append list of bytes to segment', () {
      var segment = MemorySegment(address: 0x10);
      List<int> data1 = [1, 2, 3, 4, 5, 6];
      List<int> data2 = [7, 8, 9];
      segment.appendAll(data1);
      expect(segment.address, 0x10);
      expect(segment.length, 0x06);
      for (int i = 0; i < 6; ++i) {
        expect(segment.byte(0x10 + i), i + 1);
      }
      segment.appendAll(data2);
      expect(segment.address, 0x10);
      expect(segment.length, 0x09);
      for (int i = 0; i < 9; ++i) {
        expect(segment.byte(0x10 + i), i + 1);
      }
    });

    test('Create from list of bytes and iterate', () {
      List<int> data1 = [1, 2, 3, 4, 5, 6];
      var segment = MemorySegment.fromBytes(address: 0x10, data: data1);
      expect(segment.address, 0x10);
      expect(segment.length, 0x06);
      expect(segment.endAddress, 0x16);
      int i = 0;
      for (var b in segment) {
        expect(b.address, 0x10 + i);
        expect(b.value, i + 1);
        ++i;
      }
    });

    test('Segments overlap', () {
      final segment1 = MemorySegment(address: 0, length: 32);
      final segment2 = MemorySegment(address: 16, length: 32);
      final segment3 = MemorySegment(address: 32, length: 32);
      final segment4 = MemorySegment(address: 64, length: 32);
      expect(segment1.overlaps(segment1), true);
      expect(segment1.overlaps(segment2), true);
      expect(segment1.overlaps(segment3), true);
      expect(segment1.overlaps(segment4), false);

      expect(segment2.overlaps(segment1), true);
      expect(segment2.overlaps(segment2), true);
      expect(segment2.overlaps(segment3), true);
      expect(segment2.overlaps(segment4), false);

      expect(segment3.overlaps(segment1), true);
      expect(segment3.overlaps(segment2), true);
      expect(segment3.overlaps(segment3), true);
      expect(segment3.overlaps(segment4), true);

      expect(segment4.overlaps(segment1), false);
      expect(segment4.overlaps(segment2), false);
      expect(segment4.overlaps(segment3), true);
      expect(segment4.overlaps(segment4), true);
    });

    test('Fill segments', () {
      final segment1 = MemorySegment(address: 0, length: 32);
      segment1.fill(25);
      for (var b in segment1) {
        expect(b.value, 25);
      }
    });

    test('Combine segments', () {
      final segment1 = MemorySegment(address: 0, length: 32);
      final segment2 = MemorySegment(address: 16, length: 32);
      final segment3 = MemorySegment(address: 32, length: 32);
      segment1.fill(25);
      segment2.fill(26);
      segment3.fill(27);
      for (var b in segment2) {
        expect(b.value, 26);
      }

      segment2.combine(segment2);
      expect(segment2.address, 16);
      expect(segment2.length, 32);
      expect(segment2.endAddress, 48);
      for (var b in segment2) {
        expect(b.value, 26);
      }

      segment2.combine(segment1);
      expect(segment2.address, 0);
      expect(segment2.length, 48);
      expect(segment2.endAddress, 48);
      for (var b in segment2) {
        expect(b.value, b.address < 32 ? 25 : 26);
      }

      segment2.combine(segment3);
      expect(segment2.address, 0);
      expect(segment2.length, 64);
      expect(segment2.endAddress, 64);
      for (var b in segment2) {
        expect(b.value, b.address < 32 ? 25 : 27);
      }

      segment1.combine(segment3);
      expect(segment1.address, 0);
      expect(segment1.length, 64);
      expect(segment1.endAddress, 64);
      for (var b in segment1) {
        expect(b.value, b.address < 32 ? 25 : 27);
      }
    });
  });

  group('Segment to file fragment', () {
    List<int> data = [];
    for (int i = 0; i < 32; ++i) {
      data.add(i);
    }
    final segment = MemorySegment.fromBytes(address: 0x20, data: data);
    const rv16Bytes =
        ":10002000000102030405060708090A0B0C0D0E0F58\n:10003000101112131415161718191A1B1C1D1E1F48\n";

    test('to I8HEX, 16 bytes', () {
      segment.lineLength = 16;
      var rv = segment.toFileContents(format: IntelHexFormat.i8HEX);
      expect(rv, rv16Bytes);
    });

    test('to I8HEX, 64 bytes', () {
      segment.lineLength = 64;
      var rv = segment.toFileContents(format: IntelHexFormat.i8HEX);
      expect(rv,
          ":20002000000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1FD0\n");
    });

    test('to I8HEX, 8 bytes', () {
      segment.lineLength = 8;
      var rv = segment.toFileContents(format: IntelHexFormat.i8HEX);
      expect(rv,
          ":080020000001020304050607BC\n:0800280008090A0B0C0D0E0F74\n:0800300010111213141516172C\n:0800380018191A1B1C1D1E1FE4\n");
    });

    test('to I16HEX, 16 bytes', () {
      segment.lineLength = 16;
      var rv = segment.toFileContents(format: IntelHexFormat.i16HEX);
      expect(rv, rv16Bytes);
    });

    test('to I32HEX, 16 bytes', () {
      segment.lineLength = 16;
      var rv = segment.toFileContents(format: IntelHexFormat.i32HEX);
      expect(rv, rv16Bytes);
    });
  });

  group('Large segment to file fragment', () {
    List<int> data = [];
    for (int i = 0; i < 1024 * 128; ++i) {
      data.add(i);
    }
    final segment = MemorySegment.fromBytes(address: 0x20, data: data);
    test('to I8HEX, 16 bytes per line', () {
      segment.lineLength = 16;
      expect(() => segment.toFileContents(format: IntelHexFormat.i8HEX),
          throwsA(TypeMatcher<IHexRangeError>()));
    });

    test('to I16HEX, 128 bytes per line', () {
      segment.lineLength = 128;
      var rv = segment.toFileContents(format: IntelHexFormat.i16HEX);
      int count = '\n'.allMatches(rv).length;
      expect(count, 1025);
      expect(rv.contains(":020000021000EC\n"), true);
    });

    test('to I32HEX, 128 bytes per line', () {
      segment.lineLength = 128;
      var rv = segment.toFileContents(format: IntelHexFormat.i32HEX);
      int count = '\n'.allMatches(rv).length;
      expect(count, 1025);
      expect(rv.contains(":020000040001F9\n"), true);
    });
  });
}
