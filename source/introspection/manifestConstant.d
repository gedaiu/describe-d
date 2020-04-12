module introspection.manifestConstant;

/// Stores information about manifest constants
struct ManifestConstant {
  ///
  string name;
}

///
ManifestConstant describeManifestConstant(T, string member)() {
  ManifestConstant manifestConstant;

  manifestConstant.name = member;

  return manifestConstant;
}


/// Check if a member is manifest constant
bool isManifestConstant(T, string name)()
{
  mixin(`return is(typeof(T.init.` ~ name ~ `)) && !is(typeof(&T.init.` ~ name ~ `));`);
}
