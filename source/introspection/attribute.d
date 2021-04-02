module introspection.attribute;

import std.traits;
import introspection.type;

/// Stores information about attributes
struct Attribute {
  ///
  string name;

  ///
  Type type;
}

/// Returns the list of attributes associated with T
Attribute[] describeAttributes(alias T)() if(is(typeof(T)) && !is(typeof(T) == string)) {
  return describeAttributeList!(__traits(getAttributes, T));
}

/// Returns the list of attributes associated with T
Attribute[] describeAttributeList(T...)() {
  Attribute[] list;
  string name;
  Type type;

  static foreach(attr; T) {
    static if(isCallable!(attr)) {
      name = __traits(identifier, attr);
      type = describeType!(typeof(attr));
    } else static if(isType!(attr)) {
      name = attr.stringof;
      type = describeType!(attr);
    } else static if(__traits(compiles, attr.stringof)) {
      name = attr.stringof;
      type = describeType!(typeof(attr));
    }

    if(name.length > 0 && name[0] == '"' && name[name.length - 1] == '"') {
      name = name[1..$-1];
    }

    list ~= Attribute(name, type);
  }

  return list;
}