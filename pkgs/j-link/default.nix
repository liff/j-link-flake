{ stdenv
, lib
, requireFile
, autoPatchelfHook
, makeWrapper
, makeDesktopItem
, copyDesktopItems
, fontconfig
, freetype
, libICE
, libSM
, icu63
, udev
, libX11
, libXext
, libXcursor
, libXfixes
, libXrender
, libXrandr }:

let
  seggerPackages = import ../../data/packages.nix;
  inherit (seggerPackages) version systems;

  hash = systems.${stdenv.hostPlatform.system}.hash;
  url = systems.${stdenv.hostPlatform.system}.url;
  archiveFilename = systems.${stdenv.hostPlatform.system}.filename;

  desktopItems = [
    (makeDesktopItem {
      name = "j-flash";
      desktopName = "SEGGER - J-Flash";
      categories = [ "Development" "Qt" ];
      exec = "JFlashExe";
      comment = "An application to program data images to the flash of a target device.";
    })
    (makeDesktopItem {
      name = "j-flash-lite";
      desktopName = "SEGGER - J-Flash Lite";
      categories = [ "Development" "Qt" ];
      exec = "JFlashLiteExe";
      comment = "Flash programming application to program data images to the flash of a target device (lite version for J-Link BASE and EDU).";
    })
    (makeDesktopItem {
      name = "j-flash-spi";
      desktopName = "SEGGER - J-Flash SPI";
      categories = [ "Development" "Qt" ];
      exec = "JFlashSPIExe";
      comment = "Flash programming application, which allows direct programming of SPI flashes, without any additional hardware.";
    })
    (makeDesktopItem {
      name = "j-link-config";
      desktopName = "SEGGER - J-Link Configurator";
      categories = [ "Development" "Qt" "HardwareSettings" ];
      exec = "JLinkConfigExe";
      comment = "Allows configuration of USB identification as well as TCP/IP identification of J-Link.";
    })
    (makeDesktopItem {
      name = "j-link-gdb-server";
      desktopName = "SEGGER - J-Link GDB Server";
      categories = [ "Development" "Debugger" "Qt" ];
      exec = "JLinkGDBServer";
      comment = "A remote server for GDB making it possible for GDB to connect to and communicate with the target device via J-Link.";
    })
    (makeDesktopItem {
      name = "j-link-license-manager";
      desktopName = "SEGGER - J-Link License Manager";
      categories = [ "Development" "Qt" ];
      exec = "JLinkLicenseManager";
    })
    (makeDesktopItem {
      name = "j-link-rtt-viewer";
      desktopName = "SEGGER - J-Link RTT Viewer";
      categories = [ "Development" "Debugger" "Monitor" "Qt" ];
      exec = "JLinkRTTViewerExe";
    })
    (makeDesktopItem {
      name = "j-link-registration";
      desktopName = "SEGGER - JLink Registration";
      categories = [ "Development" "Qt" ];
      exec = "JLinkRegistration";
    })
    (makeDesktopItem {
      name = "j-link-remote-server";
      desktopName = "SEGGER - J-Link Remote Server";
      categories = [ "Development" "Qt" ];
      exec = "JLinkRemoteServer";
      comment = "Utility which provides the possibility to use J-Link / J-Trace remotely via TCP/IP.";
    })
    (makeDesktopItem {
      name = "j-link-swo-viewer";
      desktopName = "SEGGER - J-Link SWO Viewer";
      categories = [ "Development" "Debugger" "Monitor" "Qt" ];
      exec = "JLinkSWOViewer";
      comment = "Displays the terminal output of the target using the SWO pin.";
    })
    (makeDesktopItem {
      name = "j-mem";
      desktopName = "SEGGER - J-Mem";
      categories = [ "Development" "Debugger" "Monitor" "Qt" ];
      exec = "JMemExe";
      comment = "Application to display and modify the RAM and SFRs (Special Function Registers) of target systems while the target is running.";
    })
  ];
in

stdenv.mkDerivation rec {
  pname = "j-link";
  inherit version;

  src = requireFile {
    name = archiveFilename;
    url = "https://www.segger.com/downloads/jlink#J-LinkSoftwareAndDocumentationPack";
    sha256 = hash;
  };

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  preferLocalBuild = true;

  nativeBuildInputs = [ copyDesktopItems autoPatchelfHook makeWrapper ];

  buildInputs = [
    icu63 udev stdenv.cc.cc.lib
    fontconfig freetype libICE libSM
    libX11 libXext libXcursor libXfixes libXrender libXrandr
  ];

  runtimeDependencies = [ icu63 udev ];

  inherit desktopItems;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/JLink $out/share/doc $out/bin

    install --directory $out/lib/udev/rules.d
    mv 99-jlink.rules $out/lib/udev/rules.d/

    mv * $out/lib/JLink

    for f in $out/lib/JLink/*; do
        name=$(basename $f)
        if [[ ! $name =~ ^lib ]]; then
            if [[ -L $f ]]; then
                mv $f $out/bin/
            elif [[ -f $f && -x $f ]]; then
                makeWrapper $f $out/bin/$name
            fi
        fi
    done

    mv $out/lib/JLink/Doc $out/share/doc/JLink
    mv \
        $out/lib/JLink/README* \
        $out/lib/JLink/Samples \
        $out/lib/JLink/GDBServer/Readme* \
        $out/share/doc/JLink/


    runHook postInstall
  '';

  preFixup = ''
    patchelf --add-needed libudev.so.1 $out/lib/JLink/libjlinkarm.so
  '';

  meta = with lib; {
    homepage = "https://www.segger.com/downloads/jlink";
    description = "SEGGER J-Link";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = with maintainers; [ liff ];
    mainProgram = "JLinkExe";
  };
}
