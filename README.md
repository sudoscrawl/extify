# extify

A minimal and fast CLI tool to scaffold browser extension boilerplates.

Templates are fetched dynamically from your GitHub repository, allowing for instant updates without changing the CLI binary.

## Features

- **Minimalist UI**: Clean, interactive prompts and symbols.
- **Remote Templates**: Fetches the latest templates from [sudoscrawl/extify-templates](https://github.com/sudoscrawl/extify-templates).
- **Zero Dependencies**: Distributed as a standalone binary; no Lua installation required.
- **Fast Scaffolding**: Automatically replaces `{{PLACEHOLDERS}}` in your boilerplate files.

## Usage

Simply run the binary to start the interactive wizard:

```bash
./extify init
```

The tool will ask for:
- **Name**: Your extension name.
- **Description**: A short bio for your extension.
- **Version**: Defaults to `1.0.0`.
- **Author**: Your name or GitHub handle.
- **Template**: Select from available structures (e.g., `basic`, `popup-only`).

## Available Templates

- **`basic`**: Standard V3 extension with background script and popup.
- **`popup-only`**: Minimal V3 extension focused only on a popup.

## Repository Setup

`extify` expects a `templates.json` file in the root of your templates repository with the following structure:

```json
[
  {
    "name": "basic",
    "files": ["manifest.json", "background.js", "popup.html"]
  }
]
```

Files should be organized in folders matching the `name` field.
