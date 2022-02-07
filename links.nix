with builtins;
{ pkgs, lib, config, ...}:
  let
    l = lib; p = pkgs; t = l.types;
    annotated = import ./annotated.nix p;
    augment = import ./augment.nix l;
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
      }
      // augment
           { options =
               { links =
                   l.mkOption
                     { type = t.submodule { options = conversion-options; };
                       default = {};
                     };
               };
           };

    config =
      { system.activationScripts =
          l.mapAttrs'
            (unescaped-path: value:
               let
                 path = l.escapeShellArg unescaped-path;
                 dir = l.escapeShellArg (dirOf unescaped-path);
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
                       mkdir -p ${dir}
                     fi

                     ln -s ${target} ${path}
                     ''
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
            ((make-annotated (removeAttrs config.links [ "annotated" "users" ]))
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
                           (make-annotated cfg.links)
                      )
                      config.users.users
                   )
                )
            );
      };
  }
