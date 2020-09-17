import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

void notify(String message, {bool error = false}) {
  showToast(
    message,
    dismissOtherToast: true,
    backgroundColor: error ? Colors.redAccent : Colors.white,
    textStyle:
        TextStyle(color: error ? Colors.white : Colors.black, fontSize: 12),
    radius: 5,
    textPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
    position: ToastPosition.bottom,
  );
}

void notifyError(String message) {
  notify(message, error: true);
}
