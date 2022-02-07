{ lib, pkgs, ... }:
  let
    l = lib; p = pkgs; t = l.types;
    augment = import ./augment.nix l;
    ini = p.formats.ini {};
  in
  { imports = [ ./links.nix ];

    options =
      augment
        ({ config, ... }:
           { options =
               { git =
                   l.mkOption
                     { type =
                         t.nullOr
                           (t.submodule
                              { options =
                                  { config =
                                      l.mkOption
                                        { type = t.nullOr ini.type;
                                          default = null;
                                        };

                                    ignore =
                                      l.mkOption
                                        { type = t.nullOr t.lines;
                                          default = null;
                                        };
                                  };
                              }
                           );

                       default = null;
                     };
               };

             config.links =
               l.mkIf (config.git != null)
                 { ini."/.gitconfig" = config.git.config;
                   lines."/.config/git/ignore" = config.git.ignore;
                 };
           }
        );
  }
