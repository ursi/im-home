{ outputs = _:
    { nixosModules =
        { git = ./git.nix;
          i3 = ./i3.nix;
          icons = ./icons.nix;
          links = ./links.nix;
        };
    };
}
