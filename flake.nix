{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Common derivation arguments used for all builds
        commonArgs = {
          buildInputs = with pkgs; [
            # Add necessary build inputs here
            cmake
            llvmPackages.openmp
            blas
            swig
          ];

          nativeBuildInputs = with pkgs; [
            # Add necessary native build inputs here
            cudaPackages.cudatoolkit
            addOpenGLRunpath
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath commonArgs.buildInputs;
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation (commonArgs // {
          pname = "faiss-c-lib";
          version = "0.1.0";

          src = ./.;

          cmakeFlags = [
            "-DFAISS_ENABLE_C_API=ON"
            "-DBUILD_SHARED_LIBS=ON"
            "-DFAISS_ENABLE_GPU=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DFAISS_ENABLE_PYTHON=OFF"
          ];


          buildPhase = ''
            make faiss_c
          '';

          installPhase = ''
            make install
          '';

        });

        devShells.default =
          pkgs.mkShell (commonArgs // { });
      }
    );
}
