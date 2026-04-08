default: shell

genflake:
	nix run .\#genflake flake.nix

shell: genflake
	nix-your-shell zsh nix develop

update: genflake
	nix flake update

