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

  static foreach(attr; T) {
    static if(isCallable!(attr)) {
      list ~= Attribute(__traits(identifier, attr)), describeType!(typeof(attr));
    } else static if(isType!(attr)) {
      list ~= Attribute(attr.stringof), describeType!(attr);
    } else static if(__traits(compiles, attr.stringof)) {
      list ~= Attribute(attr.stringof, describeType!(typeof(attr)));
    }
  }

  return list;
}