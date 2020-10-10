module introspection.callable;

import introspection.type;
import introspection.parameter;
import introspection.attribute;
import introspection.location;
import introspection.protection;

import std.traits;
import std.typecons;

version(unittest) {
  import fluent.asserts;
}

/// Stores information about callalbles
struct Callable {
  ///
  string name;

  ///
  Type type;

  ///
  Type returns;

  ///
  Parameter[] parameters;

  ///
  Attribute[] attributes;

  ///
  Location location;

  ///
  Protection protection;

  ///
  bool isStatic;

  ///
  size_t overloadIndex;
}

/// Describes a callable
Callable describeCallable(alias T, size_t overloadIndex = 0)() if(isCallable!T) {
  Parameter[] params;
  params.length = arity!T;

  size_t i;
  static foreach (name; ParameterIdentifierTuple!T) {
    params[i].name = name;
    i++;
  }

  i = 0;
  static foreach (P; Parameters!T) {
    params[i].type = describeType!P;
    i++;
  }

  i = 0;
  static foreach (D; ParameterDefaults!T) {
    static if(!is(D == void)) {
      params[i].default_.value = D.stringof;
      params[i].default_.exists = true;
    }
    i++;
  }

  i = 0;
  static foreach (S; ParameterStorageClassTuple!T) {
    static if(S == ParameterStorageClass.scope_) {
      params[i].isScope = true;
    }

    static if(S == ParameterStorageClass.out_) {
      params[i].isOut = true;
    }

    static if(S == ParameterStorageClass.ref_) {
      params[i].isRef = true;
    }

    static if(S == ParameterStorageClass.lazy_) {
      params[i].isLazy = true;
    }

    static if(S == ParameterStorageClass.return_) {
      params[i].isReturn = true;
    }

    i++;
  }

  static if(__traits(compiles, __traits(getLocation, T))) {
    enum location = __traits(getLocation, T);
  }
  else {
    enum location = tuple("unknown", 0, 0);
  }

  enum attributes = describeAttributeList!(__traits(getAttributes, T)) ~ describeAttributeList!(__traits(getFunctionAttributes, T));

  return Callable(
    __traits(identifier, T),
    describeType!(typeof(T)),
    describeType!(ReturnType!T),
    params,
    attributes,
    Location(location[0], location[1], location[2]),
    __traits(getProtection, T).toProtection,
    __traits(isStaticFunction, T),
    overloadIndex
  );
}

/// It should describe a function with no params that returns void
unittest {
  void test() { }

  auto result = describeCallable!test;

  result.name.should.equal("test");
  result.type.name.should.equal("pure nothrow @nogc @safe void()");
  result.returns.name.should.equal("void");
  result.parameters.length.should.equal(0);
  result.location.file.should.equal("source/introspection/callable.d");
  result.location.line.should.be.greaterThan(0);
  result.location.column.should.equal(8);
}

/// It should describe a function with no params that returns ref int
unittest {
  int val = 0;
  ref int test() { return val; }

  auto result = describeCallable!test;

  result.name.should.equal("test");
  result.type.name.should.equal("pure nothrow @nogc ref @safe int()");
  result.returns.name.should.equal("int");
  result.parameters.length.should.equal(0);
}

/// It should describe a function with a parameter without a default value
unittest {
  int val = 0;
  ref int test(string a) { return val; }

  auto result = describeCallable!test;

  result.parameters.length.should.equal(1);
  result.parameters[0].name.should.equal("a");
  result.parameters[0].type.name.should.equal("string");
  result.parameters[0].default_.value.should.equal("");
  result.parameters[0].default_.exists.should.equal(false);
}

/// It should describe a function with a parameter with a default value
unittest {
  int val = 0;
  ref int test(string a = "test") { return val; }

  auto result = describeCallable!test;

  result.parameters.length.should.equal(1);
  result.parameters[0].name.should.equal("a");
  result.parameters[0].type.name.should.equal("string");
  result.parameters[0].default_.value.should.equal(`"test"`);
  result.parameters[0].default_.exists.should.equal(true);

  result.parameters[0].isLazy.should.equal(false);
  result.parameters[0].isScope.should.equal(false);
  result.parameters[0].isOut.should.equal(false);
  result.parameters[0].isRef.should.equal(false);
  result.parameters[0].isReturn.should.equal(false);
}

/// It should describe a function attributes
unittest {
  int attr(int) { return 0; }

  @("attribute1") @attr(1)
  void test() { }

  auto result = describeCallable!test;

  result.attributes.length.should.equal(6);
  result.attributes[0].name.should.equal(`"attribute1"`);
  result.attributes[0].type.name.should.equal(`string`);

  result.attributes[1].name.should.equal("0");
  result.attributes[1].type.name.should.equal(`int`);

  result.attributes[2].name.should.equal(`"pure"`);
  result.attributes[2].type.name.should.equal(`string`);

  result.attributes[3].name.should.equal(`"nothrow"`);
  result.attributes[3].type.name.should.equal(`string`);

  result.attributes[4].name.should.equal(`"@nogc"`);
  result.attributes[4].type.name.should.equal(`string`);

  result.attributes[5].name.should.equal(`"@safe"`);
  result.attributes[5].type.name.should.equal(`string`);
}

/// It should find the parameter storage classes
unittest {
  void test(scope Object, out int, ref int, lazy int, return Object) { }

  auto result = describeCallable!test;

  result.parameters[0].isScope.should.equal(true);
  result.parameters[1].isOut.should.equal(true);
  result.parameters[2].isRef.should.equal(true);
  result.parameters[3].isLazy.should.equal(true);
  result.parameters[4].isReturn.should.equal(true);
}