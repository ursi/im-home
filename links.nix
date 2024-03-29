with builtins;
{ config, lib, pkgs, ... }:
  let
    l = lib; p = pkgs; t = l.types;
    annotated = import ./annotated.nix p;
    augment = import ./augment.nix l;
    null-or = import ./null-or.nix p;
    formats = import ./formats.nix p.formats;

    conversions =
      l.mapAttrs
        (format: v:
           { convert = v.generate format;
             type = v.type;
           }
        )
        formats
      // l.mapAttrs
           (type: convert:
              { inherit convert;
                type = t.${type};
              }
           )
           { lines = p.writeText "lines";
             package = l.id;
             path = l.id;
             str = p.writeText "str";
           };

    path-set = type:
      t.addCheck
        (t.attrsOf type)
        (set: all t.path.check (attrNames set))
      // { description = "set of ${type.name} with attributes that are paths"; };

    conversion-options =
      l.mapAttrs
        (type: v:
           l.mkOption
             { type = path-set (null-or v.type);
               default = {};
             }
        )
        conversions;
  in
  { options =
      { im-home.links =
          l.mkOption
            { type =
                t.submodule
                  { options =
                      { annotated =
                          l.mkOption
                            { type = path-set (null-or annotated);
                              default = {};
                            };
                      }
                      // conversion-options;
                  };

              default = {};
            };
      }
      // augment
           { options =
               { im-home.links =
                   l.mkOption
                     { type = t.submodule { options = conversion-options; };
                       default = {};
                     };
               };
           };

    config =
      { system.activationScripts =
          let
            home-name-list =
              l.mapAttrsToList
                (_: v: { inherit (v) home name; })
                config.users.users;
          in
          l.mapAttrs'
            (unescaped-path: value:
               let
                 unescaped-dir = dirOf unescaped-path;
                 path = l.escapeShellArg unescaped-path;
                 dir = l.escapeShellArg unescaped-dir;

                 user =
                   let
                     f = ls:
                       if length ls == 0 then
                         ""
                       else
                         let inherit (head ls) home name; in
                         if l.hasPrefix home unescaped-dir then
                           "-u ${l.escapeShellArg name}"
                         else
                           f (tail ls);
                   in
                   f home-name-list;

                 target =
                   l.mapNullable
                     (v: conversions.${v.type}.convert v.value)
                     value;
               in
               l.nameValuePair
                 "nixos-links: ${unescaped-path}"
                 ''
                 ${p.trash-cli}/bin/trash-put -f ${path}

                 ${if target != null then
                     ''
                     if [[ ! -e ${dir} ]]; then
                       ${p.sudo}/bin/sudo ${user} mkdir -p ${dir}
                     fi

                     ln -s ${target} ${path}
                     ''
                   else
                     ""
                 }
                 ''
            )
            config.im-home.links.annotated;

        im-home.links.annotated =
          let
            make-annotated =
              l.mapAttrsToList
                (type: path-set:
                   l.mapAttrs
                     (_: l.mapNullable (value: { inherit type value; }))
                     path-set
                );
          in
          l.mkMerge
            ((make-annotated (removeAttrs config.im-home.links [ "annotated" ]))
             ++ (concatLists
                   (l.mapAttrsToList
                      (user: cfg:
                         map
                           (l.mapAttrs'
                              (path: v:
                                 l.nameValuePair
                                   (config.users.users.${user}.home + path)
                                   v
                              )
                           )
                           (make-annotated cfg.im-home.links)
                      )
                      config.users.users
                   )
                )
            );
      };
  }
