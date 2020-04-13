module selectors.where;

import std.algorithm;
import std.array;

version(unittest) {
  import fluent.asserts;
}

///
struct Where(T : U[], U) {
  private U[] list;

  ///
  this(U[] list) {
    this.list = list;
  }

  /// Filter by attribute name
  auto attribute(string name)() {
    list = list.filter!(a => !a.attributes.filter!(a => a.name == name).empty).array;

    return this;
  }

  /// Filter by type name
  auto typeIs(string name)() {
    list = list.filter!(a => a.type.name == name || a.type.fullyQualifiedName == name).array;

    return this;
  }

  /// Filter by type name
  auto typeIsAnyOf(T...)() {
    enum string[] names = [ T ];

    list = list.filter!(a =>
      !names.filter!(name => a.type.name == name || a.type.fullyQualifiedName == name).empty)
        .array;

    return this;
  }

  /// Filter by type name
  auto typeIsNot(string name)() {
    list = list.filter!(a => a.type.name != name && a.type.fullyQualifiedName != name).array;

    return this;
  }

  /// Check if the filtered list has at least one value
  bool exists() {
    return list.length > 0;
  }

  /// Iterate over the filtered items
  int opApply(scope int delegate(ref U) dg) {
    int result = 0;

    foreach(item; list) {
      result = dg(item);

      if (result)
        break;
    }
    return result;
  }

  /// Iterate over the filtered items
  int opApply(scope int delegate(size_t index, ref U) dg) {
    int result = 0;

    foreach(index, item; list) {
      result = dg(index, item);

      if (result)
        break;
    }
    return result;
  }
}

/// Filter callables by attribute name
unittest {
  import introspection.callable;
  import introspection.attribute;

  @("test")
  void test() { }

  enum item = describeCallable!test;
  enum items = [ item ];

  enum hasAttribute = items.where.attribute!`"test"`.exists;

  hasAttribute.should.equal(true);
  items.where.attribute!"other".exists.should.equal(false);
}

version(unittest) { struct TestStructure { } }

/// Filter callables by type name
unittest {
  import introspection.aggregate;

  enum item = describeAggregate!TestStructure;
  enum items = [ item ];

  items.where.typeIs!"TestStructure".exists.should.equal(true);
  items.where.typeIs!"selectors.where.TestStructure".exists.should.equal(true);
  items.where.typeIs!"selectors.where.OtherStructure".exists.should.equal(false);

  items.where.typeIsAnyOf!("TestStructure").exists.should.equal(true);
  items.where.typeIsAnyOf!("selectors.where.TestStructure").exists.should.equal(true);
  items.where.typeIsAnyOf!("selectors.where.OtherStructure").exists.should.equal(false);

  items.where.typeIsNot!"TestStructure".exists.should.equal(false);
  items.where.typeIsNot!"selectors.where.TestStructure".exists.should.equal(false);
  items.where.typeIsNot!"selectors.where.OtherStructure".exists.should.equal(true);
}

/// Can iterate over filtered values
unittest {
  import introspection.callable;

  @("test")
  void foo() { }

  enum item = describeCallable!foo;
  enum items = [ item ];

  /// iterate without index
  size_t index;
  static foreach(element; items.where.attribute!`"test"`) {
    index.should.equal(0);
    element.name.should.equal("foo");
    index++;
  }

  index = 0;
  foreach(_; items.where.attribute!`"other"`) {
    index++;
  }
  index.should.equal(0);

  /// iterate with index
  foreach(i, element; items.where.attribute!`"test"`) {
    i.should.equal(0);
    element.name.should.equal("foo");
  }
}

/// query the introspection result
auto where(T)(T list) {
  return Where!T(list);
}