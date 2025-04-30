        ┌─┐┌─┐┬ ┬┬─┐┌─┐┌─┐  ┌┬┐┌─┐┌─┐┬  ┌─┐
        │ ┬│ ││ │├┬┘│  ├┤ ───│ │ ││ ││  └─┐
        └─┘└─┘└─┘┴└─└─┘└─┘   ┴ └─┘└─┘┴─┘└─┘
     ┌────────────────────────────────────────────────┐
     │               POSTER GENERATOR                 │
     └────────────────────────────────────────────────┘

## Features

- Clone a single repository or all repositories from a GitHub user/organization (excluding forks).
- Generate posters for each year based on commit history.
- Customizable resolution and orientation for the generated posters.
- Stylish ASCII art header and menu for a better user experience.

## Requirements

- PowerShell
- Git
- Gource
- FFmpeg

## Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/bitpaint/Gource-Tools-postergenerator.git
   cd postergen
   ```

2. Run the script:
   ```powershell
   .\postergen.ps1
   ```

3. Follow the on-screen instructions to select options and generate posters.

## Options

- **Clone a single repository**: Enter the repository URL.
- **Use an existing repository**: Provide the path to the existing repository.
- **Clone all repos from a GitHub user/org**: Enter the username or organization name.

## Directory Structure

The tool will create a `repos` directory to store cloned repositories and an `Export` directory to save generated posters.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
