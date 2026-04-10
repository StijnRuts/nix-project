(import ./project) [
  {
    project.formatters = {
      programs = {
        prettier.enable = true;
      };
    };
  }
  ./example.nix
]
