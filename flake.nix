{
  description = "SEGGER J-Link";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) genAttrs;

      systems = [ "i686-linux" "x86_64-linux" "armv7l-linux" "aarch64-linux" ];

      packages = genAttrs systems (system:
        let j-link = (import nixpkgs {
                  inherit system;
                  overlays = [ self.overlays.default ];
                  config.allowUnfree = true;
                }).j-link;
        in { inherit j-link; default = j-link; });

      overlay = final: prev: {
        j-link = final.callPackage ./pkgs/j-link {};
      };

      nixosModule = { pkgs, ... }: {
        nixpkgs.overlays = [ self.overlays.default ];
        services.udev.packages = [ pkgs.j-link ];
        environment.systemPackages = [ pkgs.j-link ];
      };

    in {
      inherit packages overlay nixosModule;

      nixosModules.default = nixosModule;

      overlays.default = overlay;

      apps =
        genAttrs systems (system:
          let
            mkApp = program: {
              type = "app";
              program = "${packages.${system}.j-link}/bin/${program}";
            };
          in {
            j-flash = mkApp "JFlashExe";
            j-flash-lite = mkApp "JFlashLiteExe";
            j-flash-spi = mkApp "JFlashSPIExe";
            j-link-config = mkApp "JFlashLinkConfigExe";
            j-link-gdb-server = mkApp "JLinkGDBServer";
            j-link-license-manager = mkApp "JLinkLicenseManager";
            j-link-rtt-viewer = mkApp "JLinkRTTViewerExe";
            j-link-registration = mkApp "JLinkRegistration";
            j-remote-server = mkApp "JLinkRemoteServer";
            j-swo-viewer = mkApp "JLinkSWOViewer";
            j-mem = mkApp "JMemExe";
          });

    };
}
