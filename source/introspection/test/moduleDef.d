module introspection.test.moduleDef;

version(unittest):

string globalVar = "test";

struct TestStructure { }
private class TestClass { }
interface TestInterface { }
union TestUnion { }

void testFunction() {}
private void privateFunction() {}

template TestTpl(T) { }
void templatedFunction(T)() {}