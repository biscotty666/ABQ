{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.bashInteractive ];
          buildInputs = with pkgs; [
            R
            quarto
            chromium
            pandoc
            texlive.combined.scheme-full
            rstudio
            (with rPackages; [
              quarto
              palmerpenguins
              reshape2
              nnet
              foreign
              GGally
              GWmodel
              car
              classInt
              corrr
              crimedata
              crimedatasets
              crsuggest
              geojsonsf
              ggpubr
              ggridges
              ggspatial
              ggtext
              gt
              gtExtras
              hereR
              janitor
              mapboxapi
              nngeo
              osmdata
              osrm
              patchwork
              plotly
              rcompanion
              # rnaturalearth
              # rnaturalearthdata
              # roxygen2
              rstatix
              rvest
              scales
              segregation
              sf
              spatialreg
              # spData
              spdep
              styler
              survey
              srvyr
              tidycensus
              tidygeocoder
              tidymodels
              tidyverse
              tmap
              units
              webshot2
              zeallot
            ])
          ];
        };
      }
    );
}
