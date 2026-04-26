{
  perSystem =
    { pkgs, ... }:
    {
      packages.frontend = pkgs.stdenv.mkDerivation {
        pname = "frontend";
        version = "1.0.0";
        src = ./public;

        installPhase = ''
          mkdir -p $out
          cp -r * $out/
        '';
      };
    };
}
