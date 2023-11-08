workflowLib': {
  config,
  lib,
  self,
  ...
}: let
  cfg = config.githubWorkflowGenerator;

  inherit
    (builtins)
    attrNames
    elem
    ;

  inherit
    (lib)
    filter
    getAttrs
    mapAttrsToList
    mdDoc
    mkOption
    literalExpression
    types
    ;

  workflowLib = workflowLib' (
    {inherit self;}
    // lib.mkIf (cfg.platforms != {}) {
      inherit (cfg) platforms;
    }
  );

  supportedOutputs = [
    "apps"
    "checks"
    "devShells"
    "darwinConfigurations"
    "homeConfigurations"
    "nixosConfigurations"
    "packages"
  ];

  platformMap = {
    options = {
      arch = mkOption {
        description = mdDoc "the architecture of a system";
        type = types.str;
        default = null;
        example = literalExpression "x86_64";
      };

      os = mkOption {
        description = mdDoc "the name of an os supported by github runners";
        type = types.str;
        default = null;
        example = literalExpression "ubuntu-latest";
      };
    };
  };

  overrides = {
    options = {
      systems = mkOption {
        description = mdDoc "list of systems to build an output for";
        type = types.listOf types.str;
        default = builtins.attrNames cfg.platforms;
      };
    };
  };

  jobs = lib.concatLists (
    map (
      output:
        workflowLib.mkMatrix (
          {inherit output;} // cfg.overrides.${output} or {}
        )
    )
    cfg.outputs
  );
in {
  options = {
    githubWorkflowGenerator = {
      outputs = mkOption {
        description = mdDoc "outputs to include in workflow";
        type = types.listOf types.str;
        default = filter (output: elem output supportedOutputs) (attrNames self);
      };

      platforms = mkOption {
        description = mdDoc ''
          an attrset that can map a nix system to an architecture and os supported by github
        '';
        type = types.attrsOf (types.submodule platformMap);
        default = {};
      };

      overrides = mkOption {
        description = mdDoc "overrides for mkMatrix args";
        type = types.attrsOf (types.submodule overrides);
        default = {};
        example = literalExpression ''
          {
            githubWorkflowGenerator.overrides = {
              checks.systems = [ "x86_64-linux" ];
            };
          }
        '';
      };
    };
  };

  config.flake.githubWorkflow = {
    matrix.include = jobs;
  };
}
