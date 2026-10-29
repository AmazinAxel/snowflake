{ pkgs, ... }:
let
  skriptTreesitterSrc = pkgs.fetchFromGitHub {
    owner = "AmazinAxel";
    repo = "skript-treesitter";
    rev = "d22fee87c5b383bb9039ba30df6d28b2f98ade3d";
    hash = "sha256-q7OQedbJ9PAMN3l3J/u410BO0qNkccJaDdro+br65D0=";
  };
  skriptTreesitter = pkgs.tree-sitter.buildGrammar {
    language = "skript";
    version = "1.0.0";
    src = skriptTreesitterSrc;
  };
in
{
  programs.helix.languages.language = [{
    name = "skript";
    scope = "source.skript";
    file-types = [ "sk" ];
    roots = [ ];
    comment-token = "#";
    indent = {
      tab-width = 4;
      unit = "\t";
    };
    grammar = "skript";
  }];
  xdg.configFile = { # needed for Skript highlighting
    "helix/runtime/queries/skript".source = "${skriptTreesitterSrc}/queries";
    "helix/runtime/grammars/skript.so".source = "${skriptTreesitter}/parser";
  };
}
