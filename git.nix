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
               { im-home.git =
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

             config.im-home.links =
               let cfg = config.im-home.git; in
               l.mkIf (cfg != null)
                 { ini."/.gitconfig" = cfg.config;
                   lines."/.config/git/ignore" = cfg.ignore;
                 };
           }
        );
  }
