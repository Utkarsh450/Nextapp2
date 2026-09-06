import 'dart:convert';
import 'dart:typed_data';

final Map<String, Uint8List> _dataUriBytesCache = {};

/// Decodes a `data:<mime>;base64,<payload>` URI's payload, memoized by the
/// full URI string.
///
/// `Uint8List` doesn't override `==` (list equality is reference-based), so
/// a fresh `base64Decode` call every widget rebuild hands `Image.memory`/
/// `MemoryImage` a "new" image each time even when the underlying photo
/// hasn't changed — `MemoryImage`'s own equality is bytes-based, so
/// Flutter's image cache never gets a hit, and it fully re-decodes and
/// re-uploads the bitmap to the GPU on every single rebuild instead of
/// reusing what it already decoded. Reusing the same [Uint8List] instance
/// for a given URI restores that cache hit.
Uint8List decodeDataUriBytes(String dataUri) {
  return _dataUriBytesCache.putIfAbsent(
    dataUri,
    () => base64Decode(dataUri.split(',').last),
  );
}
