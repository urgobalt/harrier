{pkgs, inputs, ...}: let
  hare-lsp = with pkgs;
    stdenv.mkDerivation rec {
      name = "hare-lsp";
      version = inputs.hare-lsp.shortRev;
      src = inputs.hare-lsp;
      nativeBuildInputs = [hare];
      buildPhase = ''
        mkdir -p .cache
        export HARECACHE=.cache
        export HAREPATH=${hare}/src/hare/stdlib:${hareThirdParty.hare-json}/src/hare/third-party
        echo $HAREPATH
        hare build -o hare-lsp ./lsp/server/
      '';
      installPhase = ''
        install -Dm755 hare-lsp 	-t $out/bin/
        install -Dm644 LICENCE 		-t $out/usr/local/share/licenses/hare-lsp/
      '';
    };
in {
  packages = with pkgs; [hare hare-lsp];
}
