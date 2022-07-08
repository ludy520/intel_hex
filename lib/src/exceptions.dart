// Copyright (C) 2022 by domohuhn
// 
// SPDX-License-Identifier: BSD-3-Clause

class IHexValueError implements Exception {
  String cause;
  IHexValueError(this.cause);

  @override
  String toString(){
    return "IHexValueError: $cause";
  }
}

class IHexRangeError implements Exception {
  String cause;
  IHexRangeError(this.cause);

  @override
  String toString(){
    return "IHexRangeError: $cause";
  }
}
