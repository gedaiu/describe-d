module introspection.module_;

import std.traits;
import std.conv;

import introspection.type;
import introspection.callable;
import introspection.aggregate;
import introspection.template_;
import introspection.location;
import introspection.protection;
import introspection.property;
import introspection.unittest_;
import introspection.manifestConstant;

version(unittest) {
  import fluent.asserts;
}

/// Stores information about modules
struct Module {
  /// The constant name
  string name;

  ///
  string fullyQualifiedName;

  ///
  Callable[] functions;

  ///
  Aggregate[] aggregates;

  ///
  Template[] templates;

  ///
  Property[] globals;

  ///
  ManifestConstant[] manifestConstants;

  ///
  UnitTest[] unitTests;

  ///
  Location location;
}

/// Describe a module and containing members
Module describeModule(alias T, bool withUnitTests = false)() if(__traits(isModule, T)) {
  Module module_;

  module_.name = T.stringof;
  module_.fullyQualifiedName = fullyQualifiedName!T;
  Location location;

  static foreach(member; __traits(allMembers, T)) static if(member.stringof != `"object"` && __traits(compiles, __traits(getMember, T, member))) {{
    alias M = __traits(getMember, T, member);

    static if(__traits(compiles, __traits(getLocation, M))) {
      if(module_.location.file == "") {
        module_.location.file = __traits(getLocation, M)[0];
      }
    }

    static if(isCallable!M) {
      static foreach(index, overload; __traits(getOverloads, T, member)) {
        module_.functions ~= describeCallable!(overload, index);
      }
    }
    else static if(__traits(isTemplate, M)) {
      module_.templates ~= describeTemplate!M;
    }
    else static if(isTypeTuple!M && isAggregateType!M) {
      module_.aggregates ~= describeAggregate!M;
    }
    else static if(isManifestConstant!M) {
      module_.manifestConstants ~= describeManifestConstant!(T, member);
    }
    else static if(__traits(compiles, describeProperty!M)) {
      module_.globals ~= describeProperty!M;
    }
  }}

  static if(withUnitTests) {
    module_.unitTests = describeUnitTests!T;
  }

  return module_;
}

/// It should describe a module with all functions, aggregates, templates, and global vars
unittest {
  import introspection.test.moduleDef;

  auto result = describeModule!(introspection.test.moduleDef, true);

  result.name.should.equal("module moduleDef");
  result.fullyQualifiedName.should.equal("introspection.test.moduleDef");

  /// check functions
  result.functions.length.should.equal(2);
  result.functions[0].name.should.equal("testFunction");
  result.functions[1].name.should.equal("privateFunction");

  /// check aggregates
  result.aggregates.length.should.equal(4);
  result.aggregates[0].name.should.equal("TestStructure");
  result.aggregates[1].name.should.equal("TestClass");
  result.aggregates[2].name.should.equal("TestInterface");
  result.aggregates[3].name.should.equal("TestUnion");

  /// check templates
  result.templates.length.should.equal(2);
  result.templates[0].name.should.equal("TestTpl");
  result.templates[1].name.should.equal("templatedFunction");

  /// check globals
  result.globals.length.should.equal(1);
  result.globals[0].name.should.equal("globalVar");

  /// check manifest constants
  result.manifestConstants.length.should.equal(1);
  result.manifestConstants[0].name.should.equal("someManifestConstant");

  /// check unittests
  result.unitTests.length.should.equal(2);

  ///
  result.location.file.should.equal("source/introspection/test/moduleDef.d");
  result.location.line.should.equal(0);
  result.location.column.should.equal(0);
}

/// It should be able to describe the std.array module
unittest {
  import std.array;

  auto result = describeModule!(std.array);

  result.name.should.equal("module array");
  result.fullyQualifiedName.should.equal("std.array");

  result.functions.length.should.equal(1);
  result.functions[0].name.should.equal("_d_newarrayU");

  result.templates.length.should.equal(31);
}

/// It should be able to describe the std.stdio module
unittest {
  auto result = describeModule!(std.stdio);

  result.name.should.equal("module stdio");
  result.fullyQualifiedName.should.equal("std.stdio");

  result.functions.length.should.equal(22);
  result.functions[0].name.should.equal("flockfile");

  result.templates.length.should.equal(15);
}
