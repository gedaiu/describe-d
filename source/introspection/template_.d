module introspection.template_;

import std.traits;
import std.string;
import std.algorithm;
import std.array;

import introspection.location;
import introspection.protection;

version(unittest) {
  import fluent.asserts;
}

/// Describes a template parameter
struct TemplateParameter {
  /// the parameter name
  string name;

  ///
  string type;

  ///
  string defaultValue;

  ///
  bool isVariadic;

  /// The string used to parse the template parameter
  string original;
}

///
TemplateParameter parseTemplateParameter(string paramString) {
  TemplateParameter param;
  param.original = paramString;

  auto beginDefaultValue = paramString.indexOf("=");
  if(beginDefaultValue != -1) {
    param.defaultValue = paramString[beginDefaultValue + 1..$].strip;
    paramString = paramString[0..beginDefaultValue].strip;
  }

  auto beginVariadic = paramString.indexOf("...");
  if(beginVariadic != -1) {
    param.isVariadic = true;
    paramString = paramString[0..beginVariadic].strip;
  }

  auto pieces = paramString.split(" ");

  if(pieces.length == 2) {
    param.type = pieces[0];
    param.name = pieces[1];
  } else if(pieces.length == 1) {
    param.name = pieces[0];
  }

  return param;
}

///
TemplateParameter[] parseTemplateParameters(string templateDefinition) {
  auto begin = templateDefinition.indexOf("(") + 1;
  auto end = templateDefinition.indexOf(")");

  auto params = templateDefinition[begin..end].split(",");


  return params.map!(a => parseTemplateParameter(a.strip)).array;
}

///
struct Template {
  ///
  string name;

  ///
  TemplateParameter[] templateParameters;

  ///
  TemplateParameter[] parameters;

  ///
  Protection protection;

  ///
  Location location;
}

///
TemplateParameter[] parseParameters(string templateDefinition) {
  auto templateParamsEnd = templateDefinition.indexOf(")") + 1;
  templateDefinition = templateDefinition[templateParamsEnd .. $];

  auto begin = templateDefinition.indexOf("(");
  auto end = templateDefinition.indexOf(")");

  if(end == -1 || begin == -1) {
    return [];
  }

  auto params = templateDefinition[1..end].split(",");


  return params.map!(a => parseTemplateParameter(a.strip)).array;
}

/// Describes a template
Template describeTemplate(alias T)() if(__traits(isTemplate, T)) {
  Template tpl;

  tpl.name = __traits(identifier, T);

  static if(__traits(compiles, T.stringof)) {
    tpl.templateParameters = parseTemplateParameters(T.stringof);
    tpl.parameters = parseParameters(T.stringof);
  }

  auto location = __traits(getLocation, T);
  tpl.location = Location(location[0], location[1], location[2]);

  tpl.protection = __traits(getProtection, T).toProtection;

  return tpl;
}

/// It should describe the template name and parameters
unittest {
  template foo(T) {
    alias foo = string;
  }

  auto result = describeTemplate!foo;

  result.name.should.equal("foo");
  result.parameters.length.should.equal(0);

  result.templateParameters.length.should.equal(1);
  result.templateParameters[0].name.should.equal("T");
  result.templateParameters[0].original.should.equal("T");
  result.templateParameters[0].type.should.equal("");
  result.templateParameters[0].defaultValue.should.equal("");
  result.templateParameters[0].isVariadic.should.equal(false);

  result.protection.should.equal(Protection.public_);

  result.location.file.should.equal("source/introspection/template_.d");
  result.location.line.should.be.greaterThan(0);
  result.location.column.should.equal(3);
}

/// It should describe a templated function
unittest {
  void foo(T)(T param) { }

  auto result = describeTemplate!foo;

  result.name.should.equal("foo");
  result.templateParameters.length.should.equal(1);

  result.templateParameters[0].name.should.equal("T");
  result.templateParameters[0].original.should.equal("T");
  result.templateParameters[0].type.should.equal("");
  result.templateParameters[0].defaultValue.should.equal("");
  result.templateParameters[0].isVariadic.should.equal(false);

  result.parameters.length.should.equal(1);
  result.parameters[0].name.should.equal("param");
  result.parameters[0].original.should.equal("T param");
  result.parameters[0].type.should.equal("T");
  result.parameters[0].defaultValue.should.equal("");
  result.parameters[0].isVariadic.should.equal(false);
}

/// It should describe a templated function with default values
unittest {
  void foo(T = int)(T param) { }

  auto result = describeTemplate!foo;

  result.name.should.equal("foo");
  result.templateParameters.length.should.equal(1);

  result.templateParameters[0].name.should.equal("T");
  result.templateParameters[0].defaultValue.should.equal("int");
  result.templateParameters[0].original.should.equal("T = int");
  result.templateParameters[0].type.should.equal("");
  result.templateParameters[0].isVariadic.should.equal(false);

  result.parameters.length.should.equal(1);
  result.parameters[0].name.should.equal("param");
  result.parameters[0].original.should.equal("T param");
  result.parameters[0].type.should.equal("T");
  result.parameters[0].defaultValue.should.equal("");
  result.parameters[0].isVariadic.should.equal(false);
}

/// It should describe a templated function with a numeric parameter and variadic parameters
unittest {
  void foo(int a = 3, T...)(int b) if(T.length > 1) { }

  auto result = describeTemplate!foo;

  result.name.should.equal("foo");
  result.templateParameters.length.should.equal(2);

  result.templateParameters[0].name.should.equal("a");
  result.templateParameters[0].defaultValue.should.equal("3");
  result.templateParameters[0].original.should.equal("int a = 3");
  result.templateParameters[0].type.should.equal("int");
  result.templateParameters[0].isVariadic.should.equal(false);

  result.templateParameters[1].name.should.equal("T");
  result.templateParameters[1].defaultValue.should.equal("");
  result.templateParameters[1].original.should.equal("T...");
  result.templateParameters[1].type.should.equal("");
  result.templateParameters[1].isVariadic.should.equal(true);

  result.parameters.length.should.equal(1);
  result.parameters[0].name.should.equal("b");
  result.parameters[0].original.should.equal("int b");
  result.parameters[0].type.should.equal("int");
  result.parameters[0].defaultValue.should.equal("");
  result.parameters[0].isVariadic.should.equal(false);
}


/// It should describe a templated class with a numeric parameter and variadic parameters
unittest {
  class Foo(int a = 3, T...) {
    void bar() {}
  }

  auto result = describeTemplate!Foo;

  result.name.should.equal("Foo");
  result.templateParameters.length.should.equal(2);

  result.templateParameters[0].name.should.equal("a");
  result.templateParameters[0].defaultValue.should.equal("3");
  result.templateParameters[0].original.should.equal("int a = 3");
  result.templateParameters[0].type.should.equal("int");
  result.templateParameters[0].isVariadic.should.equal(false);

  result.templateParameters[1].name.should.equal("T");
  result.templateParameters[1].defaultValue.should.equal("");
  result.templateParameters[1].original.should.equal("T...");
  result.templateParameters[1].type.should.equal("");
  result.templateParameters[1].isVariadic.should.equal(true);
}
