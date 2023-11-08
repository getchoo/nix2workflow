lib: {
  self,
  platforms ? {
    "x86_64-linux" = {
      os = "ubuntu-latest";
      arch = "x64";
    };

    "aarch64-linux" = {
      os = "ubuntu-latest";
      arch = "aarch64";
    };

    "x86_64-darwin" = {
      os = "macos-latest";
      arch = "x64";
    };
  },
  ...
}: let
  platforms' =
    platforms
    // {
      fallback = lib.warn "an output in the job matrix is not supported!" {
        os = null;
        arch = null;
      };
    };

  mkMatrixMulti = systems: output:
    lib.flatten (
      lib.mapAttrsToList (
        system:
          lib.mapAttrsToList (
            attr: _: {
              inherit (platforms'.${system} or platforms'.fallback) arch os;
              attr = "${output}.${system}.${attr}";
            }
          )
      )
      (lib.getAttrs systems self.${output})
    );

  mkMatrixFlat = {
    output,
    suffix ? "",
  }:
    lib.mapAttrsToList (
      attr: deriv: {
        inherit (platforms'.${deriv.pkgs.system} or platforms'.fallback) os arch;
        attr = "${output}.${attr}${suffix}";
      }
    )
    self.${output};
in {
  inherit
    mkMatrixMulti
    mkMatrixFlat
    ;

  mkMatrix = {
    output,
    systems ? (builtins.attrNames platforms),
  }: let
    systemMatrix = mkMatrixFlat {
      inherit output;
      suffix = ".config.system.build.toplevel";
    };
  in
    {
      "nixosConfigurations" = systemMatrix;
      "darwinConfigurations" = systemMatrix;
      "homeConfigurations" = mkMatrixFlat {
        inherit output;
        suffix = ".activationPackage";
      };
    }
    .${output}
    or (mkMatrixMulti systems output);
}
