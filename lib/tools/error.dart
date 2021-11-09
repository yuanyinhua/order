class MError extends Error {
  int? code;
  String? message;
  
  MError([this.code, this.message]);

  @override
  String toString() {
    if (message != null) {
      if (message is String) {
        return message ?? "";
      }
      return Error.safeToString(message);
    }
    return "";
  }
}