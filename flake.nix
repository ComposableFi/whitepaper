{
  inputs = {
    nix-pandoc.url = "github:serokell/nix-pandoc";
    nix-pandoc.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, nix-pandoc }: 
  {
    defaultPackage =  builtins.mapAttrs (system: pkgs: nix-pandoc.mkDoc.${system} {
      name = "whitepaper";
      src = ./src;
      phases = [ "unpackPhase" "buildPhase" "installPhase" ];
      buildPhase = "pandoc -s --toc --filter ${pkgs.haskellPackages.pandoc-crossref}/bin/pandoc-crossref --csl=styles/csl/ieee.csl --metadata link-citations=true --citeproc --bibliography=references.bib --pdf-engine=xelatex -o $name.pdf ./whitepaper.md";
      installPhase = "mkdir -p $out; cp $name.pdf $out";
    }) nixpkgs.legacyPackages;
  };
}
