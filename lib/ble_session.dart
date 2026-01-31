class BleSession{
  String lastMessage = "";
  final List<void Function(String)> _listeners = [];

  void onDataReceived(List<int> data) {
    lastMessage = String.fromCharCodes(data);

    for (final listener in _listeners) {
      listener(lastMessage);
    }
  }

  void addListener(void Function(String) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(String) listener) {
    _listeners.remove(listener);
  }
}