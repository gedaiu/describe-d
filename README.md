# describe.d

`describe.d` is a library that provides a structured interface to introspect
DLang source code.

# Usage

## Introspection

The library provides the `describe` template which returns a structure with
the introspection result:

```d
import described;

/// Introspecting modules
assert(describe!(std.array).name == "module array");
assert(describe!(std.array).fullyQualifiedName == "std.array");
assert(describe!(std.array).functions.length == 1);
assert(describe!(std.array).templates.length == 31);

/// Introspecting aggregates
struct MyStruct {
  void callMe() {
  }
}

assert(describe!MyStruct.name == "MyStruct");
assert(describe!MyStruct.methods.length == 1);
assert(describe!MyStruct.methods[0].name == "callMe");
assert(describe!MyStruct.methods[0].returns.name.should.equal("void"));

/// Introspecting methods
assert(describe!(MyStruct.callMe).name == "MyStruct");
assert(describe!(MyStruct.callMe).returns.name.should.equal("void"));
```

Given an introspected `Type` like a class or struct, it can be converted to the
D type using `fromType`:

```d
  alias T = fromType!(describe!RandomClass.type);

  static assert(is(T == RandomClass));
```

## Filtering

The library provides the `where` structure which allows you to filter the `describe` result.

### by attribute name

```d
  struct Test {
    @("test") void foo() { }
    @("other") void other() { }
  }

  /// Check that there is a method with the string attribute "test"
  static assert(describe!Test.methods.where.attribute!`"test"`.exists);

  /// Iterate over the methods with the "test" attribute
  static foreach(method; describe!Test.methods.where.attribute!`"test"`) {
    ...
  }
```

# License

This project is licensed under the **MIT** license - see the [LICENSE](LICENSE) file for details.
