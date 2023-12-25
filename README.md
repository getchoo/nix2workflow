# nix2workflow

![Test Status](https://github.com/getchoo/nix2workflow/actions/workflows/ci.yaml/badge.svg)
[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/getchoo/nix2workflow/badge)](https://flakehub.com/flake/getchoo/nix2workflow)

nix2workflow is a library for generating GitHub matrices from nix flake outputs.

## Usage

We offer both a standard library for use in any flake, along with
a [flake-parts](https://flake.parts/) module for easier integration.

You can find an example workflow for use in your own project in
[./.github/workflows/example.yaml](./.github/workflows/example.yaml).

### Flake module

A basic setup might look like this. Please see the [module](./module.nix)
for all options

```nix
{self, ...}: {
  imports = [ nix2workflow.flakeModule ];

  nix2workflow = {
    # this will automatically build all standard outputs in self
    root = self;

    overrides = {
      checks.systems = [ "x86_64-linux" ];
    };
  };
}
```

A full example can be found in [./test/module/flake.nix](./test/module/flake.nix)

### Library

The regular library will have a more complicated setup, though
it also allows using lower level functions and has no restrictions on
what flake outputs are used.

```nix
{
  workflowMatrix = let
    platforms = {
      x86_64-linux = {
        os = "ubuntu-latest";
        arch = "x64";
      };

      x86_64-darwin = {
        os = "macos-latest";
        arch = "x64";
      };
    };

    inherit (nix2workflow.lib { inherit platforms; }) mkMatrix;

    jobs = lib.flatten (
      (mkMatrix {
        root = self;
        output = "packages";
      })

      (mkMatrix {
        root = self;
        output = "checks";
        systems = [ "x86_64-linux" ];
      })
    );
  in {
    include = jobs;
  };
}
```

You can see a full example in [./test/lib/flake.nix](./test/lib/flake.nix)

### In workflows

When the matrix is imported, a few variables with added to the `matrix` context.
These can allow you to customize your workflow based on what packages are building -
such as enabling QEMU when building for aarch64

| name | use |
| --- | --- |
| `os` | The operating system of the current output. Usually `ubuntu-latest` or `macos-latest` |
| `arch` | The architecture of the current output. Will be `aarch64` or `x64` |
| `attr` | The flake attribute of the current output (can really be anything).
 Note that you will still need to prefix this with the `root` attribute if set (i.e. `.#hydraJobs.${{ matrix.attrr }}`) |

## Related projects
  - [nix-community/nix-github-actions](https://github.com/nix-community/nix-github-actions/)
    - This is the primary inspiration for this project - and I believe also one of the first 
    projects to attempt this, so kudos!
  - [nix-community/nix-eval-jobs](https://github.com/nix-community/nix-eval-jobs)
    - I liked the idea of using `hydraJobs` (and possibly others) on GitHub Actions, and
    thought it might be fun to make a direct translation of these attributes in pure nix
