{
  perSystem =
    { pkgs, ... }:
    {
      devshells.default = {
        devshell.startup.menu.text = "menu";
        packages = with pkgs; [ hello ];
        commands = [
          {
            help = "print a message";
            name = "lorem";
            command = "echo lorem ipsum";
          }
        ];
        serviceGroups.foobar = {
          description = "Example processes";
          services = {
            date.command = "while true; do date; sleep 1; done";
            hello.command = "while true; do hello; sleep 3; done";
          };
        };
      };
    };
}
