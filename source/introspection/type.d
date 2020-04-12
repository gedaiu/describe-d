module introspection.type;

import std.traits;

version(unittest) {
  import fluent.asserts;
}

///
template ArrayValueType(T : T[]) { alias ArrayValueType = T; }


/// Stores information about types
struct Type {
  /// The type name, how it was defined or used in the source code
  string name;

  /// The type name without qualifiers
  string unqualName;

  ///
  string fullyQualifiedName;

  ///
  bool isStruct;

  ///
  bool isClass;

  ///
  bool isInterface;

  ///
  bool isUnion;

  ///
  bool isArray;

  ///
  bool isEnum;

  ///
  bool isAssociativeArray;

  /// The keys used by the array
  string keyType;

  /// The array values
  string valueType;

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

  /// true if it is manifest constant. eg. `enum name = "test";`
  bool isManifestConstant;
}

/// Describe a type
Type describeType(T)() {
  Type type;

  type.name = T.stringof;
  type.unqualName = Unqual!T.stringof;
  type.fullyQualifiedName = fullyQualifiedName!T;

  type.isBasicType = isBasicType!T;
  type.isBuiltinType = isBuiltinType!T;

  static if(is(T == struct)) {
    type.isStruct = true;
  }

  static if(is(T == class)) {
    type.isClass = true;
  }

  static if(is(T == union)) {
    type.isUnion = true;
  }

  static if(is(T == interface)) {
    type.isInterface = true;
  }

  static if(is(T == enum)) {
    type.isEnum = true;
    type.isBasicType = false;
    type.isBuiltinType = false;
  }

  static if(isArray!T) {
    type.isArray = true;
    type.keyType = "size_t";
    type.valueType = ArrayValueType!T.stringof;
  }

  static if(isAssociativeArray!T) {
    type.isAssociativeArray = true;
    type.keyType = KeyType!T.stringof;
    type.valueType = ValueType!T.stringof;
  }

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

  static if(is(typeof(T)) && !is(typeof(&T))) {
    type.isManifestConstant = true;
  }

  return type;
}

/// ditto
Type describeType(alias T)() if(!is(T == enum)) {
  auto type = describeType!(typeof(T));

  static if(is(typeof(T)) && !is(typeof(&T))) {
    type.isManifestConstant = true;
  }

  return type;
}


/// It should describe an int
unittest {
  auto result = describeType!int;

  result.name.should.equal("int");
  result.unqualName.should.equal("int");
  result.fullyQualifiedName.should.equal("int");

  result.isBasicType.should.equal(true);
  result.isBuiltinType.should.equal(true);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}

/// It should describe an int at compile time
unittest {
  enum result = describeType!int;

  result.name.should.equal("int");
  result.unqualName.should.equal("int");
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

/// It should describe a int pointer
unittest {
  auto result = describeType!(int*);

  result.name.should.equal("int*");
  result.unqualName.should.equal("int*");

  result.isBasicType.should.equal(false);
  result.isBuiltinType.should.equal(false);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}

/// It should describe a manifest constant
unittest {
  enum a = "value";
  auto result = describeType!(a);

  result.name.should.equal("string");
  result.unqualName.should.equal("string");

  result.isBasicType.should.equal(false);
  result.isBuiltinType.should.equal(true);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
  result.isManifestConstant.should.equal(true);
}

/// It shuld describe an array of ints
unittest {
  auto result = describeType!(int[]);

  result.name.should.equal("int[]");
  result.unqualName.should.equal("int[]");

  result.isArray.should.equal(true);
  result.keyType.should.equal("size_t");
  result.valueType.should.equal("int");
}

/// It shuld describe an array of strings
unittest {
  auto result = describeType!(string[]);

  result.name.should.equal("string[]");
  result.unqualName.should.equal("string[]");

  result.isArray.should.equal(true);
  result.keyType.should.equal("size_t");
  result.valueType.should.equal("string");
}

/// It shuld describe an assoc array of ints
unittest {
  auto result = describeType!(int[string]);

  result.name.should.equal("int[string]");
  result.unqualName.should.equal("int[string]");

  result.isArray.should.equal(false);
  result.isAssociativeArray.should.equal(true);
  result.keyType.should.equal("string");
  result.valueType.should.equal("int");
}

/// It shuld describe an assoc array of strings
unittest {
  auto result = describeType!(string[string]);

  result.name.should.equal("string[string]");
  result.unqualName.should.equal("string[string]");

  result.isArray.should.equal(false);
  result.isAssociativeArray.should.equal(true);
  result.keyType.should.equal("string");
  result.valueType.should.equal("string");
}

/// It shuld describe a nested array
unittest {
  auto result = describeType!(int[ulong][][ulong]);

  result.name.should.equal("int[ulong][][ulong]");
  result.unqualName.should.equal("int[ulong][][ulong]");

  result.isArray.should.equal(false);
  result.isAssociativeArray.should.equal(true);
  result.keyType.should.equal("ulong");
  result.valueType.should.equal("int[ulong][]");
}

/// It should describe a struct
unittest {
  struct Test {}

  auto result = describeType!Test;

  result.name.should.equal("Test");
  result.unqualName.should.equal("Test");
  result.fullyQualifiedName.should.equal("introspection.type.__unittest_L333_C1.Test");

  result.isStruct.should.equal(true);
  result.isBasicType.should.equal(false);
  result.isBuiltinType.should.equal(false);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}

/// It should describe a class
unittest {
  class Test {}

  auto result = describeType!Test;

  result.name.should.equal("Test");
  result.unqualName.should.equal("Test");

  result.isStruct.should.equal(false);
  result.isClass.should.equal(true);
  result.isBasicType.should.equal(false);
  result.isBuiltinType.should.equal(false);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}

/// It should describe an union
unittest {
  union Test {}

  auto result = describeType!Test;

  result.name.should.equal("Test");
  result.unqualName.should.equal("Test");

  result.isStruct.should.equal(false);
  result.isClass.should.equal(false);
  result.isUnion.should.equal(true);
  result.isBasicType.should.equal(false);
  result.isBuiltinType.should.equal(false);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}

/// It should describe an interface
unittest {
  interface Test {}

  auto result = describeType!Test;

  result.name.should.equal("Test");
  result.unqualName.should.equal("Test");

  result.isStruct.should.equal(false);
  result.isClass.should.equal(false);
  result.isUnion.should.equal(false);
  result.isInterface.should.equal(true);
  result.isBasicType.should.equal(false);
  result.isBuiltinType.should.equal(false);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}

/// It should describe an enum
unittest {
  enum Test {
    a,b,c
  }

  auto result = describeType!Test;

  result.name.should.equal("Test");
  result.unqualName.should.equal("Test");

  result.isStruct.should.equal(false);
  result.isClass.should.equal(false);
  result.isUnion.should.equal(false);
  result.isInterface.should.equal(false);
  result.isEnum.should.equal(true);
  result.isBasicType.should.equal(false);
  result.isBuiltinType.should.equal(false);
  result.isConst.should.equal(false);
  result.isInout.should.equal(false);
  result.isImmutable.should.equal(false);
  result.isShared.should.equal(false);
}
