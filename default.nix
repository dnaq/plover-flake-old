{ pkgs ? import <nixpkgs> {}, sources }:
let
  pyqt5 = pkgs.python3Packages.pyqt5.override { withMultimedia = true; };
  hidapi = with pkgs; with python3Packages; buildPythonPackage rec {
    pname = "hidapi";
    version = "0.11.0.post2";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-2oFeDR1LLvHrvMhQNFchBdyilifrYYgTN6o5AQ8u+Ms=";
    };

    nativeBuildInputs = lib.optionals stdenv.isDarwin [ xcbuild ];

    propagatedBuildInputs = [ cython ]
      ++ lib.optionals stdenv.isLinux [ pkgs.libusb1 udev ]
      ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [ AppKit CoreFoundation IOKit ]);

    # Fix the USB backend library lookup
    postPatch = lib.optionalString stdenv.isLinux ''
      libusb=${pkgs.libusb1.dev}/include/libusb-1.0
      test -d $libusb || { echo "ERROR: $libusb doesn't exist, please update/fix this build expression."; exit 1; }
      sed -i -e "s|/usr/include/libusb-1.0|$libusb|" setup.py
    '';

    pythonImportsCheck = [ "hid" ];

    meta = with lib; {
      description = "A Cython interface to the hidapi from https://github.com/libusb/hidapi";
      homepage = "https://github.com/trezor/cython-hidapi";
      # license can actually be either bsd3 or gpl3
      # see https://github.com/trezor/cython-hidapi/blob/master/LICENSE-orig.txt
      license = with licenses; [ bsd3 gpl3Only ];
      maintainers = with maintainers; [ np prusnak ];
    };
  };
  path = with pkgs.python3Packages; buildPythonPackage rec {
    pname = "path";
    version = "16.2.0";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Lekl6NQh+TvOqA1RG4Gsz7an5rJJr6SlVZVXsM+BcJc=";
    };
    checkInputs = [ pytest ];
  };

  requests-futures = with pkgs.python3Packages; buildPythonPackage rec {
    pname = "requests-futures";
    version = "1.0.0";
    disabled = pythonOlder "3.3";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0j611g1wkn98qp2b16kqz7lfz29a153jyfm02r3h8n0rpw17am1m";
    };

    propagatedBuildInputs = [ requests ];

    doCheck = false;

    pythonImportsCheck = [ "requests_futures" ];
  };
  plover-stroke = with pkgs.python3Packages; buildPythonPackage rec {
    pname = "plover_stroke";
    version = "1.0.0";
    disabled = pythonOlder "3.3";

    src = sources.plover-stroke;

    doCheck = false;
  };
  rtf-tokenize = with pkgs.python3Packages; buildPythonPackage rec {
    pname = "rtf-tokenize";
    version = "1.0.0";
    disabled = pythonOlder "3.3";

    src = sources.rtf-tokenize;

    doCheck = false;
  };
  plover-dict-commands = with pkgs.python3Packages; buildPythonPackage rec {
    pname = "plover_dict_commands";
    version = "0.2.5";
    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-ki/M5V106YbQMjZQmkTNyBzFboVYi/x0hkLAXqPyk8Q=";
    };
    buildInputs = [ plover setuptools-scm ];
    doCheck = false;
  };

  plover = with pkgs.python3Packages; pkgs.qt5.mkDerivationWith buildPythonPackage rec {
    pname = "plover";
    version = "master";

    src = sources.plover;

    checkInputs = [ pytest mock ];
    propagatedBuildInputs = [
      Babel
      pyqt5
      xlib
      pyserial
      appdirs
      wcwidth
      setuptools
      certifi
      plover-stroke
      rtf-tokenize
      hid
    ];

    dontWrapQtApps = true;

    preFixup = ''
      makeWrapperArgs+=("''${qtWrapperArgs[@]}")
    '';

    doCheck = false;
  };

  plugins-manager = with pkgs.python3Packages; buildPythonPackage rec {
    pname = "plover-plugins-manager";
    version = "master";

    src = sources.plover-plugins-manager;

    patches = [ ./plover-plugins-manager.patch ];

    buildInputs = [ plover ];

    propagatedBuildInputs = [
      pip
      pkginfo
      pygments
      readme_renderer
      requests
      requests-cache
      requests-futures
      setuptools
      wheel
    ];
    checkInputs = [ path pytest ];

    doCheck = false;
  };
  spyll = with pkgs; with python3Packages; buildPythonPackage rec {
    pname = "spyll";
    version = "1.2.3";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-g2ieAtU2+1FMY3jUWAH3KprefrtQMejyGn6KM7T5Av8=";
    };
  };
  spylls = with pkgs; with python3Packages; buildPythonPackage rec {
    pname = "spylls";
    version = "0.1.7";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-cEWJLcvTJNNoX2nFp2AGPnj7g5kTckzhgHfPCgyT8iA=";
    };
    
    propagatedBuildInputs = [ spyll ];
  };
  plover2cat = with pkgs.python3Packages; pkgs.qt5.mkDerivationWith buildPythonPackage rec {
    pname = "plover2cat";
    version = "master";
    src = sources.plover2cat;
    buildInputs = [ plover ];
    propagatedBuildInputs = [
      odfpy
      pyparsing
      plover-dict-commands
      spylls
      dulwich
    ];
    dontWrapQtApps = true;
    doCheck = false;

    preFixup = ''
      makeWrapperArgs+=("''${qtWrapperArgs[@]}")
    '';
  };
  plover-with-plugins = plover.overrideAttrs (old: rec {
    pname = "plover-with-plugins";
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.python3Packages.setuptools plugins-manager plover2cat ];

    permitUserSite = true;
  });
in
 plover-with-plugins
