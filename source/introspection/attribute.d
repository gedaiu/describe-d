module introspection.attribute;

import introspection.type;

/// Stores information about attributes
struct Attribute {
  ///
  string name;

  ///
  Type type;
}

/// Returns the list of attributes associated with T
Attribute[] describeAttributes(alias T)() {
  return describeAttributes!(__traits(getAttributes, T));
}

/// Returns the list of attributes associated with T
Attribute[] describeAttributes(T...)() {
  Attribute[] list;

  static foreach(attr; T) {
    list ~= Attribute(attr.stringof, describeType!(typeof(attr)));
  }

  return list;
}