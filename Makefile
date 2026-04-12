genflake:
	nix run .\#genflake flake.nix

update: genflake
	nix flake update

