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
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python3;

        # For 'vhier' tool used by the copy_rtl_files
        verilogPerl = pkgs.perlPackages.buildPerlPackage (rec {
          pname = "Verilog-Perl";
          version = "3.482";
          src = pkgs.fetchFromGitHub {
            owner = "veripool";
            repo = "verilog-perl";
            rev = "v${version}";
            hash = "sha256-vpgxzb3DpoIhOZKiw3d6HRwJkpor4dOJBxCY26LKqLA=";
          };
          
          nativeBuildInputs = [pkgs.flex pkgs.bison];
        });

        pythonDeps = ps: [
          peakrdl-socgen.packages.${system}.default
          ps.peakrdl-regblock
        ];

        deps = with pkgs; [
          cmake
          gnumake
          verible
          verilator
          verilogPerl
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
