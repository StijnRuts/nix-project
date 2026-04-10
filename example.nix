{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = {
    project.shell = {
      packages = { pkgs, ... }: [ pkgs.hello ];
      scripts = _: { lorem = "echo ipsum"; };
      processes = _: {
        myprocesses = {
          yes.command = "yes";
        };
      };
    };
  };
}
