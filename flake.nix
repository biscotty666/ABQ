{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
        myPackages = {
          patchedQuarto = pkgs.quarto.overrideAttrs (oldAttrs: {
            postPatch = (oldAttrs.postPatch or "") + ''
              substituteInPlace bin/quarto.js \
                --replace-fail "syntax-highlighting" "highlight-style"
            '';
          });
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues {
            inherit (myPackages) patchedQuarto;
            inherit (pkgs)
              R
              # quarto
              chromium
              pandoc
              rstudio
              texliveMedium
              ;
            inherit (pkgs.rPackages)
              palmerpenguins
              reshape2
              nnet
              foreign
              GGally
              GWmodel
              bestNormalize
              car
              classInt
              corrr
              collapse
              crimedata
              crimedatasets
              crsuggest
              geojsonsf
              fixest
              ggpubr
              ggridges
              ggspatial
              ggtext
              gt
              gtExtras
              hereR
              janitor
              kit
              mapboxapi
              nngeo
              osmdata
              osrm
              patchwork
              plotly
              prettymapr
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
              ;
          };
        };
      }
    );
}
