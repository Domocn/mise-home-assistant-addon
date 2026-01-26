# Laro Home Assistant Add-ons

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FDomocn%2Flaro-home-assistant-addon)

Home Assistant add-on repository for [Laro](https://github.com/Domocn/Laro) - bring order to your larder.

## Add-ons

### [Laro](./laro)

![Supports amd64 Architecture][amd64-shield]
![Supports aarch64 Architecture][aarch64-shield]
![Supports armv7 Architecture][armv7-shield]

Self-hosted family recipe management, meal planning, and cooking assistant.

**Features:**
- Recipe management with AI-powered import from any URL
- Weekly meal planning with drag-and-drop calendar
- Auto-generated shopping lists
- Step-by-step cooking mode
- Multi-user household support
- Multiple LLM providers (Ollama, OpenAI, Anthropic, Google)

## Installation

1. Click the button above, or manually add this repository to Home Assistant:
   - Go to **Settings** → **Add-ons** → **Add-on Store**
   - Click the ⋮ menu → **Repositories**
   - Add: `https://github.com/Domocn/laro-home-assistant-addon`
2. Find "Laro" in the add-on list
3. Click **Install**
4. Configure your options
5. Click **Start**
6. Access via the Home Assistant sidebar

## Configuration

See the [Laro add-on documentation](./laro/DOCS.md) for detailed configuration options.

## Support

- [Laro Repository](https://github.com/Domocn/Laro)
- [Issue Tracker](https://github.com/Domocn/laro-home-assistant-addon/issues)

## License

MIT

[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg