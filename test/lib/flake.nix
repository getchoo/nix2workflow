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

    forAllSystems = fn: lib.genAttrs systems (sys: fn nixpkgs.legacyPackages.${sys});
    workflow = (call-flake ../../.).lib {inherit self;};
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = [pkgs.hello];
      };
    });

    packages = forAllSystems (pkgs: {
      inherit (pkgs) hello;
      default = pkgs.hello;
    });

    githubWorkflow = let
      outputs = ["packages" "devShells"];
      jobs = lib.concatLists (
        map (
          output: workflow.mkMatrix {inherit output;}
        )
        outputs
      );
    in {
      matrix.include = jobs;
    };
  };
}
