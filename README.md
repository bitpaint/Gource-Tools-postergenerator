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
- Browse and reuse locally cloned repositories and organization folders via an interactive menu.
- Combine multiple repositories (user/org) into a single unified visualization (Combined Logs mode).

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

3. Follow the on-screen instructions to select options and generate posters:
   - **1) Clone a single repository**: Enter the repository URL.
   - **2) Use an existing repository**: Browse a list of local clones, organization folders, or enter a custom path. Within an organization, choose a specific repo or **Combined Logs** to merge all histories.
   - **3) Clone all repos from a GitHub user/org**: Enter the username or organization name and optionally generate combined logs.

## Directory Structure

The tool will create two main directories:
- `repos/` - Stores:
  - Individual repositories (by name).
  - Organization/user directories containing cloned repos.
  - Combined logs directories named `<org>-combined` (for Combined Logs mode).
- `posters/` - Saves generated posters, organized by repository name or `<org>-combined` for combined outputs.

## Screenshots

(Screenshots coming soon)

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
