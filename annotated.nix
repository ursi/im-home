with builtins;
pkgs:
  let
    l = p.lib; p = pkgs; t = l.types;
    formats = import ./formats.nix p;

    # we need to use strings so we can check for equality
    get-type = type-str:
      if formats?${type-str} then
        formats.${type-str}.type
      else if t?${type-str} then
        t.${type-str}
      else
        null;
  in
  l.mkOptionType
    { name = "annotated";
      check = a:
        if a?value && a?type then
          let type = get-type a.type; in
          if type != null then
            type.check a.value
          else
            false
        else
          false;

      merge = loc: defs:
        let
          type-str = (head defs).value.type;
          type = get-type type-str;
        in
        if all (a: a.value.type == type-str) defs then
          if type != null then
            { value =
                type.merge
                  loc
                  (map
                     (d: d // { value = d.value.value; })
                     defs
                  );

              type = type-str;
            }
          else
            throw "this should never happen because of 'check'"
        else
          throw "Not all the types for ${concatStringsSep "." loc} are the same.";
    }
