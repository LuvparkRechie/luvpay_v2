void longPrint(String text) {
  const int chunkSize = 800;
  for (var i = 0; i < text.length; i += chunkSize) {
    print(
      text.substring(
        i,
        i + chunkSize > text.length ? text.length : i + chunkSize,
      ),
    );
  }
}
