module introspection.type;

import std.traits;

version(unittest) {
  import fluent.asserts;
}

/// Stores information about types
struct Type {
  /// The type name, how it was defined or used in the source code
  string name;

  /// The type name without qualifiers
  string unqualName;

  /// true if it is scalar type or void
  bool isBasicType;

  /// true if it is a type defined by the compiler
  bool isBuiltinType;

  /// true if it has `const` qualifier
  bool isConst;

  /// true if it has `inout` qualifier
  bool isInout;

  /// true if it has `immutable` qualifier
  bool isImmutable;

  /// true if it has `shared` qualifier
  bool isShared;
}


/// Describe a type
Type describeType(T)() {
  auto type = Type(
    T.stringof,
    Unqual!T.stringof
  );

  type.isBasicType = isBasicType!T;
  type.isBuiltinType = isBuiltinType!T;

  static if(is(T == const)) {
    type.isConst = true;
  }

  static if(is(T == inout)) {
    type.isInout = true;
  }

  static if(is(T == immutable)) {
    type.isImmutable = true;
  }

  static if(is(T == shared)) {
    type.isShared = true;
  }

  return type;
}

/// It should describe an int
unittest {
  auto result = describeType!int;

  result.name.should.equal("int");
  result.unqualName.should.equal("int");

  result.isBasicType.should.equal(true);
  result.isBuiltinType.should.equal(true);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}

/// It should describe a const int
unittest {
  auto result = describeType!(const(int));

  result.name.should.equal("const(int)");
  result.unqualName.should.equal("int");

  result.isBasicType.should.equal(true);
  result.isBuiltinType.should.equal(true);
  result.isConst.should.equal(true);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}

/// It should describe an inout int
unittest {
  auto result = describeType!(inout(int));

  result.name.should.equal("inout(int)");
  result.unqualName.should.equal("int");

  result.isBasicType.should.equal(true);
  result.isBuiltinType.should.equal(true);
  result.isConst.should.equal(false);
  result.isInout.should.equal(true);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}

/// It should describe an immutable int
unittest {
  auto result = describeType!(immutable(int));

  result.name.should.equal("immutable(int)");
  result.unqualName.should.equal("int");

  result.isBasicType.should.equal(true);
  result.isBuiltinType.should.equal(true);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(true);
  result.isShared.should.equal(false);
}

/// It should describe a shared int
unittest {
  auto result = describeType!(shared(int));

  result.name.should.equal("shared(int)");
  result.unqualName.should.equal("int");

  result.isBasicType.should.equal(true);
  result.isBuiltinType.should.equal(true);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(true);
}