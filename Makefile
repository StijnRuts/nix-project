default: shell

genflake:
	nix run .\#genflake flake.nix

update: genflake
	nix flake update

shell: genflake
	nix-your-shell zsh nix develop

