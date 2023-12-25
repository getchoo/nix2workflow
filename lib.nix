lib: {platforms ? null}: let
  defaultPlatforms = {
    x86_64-linux = {
      os = "ubuntu-latest";
      arch = "x64";
    };

    aarch64-linux = {
      os = "ubuntu-latest";
      arch = "aarch64";
    };

    x86_64-darwin = {
      os = "macos-latest";
      arch = "x64";
    };
  };

  platforms' =
    if platforms != null
    then platforms
    else defaultPlatforms;

  fallback = lib.warn "an output in the job matrix is not supported!" {
    os = null;
    arch = null;
  };

  platformNames = lib.attrNames platforms';

  findSystem = deriv: deriv.system or deriv.pkgs.system or deriv.activationPackage.system;
in {
  mkMatrix = {
    root,
    output,
    systems ? platformNames,
  }:
    lib.flatten (
      lib.mapAttrsToList (
        system:
          lib.mapAttrsToList (
            attr: _: {
              inherit (platforms'.${system} or fallback) arch os;
              attr = "${output}.${system}.${attr}";
            }
          )
      )
      (lib.filterAttrs (system: _: lib.elem system systems) root.${output})
    );

  mkMatrix' = {
    root,
    output,
    systems ? platformNames,
  }:
    lib.flatten (
      lib.mapAttrsToList (
        attr: deriv: let
          system = findSystem deriv;
        in {
          inherit (platforms'.${system} or fallback) arch os;
          attr = "${output}.${attr}";
        }
      )
      (
        lib.filterAttrs (
          _: deriv: builtins.elem (findSystem deriv) systems
        )
        root.${output}
      )
    );
}
