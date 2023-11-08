# nix2workflow

![test status](https://github.com/getchoo/nix2workflow/actions/workflows/ci.yaml/badge.svg)

nix2workflow is a library for generating github matrices from regular nix flake outputs.

## usage

we offer both a standard library for use in any flake, along with
a [flake-parts](https://flake.parts/) module for easier integration.

you can find an example workflow for use in your own project in
[./.github/workflows/example.yaml](./.github/workflows/example.yaml).

### flake module

a basic setup might look like this. please see the [module](./module.nix)
for all options

```nix
{
  imports = [nix2workflow.flakeModule];

  githubWorkflowGenerator = {
    outputs = [
      "checks"
      "devShells"
      "nixosConfigurations"
      "packages"
    ];

    overrides = {
      checks.systems = ["x86_64-linux"];
    };
  };
}
```

a full example can be found in [./test/module/flake.nix](./test/module/flake.nix)

### library

the regular library will have a more complicated setup, though
it also allows using lower level functions and has no restrictions on
what flake outputs are used.

```nix
{
  githubworkflow = let
    workflow = nix2workflow.lib {inherit self;};
    outputs = [
      "checks"
      "devShells"
      "nixosConfigurations"
      "packages"
    ];
  in {
    matrix.include = lib.concatLists (
      map (
        output:
          workflow.mkMatrix {
            inherit output;
            # you can also specify what systems to build each output for
            systems = ["x86_64-linux" "aarch64-darwin"];
          }
      )
      outputs
    );
  };
}
```

you can see a full example in [./test/lib/flake.nix](./test/lib/flake.nix)

### in workflows

when the matrix is imported, a few variables with added to the `matrix` context.
these can allow you to customize your workflow based on what packages are building -
such as enabling QEMU when building for aarch64

| name | use |
| --- | --- |
| `os` | the operating system of the current output. usually `ubuntu-latest` or `macos-latest` |
| `arch` | the architecture of the current output. will be `aarch64` or `x64` |
| `attr` | the flake attribute of the current output (can really be anything) |

## related projects
  - [nix-community/nix-github-actions](https://github.com/nix-community/nix-github-actions/)
    - this is the primary inspiration for this project - and i believe also one of the first 
    projects to attempt this, so kudos! i just wanted a more opionated and expandable approach :)
