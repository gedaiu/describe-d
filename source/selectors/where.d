module selectors.where;

import std.algorithm;
import std.array;
import std.traits;


import introspection.callable;
import introspection.attribute;
import introspection.parameter;

version(unittest) {
  import fluent.asserts;
}

/// Filter callable lists
auto where(Callable[] callables) {
  return WhereCallables(callables);
}

/// Filter callable lists
struct WhereCallables {
  private {
    Callable[] callables;
  }

  this(Callable[] callables) @safe pure nothrow {
    this.callables = callables;
  }

  Callable[] anyOfAttributes(string[] attributes) @safe pure nothrow {
    Callable[] result;

    foreach (Callable callable; callables) {
      auto callableAttributes = callable.attributes.map!"a.name".array;

      if(!attributes.filter!(a => callableAttributes.canFind(a)).empty) {
        result ~= callable;
      }
    }

    return result;
  }
}

/// Filter callables by attributes
unittest {
  @("test")
  void test() { }

  enum item = describeCallable!test;
  enum items = [ item ];

  items.where.anyOfAttributes(["other"]).length.should.equal(0);
  items.where.anyOfAttributes(["other", "attributes"]).length.should.equal(0);
  items.where.anyOfAttributes(["test"]).length.should.equal(1);
}
