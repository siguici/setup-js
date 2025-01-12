# Setup JavaScript/TypeScript Environment Action

This GitHub Action helps you set up a JavaScript/TypeScript runtime environment,
install dependencies, and run common scripts (such as test, build, lint, deploy)
for popular runtimes like Node.js, Deno, and Bun.
It supports multiple package managers (npm, yarn, pnpm)
and works with scripts defined in package.json or runtime-specific files.

---

## 🚀 Features

- Set up multiple runtimes: Node.js, Deno, and Bun
- Supports popular package managers: npm, yarn, pnpm
- Run common scripts: test, build, lint, deploy, etc.
- Configurable runtime version: Specify the runtime version to use
- Flexible dependency management: Automatically installs dependencies
for the specified runtime

---

## 🛠️ Inputs

- **runtime** (optional)

  - Description: The runtime to use.
  - Default: `node`
  - Options: `node`, `deno`, `bun`
  - Example: `deno`

- **version** (optional)

  - Description: The version of the runtime to use.
  - Default: latest
  - Example: 22.12.0

- **pm** (optional)

  - Description: The package manager to use.
  - Default: [Automatically detected](#-package-manager-detection)
  - Options: `npm`, `yarn`, `pnpm`
  - Example: `yarn`

- **scripts** (optional)

  - Description: A comma-separated list of scripts to run in order.
  - Example: `check,build,test,deploy`

- **cwd** (optional)

  - Description: The directory in which to execute the commands.
  - Default: `.`
  - Example: `./docs`

## 🚚 Outputs

- **runtime**
  - Description: The runtime used.
  - Example: `node`, `deno`, `bun`

- **pm**
  - Description: The package manager used.
  - Example: `npm`, `yarn`, `pnpm`

- **pm_version**
  - Description: The version of the package manager used.
  - Example: `6.14.8` (npm), `1.22.10` (yarn), `7.0.0` (pnpm)

- **pm_lockfile**
  - Description: The detected lockfile, if any.
  - Example: `package-lock.json` (npm), `yarn.lock` (yarn), `pnpm-lock.yaml` (pnpm)

- **os**
  - Description: The operating system used.
  - Example: `linux`, `darwin`, `windows`

- **os_name**
  - Description: The name of the operating system.
  - Example: `Ubuntu`, `macOS`, `Windows`

- **os_version**
  - Description: The version of the operating system.
  - Example: `20.04` (Ubuntu), `11.3` (macOS), `10.0.18363` (Windows)

- **os_arch**
  - Description: The architecture of the operating system.
  - Example: `x64`, `x86`, `arm64`

### 🧑‍💻 Usage

Add this action to your GitHub workflow file:

```yaml
name: Set up JavaScript/TypeScript environment

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  setup:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up the environment
        uses: @siguici/setup-js@v1
```

In this example, the action sets up the Node.js environment with version 14.17.0
and installs dependencies using yarn.

## 💡 Examples

Here is a complete example for a CI workflow that tests across multiple OS platforms,
runtimes, and package managers:

```yaml
name: CI

on: ['push', 'pull_request']

jobs:
  test:
    runs-on: ${{ matrix.os }}
    continue-on-error: ${{ matrix.experimental }}
    strategy:
      fail-fast: true
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        experimental: [false]
        runtime: [node, deno, bun]
        pm: [npm, pnpm, yarn]
    name: 👷 CI ${{ matrix.runtime }} on ${{ matrix.os }} with ${{ matrix.pm }}

    timeout-minutes: 60

    steps:
      - name: 🚚 Checkout repository
        uses: actions/checkout@v4

      - name: Setup Test Environment
        uses: @siguici/setup-js@v1
        with:
          runtime: ${{ matrix.runtime }}
          pm: ${{ matrix.pm }}
          scripts: check,build,test
```

## 📦 Package Manager Detection

This action automatically detects the package manager to use
based on your project configuration if it is not explicitly defined.
The detection process follows these steps:

1. **`package.json` Field**:
   - If the `packageManager` field is defined in `package.json`,
   the action uses this value to determine the package manager and its version.

2. **Lock Files**:
   - If no `packageManager` field is found,
   the action checks for the following lock files in order of precedence:
     - `pnpm-lock.yaml` → **pnpm**
     - `yarn.lock` → **yarn**
     - `package-lock.json` → **npm**
     - `bun.lockb` → **bun**
     - `deno.lock` → **deno**

3. **Runtime Environment**:
   - If no lock files are present, the runtime environment is checked:
     - If the runtime is **Deno**, the action defaults to **deno**.
     - If the runtime is **Bun**, the action defaults to **bun**.

4. **Fallback**:
   - If none of the above methods determine the package manager,
   the action defaults to **npm**.

This ensures that the action is flexible and works seamlessly
with different project setups and configurations.

### ℹ️ Customization

If you want to override the detected package manager,
you can explicitly specify it using the `pm` input.
For example:

```yaml
with:
  pm: yarn
```

## 📖 Notes

- ✅ Node.js: If you choose Node.js as the runtime,
the action will set up the specified version and install dependencies
using your selected package manager (`npm`, `yarn`, `pnpm`).
- ✅ Deno: For Deno, the action installs dependencies using `deno install`
and runs scripts with `deno task script-name`
- ✅ Bun: For Bun, it installs dependencies using `bun install`
and runs scripts with `bun run script-name`.

## 🛡️ License

Under the [MIT License](./LICENSE.md).
Created with ❤️ by [Sigui Kessé Emmanuel](https://github.com/siguici).
