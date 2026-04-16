# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This project builds JDK 21 as static libraries (`libjava.a` and `libjvm.a`) for iOS (arm64). The output libraries can be embedded in native iOS apps to enable Java execution on-device.

## Prerequisites

- **Xcode 14.3.1** with iOS 16.4 SDK — must be the `xcode-select` active Xcode (see below)
- `conda` for Python 3.10 support: `brew install --cask miniconda`
- `mx` GraalVM build tool: `brew install mx`
- GraalVM 23.1.3 Java SDK
- `cups` via Homebrew: `brew install cups`
- labsjdk-ce-21 as the Boot JDK (fetched via `mx fetch-jdk`)

Fetch the Boot JDK:
```bash
mx -y --no-warning fetch-jdk --java-distribution labsjdk-ce-21 --to ~/.mx/jdks/ --alias jdk21
export JAVA_HOME=/Users/$USER/.mx/jdks/jdk21/Contents/Home
```

### One-time Xcode setup (required for reproducible builds)

`xcodebuild`'s modern build daemon uses `xcode-select` — not `DEVELOPER_DIR` — to locate its toolchain. Using the wrong Xcode produces a mismatched VFS stat cache and `stdio.h not found` errors. Pin the system to Xcode 14.3.1 once:

```bash
sudo xcode-select -s /Volumes/MegaDisk2TB/XCode/AF56C562-4191-470B-AECA-8CBE68A2E188/Xcode.app
```

`build.sh` asserts this is set correctly and fails immediately with a fix hint if it isn't.

### Nix dev shell

Sets `JAVA_HOME`, `DEVELOPER_DIR`, and warns if `xcode-select` is wrong:
```bash
nix develop
```

## Build

```bash
./build.sh
```

Build outputs land in `build/ios-arm64/lib/`:
- `libjava.a` — JDK core Java library (native layer)
- `libjvm.a` — GraalVM SubstrateVM JVM library

## Architecture

The build has three stages orchestrated by the top-level `build.sh`:

### 1. `labs-openjdk/labs-openjdk-21/` (git submodule)
Patched labsJDK 21 source. The inner `build.sh` invokes `./configure` with the **macOS** SDK and system clang (no iOS flags), then runs `make static-libs-image`. This avoids cross-compilation issues with host build tools like `adlc` being compiled as iOS binaries. The iOS compatibility patch lives at `labs-openjdk/ios-jdk.patch` — it only touches files compiled by the Xcode projects (libjava/libnet), not by `make`.

### 2. `labs-openjdk/svm.openjdk.xcodeproj`
Xcode project that compiles the JDK native C sources (networking, I/O, etc.) into `libjava.a` for `iphoneos16.4`. This is where `ios-jdk.patch` takes effect (`TARGET_OS_IPHONE` guards). Built with the legacy build system (`-UseModernBuildSystem=NO`) so clang is invoked directly from the pinned Xcode 14.3.1 toolchain.

### 3. `svm/graal/` (git submodule) + `svm/svm.graal.xcodeproj`
GraalVM SubstrateVM source. `svm/src/main/native/JvmFuncsFallbacks.c` provides iOS-compatible fallback implementations of JVM functions. The Xcode project compiles these into `libjvm.a` under the same constraints as step 2.

## Applying the iOS Patch

If the submodule is freshly checked out, apply the iOS patch before building:
```bash
cd labs-openjdk/labs-openjdk-21
git apply ../ios-jdk.patch
```

## Submodule Initialization

```bash
git submodule update --init --recursive
```
