# ansidev's dotbs

## Introduction

I created this project for migrating my configurations among my devices.

At this moment, this project is built for macOS only.

## Installation

1. Download `bootstrap.sh` manually.
2. Download `vars.sh.example` manually and rename it to `vars.sh`.
3. Update `vars.sh`.
4. Check your variables.

   ```sh
   sh bootstrap.sh --check
   ```

   If the result is OK, go to the next step. Otherwise, go to the previous step.

5. Run

   ```sh
   sh bootstrap.sh
   ```

6. Restart your shell after the script is ran successfully.

## Flowchart

```mermaid
%% S: Start
%% E: End
%% A: Action
%% C: Condition
%%{init: {'flowchart' : {'curve' : 'linear'}}}%%

flowchart TD
    S[Start] --> A1[Load variables from vars.sh]
    A1 --> A2[Set default values]
    A2 --> C1{Is check mode?}
    C1 --> |No| A4[Check for empty variables]
    C1 --> |Yes| A3[Print out values] --> A4
    A4 --> C2{Is there any required values but empty?}
    C2 --> |No| C3{Is check mode?} --> E[End]
    C2 --> |Yes| E
    C3 --> |No| A5[Ensure brew is installed and configured]
    A5 --> A6[Ensure zsh-autosuggestions is installed and configured]
    A6 --> A7[Configure SSH key]
    A7 --> C4{Is the feature GPG key disabled?}
    C4 --> |No| A8[Configure GPG key] --> C5{Is git provider GitHub?}
    C4 --> |Yes| C5
    C5 --> |Yes| A9[Ensure SSH key is added to GitHub settings] --> C6{Are both features GPG key and GitHub GPG key enabled?}
    C5 --> |No| C7{Is the feature chezmoi dotfiles repository disabled?}
    C6 --> |Yes| A10[Ensure GPG key is added to GitHub settings] --> C7
    C6 --> |No| C7
    C7 --> |Yes| A11[Checkout and apply chezmoi dotfiles]
    C7 --> |No| E
    A11 --> E
```

## zx-import Function

The `zx-import` function recursively adds directories to zoxide for fast navigation.

### Usage

```bash
# Add all directories recursively
zx-import /path/to/project

# Add only the root directory
zx-import --depth 0 /path/to/project

# Add root and immediate children (depth 1)
zx-import --depth 1 /path/to/project

# Add directories up to depth 2
zx-import --depth 2 /path/to/project

# Preview what would be added without actually adding
zx-import --dry-run /path/to/project
zx-import --dry-run --depth 1 /path/to/project
```

### Depth Parameter

The `--depth N` parameter controls how deep to recurse into the directory tree:
- `--depth 0`: Only the root directory itself
- `--depth 1`: Root directory + immediate children
- `--depth N`: Root directory + directories up to N levels deep
- Omit `--depth`: Add all directories (no depth limit)

Tool-generated directories (node_modules, .git, dist, build, vendor, etc.) are always excluded regardless of depth.

## Author

Le Minh Tri [@ansidev](https://ansidev.xyz/about).

## License

This source code is released under the [MIT License](/LICENSE).
