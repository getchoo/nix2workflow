workflowLib': {
  config,
  lib,
  self,
  ...
}: let
  cfg = config.nix2workflow;

  inherit
    (lib)
    attrNames
    concatLists
    elem
    filter
    filterAttrs
    literalExpression
    mapAttrsToList
    mdDoc
    mkOption
    recursiveUpdate
    types
    ;

  workflowLib = workflowLib' {inherit (cfg) platforms;};
  inherit (workflowLib) mkMatrix mkMatrix';

  supportedOutputs = [
    "checks"
    "devShells"
    "nixosConfigurations"
    "darwinConfigurations"
    "homeConfigurations"
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

  jobs = concatLists (
    mapAttrsToList (
      output: value: let
        common =
          recursiveUpdate
          {
            root = cfg.output;
            inherit output;
          }
          (cfg.overrides.${output} or {});

        flat = mkMatrix' common;
        multi = mkMatrix common;
      in
        {
          # TODO: maybe make this configurable? or follow flake-schemas?
          # these are known "flat" values
          "nixosConfigurations" = flat;
          "darwinConfigurations" = flat;
          "homeConfigurations" = flat;
        }
        .${output}
        or multi
    )
    (filterAttrs (output: _: elem output supportedOutputs) cfg.output)
  );
in {
  options = {
    nix2workflow = {
      output = mkOption {
        description = mdDoc "Root attribute for CI jobs";
        type = types.lazyAttrsOf types.raw;
        default = self;
        example = literalExpression "hydraJobs";
      };

      platforms = mkOption {
        description = mdDoc ''
          an attrset that can map a nix system to an architecture and os supported by github
        '';
        type = types.nullOr (types.attrsOf (types.submodule platformMap));
        default = null;
        example = literalExpression ''
          {
            "x86_64-linux" = {
              os = "ubuntu-latest";
              arch = "x64";
            };

            "aarch64-linux" = {
              os = "self-hosted";
              arch = "aarch64";
            };

            "x86_64-darwin" = {
              os = "macos-latest";
              arch = "x64";
            };
          }
        '';
      };

      exclude = mkOption {
        description = mdDoc "outputs to exclude from matrix";
        type = types.listOf types.str;
        default = [];
        example = literalExpression ''
          {
            nix2workflow.exclude = [
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
            nix2workflow.overrides = {
              checks.systems = [ "x86_64-linux" ];
            };
          }
        '';
      };
    };
  };

  config.flake.workflowMatrix = {
    include = filter (job: !elem job.attr cfg.exclude) jobs;
  };
}
