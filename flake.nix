{
  description = "SEGGER J-Link";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) genAttrs;

      systems = [ "i686-linux" "x86_64-linux" "armv7l-linux" "aarch64-linux" ];

      packages = genAttrs systems (system: {
        j-link = (import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        }).j-link;
      });

    in {
      inherit packages;

      defaultPackage = genAttrs systems (system: packages."${system}".j-link);

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

      overlay = final: prev: {
        j-link = final.callPackage ./pkgs/j-link {};
      };

      nixosModule = { pkgs, ... }: {
        nixpkgs.overlays = [ self.overlay ];
        services.udev.packages = [ pkgs.j-link ];
        environment.systemPackages = [ pkgs.j-link ];
      };
    };
}
