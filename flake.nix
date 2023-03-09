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
            cudaPackages.cudatoolkit
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath commonArgs.buildInputs;
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation (commonArgs // {
          pname = "faiss-c-lib";
          version = "1.7.3";

          src = ./.;

          cmakeFlags = [
            "-DFAISS_ENABLE_C_API=ON"
            "-DBUILD_SHARED_LIBS=ON"
            "-DFAISS_ENABLE_GPU=ON"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DFAISS_ENABLE_PYTHON=OFF"
          ];


          buildPhase = ''
            ls
            make -j"$NIX_BUILD_CORES" faiss_c
          '';

          installPhase = ''
            make install
            cp c_api/libfaiss_c.so $out/lib
            patchelf --set-rpath '$ORIGIN/../lib' $out/lib/libfaiss_c.so
          '';
        });

        devShells.default =
          pkgs.mkShell (commonArgs // { });
      }
    );
}
