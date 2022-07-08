// Copyright (C) 2022 by domohuhn
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:intel_hex/src/memory_segment.dart';
import 'dart:math';

/// This class represents multiple memory segments.
///
/// The contents of the memory are stored as instances of [MemorySegment].
class MemorySegmentContainer {
  /// list with all segments.
  final List<MemorySegment> _segments;

  /// Returns all segments in the container. To add data, use [addSegment] or [addAll].
  List<MemorySegment> get segments => _segments;

  /// Creates a container with a single segment if [address] is >= 0 and [length] is >= 0.
  /// Otherwise there are no segments.
  MemorySegmentContainer({int? address, int? length}) : _segments = [] {
    if (address != null && length != null && address >= 0 && length >= 0) {
      addSegment(MemorySegment(address: address, length: length));
    }
  }

  /// Creates a container with a single segment with all bytes from [data].
  /// The start [address] is 0 unless another value is provided.
  ///
  /// The contents of [data] will be truncated to (0, 255).
  MemorySegmentContainer.fromData(Iterable<int> data, {int address = 0})
      : _segments = [] {
    addAll(address, data);
  }

  /// Adds the data contained in [data] to the container at [startAddress].
  /// Contents will be truncated to (0, 255).
  /// If there was data at any of the address in the range then the old data will be overwritten.
  void addAll(int startAddress, Iterable<int> data) {
    var newSegment = MemorySegment.fromBytes(address: startAddress, data: data);
    addSegment(newSegment);
  }

  /// Adds the [segment] to the container and overwrites data that was stored previously at the
  /// same addresses.
  ///
  /// Also sorts the segments, merges overlapping segments and the remove the duplicates.
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
    sortSegments();
    mergeSegments();
  }

  /// Merges all overlapping segments. If addresses are duplicated, then the values of the
  /// segments starting at lower addresses are retained.
  void mergeSegments() {
    for (int i = 0; i < _segments.length; ++i) {
      for (int k = i + 1; k < _segments.length; ++k) {
        if (_segments[k].overlaps(_segments[i])) {
          _segments[k].combine(_segments[i]);
          _segments[i].isOverlapping = true;
        }
      }
    }
    _segments.removeWhere((item) => item.isOverlapping);
  }

  /// Sorts the segments, so that they are ordered with increasing addresses.
  void sortSegments() {
    _segments.sort((a, b) => a.address.compareTo(b.address));
  }

  /// Returns the max address of a segment in the container.
  int get maxAddress => segments.fold(
      0,
      (int previousValue, MemorySegment element) =>
          max(previousValue, element.endAddress));

  /// Prints the list of segments and their address ranges as json array.
  @override
  String toString() {
    String rv = '"segments": [ ';
    for (var element in _segments) {
      rv += '{"start": ${element.address},"end": ${element.endAddress}},';
    }
    return '${rv.substring(0, rv.length - 1)}]';
  }

  /// Validates that all segments have unique address and are not overlapping.
  bool validateSegmentsAreUnique() {
    for (int i = 0; i < _segments.length; ++i) {
      for (int k = i + 1; k < _segments.length; ++k) {
        if (_segments[i].overlaps(_segments[k])) {
          return false;
        }
      }
    }
    return true;
  }
}
