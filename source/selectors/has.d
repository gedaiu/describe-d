module selectors.has;

import std.algorithm;
import std.array;
import std.traits;


import introspection.callable;
import introspection.attribute;
import introspection.parameter;

version(unittest) {
  import fluent.asserts;
}

/// Callables checks
struct HasCallable {
  private {
    Callable callable;
  }

  this(Callable callable) @safe pure nothrow {
    this.callable = callable;
  }

  bool anyParameterOfType(string typeName) @safe pure nothrow {
    foreach (Parameter parameter; callable.parameters) {
      if(parameter.type.name == typeName || parameter.type.fullyQualifiedName == typeName) {
        return true;
      }
    }

    return false;
  }
}

/// Callables checks
HasCallable has(Callable callable) @safe pure nothrow {
  return HasCallable(callable);
}


/// Checks if it has an attribute of type
unittest {
  @("test")
  void test(string, int) { }

  enum item = describeCallable!test;

  item.has.anyParameterOfType("other").should.equal(false);
  item.has.anyParameterOfType("string").should.equal(true);
  item.has.anyParameterOfType("int").should.equal(true);
}


