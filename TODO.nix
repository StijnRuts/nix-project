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
    function =
      arg:
      transform {
        function = keep;
        fallback = x: _: x;
      } (match.type arg);
    list =
      arg:
      transform {
        list = keep;
        fallback = x: [ x ];
      } (match.type arg);
    attrsKey =
      k: arg:
      transform [
        merge.attrs
        {
          match = x: { ${k} = x; };
          rest = keep;
          nomatch = x: { ${k} = x; };
        }
      ] (match.attrsKey k arg);
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
    processes = [ ];
    scripts = [ ];
    configs = [ ];
    containers = [ ];
  };

  example = {
    shell = {
      packages = { pkgs, ... }: [ pkgs.hello ];
      scripts = _: { lorem = "echo ipsum"; };
      processes = _: {
        dev = {
          server.command = "while true; do echo running...; sleep 2; done";
        };
      };
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
