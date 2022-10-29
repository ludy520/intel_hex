// Copyright (C) 2022 by domohuhn
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:typed_data';

import 'package:intel_hex/intel_hex.dart';
import 'dart:io';

/// This file shows how to create a program that reads a Intel HEX file
/// from the file system and writes the contents as binary file.

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print(
        "Intel HEX file converter. This program will read an Intel HEX file and convert it to a binary file.\n    Usage: convert_to_binary <path to intel hex file>\n");
    exit(0);
  }
  String file = "";
  try {
    file = File(arguments[0]).readAsStringSync();
  } catch (e) {
    print("Failed to open file '${arguments[0]}':\n$e");
    exit(1);
  }
  try {
    var hex = IntelHexFile.fromString(file);
    final filesize = hex.maxAddress;
    final outfile = getOutputFileName(arguments[0]);
    print("Converting input file to binary: output: '$outfile' -> $filesize bytes!\n");
    var data = Uint8List(filesize);
    for(final seg in hex.segments) {
      for(int i=seg.address;i<seg.endAddress;++i) {
        data[i] = seg.byte(i);
      }
    }
    File(outfile).writeAsBytesSync(data);
  } catch (e) {
    print("'${arguments[0]}' is not a valid Intel hex file:\n$e");
    exit(1);
  }
}

String getOutputFileName(String nm) {
  int index = nm.lastIndexOf('.');
  if(index>0) {
    return '${nm.substring(0,index)}.bin';
  }
  return '$nm.bin';
}
