{
  description = "SoCMake environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/02263f46911178e286242786fd6ea1d229583fbb";
    flake-utils.url = "github:numtide/flake-utils";

    peakrdl-socgen.url = "github:HEP-SoC/PeakRDL-socgen?ref=refs/tags/v0.1.6";
    peakrdl-socgen.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, peakrdl-socgen } :
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          (self: super: {
            sv-lang = super.sv-lang.overrideAttrs (old: {
              version = "10.0";
              src = super.fetchFromGitHub {
                owner = "MikePopoloski";
                repo = "slang";
                tag = "v10.0";
                hash = "sha256-rw+DztENuY+DiAhQR2oNN/dQJzrcP5neF3LoWnqri+c=";
              };
            });
          })
        ];

        pkgs = import nixpkgs { inherit system overlays; };
        python = pkgs.python3;

        pythonDeps = ps: [
          peakrdl-socgen.packages.${system}.default
          ps.peakrdl-regblock
        ];

        deps = with pkgs; [
          cmake
          gnumake
          sv-lang
          verible
          verilator
        ];

      in {
        inherit pythonDeps deps;

        devShells.default = pkgs.mkShell {
          name = "socmake-shell";
          packages = deps ++ [ (python.withPackages pythonDeps) ];
          shellHook = ''
            echo "❄️  SoCMake environment loaded (cmake, verible, verilator, peakrdl)"
          '';
        };
      }
    );
}
