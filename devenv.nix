{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    rstudio
    pandoc
    quarto
    texliveMedium
    rPackages.classInt
    rPackages.crsuggest
    rPackages.geofacet
    rPackages.geojsonsf
    rPackages.ggspatial
    rPackages.ggtext
    rPackages.gt
    rPackages.janitor
    rPackages.nngeo
    rPackages.pagedown
    rPackages.patchwork
    rPackages.prettymapr
    rPackages.rvest
    rPackages.sf
    rPackages.tidycensus
    rPackages.tidyverse
    rPackages.units
    rPackages.zeallot
  ];

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
