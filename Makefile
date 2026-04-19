default: shell

update:
	nix flake update

format:
	nix fmt

check:
	nix flake check

shell:
	nix-your-shell zsh nix develop

