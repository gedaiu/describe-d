module selectors.where;

import std.algorithm;
import std.array;
import std.traits;
import std.string;

version(unittest) {
  import fluent.asserts;
}

///
struct WhereArrayString(T : U[], string path1, string indexName, string path2, U) {
  private {
    U[] list;
    bool negation;
  }

  private template Item(A : B[], B) {
    alias Item = B;
  }

  mixin(`alias ListType = typeof(U.` ~ path1 ~ `);`);

  mixin(`alias M = typeof(Item!(ListType).init.` ~ path2 ~ `);`);

  ///
  this(U[] list) {
    this.list = list;
  }

  /// Does nothing but improve code readability
  auto and() {
    return this;
  }

  /// Negates the next filter
  auto not() {
    negation = !negation;
    return this;
  }

  /// Check equality
  auto equal(M value) {
    U[] newList = [];

    alias TmpWhere = WhereString!(ListType, path2);

    foreach(item; list) {
      mixin(`auto subList = item.` ~ path1 ~ `;`);

      auto localWhere = TmpWhere(subList);
      localWhere.negation = negation;

      if(localWhere.equal(value).exists) {
        newList ~= item;
      }
    }

    list = newList;

    return this;
  }

  /// Returns all items that match at least one value
  auto isAnyOf(M[] values) {
    U[] newList = [];

    alias TmpWhere = WhereString!(ListType, path2);

    foreach(item; list) {
      mixin(`auto subList = item.` ~ path1 ~ `;`);

      auto localWhere = TmpWhere(subList);
      localWhere.negation = negation;

      if(localWhere.isAnyOf(values).exists) {
        newList ~= item;
      }
    }

    list = newList;

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

///
struct WhereString(T : U[], string path, U) {
  private {
    U[] list;
    bool negation;
  }

  mixin(`alias M = typeof(U.` ~ path ~ `);`);

  ///
  this(U[] list) {
    this.list = list;
  }

  /// Does nothing but improve code readability
  auto and() {
    return this;
  }

  /// Negates the next filter
  auto not() {
    negation = !negation;
    return this;
  }

  /// Check equality
  auto equal(M value) {
    U[] newList = [];

    foreach(item; list) {
      mixin(`M itemValue = item.` ~ path ~ `;`);

      if(!negation && itemValue == value) {
        newList ~= item;
      }

      if(negation && itemValue != value) {
        newList ~= item;
      }
    }

    list = newList;

    return this;
  }

  /// Returns all items that match at least one value
  auto isAnyOf(M[] values) {
    U[] newList = [];

    foreach(item; list) {
      mixin(`M itemValue = item.` ~ path ~ `;`);

      if(!negation && values.canFind(itemValue)) {
        newList ~= item;
      }

      if(negation && !values.canFind(itemValue)) {
        newList ~= item;
      }
    }

    list = newList;

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

  enum hasAttribute = items.where!"attributes[i].name".equal(`"test"`).exists;

  hasAttribute.should.equal(true);

  items.where!"attributes[i].name".equal("other").exists.should.equal(false);

  items.where!"attributes[i].name".isAnyOf([`"test"`, `"other test"`]).exists.should.equal(true);
  items.where!"attributes[i].name".not.isAnyOf([`"test"`]).exists.should.equal(false);
}

version(unittest) { struct TestStructure { } }

/// Filter callables by type name
unittest {
  import introspection.aggregate;

  enum item = describeAggregate!TestStructure;
  enum items = [ item ];

  items.where!"type.name".equal("TestStructure").and.exists.should.equal(true);
  items.where!"type.fullyQualifiedName".equal("selectors.where.TestStructure").and.exists.should.equal(true);
  items.where!"type.fullyQualifiedName".equal("selectors.where.OtherStructure").and.exists.should.equal(false);

  items.where!"type.name".isAnyOf(["TestStructure"]).and.exists.should.equal(true);
  items.where!"type.fullyQualifiedName".isAnyOf(["selectors.where.TestStructure"]).and.exists.should.equal(true);
  items.where!"type.fullyQualifiedName".isAnyOf(["selectors.where.OtherStructure"]).and.exists.should.equal(false);

  items.where!"type.name".not.equal("TestStructure").and.exists.should.equal(false);
  items.where!"type.fullyQualifiedName".not.equal("selectors.where.TestStructure").and.exists.should.equal(false);
  items.where!"type.fullyQualifiedName".not.equal("selectors.where.OtherStructure").and.exists.should.equal(true);

  items.where!"type.name".not.isAnyOf(["TestStructure"]).and.exists.should.equal(false);
  items.where!"type.fullyQualifiedName".not.isAnyOf(["selectors.where.TestStructure"]).and.exists.should.equal(false);
  items.where!"type.fullyQualifiedName".not.isAnyOf(["selectors.where.OtherStructure"]).and.exists.should.equal(true);
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
  foreach(element; items.where!"attributes[i].name".equal(`"test"`)) {
    index.should.equal(0);
    element.name.should.equal("foo");
    index++;
  }

  index = 0;
  foreach(_; items.where!"attributes[i].name".equal(`"other"`)) {
    index++;
  }
  index.should.equal(0);

  /// iterate with index
  foreach(i, element; items.where!"attributes[i].name".equal(`"test"`)) {
    i.should.equal(0);
    element.name.should.equal("foo");
  }
}

/// query the introspection result
auto where(string path, T : U[], U)(T list) {
  static if(path.canFind("[")) {
    enum index1 = path.indexOf('[');
    enum index2 = path.indexOf(']');

    return WhereArrayString!(T, path[0..index1], path[index1+1..index2], path[index2+2..$], )(list);
  } else {
    return WhereString!(T, path)(list);
  }
}