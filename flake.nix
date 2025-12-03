{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.11";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    devDB.url = "github:hermann-p/nix-postgres-dev-db";
    devDB.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, flake-utils, devDB, ... }:
    let supportedSystems = [
         "x86_64-linux"
         "x86_64-darwin"
         "aarch64-linux"
         "aarch64-darwin"      
    ];
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        db = devDB.outputs.packages.${system};
      in
      {
        devShells.default = with pkgs; mkShell {
          nativeBuildInputs = [ bashInteractive ];
          buildInputs = [
            R
            postgresql_15
            db.start-database
            db.stop-database
            db.psql-wrapped
            pgadmin4-desktopmode
            dbeaver-bin
            chromium
            pandoc
            texlive.combined.scheme-full
            rstudio
            quarto
            ( with rPackages; [
              GWmodel
              RPostgres
              XML
              areal
              blscrapeR
              broom_helpers
              car
              cardx
              cartogram
              censusapi
              chirps
              codetools
              corrr
              crsuggest
              dash
              dashCoreComponents
              dashHtmlComponents
              dbplyr
              devtools
              elevatr
              flowmapblue
              geodata
              geofacet
              geojsonsf
              ggbeeswarm
              ggiraph
              ggpattern
              ggridges
              ggspatial
              gifski
              gt
              gtExtras
              gtsummary
              historydata
              htmlwidgets
              httr
              ipumsr
              janitor
              jqr
              jsonlite
              leaflet
              leaflet_extras
              leaflet_extras2
              leafsync
              lehdr
              lwgeom
              mapboxapi
              mapdeck
              maps
              mapview
              osmdata
              pagedown
              palmerpenguins
              parameters
              patchwork
              plotly
              prettymapr
              quarto
              rcartocolor
              rmapshaper
              rnaturalearth
              rnaturalearthdata
              rosm
              rvest
              segregation
              sf
              shiny
              shiny
              spData
              spatialreg
              spdep
              spocc
              srvyr
              styler
              survey
              terra
              tidyUSDA
              tidycensus
              tidygeocoder
              tidyterra
              tidyverse
              tmap
              trajr
              usethis
              viridis
              wbstats
              webshot
              worldbank
            ]
          )];
          shellHook = ''
            export PG_ROOT=$(git rev-parse --show-toplevel)
          '';
        };
      }
    );
}

