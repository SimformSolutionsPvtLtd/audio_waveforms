import 'dart:js_interop';

import 'package:web/web.dart';

extension WebConsoleLogger on String {
  void log() => console.log(toJS);

  void info() => console.info(toJS);

  void warn() => console.warn(toJS);

  void error() => console.error(toJS);
}
