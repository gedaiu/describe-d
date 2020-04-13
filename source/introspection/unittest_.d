module introspection.unittest_;

import introspection.type;
import introspection.attribute;
import introspection.location;

version(unittest) {
  import fluent.asserts;
}

alias TestFunction = void function();

/// Structure representing an unittest
struct UnitTest {
  ///
  TestFunction testFunction;

  ///
  Type type;

  ///
  Attribute[] attributes;

  ///
  Location location;
}

///
UnitTest describeUnitTest(alias T)() {
  UnitTest test;

  test.testFunction = &T;

  test.type = describeType!(typeof(T));

  test.attributes = describeAttributeList!(__traits(getAttributes, T));

  auto location = __traits(getLocation, T);
  test.location = Location(location[0], location[1], location[2]);

  return test;
}

///
UnitTest[] describeUnitTests(alias T)() {
  UnitTest[] tests;

  static foreach(test; __traits(getUnitTests, T)) {
    tests ~= describeUnitTest!test;
  }

  return tests;
}

/// it should describe this unittest
@("some attribute")
unittest {
  auto result = describeUnitTests!(introspection.unittest_);

  result.length.should.equal(1);

  result[0].type.name.should.equal("void()");

  result[0].attributes.length.should.equal(1);
  result[0].attributes[0].name.should.equal(`"some attribute"`);

  result[0].location.file.should.equal("source/introspection/unittest_.d");
  result[0].location.line.should.be.greaterThan(0);
  result[0].location.column.should.equal(1);
}