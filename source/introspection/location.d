module introspection.location;


/// Stores information about symbol location in the source code
struct Location {
  ///
  string file;

  ///
  int line;

  ///
  int column;
}