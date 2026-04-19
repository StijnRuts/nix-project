{
  perSystem =
    { pkgs, ... }:
    {
      devshells.default = {
        packages = with pkgs; [ hello ];
        commands = [
          {
            help = "print a message";
            name = "lorem";
            command = "echo lorem ipsum";
          }
        ];
      };
    };
}
