module introspection.parameter;

import introspection.type;

///
struct ParameterDefault {
  ///
  string value;

  ///
  bool exists;
}

/// Stores information about callalble parameters
struct Parameter {
  ///
  string name;

  ///
  Type type;

  ///
  ParameterDefault default_;
}
