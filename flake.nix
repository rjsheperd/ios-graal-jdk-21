{
  description = "JDK to iOS build environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Xcode 14.3.1 — required for the iOS 16.4 SDK.
        # The build system (xcodebuild) must use this exact version;
        # the modern build daemon ignores DEVELOPER_DIR and uses whichever
        # Xcode xcode-select points at.  Run:
        #   sudo xcode-select -s ${xcodeApp}/Contents/Developer
        # once before building (or use `nix develop` which will warn you).
        xcodeApp = "/Volumes/MegaDisk2TB/XCode/AF56C562-4191-470B-AECA-8CBE68A2E188/Xcode.app";
        xcodeDeveloperDir = "${xcodeApp}/Contents/Developer";
      in

      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Graal
            graalvmPackages.graalvm-ce
            maven
            # Build
            autoconf
            # fastlane — for provisioning profile management via App Store Connect API.
            # nixpkgs ships fastlane with its own Ruby, avoiding the Ruby 4.0 / OpenSSL 3
            # incompatibility that breaks the Homebrew fastlane with Apple p8 API keys.
            fastlane
          ];

          shellHook = ''
            export JAVA_HOME=$PWD/boot-jdk-21/jdk21/Contents/Home
            export DEVELOPER_DIR="${xcodeDeveloperDir}"

            # Warn if xcode-select doesn't point at the required Xcode.
            # The modern build daemon uses xcode-select, not DEVELOPER_DIR.
            _active_xcode=$(xcode-select -p 2>/dev/null)
            if [ "$_active_xcode" != "${xcodeDeveloperDir}" ]; then
              echo ""
              echo "WARNING: xcode-select is pointing at:"
              echo "  $_active_xcode"
              echo "This build requires Xcode 14.3.1 at:"
              echo "  ${xcodeDeveloperDir}"
              echo "Run the following to fix it, then re-enter the shell:"
              echo "  sudo xcode-select -s ${xcodeApp}"
              echo ""
            else
              echo "Environment loaded! Xcode 14.3.1 active."
            fi
            unset _active_xcode
          '';
        };
      }
    );
}
