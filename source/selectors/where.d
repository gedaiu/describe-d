module selectors.where;

import std.algorithm;
import std.array;
import std.traits;

version(unittest) {
  import fluent.asserts;
}

///
struct WhereAnyProxy(T: U[], U) {
  private {
    U[] list;
  }

  alias M = U.M;
  alias RootType = U.RootType;

  this(T list) {
    this.list = list;
  }

  ///
  auto dispatch(string name, P...)() {
    mixin(`alias R = ReturnType!(U.` ~ name ~ `);`);

    R[] result;

    foreach(localWhere; list) {
      mixin(`result ~= localWhere.` ~ name ~ `();`);
    }

    return whereAnyProxy(result);
  }

  static if(isAggregateType!M) {
    static foreach(member; __traits(allMembers, M)) {
      static if(!std.traits.isArray!(typeof(__traits(getMember, M, member))) || isSomeString!(typeof(__traits(getMember, M, member))) ) {
        mixin(`
          auto ` ~ member ~ `(P...)() {
            return dispatch!("` ~ member ~ `", P)();
          }
        `);
      }
    }
  }


  /// Does nothing but improve code readability
  auto and() {

    foreach(localWhere; list) {
      localWhere.and;
    }

    return this;
  }

  /// Negates the next filter
  auto not() {

    foreach(localWhere; list) {
      localWhere.not;
    }

    return this;
  }

  /// Check equality
  auto equal(M value)() {

    foreach(index, localWhere; list) {
      list[index].equal!value;
    }

    return this;
  }

  /// Returns all items that match at least one value
  auto isAnyOf(T...)() {
    foreach(localWhere; list) {
      localWhere.isAnyOf!T;
    }

    return this;
  }

  /// Check if the filtered list has at least one value
  bool exists() {
    return !list.filter!(a => a.exists).empty;
  }

  /// Iterate over the filtered items
  int opApply(scope int delegate(RootType) dg) {
    int result = 0;

    foreach(item; list) {
      if(item.exists) {
        result = dg(item.rootItem);
      }

      if (result)
        break;
    }
    return result;
  }

  /// Iterate over the filtered items
  int opApply(scope int delegate(size_t index, RootType) dg) {
    int result = 0;

    foreach(index, item; list) {
      if(item.exists) {
        result = dg(index, item.rootItem);
      }

      if (result)
        break;
    }
    return result;
  }
}

///
auto whereAnyProxy(T)(T list) {
  return WhereAnyProxy!(T)(list);
}

///
struct WhereAny(T : U[], string path, U) {
  private {
    U[] list;
    bool negation;
  }

  static if(path == "") {
    alias M = U;
  } else {
    mixin(`alias M = typeof(U` ~ path ~ `);`);
  }

  auto dispatch(string name)() {
    mixin(`
    return whereAnyProxy(list.map!(item => where(item, item.` ~ name ~ `)).array);
    `);
  }

  static if(isAggregateType!M) {
    static foreach(member; __traits(allMembers, M)) {
      static if(std.traits.isArray!(typeof(__traits(getMember, M, member))) && !isSomeString!(typeof(__traits(getMember, M, member))) ) {
        mixin(`
          auto ` ~ member ~ `() {
            return dispatch!"` ~ member ~ `";
          }
        `);
      }
    }
  }
}

///
struct Where(T : U[], string path, RootType_, U) {
  private {
    U[] list;
    bool negation;
  }

  alias RootType = RootType_;

  static if(path == "") {
    alias M = U;
  } else {
    mixin(`alias M = typeof(U` ~ path ~ `);`);
  }

  ///
  this(U[] list) {
    this.list = list;
  }

  static if(!is(RootType == void)) {
    private RootType _root;

    this(U[] list, RootType root) {
      this.list = list;
      this._root = root;
    }

    ///
    RootType rootItem() {
      return _root;
    }
  }

  /// Filter by a member name
  private auto dispatch(string member)() {
    static if (path == "") {
      enum newPath = "." ~ member;
    } else {
      enum newPath = path ~ "." ~ member;
    }

    static assert(__traits(hasMember, M, member), "The `" ~ M.stringof ~ "` type has no `" ~ member ~ "` property.");

    static if(is(RootType == void)) {
      return Where!(T, newPath, RootType)(list);
    } else {
      return Where!(T, newPath, RootType)(list, rootItem);
    }
  }

  static if(isAggregateType!M) {
    static foreach(member; __traits(allMembers, M)) {
      static if(!std.traits.isArray!(typeof(__traits(getMember, M, member))) || isSomeString!(typeof(__traits(getMember, M, member))) ) {
        mixin(`
          auto ` ~ member ~ `() {
            return dispatch!"` ~ member ~ `";
          }
        `);
      }
    }
  }

  /// Query array properties
  auto any() {
    return WhereAny!(T, path)(list);
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
  auto equal(M value)() {
    bool aff(const U item) pure {
      mixin(`return item` ~ path ~ ` == value;`);
    }

    bool neg(const U item) pure {
      mixin(`return item` ~ path ~ ` != value;`);
    }

    if(negation) {
      list = list.filter!neg.array;
    } else {
      list = list.filter!aff.array;
    }

    return this;
  }

  /// Returns all items that match at least one value
  auto isAnyOf(T...)() {
    enum string[] names = [ T ];

    bool aff(const U item) pure {
      mixin(`return names.canFind(item` ~ path ~ `);`);
    }

    bool neg(const U item) pure {
      mixin(`return !names.canFind(item` ~ path ~ `);`);
    }

    if(negation) {
      list = list.filter!neg.array;
    } else {
      list = list.filter!aff.array;
    }

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

  ///auto hasAttribute = items.where.any.attributes.name.equal!`"test"`.exists;

  //hasAttribute.should.equal(true);
  items.where.any.attributes.name.equal!"other".exists.should.equal(false);
}

version(unittest) { struct TestStructure { } }

/// Filter callables by type name
unittest {
  import introspection.aggregate;

  enum item = describeAggregate!TestStructure;
  enum items = [ item ];

  items.where.type.name.equal!"TestStructure".and.exists.should.equal(true);
  items.where.type.fullyQualifiedName.equal!"selectors.where.TestStructure".and.exists.should.equal(true);
  items.where.type.fullyQualifiedName.equal!"selectors.where.OtherStructure".and.exists.should.equal(false);

  items.where.type.name.isAnyOf!"TestStructure".and.exists.should.equal(true);
  items.where.type.fullyQualifiedName.isAnyOf!"selectors.where.TestStructure".and.exists.should.equal(true);
  items.where.type.fullyQualifiedName.isAnyOf!"selectors.where.OtherStructure".and.exists.should.equal(false);

  items.where.type.name.not.equal!"TestStructure".and.exists.should.equal(false);
  items.where.type.fullyQualifiedName.not.equal!"selectors.where.TestStructure".and.exists.should.equal(false);
  items.where.type.fullyQualifiedName.not.equal!"selectors.where.OtherStructure".and.exists.should.equal(true);

  items.where.type.name.not.isAnyOf!"TestStructure".and.exists.should.equal(false);
  items.where.type.fullyQualifiedName.not.isAnyOf!"selectors.where.TestStructure".and.exists.should.equal(false);
  items.where.type.fullyQualifiedName.not.isAnyOf!"selectors.where.OtherStructure".and.exists.should.equal(true);
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
  foreach(element; items.where.any.attributes.name.equal!`"test"`) {
    index.should.equal(0);
    element.name.should.equal("foo");
    index++;
  }

  index = 0;
  foreach(_; items.where.any.attributes.name.equal!`"other"`) {
    index++;
  }
  index.should.equal(0);

  /// iterate with index
  foreach(i, element; items.where.any.attributes.name.equal!`"test"`) {
    i.should.equal(0);
    element.name.should.equal("foo");
  }
}

/// query the introspection result
auto where(T)(T list) {
  return Where!(T, "", void)(list);
}

/// query the introspection result
auto where(T, U)(T rootItem, U list) {
  return Where!(U, "", T)(list, rootItem);
}