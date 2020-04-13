module introspection.manifestConstant;

import std.traits;
import std.conv;

import introspection.type;
import introspection.location;
import introspection.protection;

version(unittest) {
  import fluent.asserts;
}

/// Stores information about manifest constants
struct ManifestConstant {
  /// The constant name
  string name;

  ///
  string value;

  ///
  Type type;

  ///
  Protection protection;

  ///
  Location location;
}

/// Describe a manifest constant defined in aggregate types
ManifestConstant describeManifestConstant(T, string member)() {
  ManifestConstant manifestConstant;

  manifestConstant.name = member;
  manifestConstant.value = __traits(getMember, T, member).to!string;
  manifestConstant.type = describeType!(__traits(getMember, T, member));

  auto location = __traits(getLocation, T);
  manifestConstant.location = Location(location[0], location[1], location[2]);

  manifestConstant.protection = __traits(getProtection, __traits(getMember, T, member)).toProtection;

  return manifestConstant;
}

/// ditto
ManifestConstant describeManifestConstant(alias T, string member)() {
  ManifestConstant manifestConstant;

  manifestConstant.name = member;
  manifestConstant.value = __traits(getMember, T, member).to!string;
  manifestConstant.type = describeType!(__traits(getMember, T, member));

  auto location = __traits(getLocation, __traits(getMember, T, member));
  manifestConstant.location = Location(location[0], location[1], location[2]);

  manifestConstant.protection = __traits(getProtection, __traits(getMember, T, member)).toProtection;

  return manifestConstant;
}

/// Check if a member is manifest constant
bool isManifestConstant(T, string name)() {
  mixin(`return is(typeof(T.init.` ~ name ~ `)) && !is(typeof(&T.init.` ~ name ~ `));`);
}

/// ditto
bool isManifestConstant(alias T)() {
  return is(typeof(T)) && !is(typeof(&T));
}

/// it should describe a public manifest constant
unittest {
  struct Test {
    enum config = 3;
  }

  auto result = describeManifestConstant!(Test, "config");

  result.name.should.equal("config");
  result.value.should.equal("3");

  result.type.name.should.equal("int");
  result.type.isManifestConstant.should.equal(true);

  result.protection.should.equal(Protection.public_);

  result.location.file.should.equal("source/introspection/manifestConstant.d");
  result.location.line.should.be.greaterThan(0);
  result.location.column.should.equal(3);
}

/// it should describe a private manifest constant
unittest {
  struct Test {
    private enum config = "test";
  }

  auto result = describeManifestConstant!(Test, "config");

  result.name.should.equal("config");
  result.value.should.equal("test");

  result.type.name.should.equal("string");
  result.type.isManifestConstant.should.equal(true);

  result.protection.should.equal(Protection.private_);
}
