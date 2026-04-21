{
  perSystem =
    { pkgs, ... }:
    let
      deps = pkgs.stdenv.mkDerivation {
        pname = "deps";
        version = "1.0.0";

        src = ./.;
        nativeBuildInputs = [
          pkgs.nodejs_24
          pkgs.cacert
        ];

        outputHashMode = "recursive";
        outputHash = "sha256-e03E36eqHwId4FYQC4XXe982qPFdxEf6QdcAb+uCzNQ=";

        buildPhase = ''
          export HOME=$PWD/home
          mkdir -p $HOME

          npm ci --ignore-scripts
        '';

        installPhase = ''
          mkdir -p $out
          cp -r node_modules $out/
        '';
      };
    in
    {
      packages.deps = deps;
      packages.frontend = pkgs.stdenv.mkDerivation {
        pname = "frontend";
        version = "1.0.0";

        src = ./.;
        inherit deps;
        buildInputs = [ pkgs.nodejs_24 ];

        patchPhase = ''
          cp -r ${deps}/node_modules ./node_modules
          patchShebangs node_modules
        '';

        buildPhase = ''
          npm run build
        '';

        installPhase = ''
          mkdir -p $out
          cp -r dist/* $out/
        '';
      };
    };
}
