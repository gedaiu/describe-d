module described;

import introspection.type;
import introspection.callable;

import std.traits;

version(unittest) {
  import fluent.asserts;
}

/// Describe a build in type
Type describe(T)() if(isBuiltInType!T) {
  return describeType!T;
}

/// It should describe an int
unittest {
  enum result = describeType!int;
  result.name.should.equal("int");
}

/// Describe a build in type
Callable describe(alias T)() if(isCallable!T) {
  return describeCallable!T;
}

/// It should describe a function
unittest {
  void test() { }

  enum result = describe!test;

  result.name.should.equal("test");
  result.type.name.should.equal("pure nothrow @nogc @safe void()");
}