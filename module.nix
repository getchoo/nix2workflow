workflowLib': {
  config,
  lib,
  self,
  ...
}: let
  cfg = config.githubWorkflowGenerator;

  inherit
    (lib)
    attrNames
    concatLists
    elem
    filter
    mdDoc
    mkOption
    literalExpression
    types
    ;

  workflowLib = workflowLib' {
    inherit self;
    inherit (cfg) platforms;
  };

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
        type = types.either types.str (types.listOf types.str);
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
        default = attrNames cfg.platforms;
      };
    };
  };

  unfilteredJobs = concatLists (
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
        default = {
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
        };
      };

      exclude = mkOption {
        description = mdDoc "outputs to exclude from matrix";
        type = types.listOf types.str;
        default = [];
        example = literalExpression ''
          {
            githubWorkflowGenerator.exclude = [
           	  "packages.x86_64-linux.foo"
           	];
          }
        '';
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
    matrix.include = filter (job: !builtins.elem job.attr cfg.exclude) unfilteredJobs;
  };
}
