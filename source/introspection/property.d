module introspection.property;

import introspection.type;
import introspection.protection;
import introspection.attribute;

import std.traits;

/// Stores information about properties

struct Property {
  ///
  string name;

  ///
  Type type;

  ///
  Protection protection;

  ///
  Attribute[] attributes;

  ///
  bool isStatic;
}

/// Describe a property
Property describeProperty(T, string member)() {
  alias M = __traits(getMember, T, member);

  auto property = Property(member, describeType!(typeof(M)), __traits(getProtection, M).toProtection);
  property.attributes = describeAttributes!(__traits(getAttributes, M));
  property.isStatic = hasStaticMember!(T, member);

  return property;
}

/// Describe a property
Property describeProperty(alias T)() {
  auto property = Property(T.stringof, describeType!(typeof(T)), __traits(getProtection, T).toProtection);
  property.attributes = describeAttributes!(__traits(getAttributes, T));
  /// property.isStatic = hasStaticMember!(T, member);

  return property;
}
