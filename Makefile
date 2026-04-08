default: shell

genflake:
	nix run .\#genflake flake.nix

shell: genflake
	nix develop

update: genflake
	nix flake update

