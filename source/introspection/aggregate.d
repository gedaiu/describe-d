module introspection.aggregate;

import std.traits;
import introspection.type;
import introspection.location;
import introspection.attribute;
import introspection.protection;
import introspection.callable;
import introspection.enum_;
import introspection.manifestConstant;
import introspection.template_;
import introspection.protection;
import introspection.property;
import introspection.unittest_;

version(unittest) {
  import fluent.asserts;
  import std.algorithm;
  import std.array;
}

/// Stores information about attributes
struct Aggregate {
  ///
  string name;

  ///
  Type type;

  ///
  Type[] baseClasses;

  ///
  Type[] interfaces;

  ///
  Type[] nested;

  ///
  Attribute[] attributes;

  ///
  Property[] properties;

  ///
  Callable[] methods;

  ///
  Enum[] enums;

  ///
  ManifestConstant[] manifestConstants;

  ///
  Template[] templates;

  ///
  UnitTest[] unitTests;

  ///
  Location location;

  ///
  Protection protection;
}

/// Describes classes, structs, unions and interfaces
Aggregate describeAggregate(T, bool withUnitTests = false)() if(isAggregateType!T) {
  Aggregate aggregate;

  aggregate.name = Unqual!T.stringof;
  aggregate.type = describeType!T;

  static if(is(T == class)) {
    static foreach (B; BaseClassesTuple!T) {
      aggregate.baseClasses ~= describeType!B;
    }

    static foreach (I; InterfacesTuple!T) {
      aggregate.interfaces ~= describeType!I;
    }
  }

  aggregate.attributes = describeAttributeList!(__traits(getAttributes, T));

  static foreach(member; __traits(allMembers, T)) static if(member != "this" && member != "Monitor") {{
    alias M = __traits(getMember, T, member);

    static if(isCallable!M) {
      static foreach(index, overload; __traits(getOverloads, T, member)) {{
        aggregate.methods ~= describeCallable!(overload, index);
      }}
    }
    else static if(isManifestConstant!(T, member)) {
      aggregate.manifestConstants ~= describeManifestConstant!(T, member);
    }
    else static if(is(M == enum)) {
      aggregate.enums ~= describeEnum!M;
    }
    else static if(is(M == class) || is(M == struct) || is(M == interface) || is(M == union)) {
      aggregate.nested ~= describeType!M;
    }
    else static if(__traits(isTemplate, M)) {
      aggregate.templates ~= describeTemplate!M;
    }
    else {
      aggregate.properties ~= describeProperty!(T, member);
    }
  }}

  auto location = __traits(getLocation, T);
  aggregate.location = Location(location[0], location[1], location[2]);

  aggregate.protection = __traits(getProtection, T).toProtection;

  static if(withUnitTests) {
    aggregate.unitTests = describeUnitTests!T;
  }

  return aggregate;
}

/// It should describe a class with interfaces and base classes
unittest {
  interface I1 { }
  interface I2 { }

  class C1 { }
  class C2 : C1, I1 { }
  class C3 : C2, I2 { }

  auto result = describeAggregate!C3;

  result.name.should.equal("C3");

  result.baseClasses.length.should.equal(3);
  result.baseClasses[0].name.should.equal("C2");
  result.baseClasses[1].name.should.equal("C1");
  result.baseClasses[2].name.should.equal("Object");

  result.interfaces.length.should.equal(2);
  result.interfaces[0].name.should.equal("I1");
  result.interfaces[1].name.should.equal("I2");

  result.location.file.should.equal("source/introspection/aggregate.d");
  result.location.line.should.be.greaterThan(0);
  result.location.column.should.equal(3);

  result.protection = Protection.public_;
}

/// It should describe struct attributes
unittest {
  int attr(int) { return 0; }

  @("attribute1") @attr(1)
  struct Test { }

  auto result = describeAggregate!Test;

  result.name.should.equal("Test");
  result.attributes.length.should.equal(2);

  result.attributes[0].name.should.equal(`attribute1`);
  result.attributes[0].type.name.should.equal(`string`);

  result.attributes[1].name.should.equal("0");
  result.attributes[1].type.name.should.equal(`int`);
}

/// It should find properties from a struct
unittest {
  struct Test { int a; string b; }

  auto result = describeAggregate!Test;

  result.properties.length.should.equal(2);

  result.properties[0].name.should.equal("a");
  result.properties[0].isStatic.should.equal(false);
  result.properties[0].protection.should.equal(Protection.public_);
  result.properties[0].type.name.should.equal("int");

  result.properties[1].name.should.equal("b");
  result.properties[0].isStatic.should.equal(false);
  result.properties[1].protection.should.equal(Protection.public_);
  result.properties[1].type.name.should.equal("string");
}

/// It should find a static property
unittest {
  struct Test {
    static int a;
    string b;
  }

  auto result = describeAggregate!Test;

  result.properties[0].name.should.equal("a");
  result.properties[0].isStatic.should.equal(true);
  result.properties[1].isStatic.should.equal(false);
}

/// It should find property protection levels
unittest {
  class Test {
    public int a;
    protected int b;
    private int c;
    export int d;
  }

  auto result = describeAggregate!Test;

  result.properties.length.should.equal(4);

  result.properties[0].name.should.equal("a");
  result.properties[0].protection.should.equal(Protection.public_);

  result.properties[1].name.should.equal("b");
  result.properties[1].protection.should.equal(Protection.protected_);

  result.properties[2].name.should.equal("c");
  result.properties[2].protection.should.equal(Protection.private_);

  result.properties[3].name.should.equal("d");
  result.properties[3].protection.should.equal(Protection.export_);
}

/// It should describe struct property attributes
unittest {
  int attr(int) { return 0; }

  struct Test {
    @("attribute1") @attr(1)
    string name;
  }

  auto result = describeAggregate!Test;

  result.name.should.equal("Test");

  result.properties[0].attributes.length.should.equal(2);
  result.properties[0].attributes[0].name.should.equal(`attribute1`);
  result.properties[0].attributes[0].type.name.should.equal(`string`);
}

/// It should find public methods from a struct
unittest {
  struct Test {
    void a() {}
    void b() {}
  }

  auto result = describeAggregate!Test;

  result.methods.length.should.equal(2);

  result.methods[0].name.should.equal("a");
  result.methods[0].isStatic.should.equal(false);
  result.methods[0].protection.should.equal(Protection.public_);
  result.methods[0].type.name.should.equal("@system void()");

  result.methods[1].name.should.equal("b");
  result.methods[1].isStatic.should.equal(false);
  result.methods[1].protection.should.equal(Protection.public_);
  result.methods[1].type.name.should.equal("@system void()");
}

/// It should find all methods from a class
unittest {
  class Test {
    public void a() {}
    protected void b() {}
    private void c() {}
  }

  auto result = describeAggregate!Test;

  result.methods.length.should.equal(8);

  result.methods.map!(a => a.name).array.should.equal(["a", "b", "c", "toString", "toHash", "opCmp", "opEquals", "factory"]);

  result.methods[0].name.should.equal("a");
  result.methods[0].isStatic.should.equal(false);
  result.methods[0].protection.should.equal(Protection.public_);
  result.methods[0].type.name.should.equal("@system void()");

  result.methods[1].name.should.equal("b");
  result.methods[1].isStatic.should.equal(false);
  result.methods[1].protection.should.equal(Protection.protected_);
  result.methods[1].type.name.should.equal("@system void()");

  result.methods[2].name.should.equal("c");
  result.methods[2].isStatic.should.equal(false);
  result.methods[2].protection.should.equal(Protection.private_);
  result.methods[2].type.name.should.equal("@system void()");
}

/// It should find overloaded methods
unittest {
  class Test {
    void a(int) {}
    void a(string) {}
  }

  auto result = describeAggregate!Test;

  result.methods.length.should.equal(7);

  result.methods.map!(a => a.name).array.should.equal(["a", "a", "toString", "toHash", "opCmp", "opEquals", "factory"]);

  result.methods[0].name.should.equal("a");
  result.methods[0].overloadIndex.should.equal(0);
  result.methods[0].isStatic.should.equal(false);
  result.methods[0].protection.should.equal(Protection.public_);
  result.methods[0].type.name.should.equal("void(int)");
  result.methods[0].parameters[0].name.should.equal("_param_0");
  result.methods[0].parameters[0].type.name.should.equal("int");

  result.methods[1].name.should.equal("a");
  result.methods[1].overloadIndex.should.equal(1);
  result.methods[1].isStatic.should.equal(false);
  result.methods[1].protection.should.equal(Protection.public_);
  result.methods[1].type.name.should.equal("void(string)");
  result.methods[1].parameters[0].name.should.equal("_param_0");
  result.methods[1].parameters[0].type.name.should.equal("string");
}

/// It should describe struct method attributes
unittest {
  int attr(int) { return 0; }

  struct Test {
    @("attribute1") @attr(1)
    string name();
  }

  auto result = describeAggregate!Test;

  result.name.should.equal("Test");
  result.methods[0].attributes.length.should.equal(3);
  result.methods[0].attributes[0].name.should.equal(`attribute1`);
  result.methods[0].attributes[0].type.name.should.equal(`string`);
}

/// It should describe a struct @property
unittest {
  int attr(int) { return 0; }

  struct Test {
    @property string name();
  }

  auto result = describeAggregate!Test;

  result.name.should.equal("Test");
  result.methods[0].attributes.length.should.equal(2);
  result.methods[0].attributes[0].name.should.equal(`@property`);
  result.methods[0].attributes[0].type.name.should.equal(`string`);
  result.methods[0].attributes[1].name.should.equal(`@system`);
  result.methods[0].attributes[1].type.name.should.equal(`string`);
}

/// It should describe static struct method
unittest {
  struct Test {
    static string name();
    string name(int);
  }

  auto result = describeAggregate!Test;

  result.name.should.equal("Test");
  result.methods[0].name.should.equal("name");
  result.methods[0].isStatic.should.equal(true);
  result.methods[0].parameters.length.should.equal(0);

  result.methods[1].name.should.equal("name");
  result.methods[1].isStatic.should.equal(false);
  result.methods[1].parameters.length.should.equal(1);
}

/// It should describe enums defined in classes
unittest {
  class Test {
    enum Other : int {
      a, b, c, d
    }
  }

  auto result = describeAggregate!Test;

  result.enums.length.should.equal(1);
  result.enums[0].name.should.equal("Other");
}

/// It should describe a manifest constant
unittest {
  class Test {
    enum constant = 4;
  }

  auto result = describeAggregate!Test;

  result.manifestConstants.length.should.equal(1);
  result.manifestConstants[0].name.should.equal("constant");
}

/// It should describe a struct type defined inside a class
unittest {
  class Test {
    struct Other {}
  }

  auto result = describeAggregate!Test;

  result.nested.length.should.equal(1);
  result.nested[0].name.should.equal("Other");
}

/// It should describe a template defined inside a class
unittest {
  class Test {
    struct Other(T) {}
  }

  auto result = describeAggregate!Test;

  result.nested.length.should.equal(0);

  result.templates.length.should.equal(1);
  result.templates[0].name.should.equal("Other");
}

/// It should describe an instantiated template
unittest {
  class Test(T) {
    T bar(T val) { return val; }
  }

  alias TestInstantiated = Test!string;

  auto result = describeAggregate!TestInstantiated;

  result.name.should.equal("Test!string");
  result.nested.length.should.equal(0);
  result.templates.length.should.equal(0);

  result.methods.length.should.equal(6);
  result.methods[0].name.should.equal("bar");
  result.methods[0].returns.name.should.equal("string");
}

/// It should describe unittests defined in a struct
unittest {
  struct Test { unittest { } }

  auto result = describeAggregate!(Test, true);
  result.unitTests.length.should.equal(1);
}

/// It should describe attributes that return structs
unittest {
  struct Mapper { }
  Mapper mapper() {
    return Mapper();
  }

  class MockClass {
    @mapper @Mapper @("mapper")
    void mapper() @trusted nothrow { }
  }

  enum result = describeAggregate!(MockClass, true);
  result.methods[0].attributes.length.should.equal(5);
  result.methods[0].attributes[0].name.should.equal("mapper");
  result.methods[0].attributes[0].type.name.should.equal("nothrow @trusted void()");
  result.methods[0].attributes[1].name.should.equal("Mapper");
  result.methods[0].attributes[2].name.should.equal(`mapper`);
}