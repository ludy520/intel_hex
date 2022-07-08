## 1.1.0

- Added check for duplicate addresses when parsing a string.
- Added a method to get a ByteData object from the underlying buffer of a segment to simplify deserializing data.
- Added methods to append typed data to a memory segment.
- Added a check in toFileContents() to search for overlapping addresses.
- Management of the memory segments has been moved to its own class.

## 1.0.0

- Initial version.
- Support for Intel HEX files with all standard records and a configurable start code added.
