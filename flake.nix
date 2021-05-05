{ outputs = _:
    { nixosModules =
        { git = ./git.nix;
          icons = ./icons.nix;
          links = ./links.nix;
        };
    };
}
