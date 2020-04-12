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
  Attribute[] list;

  static foreach(attr; __traits(getAttributes, T)) {
    list ~= Attribute(attr.stringof, describeType!(typeof(attr)));
  }

  return list;
}