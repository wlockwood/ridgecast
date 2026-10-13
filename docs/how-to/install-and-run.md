# Install and run RidgeCast

Windows release tooling produces a portable ZIP and can also produce a per-user
installer. Use the assets offered by the [release repository](https://github.com/wlockwood/ridgecast/releases);
building from source remains available on Windows, macOS and Linux.

## Windows packages

For a release containing `RidgeCast-vVERSION-windows-x64-setup.exe`, run the
installer as your normal user. It installs desktop, MCP and offline documentation
under `%LOCALAPPDATA%\Programs\RidgeCast`, creates Start Menu and uninstall entries,
and opens the desktop with `%LOCALAPPDATA%\RidgeCast\workspace` as its writable
working directory. Launching directly from the installation directory also uses
that workspace. An explicit project working directory is preserved.

An upgrade uses the same application identity and replaces packaged files.
Uninstall removes application files and shortcuts while retaining networks,
preferences and caches. Repair by rerunning the installer for the same version.
No YAML or JSON file associations are claimed.

For portable use, extract the ZIP into a writable directory and run
`ridgecast.exe`. The adjacent `ridgecast-mcp.exe` supplies automation; see
[assistant setup](drive-ridgecast-from-an-ai-assistant.md). Both executables accept
`--help` and `--version`. A source checkout and Rust are unnecessary for packages.

## Requested update checks

Open **Help → Check for Updates** and choose **Check now**. No check runs by
default, and **Work Offline** blocks feed/download requests. Stable releases are
the default; prereleases require selecting the explicit option.

Automatic installation requires a public release key pinned into the application
and a matching Ed25519-signed version/platform/asset-digest manifest. Builds without
that trust root display the reason and keep manual release downloads available.
After reviewing notes, download a verified payload, then explicitly choose
**Install after closing RidgeCast**. Resolve the unsaved-work dialog and close
installed MCP processes; replacement waits for both applications to exit. Canceling
the unsaved-work dialog keeps the payload staged and starts no replacement helper.

The update journal retains previous application files for rollback and does not
change projects, preferences, caches or the working directory. To recover an
interrupted or unwanted update, close desktop/MCP and run the installed desktop
with `--rollback-update`. Successful later updates archive older recovery journals
inside their corresponding `.ridgecast-rollback-*` directories; keep these while
you need their previous files. Helper success or failure appears in the update
window on the next launch and is recorded in `.ridgecast-update-status.json`
beside the application. Manual portable installation remains available.

## Source prerequisites

- Rust 1.95 or newer
- Git
- A C++17-capable compiler for the bundled ITM implementation
- A desktop graphics environment with WebGPU support

Platform-specific requirements:

- **Windows:** Visual Studio 2022 Build Tools with **Desktop development with
  C++**, plus the default Rust MSVC toolchain.
- **macOS:** Xcode Command Line Tools, installed with
  `xcode-select --install`.
- **Ubuntu/Debian:**

  ```bash
  sudo apt-get update
  sudo apt-get install -y build-essential pkg-config libxkbcommon-dev libgtk-3-dev
  ```

Other Linux distributions need equivalent C/C++ compiler, X11, xkbcommon, and
GTK development packages.

Install Rust through [rustup](https://rustup.rs/) if needed. Before building,
check the tools in the terminal you will use:

```text
rustc --version
rustc -vV
rustup show active-toolchain
git --version
```

The Rust version must meet the 1.95 minimum. On Windows, the host/active native
toolchain must use `pc-windows-msvc`, rather than `pc-windows-gnu`. In Visual
Studio Installer, confirm **Desktop development with C++** includes the MSVC
tools and a Windows SDK; see the official
[MSVC prerequisites](https://rust-lang.github.io/rustup/installation/windows-msvc.html).

## Build and launch

First download or clone this repository, then open a terminal in its top-level
directory (the directory containing `Cargo.toml`). Run:

```bash
cargo run --release
```

The first build compiles both Rust and the bundled C++ ITM implementation and
can take several minutes. For a quicker development compile, use `cargo run`,
but expect propagation calculations to be substantially slower.

No API keys are required for built-in data sources. Internet access is needed
only for data that is not already cached.

RidgeCast is a graphical application. A headless shell or remote terminal cannot
display its window without a desktop session and graphics forwarding.

## Verify the installation

Confirm that the application window opens and the map can be panned and zoomed.
Then continue with [Plan your first network](../tutorials/plan-your-first-network.md).
