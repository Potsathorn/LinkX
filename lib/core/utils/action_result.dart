import 'package:flutter/foundation.dart';

@immutable
class ActionResult {
  const ActionResult._(this.success, this.message, {this.silent = false});
  const ActionResult.ok(String message) : this._(true, message);
  const ActionResult.error(String message) : this._(false, message);
  const ActionResult.none() : this._(true, '', silent: true);
  final bool success;
  final String message;
  final bool silent;

  bool get shouldNotify => !silent && message.isNotEmpty;
}
