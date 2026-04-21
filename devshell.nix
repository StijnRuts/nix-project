{
  perSystem =
    {
      self',
      lib,
      pkgs,
      ...
    }:
    {
      devshells.default = {
        devshell.startup.menu.text = "menu";

        packages = [ pkgs.hello ];

        commands = [
          {
            category = "[example]";
            help = "print a message";
            name = "lorem";
            command = "echo lorem ipsum";
          }
          {
            category = "[processes]";
            help = "start dev processes";
            name = "dev";
            command = "${lib.getExe self'.packages.dev}";
          }
        ];
      };

      process-compose.dev = {
        settings.is_strict = true;
        cli.options.no-server = true;
        settings = {
          processes = {
            date.command = "while true; do date; sleep 1; done";
            hello.command = "while true; do hello; sleep 3; done";
          };
        };
      };
    };
}
