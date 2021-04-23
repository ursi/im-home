{ pkgs, lib, config, ...}:
  let
    b = builtins; l = lib; p = pkgs; t = l.types;
    annotated = import ./annotated.nix p;
    null-or = import ./null-or.nix p;

    formats =
      { ini = p.formats.ini {};
        json = p.formats.json {};
        toml = p.formats.toml {};
        yaml = p.formats.yaml {};
      };

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
             str = p.writeText "str";
           };

    path-set = type:
      t.addCheck
        (t.attrsOf type)
        (set: b.all t.path.check (b.attrNames set))
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
      { links =
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

        users.users =
          l.mkOption
            { type =
                t.attrsOf
                  (t.submodule
                     { options =
                         { links =
                             l.mkOption
                               { type = t.submodule { options = conversion-options; };
                                 default = {};
                               };
                         };
                     }
                  );
            };
      };

    config =
      { system.activationScripts =
          l.mapAttrs'
            (unescaped-path: value:
               let
                 path = l.escapeShellArg unescaped-path;
                 dir = l.escapeShellArg (b.dirOf unescaped-path);
                 target =
                   l.mapNullable
                     (v: conversions.${v.type}.convert v.value)
                     value;
               in
               l.nameValuePair
                 "nixos-links: ${unescaped-path}"
                 ''
                 ${p.trash-cli}/bin/trash-put -f ${path}

                 if [[ ! -e ${dir} ]]; then
                   mkdir -p ${dir}
                 fi

                 ${if target != null then
                     "ln -s ${target} ${path}"
                   else
                     ""
                 }
                 ''
            )
            config.links.annotated;

        links.annotated =
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
            ((make-annotated (b.removeAttrs config.links [ "annotated" "users" ]))
             ++ (b.concatLists
                   (l.mapAttrsToList
                      (user: cfg:
                         b.map
                           (l.mapAttrs'
                              (path: v:
                                 l.nameValuePair
                                   (config.users.users.${user}.home + path)
                                   v
                              )
                           )
                           (make-annotated cfg.links)
                      )
                      config.users.users
                   )
                )
            );
      };
  }
