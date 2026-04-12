with builtins;
let
  typeOf =
    x:
    if isFunction x then
      "function"
    else if isAttrs x then
      "attrs"
    else
      builtins.typeOf x;

  take =
    n: v:
    if n == 0 then
      [ ]
    else if v == [ ] then
      [ ]
    else
      let
        first = head v;
        rest = tail v;
      in
      [ first ] ++ take (n - 1) rest;

  toString =
    x:
    let
      truncateString = n: v: if stringLength v <= n then v else "${substring 0 (n - 1) v}…";
      concatList =
        n: v: if length v <= n then concatStringsSep ", " v else "${concatList n (take n v)}, …";
    in
    {
      null = _: "null";
      int = builtins.toString;
      float = builtins.toString;
      path = builtins.toString;
      bool = v: if v then "true" else "false";
      function = "<function>";
      string = v: "\"${truncateString 20 v}\"";
      list = v: "[${concatList 3 (map toString v)}]";
      attrs =
        v:
        if hasAttr "__toString" v || hasAttr "outPath" v then
          builtins.toString v
        else
          "{${concatList 3 (attrNames v)}}";
    }
    .${typeOf x}
    x;
in
rec {
  keep = v: v;
  discard = _: null;
  unsupported = v: throw "Unsupported ${typeOf v} with value ${toString v}";

  apply = over.type {
    function = keep;
    null = _: keep;
    path = f: apply (import f);
    list = fs: arg: foldl' (x: f: apply f x) arg fs;
  };

  over = {
    type = f: v: (f.${typeOf v} or f._fallback or unsupported) v;
    nonNull = f: v: if v == null then null else apply f v;
    list = f: map (apply f);
    attrs = f: mapAttrs (_: apply f);
    path = f: v: apply f (import v);
    function =
      f: v: args:
      v (apply f args);
  };

  to = {
    list = over.type {
      list = keep;
      _fallback = v: [ v ];
    };
    function = over.type {
      function = keep;
      _fallback = v: _: v;
    };
  };

  attrs = {
    key = rec {
      get = k: v: v.${k} or null;
      set =
        k: new: v:
        v // { ${k} = new; };
      remove = k: x: removeAttrs x [ k ];
      over =
        k: f: v:
        set k (apply f (get k v)) v;
      extract = k: v: {
        value = get k v;
        rest = remove k v;
      };
      singleton = k: v: set k v { };
      fold =
        f: initial:
        let
          v =
            foldl'
              (
                prev: k:
                let
                  next = attrs.key.extract k prev.rest;
                in
                {
                  value = merge prev.value (apply f.${k} next.value);
                  inherit (next) rest;
                }
              )
              {
                value = null;
                rest = initial;
              }
              (attrNames (removeAttrs f [ "_rest" ]));
        in
        merge v.value (apply f._rest v.rest);
    };
    path = rec {
      fromString = p: filter isString (split "\\." p);
      get =
        p: v:
        let
          k = head p;
          rest = tail p;
        in
        if isString p then
          get (fromString p) v
        else if p == [ ] then
          v
        else
          get rest (attrs.get.key k v);
      set =
        p: new: v:
        let
          k = head p;
          rest = tail p;
        in
        if isString p then
          set (fromString p) new v
        else if p == [ ] then
          new
        else
          set rest new (attrs.get.key k v);
      remove =
        p: v:
        let
          k = head p;
          rest = tail p;
        in
        if isString p then
          remove (fromString p) v
        else if p == [ ] then
          v
        else if tail == [ ] then
          attrs.key.remove k v
        else
          attrs.key.set k (remove rest v);
      over =
        p: f: v:
        set p (apply f (get p v)) v;
      extract = p: x: {
        value = get p x;
        rest = remove p x;
      };
      singleton = p: v: set p v { };
      fold = todo;
    };
  };

  merge = {
    __functor =
      _:
      let
        merge' =
          path: a: b:
          if a == null then
            b
          else if b == null then
            a

          else if isAttrs a && isAttrs b then
            foldl' (
              acc: key:
              let
                aVal = a.${key} or null;
                bVal = b.${key} or null;
                newPath = path ++ [ key ];
              in
              if aVal == null then
                acc // { ${key} = bVal; }
              else if bVal == null then
                acc // { ${key} = aVal; }
              else
                acc // { ${key} = merge' newPath aVal bVal; }
            ) { } (attrNames (a // b))

          else if isList a && isList b then
            a ++ b

          else if isFunction a && isFunction b then
            x: merge' (path ++ [ "<function>" ]) (a x) (b x)
          else if isFunction a && isAttrs b then
            x: merge' (path ++ [ "<function>" ]) (a x) b
          else if isAttrs a && isFunction b then
            x: merge' (path ++ [ "<function>" ]) a (b x)

          else if a == b then
            a

          else
            throw (
              "Cannot merge types ${typeOf a} and ${typeOf b}"
              + " with values ${toString a} and ${toString b}"
              + (if (length path) == 0 then "" else " at " + (concatStringsSep "." path))
            );
      in
      merge' [ ];

    list = foldl' merge null;

    attrs = attrs: merge.list (attrValues attrs);
  };
}
