{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    call-flake.url = "github:divnix/call-flake";

    parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = {
    parts,
    call-flake,
    ...
  } @ inputs:
    parts.lib.mkFlake {inherit inputs;} {
      imports = [(call-flake ../../.).flakeModule];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      githubWorkflowGenerator.exclude = [
        "packages.x86_64-linux.otherHello"
      ];

      perSystem = {pkgs, ...}: {
        devShells.default = pkgs.mkShell {
          packages = [pkgs.hello];
        };

        packages = {
          inherit (pkgs) hello;
          otherHello = pkgs.hello;
          default = pkgs.hello;
        };
      };
    };
}
