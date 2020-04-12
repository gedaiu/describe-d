module introspection.enum_;


/// Stores information about enums
struct Enum {
  ///
  string name;
}

////
Enum describeEnum(T)() {
  Enum enum_;

  enum_.name = T.stringof;

  return enum_;
}