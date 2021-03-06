A Nix [flake](https://nixos.wiki/wiki/Flakes) for
[SEGGER J-Link](https://www.segger.com/downloads/jlink/).

The package version is automatically updated daily.

# Usage

In addition to the `j-link` package and app, this Flake provides a
NixOS module that installs the package and sets up the USB device 
permissions.

```nix
{
  inputs.j-link.url = "github:liff/j-link-flake";

  outputs = { self, nixpkgs, j-link }: {
    # replace 'joes-desktop' with your hostname here.
    nixosConfigurations.joes-desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # …
        j-link.nixosModule
      ];
    };
  };
}
```

# Note on unfree packages

Due to limitations of flakes, this flake enables `config.allowUnfree`
on its import of nixpkgs, meaining that packages can be built without
otherwise enabling unfree software.
