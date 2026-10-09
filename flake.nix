{
  description = "Nix flake and NixOS module for Strata (Qwen3.8-Flash-Next 125B inference engine by Niko1221)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };

        strataP40 = pkgs.callPackage ./package.nix {
          cudaArch = "61";
          experimentalSm60 = true;
        };

        strataGeneric = pkgs.callPackage ./package.nix {
          cudaArch = "61;70;75;80;86;89";
          experimentalSm60 = true;
        };
      in
      {
        packages = {
          default = strataP40;
          strata-inference = strataGeneric;
          strata-inference-p40 = strataP40;
          strata-engine = strataGeneric;
          strata-engine-p40 = strataP40;
        };

        apps.default = {
          type = "app";
          program = "${strataP40}/bin/strata-inference";
        };
      }
    )
    // {
      nixosModules = {
        default = import ./modules/strata-inference.nix;
        strata-inference = import ./modules/strata-inference.nix;
      };

      overlays.default = final: prev: {
        strata-inference = self.packages.${prev.stdenv.hostPlatform.system}.default;
        strata-inference-p40 = self.packages.${prev.stdenv.hostPlatform.system}.strata-inference-p40;
      };
    };
}
