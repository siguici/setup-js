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

- `runtime` (optional)

  - Description: The runtime to use.
  - Default: `node`
  - Options: `node`, `deno`, `bun`
  - Example: `deno`

- `version` (optional)

  - Description: The version of the runtime to use.
  - Default: latest
  - Example: 22.12.0

- `pm` (optional)

  - Description: The package manager to use.
  - Default: npm
  - Options: `npm`, `yarn`, `pnpm`
  - Example: `yarn`

- `scripts` (optional)

  - Description: A comma-separated list of scripts to run in order.
  - Example: `check,build,test,deploy`

## 🚚 Outputs

This action does not produce any outputs directly
but runs scripts based on the provided configuration.

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
        version: ["latest"]
        pm: [npm, pnpm, yarn]
        exclude:
          - runtime: bun
            pm: pnpm
          - runtime: bun
            pm: yarn
          - runtime: deno
            pm: pnpm
          - runtime: deno
            pm: yarn
    name: 👷 CI ${{ matrix.runtime }}@${{ matrix.version }} under ${{ matrix.os }} using ${{ matrix.pm }}

    timeout-minutes: 60

    steps:
      - name: 🚚 Checkout repository
        uses: actions/checkout@v4

      - name: Setup Test Environment
        uses: @siguici/setup-js@v1
        with:
          runtime: ${{ matrix.runtime }}
          version: ${{ matrix.version }}
          pm: ${{ matrix.pm }}
          scripts: check,build,test
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
