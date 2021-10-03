{ stdenv
, lib
, requireFile
, autoPatchelfHook
, makeWrapper
, makeDesktopItem
, copyDesktopItems
, fontconfig
, freetype
, libusb
, libICE
, libSM
, udev
, libX11
, libXext
, libXcursor
, libXfixes
, libXrender
, libXrandr }:

let
  architectures = {
    aarch64-linux = "arm64";
    armv7l-linux  = "arm";
    i686-linux    = "i386";
    x86_64-linux  = "x86_64";
  };

  architecture = architectures.${stdenv.hostPlatform.system};

  version = "7.54d";
  archiveVersion = "V" + builtins.replaceStrings [ "." ] [ "" ] version;

  hashes = {
    aarch64-linux = "sha256-KyCVRLlNMRstxfJSlEdRqdr8aEDIEQvVK0knY7MRzFw=";
    armv7l-linux  = "sha256-/F2mvOWod7maI+m6xHcTDd/MlNls3I3kmdD1bCYBfXM=";
    i686-linux    = "sha256-Xy9luxZCwhWh5J7vvOp2sj2yiKe7wyxeyfeZbvBGlEU=";
    x86_64-linux  = "sha256-IPLF/v92MSW1h26oft7+PDZc047EKmwJ+hsjX72LCZo=";
  };

  hash = hashes.${stdenv.hostPlatform.system};

  desktopItems = [
    (makeDesktopItem {
      name = "j-flash";
      desktopName = "SEGGER - J-Flash";
      categories = "Development;Qt;";
      exec = "JFlashExe";
      comment = "An application to program data images to the flash of a target device.";
    })
    (makeDesktopItem {
      name = "j-flash-lite";
      desktopName = "SEGGER - J-Flash Lite";
      categories = "Development;Qt;";
      exec = "JFlashLiteExe";
      comment = "Flash programming application to program data images to the flash of a target device (lite version for J-Link BASE and EDU).";
    })
    (makeDesktopItem {
      name = "j-flash-spi";
      desktopName = "SEGGER - J-Flash SPI";
      categories = "Development;Qt;";
      exec = "JFlashSPIExe";
      comment = "Flash programming application, which allows direct programming of SPI flashes, without any additional hardware.";
    })
    (makeDesktopItem {
      name = "j-link-config";
      desktopName = "SEGGER - J-Link Configurator";
      categories = "Development;Qt;HardwareSettings;";
      exec = "JLinkConfigExe";
      comment = "Allows configuration of USB identification as well as TCP/IP identification of J-Link.";
    })
    (makeDesktopItem {
      name = "j-link-gdb-server";
      desktopName = "SEGGER - J-Link GDB Server";
      categories = "Development;Debugger;Qt;";
      exec = "JLinkGDBServer";
      comment = "A remote server for GDB making it possible for GDB to connect to and communicate with the target device via J-Link.";
    })
    (makeDesktopItem {
      name = "j-link-license-manager";
      desktopName = "SEGGER - J-Link License Manager";
      categories = "Development;Qt;";
      exec = "JLinkLicenseManager";
    })
    (makeDesktopItem {
      name = "j-link-rtt-viewer";
      desktopName = "SEGGER - J-Link RTT Viewer";
      categories = "Development;Debugger;Monitor;Qt;";
      exec = "JLinkRTTViewerExe";
    })
    (makeDesktopItem {
      name = "j-link-registration";
      desktopName = "SEGGER - JLink Registration";
      categories = "Development;Qt;";
      exec = "JLinkRegistration";
    })
    (makeDesktopItem {
      name = "j-link-remote-server";
      desktopName = "SEGGER - J-Link Remote Server";
      categories = "Development;Qt;";
      exec = "JLinkRemoteServer";
      comment = "Utility which provides the possibility to use J-Link / J-Trace remotely via TCP/IP.";
    })
    (makeDesktopItem {
      name = "j-link-swo-viewer";
      desktopName = "SEGGER - J-Link SWO Viewer";
      categories = "Development;Debugger;Monitor;Qt;";
      exec = "JLinkSWOViewer";
      comment = "Displays the terminal output of the target using the SWO pin.";
    })
    (makeDesktopItem {
      name = "j-mem";
      desktopName = "SEGGER - J-Mem";
      categories = "Development;Debugger;Monitor;Qt;";
      exec = "JMemExe";
      comment = "Application to display and modify the RAM and SFRs (Special Function Registers) of target systems while the target is running.";
    })
  ];
in

stdenv.mkDerivation rec {
  pname = "j-link";
  inherit version;

  src = requireFile {
    name = "JLink_Linux_${archiveVersion}_${architecture}.tgz";
    url = "https://www.segger.com/downloads/jlink#J-LinkSoftwareAndDocumentationPack";
    sha256 = hash;
  };

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  preferLocalBuild = true;

  nativeBuildInputs = [ copyDesktopItems autoPatchelfHook makeWrapper ];

  buildInputs = [
    udev stdenv.cc.cc.lib
    fontconfig freetype libICE libSM
    libX11 libXext libXcursor libXfixes libXrender libXrandr
  ];

  runtimeDependencies = [ udev ];

  inherit desktopItems;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/JLink" "$out/share/doc" "$out/bin"

    cp -R * "$out/lib/JLink"
    rm "$out/lib/JLink/99-jlink.rules"

    for f in "$out/lib/JLink"/J*; do
        if [[ -L $f ]]; then
            mv "$f" "$out/bin/"
        elif [[ -x $f ]]; then
            makeWrapper "$f" "$out/bin/$(basename "$f")"
        fi
    done

    mv "$out/lib/JLink/Doc" "$out/share/doc/JLink"
    mv \
        "$out/lib/JLink"/README* \
        "$out/lib/JLink/Samples" \
        "$out/lib/JLink/GDBServer"/Readme* \
        "$out/share/doc/JLink/"

    install -D -t "$out/lib/udev/rules.d" 99-jlink.rules

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
  };
}
