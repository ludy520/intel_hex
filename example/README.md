# Example files

The full source code for the examples can be found in [the examples directory in github](https://github.com/domohuhn/intel_hex/tree/main/example).

## Intel HEX file linter

The file "intel_hex_lint.dart" contains all the code you need to validate that
an Intel HEX file contains no errors. The program reads a file, and parses all
records until the first "End of file" record is found. If there is any type of error (checksum not valid, wrong record block, wrong characters...) an exception is thrown.

The example condensed into a few lines:
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

The file "convert_to_intel_hex.dart" contains all the code you need to convert binary data to an Intel HEX file.

The example condensed into a few lines:
```dart
import 'package:intel_hex/intel_hex.dart';

List<int> data = /* fill data */;
var hex = IntelHexFile.fromData(data);
var hexString = hex.toFileContents();
```

## Try the executables

You can try the example executables with a few simple commands in the project root directory:
```bash
# Runs the linter on an invalid file - will display an error and return a nonzero value
dart ./example/intel_hex_lint.dart ./example/convert_to_intel_hex.dart
# Converts a file to Intel HEX
dart ./example/convert_to_intel_hex.dart ./example/convert_to_intel_hex.dart
# Runs the linter on a valid file
dart ./example/intel_hex_lint.dart ./example/convert_to_intel_hex.dart.hex
```
