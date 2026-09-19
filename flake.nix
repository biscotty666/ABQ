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
          sfnetworks = pkgs.rPackages.buildRPackage {
            name = "sfnetworks";
            src = pkgs.fetchFromGitHub {
              owner = "luukvdmeer";
              repo = "sfnetworks";
              rev = "fe6edf8c9a73160110cbf25b673853b7aa23f927";
              sha256 = "cDMC5+BP7dxQbJtGjPd0Xk7MnN3PecHLjLYmSO+LOoc=";
            };
            propagatedBuildInputs = with pkgs.rPackages; [
              igraph
              dplyr
              lwgeom
              pillar
              sf
              sfheaders
              tibble
              tidygraph
              tidyselect
              units
            ];
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.fontconfig
          ];
          packages = builtins.attrValues {
            inherit (myPackages) sfnetworks patchedQuarto;
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
              FastUtils
              GGally
              GWmodel
              bestNormalize
              car
              classInt
              corrr
              collapse
              crimedata
              microbenchmark
              crimedatasets
              crsuggest
              geojsonsf
              fixest
              glue
              rjson
              ggprism
              rsconnect
              ggpubr
              ggraph
              ggridges
              ggspatial
              ggtext
              gt
              gtExtras
              hereR
              igraph
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
              rgeoda
              rmapshaper
              # roxygen2
              rstatix
              rvest
              scales
              segregation
              sf
              sfdep
              # sfnetworks
              spatialreg
              # spData
              spdep
              styler
              survey
              srvyr
              tidycensus
              tidygeocoder
              tidygraph
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
