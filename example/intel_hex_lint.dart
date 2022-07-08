// Copyright (C) 2022 by domohuhn
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:intel_hex/intel_hex.dart';
import 'dart:io';

/// This file shows how to create a program that reads a Intel HEX file
/// from the file system and checks if there are any errors in the file.

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print(
        "Intel HEX file linter. This program will read an Intel HEX file and check for any errors.\n    Usage: intel_hex_lint <path to intel hex file>\n");
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
    print("Valid:\n$hex");
  } catch (e) {
    print("'${arguments[0]}' is not a valid Intel hex file:\n$e");
    exit(1);
  }
}
