// Copyright (C) 2022 by domohuhn
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:intel_hex/src/exceptions.dart';
import 'package:intel_hex/src/memory_segment.dart';
import 'package:intel_hex/src/string_conversion.dart';
import 'dart:math';

/// The format that is used to print the intel hex file.
///
enum IntelHexFormat {
  /// only uses record types 0 and 1. Max address is 65535 (65 kB).
  i8HEX,

  /// only uses record types 0 through 3. Max address is 1048560 (1 MB).
  i16HEX,

  /// only uses record types 0, 1, 4 and 5. Max address is 2^32 (4 GB).
  i32HEX
}

/// Data type representing the start segment address.
/// For 80x86 CPUs, this is the start address of the execution.
class StartSegmentAddress {
  /// Initial value of the instruction pointer. 16 bits.
  int instructionPointer = 0;

  /// Start address of the code segement. 16 bits.
  int codeSegment = 0;
}

/// This class represents the interface to read and write Intel hex files.
///
/// To parse a file, simply read it as string and call the fromString()
/// constructor. If you want to write a file with binary data, then
/// you can create an empty file and add your data by calling addAll().
///
/// The contents of the file are stored as [MemorySegment].
class IntelHexFile {
  final List<MemorySegment> _segments;

  /// Returns all segments in the file. To add data, use [addSegment] or [addAll].
  List<MemorySegment> get segments => _segments;

  /// The start address where the code is executed (for 80x86 CPUs).
  /// This value may be null if it is not contained in the file.
  StartSegmentAddress? startSegmentAddress;

  /// The start address where the code is executed (if supported by the CPU).
  /// This value may be null if it is not contained in the file.
  int? startLinearAddress;

  /// The start code for a record. The standard value is ":".
  String startCode = ":";

  /// Creates a file with a single segment if [address] is >= 0 and [length] is >0.
  /// Otherwise the file is empty.
  IntelHexFile({int? address, int? length}) : _segments = [] {
    if (address != null && length != null && address >= 0 && length > 0) {
      addSegment(MemorySegment(address: address, length: length));
    }
  }

  /// Creates a file with a single segment containing all bytes from [data].
  /// The start [address] is 0 unless another value is provided.
  ///
  /// The contents of [data] will be truncated to (0, 255).
  IntelHexFile.fromData(Iterable<int> data, {int address = 0})
      : _segments = [] {
    addAll(address, data);
  }

  /// Parses the Intel Hex records in the [data] string and adds it to the
  /// segments in this object. All lines without ":" are ignored. In lines with a colon all preceding
  /// characters are ignored. After the colon, only valid characters for hexadecimal numbers (0-9a-fA-F)
  /// are allowed up until the end of the line.
  ///
  /// May throw an error during parsing. Potential error cases are: a checksum that is not correct,
  /// a record with an unknown record type, a record where the given length is wrong, a record that
  /// can not be converted to integers or if records 3 or 5 occur multiple times.
  ///
  /// If a nonstandard start code should be used instead of ":", then you must provide it
  /// via the optional argument [startToken]. If provided, the [startCode] property will be set.
  ///
  /// The constructor will also verify that every address in the data string is unique. You can prevent this
  /// check by setting [allowDuplicateAddresses] to true.
  IntelHexFile.fromString(String data,
      {String? startToken, bool allowDuplicateAddresses = false})
      : _segments = [] {
    if (startToken != null) {
      startCode = startToken;
    }
    final re = RegExp(r'[\r\n]+');
    final lines = data.split(re);
    int lineNo = 0;
    int extendedSegmentAddress = 0;
    int extendedLinearAddress = 0;

    for (final line in lines) {
      lineNo++;
      if (!line.contains(startCode)) {
        continue;
      }
      bool done = false;
      try {
        var record = IHexRecord(line, startCode: startCode);
        switch (record.recordType) {
          case IHexRecordType.data:
            _addDataRecord(record, extendedLinearAddress,
                extendedSegmentAddress, allowDuplicateAddresses);
            break;
          case IHexRecordType.endOfFile:
            done = true;
            break;
          case IHexRecordType.extendedSegmentAddress:
            extendedSegmentAddress = record.extendedSegmentAddress;
            break;
          case IHexRecordType.startSegmentAddress:
            if (startSegmentAddress != null) {
              throw IHexValueError(
                  "Start segment address record occurs more than once!");
            }
            startSegmentAddress = record.startSegmentAddress;
            break;
          case IHexRecordType.extendedLinearAddress:
            extendedLinearAddress = record.extendedLinearAddress;
            break;
          case IHexRecordType.startLinearAddress:
            if (startLinearAddress != null) {
              throw IHexValueError(
                  "Start linear address record occurs more than once!");
            }
            startLinearAddress = record.startLinearAddress;
            break;
        }
      } catch (e) {
        throw IHexValueError("Parsing error on line $lineNo : $e");
      }
      if (done) {
        break;
      }
    }
  }

  /// Converts this instance of IntelHexFile to an Intel Hex file record block.
  String toFileContents({IntelHexFormat format = IntelHexFormat.i32HEX}) {
    String rv = "";
    if (startLinearAddress != null) {
      rv += createStartLinearAddressRecord(startLinearAddress!,
          startCode: startCode);
    }
    if (startSegmentAddress != null) {
      rv += createStartSegmentAddressRecord(startSegmentAddress!.codeSegment,
          startSegmentAddress!.instructionPointer,
          startCode: startCode);
    }

    for (final seg in segments) {
      rv += seg.toFileContents(format: format, startCode: startCode);
    }
    rv += createEndOfFileRecord(startCode: startCode);
    return rv;
  }

  /// Adds the data conatined in [data] to the file at [startAddress].
  /// Contents will be truncated to (0, 255).
  /// If there was data
  void addAll(int startAddress, Iterable<int> data) {
    var newSegment = MemorySegment.fromBytes(address: startAddress, data: data);
    addSegment(newSegment);
  }

  /// Adds the [segment] to the file and overwrites data that was stored previously at the
  /// same addresses.
  void addSegment(MemorySegment segment) {
    bool combined = false;
    for (var old in _segments) {
      if (old.overlaps(segment)) {
        old.combine(segment);
        combined = true;
        break;
      }
    }
    if (!combined) {
      _segments.add(segment);
    }
    _sortSegments();
    _mergeSegments();
    _removeOverlapping();
  }

  void _mergeSegments() {
    for (int i = 0; i < _segments.length; ++i) {
      for (int k = i + 1; k < _segments.length; ++k) {
        if (_segments[k].overlaps(_segments[i])) {
          _segments[k].combine(_segments[i]);
          _segments[i].isOverlapping = true;
        }
      }
    }
  }

  void _removeOverlapping() {
    _segments.removeWhere((item) => item.isOverlapping);
  }

  void _sortSegments() {
    _segments.sort((a, b) => a.address.compareTo(b.address));
  }

  void _addDataRecord(IHexRecord record, int extendedLinearAddress,
      int extendedSegmentAddress, bool allowDuplicateAddresses) {
    final address =
        record.recordAddress + extendedLinearAddress + extendedSegmentAddress;
    final seg = MemorySegment.fromBytes(address: address, data: record.payload);
    if (!allowDuplicateAddresses) {
      _verifyAddressIsUnique(seg);
    }
    addSegment(seg);
  }

  void _verifyAddressIsUnique(MemorySegment next) {
    for (final old in _segments) {
      if (old.isInRange(next.address, 1) || old.isInRange(next.endAddress, 1)) {
        throw IHexRangeError(
            "The address range [${next.address}, ${next.endAddress}[ of a record is not unique! It is overlapping with: [${old.address}, ${old.endAddress}[");
      }
    }
  }

  /// Returns the max address in the file.
  int get maxAddress => segments.fold(
      0,
      (int previousValue, MemorySegment element) =>
          max(previousValue, element.endAddress));

  /// Returns the format that can be used to represent the file.
  IntelHexFormat get format {
    final maxAddr = maxAddress;
    if (maxAddr <= 65536) {
      return IntelHexFormat.i8HEX;
    } else if (maxAddr <= 1048576) {
      return IntelHexFormat.i16HEX;
    }
    return IntelHexFormat.i32HEX;
  }

  /// Returns a list of possible file extensions for intel hex files
  List<String> fileExtensions() {
    return [
      ".hex",
      ".h86",
      ".hxl",
      ".hxh",
      ".obl",
      ".obh",
      ".mcs",
      ".ihex",
      ".ihe",
      ".ihx",
      ".a43",
      ".a90"
    ];
  }

  /// Prints information about the file and its contents.
  @override
  String toString() {
    String rv = '"Intel HEX" : { "segments": [ ';
    for (var element in _segments) {
      rv += '{"start": ${element.address},"end": ${element.endAddress}},';
    }
    return '${rv.substring(0, rv.length - 1)}] }';
  }
}
