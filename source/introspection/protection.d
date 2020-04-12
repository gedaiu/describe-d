module introspection.protection;


version(unittest) {
  import fluent.asserts;
}

///
enum Protection {
  unknown_, public_, protected_, private_, export_
}

///
Protection toProtection(string value) {
  if(value == "public") {
    return Protection.public_;
  }

  if(value == "protected") {
    return Protection.protected_;
  }

  if(value == "private") {
    return Protection.private_;
  }

  if(value == "export") {
    return Protection.export_;
  }

  return Protection.unknown_;
}