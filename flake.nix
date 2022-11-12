{
  description = "tiny flake for hid_bootloader_cli";
  inputs = {
      nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
      flake-utils.url = "github:numtide/flake-utils";
      plover = { url = "github:openstenoproject/plover"; flake = false; };
      plover-plugins-manager = { url = "github:benoit-pierre/plover_plugins_manager"; flake = false; };
      plover-stroke = { url = "github:benoit-pierre/plover_stroke"; flake = false; };
      rtf-tokenize = { url = "github:benoit-pierre/rtf_tokenize"; flake = false; };
      plover2cat = { url = "github:greenwyrt/plover2CAT"; flake = false; };
  };
  

  outputs = { self, nixpkgs, flake-utils, ... }@attrs:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
          sources = { inherit (attrs) plover plover-plugins-manager plover-stroke rtf-tokenize plover2cat; };
      in
      {
        packages = rec {
            plover = import ./default.nix { inherit pkgs sources; };
            default = plover;
        };
        apps.default = {
            type = "app";
            program = "${self.packages."${system}".plover}/bin/plover";
        };
      }
    );
}
