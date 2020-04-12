module described;

import introspection.type;
import introspection.callable;
import introspection.aggregate;

import std.traits;

version(unittest) {
  import fluent.asserts;
}

/// Describe a build in type
Type describe(T)() if(isBuiltinType!T) {
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

/// Describe a build in type
Aggregate describe(T)() if(isAggregateType!T) {
  return describeAggregate!T;
}

/// It should describe a class
unittest {
  class C3 { }

  auto result = describe!C3;

  result.name.should.equal("C3");
}

/// Get a symbol from the type definition
template fromType(alias type){
  mixin(`import ` ~ type.module_ ~ ` : ` ~ type.name ~ `;`);
  mixin(`alias fromType = ` ~ type.fullyQualifiedName ~ `;`);
}

version(unittest) class RandomClass { }

/// It should describe a class by type
unittest {
  alias T = fromType!(describe!RandomClass.type);

  static assert(is(T == RandomClass));
}