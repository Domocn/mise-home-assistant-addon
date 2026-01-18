# Mise Home Assistant Add-on Documentation

## Overview

Mise is a self-hosted recipe management system designed for families. This add-on packages Mise to run seamlessly within Home Assistant, providing a privacy-focused solution for managing your recipes, meal plans, and shopping lists.

## Features

### Recipe Management
- Create, edit, and organize recipes
- Categorize with tags and collections
- Search and filter your recipe library
- Version history for recipe changes

### AI-Powered Recipe Import
- Import recipes from any URL automatically
- AI extracts ingredients, instructions, and metadata
- Supports multiple LLM providers (local or cloud)

### Meal Planning
- Weekly meal planner with drag-and-drop interface
- Assign recipes to specific days and meals
- View nutritional information
- Plan for multiple household members

### Shopping Lists
- Auto-generate shopping lists from meal plans
- Combine ingredients intelligently
- Check off items while shopping
- Share lists with household members

### Cooking Mode
- Step-by-step cooking instructions
- Timer integration
- Ingredient scaling
- Voice commands (optional)

### Household Management
- Multiple user accounts
- Role-based permissions
- Share recipes within household
- Activity audit logging

## Installation

### Prerequisites

- Home Assistant OS or Supervised installation
- At least 2GB RAM available
- 1GB+ free storage space

### Steps

1. Navigate to **Settings** > **Add-ons** > **Add-on Store**
2. Click the menu (three dots) and select **Repositories**
3. Add: `https://github.com/Domocn/mise-home-assistant-addon`
4. Find "Mise" in the add-on list and click **Install**
5. Wait for the installation to complete
6. Configure the add-on options (see below)
7. Click **Start**
8. Access via the sidebar or ingress URL

## Configuration Options

### Authentication

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `jwt_secret` | string | (auto) | JWT signing secret. Leave empty for auto-generation |
| `enable_registration` | bool | true | Allow new users to register |

### AI/LLM Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `llm_provider` | string | embedded | AI provider: `embedded`, `ollama`, `openai`, `anthropic`, `google` |
| `ollama_url` | string | http://homeassistant.local:11434 | Ollama server URL |
| `ollama_model` | string | llama3 | Ollama model name |
| `openai_api_key` | string | - | OpenAI API key |
| `anthropic_api_key` | string | - | Anthropic API key |
| `google_ai_api_key` | string | - | Google AI API key |

### Email (SMTP)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `email_enabled` | bool | false | Enable email functionality |
| `smtp_server` | string | - | SMTP server hostname |
| `smtp_port` | int | 587 | SMTP server port |
| `smtp_username` | string | - | SMTP username |
| `smtp_password` | string | - | SMTP password |
| `smtp_from_email` | string | - | From email address |

### OAuth Providers

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable_oauth_google` | bool | false | Enable Google OAuth |
| `google_client_id` | string | - | Google OAuth client ID |
| `google_client_secret` | string | - | Google OAuth client secret |
| `enable_oauth_github` | bool | false | Enable GitHub OAuth |
| `github_client_id` | string | - | GitHub OAuth client ID |
| `github_client_secret` | string | - | GitHub OAuth client secret |

## Using Ollama for Local AI

For the best privacy and performance, run Ollama alongside Home Assistant:

### Option 1: Ollama Add-on
Install the Ollama add-on from the Home Assistant Add-on Store, then configure Mise:
```yaml
llm_provider: ollama
ollama_url: http://homeassistant.local:11434
ollama_model: llama3
```

### Option 2: External Ollama Server
If you have Ollama running on another machine:
```yaml
llm_provider: ollama
ollama_url: http://192.168.1.100:11434
ollama_model: llama3
```

### Recommended Models
- `llama3` - Best balance of quality and speed
- `mistral` - Fast and efficient
- `llama3:70b` - Higher quality (requires more RAM)

## Data Persistence

All data is stored in Home Assistant's `/data` directory:
- `/data/mongodb/` - Database files
- `/data/uploads/` - Uploaded images and files
- `/data/jwt_secret` - JWT secret (auto-generated)

Data persists across add-on restarts and updates.

## Backup

The add-on data is included in Home Assistant backups. To backup manually:

1. Go to **Settings** > **System** > **Backups**
2. Create a new backup
3. Select the Mise add-on data

## Troubleshooting

### Add-on won't start
- Check the add-on logs for error messages
- Ensure sufficient RAM (2GB+ recommended)
- Verify MongoDB has storage space

### Can't import recipes
- Check LLM provider configuration
- Verify API keys are correct
- Test Ollama connectivity: `curl http://your-ollama-url:11434/api/tags`

### Slow performance
- Increase Home Assistant resources
- Use a smaller LLM model
- Consider external Ollama server

### Database issues
- Stop the add-on
- Check `/data/mongodb/` permissions
- Restart the add-on

## API Access

The backend API is available at port 8001 (if exposed) or via ingress at `/api/`.

Example API endpoints:
- `GET /api/health` - Health check
- `GET /api/recipes` - List recipes (requires auth)
- `POST /api/recipe-import` - Import recipe from URL

## Security

- All traffic uses Home Assistant ingress (HTTPS)
- JWT-based authentication
- Optional 2FA support
- Audit logging for sensitive actions
- No external connections except configured LLM providers

## Support

- Mise App: https://github.com/Domocn/Mise
- Add-on Issues: https://github.com/Domocn/mise-home-assistant-addon/issues
