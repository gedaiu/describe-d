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
  Location location;
}

/// Describe a module and containing members
Module describeModule(alias T)() if(__traits(isModule, T)) {
  Module module_;

  module_.name = T.stringof;
  module_.fullyQualifiedName = fullyQualifiedName!T;
  Location location;

  static foreach(member; __traits(allMembers, T)) static if(member.stringof != `"object"`) {{
    alias M = __traits(getMember, T, member);

    static if(__traits(compiles, __traits(getLocation, M))) {
      if(module_.location.file == "") {
        module_.location.file = __traits(getLocation, M)[0];
      }
    }

    static if(isCallable!M) {
      module_.functions ~= describeCallable!M;
    }
    else static if(__traits(isTemplate, M)) {
      module_.templates ~= describeTemplate!M;
    }
    else static if(!isExpressions!M && isAggregateType!M) {
      module_.aggregates ~= describeAggregate!M;
    } else {
      module_.globals ~= describeProperty!M;
    }
  }}

  return module_;
}

/// It should describe a module with all functions, aggregates, templates, and global vars
unittest {
  import introspection.test.moduleDef;

  auto result = describeModule!(introspection.test.moduleDef);

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

  result.location.file.should.equal("source/introspection/test/moduleDef.d");
  result.location.line.should.equal(0);
  result.location.column.should.equal(0);
}