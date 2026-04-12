with builtins;
with (import ./wrench.nix);
rec {
  __functor =
    _:
    apply [
      module.load
    ];

  module = {
    __functor =
      _:
      apply [
        (attrs.key.fold {
          inputs = over.nonNull (attrs.key.singleton "inputs");
          outputs = over.nonNull (attrs.key.singleton "outputs");
          _rest = attrs.key.singleton "outputs";
        })
        (attrs.key.over "outputs" to.function)
      ];

    load = over.type {
      path = p: module.load (import p);
      list = l: merge.list (map module.load l);
      attrs = module;
    };
  };

  #perSystem =
  #  systems: getValue:
  #  builtins.listToAttrs (
  #    builtins.map (system: {
  #      name = system;
  #      value = getValue system;
  #    }) systems
  #  );
}
