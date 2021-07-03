{ pkgs, lib, ...}:
  let
    l = lib; p = pkgs; t = l.types;
    augment = import ./augment.nix l;
  in
  { imports = [ ./links.nix ];

    options =
      augment
        ({ config, ... }:
           { options =
               { i3 =
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

             config.links =
               let cfg = config.i3; in
               l.mkIf (cfg != null)
                 { lines."/.config/i3/config" =
                     let
                       bap = cfg.backlight-adjust-percent;
                       bctl = "${p.brightnessctl}/bin/brightnessctl";
                     in
                     ''
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
