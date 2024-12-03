{
  description = "A Python project with Nix flakes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };  # Adjust system as needed
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          python311
          python311Packages.pip
          python311Packages.virtualenv
          zstd
        ];
      };
    };
}
