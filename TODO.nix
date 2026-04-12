let
  lib = import "${
    fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-25.11.tar.gz";
      sha256 = "sha256:1vs1g86i75rgpsvs7kyqfv22j6x3sg3daf4cv6ws3d0ghkb2ggpz";
    }
  }/lib";

  recursive = import (
    builtins.fetchurl {
      url = "https://raw.githubusercontent.com/StijnRuts/nix-recursive-merge/9d50a86218c6a8cf6880b490e5a76bce32af0fb1/recursive.nix";
      sha256 = "sha256:1lnwfn9h5mwn3vdsa7as0c86929p4w45bnkcw1lszbnh3y5im9q1";
    }
  );

  typeOf' =
    x:
    let
      t = builtins.typeOf x;
    in
    if (t == "lambda") then
      "function"
    else if (t == "set") then
      "attrs"
    else
      t;

in
with builtins lib;

rec {
  # TODO: add debug path trace info, like in recursive
  transform =
    f: x:
    if isFunction f then
      f x
    else if isList f then
      foldl' (x': f': transform f' x') x f
    else if isAttrs f then
      if isAttr x then
        let
          unsupported = subtractLists (builtins.attrNames x) (builtins.attrNames f);
        in
        if unsupported == [ ] || hasAttr "fallback" f then
          foldl' (a: k: a // { ${k} = (f.${k} or f.fallback) x.${k}; }) { } (attrNames x)
        else
          throw "No function found to transform ${unsupported}"
      else
        throw "Transform got mismatched arguments of types ${typeOf' f} and ${typeOf' x}"
    else
      throw "Transform got unsupported argument of type ${typeOf' f}";

  inside = {
    path = f: x: if isPath x then transform f (import x) else throw "Expected path, got ${typeOf' x}";
    function =
      f: x:
      if isFunction x then arg: transform f (x arg) else throw "Expected function, got ${typeOf' x}";
    list = f: x: if isList x then map (transform f) x else throw "Expected list, got ${typeOf' x}";
    attrs =
      f: x: if isAttrs x then mapAttrs (_: transform f) x else throw "Expected attrs, got ${typeOf' x}";
    attrsKey =
      k: f: x:
      if isAttrs x then
        if hasKey k then x // { ${k} = transform f x.${k}; } else x
      else
        throw "Expected attrs, got ${typeOf' x}";
  };

  match = {
    type = x: { ${typeOf' x} = x; };
    attrsKey =
      k: x:
      let
        rest = removeAttrs x [ k ];
      in
      if isAttrs x && hasAttr k x then
        if rest != { } then
          {
            match = x.${k};
            inherit rest;
          }
        else
          {
            match = x.${k};
            rest = null;
          }
      else
        { nomatch = x; };
    attrsSingleton =
      x:
      if isAttrs x && length (attrNames x) == 1 then
        { match = (attrValues x) [ 0 ]; }
      else
        { nomatch = x; };
    listSingleton = x: if isList x && length x == 1 then { match = x [ 0 ]; } else { nomatch = x; };
  };

  keep = x: x;
  discard = _: null;

  enshure = {
    function = transform [
      match.type
      {
        function = keep;
        fallback = x: _: x;
      }
      merge.attrs
    ];
    list = transform [
      match.type
      {
        list = keep;
        fallback = x: [ x ];
      }
      merge.attrs
    ];
    attrsKey =
      k:
      transform [
        (match.attrsKey k)
        {
          match = x: { ${k} = x; };
          rest = keep;
          nomatch = x: { ${k} = x; };
        }
        merge.attrs
      ];
  };

  project = {
    modules = [
      match.type
      {
        path = inside.path project.module;
        list = merge.list (inside.list project.outputs);
        attrs = project.outputs;
      }
    ];
    outputs = [
      (enshure.attrsKey "outputs")
      (inside.attrsKey "outputs" [
        enshure.function
        (inside.function [
          # with inputs
          project.containers
          project.shell
          project.shells
          project.configs
        ])
      ])
    ];
    shell = [
      (match.attrsKey "shell")
      {
        match = x: { shells.default = x; };
        rest = keep;
        nomatch = keep;
      }
      merge.attrs
    ];
    shells = inside.attrsKey "shells" (
      inside.attrs [
        project.processes
        project.scripts
      ]
    );
    scripts = [ ];
    processes = [
      (match.attrsKey "processes")
      {
        match = inside.function;
        rest = keep;
        nomatch = keep;
      }
    ];
    configs = [ ];
    containers = [ ];
  };

  optics = {
    # string to query, list to alternative
    from = [
      "foo ?bar {key} args1: ?args2: [] ?[] =value"
      "/path1.bla ?/path2 =value2"
      "(foo.bar,lorem.ipsum)" # this makes it harder, just use list
    ];
    # filter by returning null
    # duplicate by returning list
    # inject systems
    change = { key, ... }@attrs: [(attrs // { key = uppercase key; extra = foobar; })];
    # string to query, list to alternative
    to = [
      ".foo .bar .{key} .args2: .args1: .[] .<system> =value"
      ""
    ];
  };

  from = {
    value = name: callback: x: callback { ${name} = x; } null;
    key = k: callback: x: if (isAttr x && hasAttr k x) then callback {} x.${k} else callback {} null;
    anyKey = name: callback: x: mapAttr (k: v: callback { ${name} = k; } v );
    list = callback: x: map (x': callback {} x') x;
    function = callback: x: args: 
    path = ;
    alternative = [matchers]: ;
    sequence = [matchers]: ;
    optional = matcher: ;
    query = string: ;
  };

  to = {
    value = name: callback: attrs: callback attrs.name;
    key = k: ;
    list = ;
    function = ;
    sequence = [writers]: ;
    alternative = [writers]: ;
    query = string: ;
  };

  example_result = {
    devShells.${system}.default = pkgs.mkShell (import ./nix/devshell.nix { inherit pkgs; });
    nixosConfigurations = {
      dev = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            networking.hostName = "opmaat-dev";
            system.stateVersion = "25.11";
          }
        ];
      };
      staging = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            networking.hostName = "opmaat-staging";
            system.stateVersion = "25.11";
          }
        ];
      };
    };
  };

  # is transform
  apply = f: x:
    if isFunction f then
      f x
    else if isList f then
      builtins.foldl' (flip apply) x f
    else if isAttr f then
      # ???
    else
      throw;

  loadModules = f: x:
    if isPath x then
      loadModules f (import x)
    else if isList x then
      mergeList (map (loadModules f) x)
    else if isAttrs x then
      f x
    else
      throw

  # reify.modules.main
  # reify.modules.shells.main
  # reify.modules.shells.processes
  # reify.modules.shells.scripts
  # reify.modules.shells.packages
  (map.key "output" create.key # or missingKey = throw ;;; create.null = _ ;;; create.key val: val; })
    (map.fn createDefaultFn systemInputs: inputs: [
      (move.key "shells" "shells.default" emptyAttr)
      # map.key = move.key k k
      (map.key "shells" emptyAttr
        (map.attrs (in_.fn pkgs
          (move.key "processes" "scripts" (map.fn pkgs: transformProcesses pkgs)
          (move.key "scripts" "packages" (map.fn pkgs: transformScripts pkgs))
          packages = config.packages pkgs;
        )
       )
      (move.key "shells" "devShells"
        (wrap.systems (system: pkgs.mkShell system (systemInputs))
      )
      (map.key "configs" defaultKey
        (map.attrs [
          (move.key "*" "modules" id)
          (move.key "modules.system.arch" "system" throwMissing)
          (map.key "modules" mkList)
        ])
      )
      nixosConfigurations.key.(nixpkgs.lib.nixosSystem)
    ])

  (inKey "inputs.global" (default {}))

  (inKey "inputs.system" [
    default (inputs: _: inputs) # inputs: system: { pkgs };
  ]);

  (conf: {
    inputs = conf.inputs;
    outputs = conf.outputs conf.systemInputs;
  })
)

  
    

  example = {
    shell = {
      packages = { pkgs, ... }: [ pkgs.hello ];
      scripts = _: { lorem = "echo ipsum"; };
      processes = _: {
        dev = {
          server.command = "while true; do echo running...; sleep 2; done";
        };
      };
      shellHook = "hello";
    };
    configs.dev = {
      system.arch = "x86_64-linux";
      system.stateVersion = "25.11";
    };
    containers.dev = {
      shell = "default";
      processes = "dev";
      flake = "dev";
    };
    containers.opmaatdev = {
      config = "dev";
      hostIp = "";
      clientIp = "";
      ftpMounts = [
        {
          hostPath = null;
          clientPath = null;
        }
      ];
    };
    servers.prod = {
      # script provision:prod deploy:prod
      shell = "default";
      config = "prod";
      server = {
        ip = "...";
      };
    };
  };
}
