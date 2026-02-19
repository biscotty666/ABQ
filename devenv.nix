{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = with pkgs;
    [ git rstudio pandoc quarto texliveMedium ] ++ (with rPackages; [
      styler
      admisc
      car
      classInt
      corrr
      crsuggest
      devtools
      geofacet
      geojsonsf
      # ggsci
      GGally
      ggpubr
      ggspatial
      ggtext
      # ggthemes
      gt
      gtExtras
      janitor
      nngeo
      nortest
      pagedown
      paletteer
      patchwork
      prettymapr
      rcompanion
      rnaturalearth
      rnaturalearthdata
      roxygen2
      rstatix
      rvest
      sf
      spData
      spdep
      tidycensus
      tidyverse
      tmap
      units
      zeallot
    ]);

  # https://devenv.sh/languages/
  languages.r = {
    enable = true;
    radian.enable = true;
  };

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    hello         # Run scripts directly
    git --version # Use packages
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
