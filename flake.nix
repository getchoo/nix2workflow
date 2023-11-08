{
  description = "generate github matrices with nix!";

  inputs.nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";

  outputs = {
    self,
    nixpkgs-lib,
    ...
  }: {
    lib = import ./lib.nix nixpkgs-lib.lib;
    flakeModule = import ./module.nix self.lib;
  };
}
