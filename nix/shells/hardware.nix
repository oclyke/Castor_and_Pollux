{
  self,
  system,
  lib,
  pkgs,
  ...
}:
let
  # ANSI color codes helper.
  # Alternatives include:
  # - https://github.com/phip1611/ansi-escape-sequences-cli
  #   - https://crates.io/crates/ansi-escape-sequences-cli
  #   - https://github.com/NixOS/nixpkgs/blob/c618e28f70257593de75a7044438efc1c1fc0791/pkgs/by-name/an/ansi/package.nix#L19
  ansi = import (self + /nix/derivations/ansi.nix) {
    inherit pkgs;
    inherit system;
  };

  # Color gradient generator.
  gradient = import (self + /nix/derivations/gradient-rs.nix) {
    inherit pkgs;
    inherit system;
  };
in
pkgs.mkShell {
  name = "castor and pollux development environment";
  buildInputs = with pkgs; [
    python3
    protobuf_28
    fzf
    git
    ripgrep
    uutils-coreutils-noprefix
  ] ++ [
    ansi
    gradient
  ];

  shellHook = ''
    setup() {
      export PATH="${pkgs.uutils-coreutils-noprefix}/bin:$PATH"
    }

    customize() {
      export PS1="[$(ansi --green-intense 'hardware')] \u@\h:\w \$ "
    }

    help() {
      echo "Available commands:"
      echo "  help: shows this help message"
      echo ""
    }

    pointless_waste_of_time() {
      # This function prints a 10x10 gradient of colors.
      # It should have been simple, but the OSX Terminal.app
      # is anachronistic and doesn't support 24-bit colors.
      # As a workaround we quantize the RGB values to thos
      # supported by the xterm color palette.
      #
      # This serves as a vivid demonstration of how
      # launching a subshell to perform division is a
      # fantastic waste of time.

      quantize_rgb_to_xterm() {
        # $1 = "#rrggbb"

        # extract the RGB values from the hex color
        r=$(echo $1 | cut -c 2-3)
        g=$(echo $1 | cut -c 4-5)
        b=$(echo $1 | cut -c 6-7)
        r=$((0x$r))
        g=$((0x$g))
        b=$((0x$b))
        # convert to xterm color
        if [ $r -eq $g ] && [ $g -eq $b ]; then
          if [ $r -lt 8 ]; then
            echo 16
          elif [ $r -gt 248 ]; then
            echo 231
          else
            echo $(( ( (r - 8) * 24 ) / 247 + 232 ))
          fi
        else
          r_idx=$(( r / 51 ))
          g_idx=$(( g / 51 ))
          b_idx=$(( b / 51 ))
          echo $(( 16 + (36 * r_idx) + (6 * g_idx) + b_idx ))
        fi
      }

      row=0
      gradient -c 'oklch(75% 0.20 330)' 'oklch(70% 0.15 260)' -m oklab -t 100 | \
        awk '{print $1}' | \
        while read -r color; do
          xterm_color=$(quantize_rgb_to_xterm $color)
          printf "\e[38;5;%sm█\e[0m" $xterm_color
          row=$((row + 1))
          if [ $row -eq 10 ]; then
            echo ""
            row=0
          fi
        done
      echo -e "\n\n"
    }

    setup
    customize

    if [ ! -d venv ]; then
      python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -r hardware/requirements.txt >> /dev/null

    pointless_waste_of_time
  '';
}
