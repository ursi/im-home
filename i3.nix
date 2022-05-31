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
               { im-home.i3 =
                   l.mkOption
                     { type =
                         t.nullOr
                           (t.submodule
                              { options =
                                  { backlight-adjust-percent =
                                      l.mkOption
                                        { type = t.nullOr (t.either t.int t.float);
                                          default = null;
                                        };

                                    font =
                                      { font =
                                          l.mkOption
                                            { type = t.str;
                                              default = "pango:monospace";
                                            };

                                        size =
                                          l.mkOption
                                            { type = t.either t.int t.float;
                                              default = 8;
                                            };
                                      };

                                    extra-config =
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
               let cfg = config.im-home.i3; in
               l.mkIf (cfg != null)
                 { lines."/.config/i3/config" =
                     let
                       bap = cfg.backlight-adjust-percent;
                       bctl = "${p.brightnessctl}/bin/brightnessctl";
                     in
                     ''
                     font ${cfg.font.font} ${toString cfg.font.size}px

                     ${if bap != null then
                         ''
                         bindcode 232 exec --no-startup-id ${bctl} set ${toString bap}%-
                         bindcode 233 exec --no-startup-id ${bctl} set ${toString bap}%+
                         ''
                       else
                         ""
                     }

                     ${if cfg.extra-config != null then
                         cfg.extra-config
                       else
                         ""
                     }
                     '';
                 };
           }
        );
  }
