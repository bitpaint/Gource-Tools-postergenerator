        ┌─┐┌─┐┬ ┬┬─┐┌─┐┌─┐  ┌┬┐┌─┐┌─┐┬  ┌─┐
        │ ┬│ ││ │├┬┘│  ├┤ ───│ │ ││ ││  └─┐
        └─┘└─┘└─┘┴└─└─┘└─┘   ┴ └─┘└─┘┴─┘└─┘
     ┌────────────────────────────────────────────────┐
     │               POSTER GENERATOR                 │
     └────────────────────────────────────────────────┘

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://github.com/PowerShell/PowerShell)
[![Gource](https://img.shields.io/badge/Uses-Gource-green)](https://gource.io/)
[![FFmpeg](https://img.shields.io/badge/Requires-FFmpeg-orange)](https://ffmpeg.org/)

## Features

- Clone a single repository or all repositories from a GitHub user/organization (excluding forks).
- Generate posters for each year based on commit history.
- Customizable resolution and orientation for the generated posters.
- Stylish ASCII art header and menu for a better user experience.

## Requirements

- PowerShell
- Git
- [Gource](https://gource.io/)
- [FFmpeg](https://ffmpeg.org/)

## Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/bitpaint/Gource-Tools-postergenerator.git
   cd Gource-Tools-postergenerator
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

The tool will create two main directories:
- `repos/` - Stores cloned repositories
- `posters/` - Saves generated posters, organized by repository name

## Screenshots

(Screenshots coming soon)

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
