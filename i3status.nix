with builtins;
{ lib, pkgs, ... }:
  let
    l = lib; p = pkgs; t = l.types;
    augment = import ./augment.nix l;
  in
  { imports = [ ./links.nix ];

    options =
      augment
        ({ config, ... }:
           { options =
               { im-home.i3status =
                   l.mkOption
                     { type =
                         t.nullOr
                           (t.submodule
                              { options =
                                  { output-format =
                                      l.mkOption
                                        { type = t.str;
                                          default = "i3bar";
                                        };

                                    status-bar =
                                      l.mkOption
                                        { type =
                                            t.listOf
                                              (t.submodule
                                                 { options =
                                                     { name = l.mkOption { type = t.str; };

                                                       config =
                                                         l.mkOption
                                                           { type = t.attrsOf t.str; };
                                                     };
                                                 }
                                              );

                                          default = [];
                                        };
                                  };
                              }
                           );

                       default = null;
                     };
               };

             config.im-home.links =
               let cfg = config.im-home.i3status; in
               l.mkIf (cfg != null)
                 { lines."/.config/i3status/config" =
                     ''
                     general {
                         output_format = "${cfg.output-format}"
                     }

                     ${concatStringsSep "\n"
                         (map (module: ''order += "${module.name}"'') cfg.status-bar)
                     }

                     ${concatStringsSep "\n"
                         (map
                            (module:
                               ''
                               ${module.name} {
                                 ${concatStringsSep "\n"
                                     (l.mapAttrsToList
                                        (n: v: ''${n} = "${v}"'')
                                        module.config
                                     )
                                 }
                               }
                               ''
                            )
                            cfg.status-bar
                         )
                     }
                     '';
                 };
           }
        );
  }
