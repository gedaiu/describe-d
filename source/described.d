module described;

import introspection.type;
import introspection.callable;
import introspection.aggregate;
import introspection.module_;
import introspection.enum_;

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
Module describe(alias T)() if(__traits(isModule, T)) {
  return describeModule!T;
}

/// It should describe a function
unittest {
  void test() { }

  enum result = describe!(introspection.template_);

  result.name.should.equal("module template_");
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

/// Describe an enum
auto describe(alias T)() if(is(T == enum)) {
  return describeEnum!T;
}

/// It should describe an enum
unittest {
  enum Something { A, B }

  auto result = describe!Something;

  result.name.should.equal("Something");
}

/// Get a symbol from the type definition
template fromType(alias type){
  mixin(`import ` ~ type.module_ ~ ` : ` ~ type.name ~ `;`);
  mixin(`alias fromType = ` ~ type.fullyQualifiedName ~ `;`);
}

version(unittest) class RandomClass { }

/// It should get the symbol from the type definition
unittest {
  alias T = fromType!(describe!RandomClass.type);

  static assert(is(T == RandomClass));
}

/// Describe a type
Aggregate describe(Type type)() if(type.isClass || type.isStruct || type.isUnion || type.isInterface) {
  return describe!(fromType!type);
}

/// It should describe a class by type
unittest {
  enum result = describe!(describe!RandomClass.type);

  result.name.should.equal("RandomClass");
}
