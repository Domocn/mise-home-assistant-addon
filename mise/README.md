# Mise - Home Assistant Add-on

Self-hosted family recipe management, meal planning, and cooking assistant for Home Assistant.

## About

Mise is a comprehensive recipe management system that runs directly on your Home Assistant instance. It provides:

- **Recipe Management**: Store, organize, and search your family recipes
- **AI-Powered Import**: Import recipes from any URL using AI
- **Meal Planning**: Plan your weekly meals with drag-and-drop calendar
- **Shopping Lists**: Auto-generate shopping lists from meal plans
- **Cooking Mode**: Step-by-step cooking guidance
- **Multi-User Support**: Household management with multiple users
- **Privacy-First**: All data stays on your Home Assistant

## Installation

1. Add this repository to your Home Assistant Add-on Store
2. Install the "Mise" add-on
3. Configure your options (see Configuration below)
4. Start the add-on
5. Access via the Home Assistant sidebar

## Configuration

### Basic Options

| Option | Description | Default |
|--------|-------------|---------|
| `jwt_secret` | Secret key for authentication (auto-generated if empty) | Auto-generated |
| `llm_provider` | AI provider: `embedded`, `ollama`, `openai`, `anthropic`, `google` | `embedded` |
| `enable_registration` | Allow new user registration | `true` |

### LLM Configuration

For AI-powered recipe import and features:

**Ollama (Recommended for local AI)**
```yaml
llm_provider: ollama
ollama_url: http://homeassistant.local:11434
ollama_model: llama3
```

**OpenAI**
```yaml
llm_provider: openai
openai_api_key: your-api-key
```

**Anthropic Claude**
```yaml
llm_provider: anthropic
anthropic_api_key: your-api-key
```

### Email Configuration (Optional)

For password reset and notifications:

```yaml
email_enabled: true
smtp_server: smtp.example.com
smtp_port: 587
smtp_username: your-username
smtp_password: your-password
smtp_from_email: mise@example.com
```

### OAuth Configuration (Optional)

Enable Google/GitHub login:

```yaml
enable_oauth_google: true
google_client_id: your-client-id
google_client_secret: your-client-secret
```

## Support

- [Documentation](https://github.com/Domocn/Mise)
- [Issue Tracker](https://github.com/Domocn/Mise/issues)
