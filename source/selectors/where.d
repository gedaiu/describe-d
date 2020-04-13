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

  /// Filter by attribute value
  auto attribute(string value)() {
    list = list.filter!(a => !a.attributes.filter!(a => a.name == value).empty).array;

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