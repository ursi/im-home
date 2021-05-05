l: module:
  let t = l.types; in
  { users.users = l.mkOption { type = t.attrsOf (t.submodule module); }; }
