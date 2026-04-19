default: shell

update:
	nix flake update

shell:
	nix-your-shell zsh nix develop

