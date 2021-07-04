{ outputs = _:
    { nixosModules =
        { git = ./git.nix;
          i3 = ./i3.nix;
          i3status = ./i3status.nix;
          icons = ./icons.nix;
          links = ./links.nix;
        };
    };
}
