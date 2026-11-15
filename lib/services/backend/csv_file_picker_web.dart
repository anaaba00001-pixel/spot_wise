import 'dart:async';
import 'dart:js_interop';

const canPickCsvFile = true;

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Input createElement(String tag);
}

extension type _Input(JSObject _) implements JSObject {
  external set type(String value);
  external set accept(String value);
  external _Files? get files;
  external void addEventListener(String event, JSFunction listener);
  external void click();
}

extension type _Files(JSObject _) implements JSObject {
  external _File? item(int index);
}

extension type _File(JSObject _) implements JSObject {
  external int get size;
  external JSPromise<JSString> text();
}

Future<String?> pickCsvFile() async {
  final selected = Completer<_File?>();
  final input = _document.createElement('input')
    ..type = 'file'
    ..accept = '.csv,text/csv';
  input.addEventListener(
    'change',
    ((JSObject _) {
      if (!selected.isCompleted) selected.complete(input.files?.item(0));
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((JSObject _) {
      if (!selected.isCompleted) selected.complete(null);
    }).toJS,
  );
  input.click();
  final file = await selected.future;
  if (file == null) return null;
  if (file.size > 1000000) throw const FormatException('الملف كبير جدًا.');
  return (await file.text().toDart).toDart;
}
