{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    call-flake.url = "github:divnix/call-flake";
  };

  outputs = {
    self,
    nixpkgs,
    call-flake,
    ...
  }: let
    inherit (nixpkgs) lib;

    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forSystem = system: fn: fn nixpkgs.legacyPackages.${system};
    forAllSystems = fn: lib.genAttrs systems (sys: forSystem sys fn);
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = [pkgs.hello];
      };
    });

    flatPackages = forSystem "x86_64-linux" ({hello, ...}: {inherit hello;});

    packages = forAllSystems (pkgs: {
      inherit (pkgs) hello;
      default = pkgs.hello;
    });

    workflowMatrix = let
      platforms = {
        x86_64-linux = {
          os = "ubuntu-latest";
          arch = "x64";
        };

        aarch64-linux = {
          os = "ubuntu-latest";
          arch = "aarch64";
        };
      };

      inherit ((call-flake ../../.).lib {inherit platforms;}) mkMatrix mkMatrix';

      jobs = lib.flatten (
        (mkMatrix' {
          root = self;
          output = "flatPackages";
        })
        ++ (mkMatrix {
          root = self;
          output = "packages";
        })
      );
    in {
      include = jobs;
    };
  };
}
