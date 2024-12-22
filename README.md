# code2pdf

Convert source code files to PDF with a table of contents, preserving code formatting and making it easy to share or print your code.

## Features

- Convert single source code files to PDF
- Convert entire directories of code files to PDF with a table of contents
- Preserve syntax highlighting and formatting
- Support for multiple programming languages
- Available as a command-line tool

## Installation

### Via Homebrew (recommended for macOS users)

```bash
brew tap readbysearch/code2pdf
brew install code2pdf
```

### Manual Installation (if you are not using Homebrew)

#### Prerequisites

- Vim (for syntax highlighting)
- Ghostscript (for PDF operations)
- jq (for JSON processing)
- Bash shell (Unix-like systems)

#### Installation Steps

1. Clone the repository
```bash
git clone https://github.com/readbysearch/code2pdf.git
cd code2pdf
```

2. Install dependencies (macOS example)
```bash
brew install vim ghostscript jq
```

3. Make the script executable
```bash
chmod +x bin/code2pdf
```

4. Add to your PATH (optional)
```bash
ln -s "$(pwd)/bin/code2pdf" /usr/local/bin/code2pdf
```

## Usage

### Command Line Interface

Convert a single file:
```bash
code2pdf -s myfile.py
```

Convert all files in a directory:
```bash
code2pdf -a src/
```

Show help:
```bash
code2pdf --help
```