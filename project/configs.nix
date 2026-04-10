let
  removeAttrByPath =
    path: set:
    if path == [ ] then
      set
    else
      let
        key = builtins.head path;
        rest = builtins.tail path;
      in
      if rest == [ ] then
        builtins.removeAttrs set [ key ]
      else
        set
        // {
          ${key} = removeAttrByPath rest set.${key};
        };
in
{
  outputs =
    { lib, config, ... }:
    {
      options.project.configs = lib.mkOption {
        type = lib.types.anything;
        default = lib.mkDefault { };
      };

      config = {
        nixosConfigurations = lib.mkMerge [
          (builtins.mapAttrs (_: conf: {
            system = conf.system.arch;
            modules = [ (removeAttrByPath [ "system" "arch" ] conf) ];
          }) config.project.configs)
        ];
      };
    };
}
