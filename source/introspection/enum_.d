module introspection.enum_;

import std.traits;
import std.string;

import introspection.type;
import introspection.location;
import introspection.protection;

version(unittest) {
  import fluent.asserts;
}

///
struct EnumMember {
  ///
  string name;

  ///
  string value;
}

/// Stores information about enums
struct Enum {
  ///
  string name;

  ///
  Type type;

  ///
  EnumMember[] members;

  ///
  Location location;

  ///
  Protection protection;
}

////
Enum describeEnum(T)() if(is(T == enum)){
  Enum enum_;

  enum_.name = T.stringof;

  static foreach (i, member; EnumMembers!T) {
    enum_.members ~= EnumMember(__traits(identifier, EnumMembers!T[i]), member.stringof);
  }

  enum_.type = describeType!T;

  auto location = __traits(getLocation, T);

  enum_.location = Location(location[0], location[1], location[2]);
  enum_.protection = __traits(getProtection, T).toProtection;

  return enum_;
}

/// it should describe an enum
unittest {
  enum Type : string {
    a = "A", b = "B", c = "C"
  }

  auto result = describeEnum!(Type);

  result.name.should.equal("Type");

  result.type.name.should.equal("Type");
  result.type.isEnum.should.equal(true);

  result.members.length.should.equal(3);
  result.members[0].name.should.equal("a");
  result.members[0].value.should.equal(`"A"`);

  result.location.file.should.equal("source/introspection/enum_.d");
  result.location.line.should.be.greaterThan(0);
  result.location.column.should.equal(3);

  result.protection.should.equal(Protection.public_);
}