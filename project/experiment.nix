
callable = rec {
  apply =
    op: f: x:
      if isFunction f || isAttrs f then
        f x
      else if isList f then
        op f x
      else
        throw "Unsupported type ${typeOf f}";

  map = f: x: apply (f': function.map f' x) f x;

  fold = f: x: apply (f': foldl' (x': f': apply f' x') x f) f x;
};




Callable = {
  Fun = f: { tag = "Fun"; fun = f; };
  List = xs: { tag = "List"; items = xs; };
};

toCallable = f:
  if isFunction f || isAttrs f then Callable.Fun f
  else if isList f then Callable.List (map toCallable f)
  else throw "Unsupported type ${typeOf f}";

matchCallable = c: cases:
  let tag = c.tag or (throw "Missing tag in callable");
  in cases.${tag} c;

callableMap = c: x:
  matchCallable c {
    Fun = c: c.fun x;
    List = c: map (c': callableMap c' x) c.items;
  };

callableFold = c: x:
  matchCallable c {
    Fun = c: c.fun x;
    List = c: foldl' (acc: c': callableFold c' acc) x c.items;
  };




   ReaderCallable = {
    Fun  = f: { tag = "Fun";  fun   = f; };      # f : env -> a
    List = xs: { tag = "List"; items = xs; };    # sequence of readers
  };

  matchRC = c: cases:
    let tag = c.tag or (throw "Missing tag in ReaderCallable");
    in cases.${tag} c;

  # runReader: ReaderCallable env a -> env -> a
  runReader = c: env:
    matchRC c {
      Fun  = c: c.fun env;
      List = c:
        # fold a list of env -> env (or env -> a) over env
        lib.foldl' (e: rc: runReader rc e) env c.items;
    };

  # helper: lift a plain function env -> env into a ReaderCallable
  fromFun = f: ReaderCallable.Fun f;

  # example: a pipeline of environment transforms
  example =
    ReaderCallable.List [
      fromFun (env: env // { a = 1; })
      fromFun (env: env // { b = env.a + 1; })
      fromFun (env: env // { c = env.b * 2; })
    ];






  Effect = {
    Pure   = v: { tag = "Pure";   value = v; };
    Fun    = f: { tag = "Fun";    fun   = f; };      # x -> x
    Log    = msg: { tag = "Log";  message = msg; };  # log side info
    List   = xs: { tag = "List";  items = xs; };     # sequence of effects
  };

  # State: { value = ...; logs = [ ... ]; }
  matchEffect = e: cases:
    let tag = e.tag or (throw "Missing tag in Effect");
    in cases.${tag} e;

  runEffect = e: state:
    matchEffect e {
      Pure = e: state // { value = e.value; };

      Fun = e:
        let newValue = e.fun state.value;
        in state // { value = newValue; };

      Log = e:
        state // { logs = state.logs ++ [ e.message ]; };

      List = e:
        lib.foldl' (st: eff: runEffect eff st) state e.items;
    };

  # helpers
  pure = Effect.Pure;
  fun  = Effect.Fun;
  log  = Effect.Log;
  seq  = Effect.List;

  example =
    seq [
      pure 0
      fun (x: x + 1)
      log "Incremented once"
      fun (x: x * 10)
      log "Multiplied by 10"
    ];

  initialState = { value = null; logs = [ ]; };

  result = runEffect example initialState;






Effect = {
  Pure   = v: { tag = "Pure";   value = v; };
  Map    = f: { tag = "Map";    fun   = f; };      # config -> config
  Zoom   = p: { tag = "Zoom";   path  = p; };      # focus on subpath
  Seq    = xs: { tag = "Seq";   items = xs; };     # sequence of effects
  Merge = v: { tag = "Merge"; value = v; };
};

pure = Effect.Pure;
map  = Effect.Map;
zoom = Effect.Zoom;
seq  = Effect.Seq;

runEffect = eff: cfg:
  let
    go = eff: cfg:
      let tag = eff.tag;
      in if tag == "Pure" then
           eff.value
         else if tag == "Map" then
           eff.fun cfg
         else if tag == "Zoom" then
           lib.getAttrFromPath eff.path cfg
         else if tag == "Seq" then
           lib.foldl' (acc: e: go e acc) cfg eff.items
         else if tag == "Validate" then
            (if eff.fun cfg then cfg else throw "Validation failed")
         else if tag == "Merge" then
            lib.recursiveUpdate cfg eff.value
         else
           throw "Unknown effect ${tag}";
  in go eff cfg;

project = {
  name = "myapp";
  packages = {
    server = { src = ./server; };
    client = { src = ./client; };
  };
};

flakePipeline =
  seq [
    zoom [ "packages" "server" ]
    map (pkg: pkg // { build = "cargo build"; })
    zoom [ "packages" ]
    map (pkgs: {
      outputs = {
        packages.default = pkgs.server;
      };
    })
  ];

flakeConfig = runEffect flakePipeline project;



local = path: eff:
  seq [
    zoom path
    eff
  ];

flakePipeline =
  seq [
    local [ "packages" "server" ] (map (pkg: pkg // { build = "cargo build"; }))
    local [ "packages" ] (map (pkgs: { outputs.packages.default = pkgs.server; }))
  ];

Effect.Validate = f: { tag = "Validate"; fun = f; };




  Effect = {
    RunEffect = f: e: ...;
    Pure     = v: { tag = "Pure";     value = v; };
    Map      = f: { tag = "Map";      fun   = f; };        # cfg -> cfg
    Seq      = xs: { tag = "Seq";     items = xs; };       # [Effect]
    Zoom     = p: e: { tag = "Zoom";  path  = p; inner = e; };  # bidirectional
    # innerpath vs outerpath?
    # basepath, readpath, writepath
    Validate = msg: pred: { tag = "Validate"; message = msg; pred = pred; };
  };

  # helpers
  pure     = Effect.Pure;
  map      = Effect.Map;
  seq      = Effect.Seq;
  zoom     = Effect.Zoom;
  validate = Effect.Validate;

  # setAttrByPath: like getAttrFromPath but for setting
  setAttrByPath = path: value: cfg:
    if path == [] then value else
    let
      key  = lib.head path;
      rest = lib.tail path;
      old  = cfg.${key} or { };
      new  = setAttrByPath rest value old;
    in cfg // { ${key} = new; };

  # runEffect: Effect -> cfg -> cfg
  runEffect = eff: cfg0:
    let
      go = eff: cfg: path:
        let tag = eff.tag;
        in
        if tag == "Pure" then
          eff.value

        else if tag == "Map" then
          eff.fun cfg

        else if tag == "Seq" then
          lib.foldl' (acc: e: go e acc path) cfg eff.items

        else if tag == "Zoom" then
          # bidirectional zoom:
          # 1. focus on subcfg
          # 2. run inner effect on it
          # 3. write result back into parent
          let
            subPath = path ++ eff.path;
            subCfg  = lib.getAttrFromPath eff.path cfg;
            newSub  = go eff.inner subCfg subPath;
          in
          setAttrByPath eff.path newSub cfg

        else if tag == "Validate" then
          if eff.pred cfg then
            cfg
          else
            throw "Validation failed at ${lib.concatStringsSep \".\" path}: ${eff.message}"

        else
          throw "Unknown effect ${tag}";
    in
    go eff cfg0 [];
in
{
  inherit Effect pure map seq zoom validate runEffect;
}










{ lib }:

let
  # --- ADT ---------------------------------------------------------
  Effect = {
    # recurse?
    Pure     = v: { tag = "Pure";     value = v; };
    Map      = f: { tag = "Map";      fun   = f; };
    Seq      = xs: { tag = "Seq";     items = xs; };
    Zoom     = p: e: { tag = "Zoom";  path  = p; inner = e; };
    Validate = msg: pred: { tag = "Validate"; message = msg; pred = pred; };
  };

  # --- Helpers -----------------------------------------------------
  pure     = Effect.Pure;
  map      = Effect.Map;
  seq      = Effect.Seq;
  zoom     = Effect.Zoom;
  validate = Effect.Validate;

  # Set a nested attribute
  setAttrByPath = path: value: cfg:
    if path == [] then value else
    let
      key  = lib.head path;
      rest = lib.tail path;
      old  = cfg.${key} or { };
      new  = setAttrByPath rest value old;
    in cfg // { ${key} = new; };

  # --- Interpreter -------------------------------------------------
  runEffect = eff: cfg0:
    let
      go = eff: cfg: path:
        let tag = eff.tag;
        in
        if tag == "Pure" then
          eff.value

        else if tag == "Map" then
          eff.fun cfg

        else if tag == "Seq" then
          lib.foldl' (acc: e: go e acc path) cfg eff.items

        else if tag == "Zoom" then
          let
            subPath = path ++ eff.path;
            subCfg  = lib.getAttrFromPath eff.path cfg;
            newSub  = go eff.inner subCfg subPath;
          in
          setAttrByPath eff.path newSub cfg

        else if tag == "Validate" then
          if eff.pred cfg then cfg
          else throw "Validation failed at ${lib.concatStringsSep \".\" path}: ${eff.message}"

        else
          throw "Unknown effect ${tag}";
    in
    go eff cfg0 [];

  # --- Ready-made combinators -------------------------------------

  # Require an attribute to exist
  require = path: msg:
    zoom path (validate msg (cfg: cfg != null));

  # Add a default if missing
  default = path: value:
    zoom path (map (cfg: if cfg == null then value else cfg));

  # Transform a subpath
  transform = path: f:
    zoom path (map f);

  # Turn a project.packages.<name> into a flake output
  packageToFlakeOutput = pkgName:
    transform [ "packages" pkgName ] (pkg: {
      inherit (pkg) src;
      build = pkg.build or "nix build .#${pkgName}";
    });

  # Convert all packages into flake outputs
  allPackagesToFlake = map (project: {
    outputs = {
      packages = lib.mapAttrs (name: pkg: pkg) project.packages;
    };
  });

in
{
  inherit
    Effect pure map seq zoom validate runEffect
    require default transform
    packageToFlakeOutput allPackagesToFlake;
}


 project = {
    name = "myapp";
    packages = {
      server = { src = ./server; };
      client = { src = ./client; };
    };
  };

  pipeline =
    seq [
      require [ "name" ] "Project must have a name"
      require [ "packages" ] "Project must define packages"

      # Add defaults
      default [ "packages" "server" "build" ] "cargo build"
      default [ "packages" "client" "build" ] "npm run build"

      # Convert each package to flake output form
      packageToFlakeOutput "server"
      packageToFlakeOutput "client"

      # Build final flake structure
      map allPackagesToFlake
    ];
in
runEffect pipeline project









 # Collect all options and configs
  collected =
    lib.foldl'
      (acc: m: {
        options = acc.options // (m.options or { });
        configs = acc.configs ++ [ (m.config or { }) ];
      })
      { options = { }; configs = [ ]; }
      modules;

  options = collected.options;

  # Merge configs with mkMerge-like semantics
  mergedConfig = lib.foldl' lib.recursiveUpdate { } collected.configs;

  # Optionally: validate types using options.*.type
  # (left as a sketch)



  lib = import <nixpkgs/lib> { };
  modules = [
    (import ./modules/base.nix { inherit lib; })
    (import ./modules/server.nix { inherit lib; })
    (import ./modules/client.nix { inherit lib; })
  ];

  flakeConfig = import ./project-top.nix { inherit lib modules; };





