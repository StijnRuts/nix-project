default: shell

genflake:
	nix run .\#genflake flake.nix

shell: genflake
	nix-your-shell zsh nix develop

format: genflake
	nix fmt

check: genflake
	nix flake check

update: genflake
	nix flake update

