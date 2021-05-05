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
               { icons =
                   l.mkOption
                     { type =
                         t.nullOr
                           (t.submodule
                              { options =
                                  { cursor =
                                      l.mkOption
                                        { type = t.nullOr t.package;
                                          default = null;
                                        };
                                  };
                              }
                           );

                       default = null;
                     };
               };

             config.links =
               l.mkIf (config.icons != null)
                 (let bindCursor = f: l.mapNullable f config.icons.cursor; in
                  { ini =
                      { "/.config/gtk-3.0/settings.ini" =
                          bindCursor
                            (cursor:
                               { Settings =
                                   { gtk-cursor-theme-name = cursor.name; };
                               }
                            );

                        "/.local/share/icons/default/index.theme" =
                           bindCursor
                             (cursor:
                                { "icon theme" = { Inherits = cursor.name; }; }
                             );
                      };

                    package =
                      let inherit (config.icons) cursor; in
                      if cursor != null then
                        { "/.local/share/icons/${cursor.name}" = cursor; }
                      else
                        {};
                  }
                 );
           }
        );
  }
