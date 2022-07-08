# Example files

This directory contains example files for the intel_hex library.

## Intel HEX file linter

The file "intel_hex_lint.dart" contains everything you need to validate that
an Intel HEX file contains no errors. The program reads a file, and parses all
records until the first "End of file" record is found. If there is any type of error (checksum not valid, wrong record block, wrong characters...) an exception is thrown.

Condensed to a few lines:
```dart
import 'package:intel_hex/intel_hex.dart';

try {
  var file = File(path).readAsStringSync();
  var hex = IntelHexFile.fromString(file);
} catch (e) {
  // handle error
}
```

## Intel HEX file converter

The file "convert_to_intel_hex.dart" contains everything you need to convert binary data to an Intel HEX file.

Condensed to a few lines:
```dart
import 'package:intel_hex/intel_hex.dart';

List<int> data = /* fill data */;
var hex = IntelHexFile.fromData(data);
var hexString = hex.toFileContents();
```
