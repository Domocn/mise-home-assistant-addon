# Mise Home Assistant Add-on Documentation

## Overview

Mise is a self-hosted recipe management system designed for families. This add-on packages Mise to run seamlessly within Home Assistant, providing a privacy-focused solution for managing your recipes, meal plans, and shopping lists.

**Version 2.0.0** includes major architectural improvements:
- ✅ **PostgreSQL 15** - High-performance relational database
- ✅ **Redis 7** - Pub/Sub for real-time updates and job queue
- ✅ **Celery + Flower** - Background job processing with monitoring dashboard
- ✅ **Multi-instance support** - Horizontal scaling ready

## Features

### Recipe Management
- Create, edit, and organize recipes
- Categorize with tags and collections
- Search and filter your recipe library
- Version history for recipe changes

### AI-Powered Recipe Import
- Import recipes from any URL automatically
- AI extracts ingredients, instructions, and metadata
- **Background processing** - Non-blocking AI operations
- Supports multiple LLM providers (local or cloud)

### Meal Planning
- Weekly meal planner with drag-and-drop interface
- **Auto-generate meal plans** with AI (background job)
- Assign recipes to specific days and meals
- View nutritional information
- Plan for multiple household members

### Shopping Lists
- Auto-generate shopping lists from meal plans
- Combine ingredients intelligently
- Check off items while shopping
- **Real-time sync** across all devices via Redis Pub/Sub
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

### Background Job Processing
- **Recipe imports** - Process AI extraction in background
- **Meal plan generation** - Heavy AI operations don't block UI
- **Fridge search** - AI-powered ingredient matching
- **Flower dashboard** - Monitor job status at port 5555

## Installation

### Prerequisites

- Home Assistant OS or Supervised installation
- **At least 4GB RAM** available (increased from 2GB for PostgreSQL + Redis + Workers)
- 2GB+ free storage space
- Recommended: 2+ CPU cores

### Steps

1. Navigate to **Settings** > **Add-ons** > **Add-on Store**
2. Click the menu (three dots) and select **Repositories**
3. Add: `https://github.com/Domocn/mise-home-assistant-addon`
4. Find "Mise" in the add-on list and click **Install**
5. Wait for the installation to complete (may take longer than v1.x due to PostgreSQL/Redis)
6. Configure the add-on options (see below)
7. Click **Start**
8. Wait ~60 seconds for all services to initialize
9. Access via the sidebar or ingress URL

## ⚠️ Upgrading from 1.x to 2.0.0

**WARNING:** Version 2.0.0 is a **breaking change** that migrates from MongoDB to PostgreSQL.

### Automatic Migration (Recommended)

The add-on will attempt to migrate your data automatically on first startup:

1. **Backup your data** via Home Assistant: Settings > System > Backups
2. Update to version 2.0.0
3. Start the add-on
4. Check logs for migration status: `/var/log/mise/migration.log`
5. If migration fails, restore from backup and report issue

### Manual Migration

If automatic migration fails:

1. Export your MongoDB data (from v1.x):
   ```bash
   docker exec mise-addon mongodump --out=/data/backup
   ```
2. Use the provided migration tool (see GitHub repository)
3. Import into PostgreSQL

### Migration Notes

- ✅ All recipes, meal plans, users preserved
- ✅ Shopping lists and household data migrated
- ⚠️ Session tokens will be invalidated (users must re-login)
- ⚠️ OAuth connections need to be re-authorized

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

### Database & Performance (NEW in v2.0.0)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `postgres_max_connections` | int | 100 | Maximum PostgreSQL connections |
| `postgres_shared_buffers` | string | 256MB | PostgreSQL shared memory buffer |
| `redis_maxmemory` | string | 256mb | Maximum Redis memory usage |
| `celery_concurrency` | int | 2 | Number of background worker processes |
| `enable_flower_dashboard` | bool | true | Enable Flower job monitoring dashboard |

### Performance Tuning

**For systems with 4GB RAM** (default):
```yaml
postgres_shared_buffers: "256MB"
redis_maxmemory: "256mb"
celery_concurrency: 2
```

**For systems with 8GB+ RAM**:
```yaml
postgres_shared_buffers: "512MB"
redis_maxmemory: "512mb"
celery_concurrency: 4
```

**For low-resource systems (2-3GB RAM)**:
```yaml
postgres_shared_buffers: "128MB"
redis_maxmemory: "128mb"
celery_concurrency: 1
enable_flower_dashboard: false  # Save resources
```

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

## Architecture

### Services Running

The add-on runs **6 services** managed by Supervisor:

1. **PostgreSQL 15** (127.0.0.1:5432)
   - Main application database
   - Data stored in `/data/postgres/`
   - Configured for optimal performance

2. **Redis 7** (127.0.0.1:6379)
   - Pub/Sub for real-time WebSocket sync
   - Job queue backend for Celery
   - Data stored in `/data/redis/`

3. **Backend API** (127.0.0.1:8001)
   - FastAPI Python server
   - Handles all API requests
   - Connects to PostgreSQL and Redis

4. **Celery Worker** (Background)
   - Processes heavy AI operations
   - Recipe imports, meal planning, fridge search
   - Configurable concurrency (default: 2 workers)

5. **Flower Dashboard** (127.0.0.1:5555)
   - Web-based job monitoring
   - View active/completed/failed tasks
   - Retry failed jobs
   - Access via port 5555 or `/flower` ingress path

6. **Nginx** (0.0.0.0:3000)
   - Serves frontend React app
   - Proxies API requests
   - Handles Home Assistant ingress

### Data Persistence

All data is stored in Home Assistant's `/data` directory:
- `/data/postgres/` - PostgreSQL database files
- `/data/redis/` - Redis persistence and job queue data
- `/data/uploads/` - Uploaded recipe images and files
- `/data/jwt_secret` - JWT secret (auto-generated)

Data persists across add-on restarts and updates.

## Backup

The add-on data is included in Home Assistant backups. To backup manually:

1. Go to **Settings** > **System** > **Backups**
2. Create a new backup
3. Select the Mise add-on data

**Backup includes:**
- PostgreSQL database (all recipes, users, meal plans)
- Redis data (job queue, cached data)
- Uploaded images and files
- Configuration and secrets

## Monitoring

### Service Logs

View logs for each service:

```bash
# All services
docker exec mise-addon tail -f /var/log/mise/supervisord.log

# PostgreSQL
docker exec mise-addon tail -f /var/log/mise/postgres.log

# Redis
docker exec mise-addon tail -f /var/log/mise/redis.log

# Backend API
docker exec mise-addon tail -f /var/log/mise/backend.log

# Celery Worker
docker exec mise-addon tail -f /var/log/mise/worker.log

# Flower Dashboard
docker exec mise-addon tail -f /var/log/mise/flower.log

# Nginx
docker exec mise-addon tail -f /var/log/mise/nginx.log
```

### Flower Dashboard

Access the Flower dashboard to monitor background jobs:

- **Via Port:** http://[homeassistant-ip]:5555 (if port exposed)
- **Via Ingress:** http://[homeassistant-url]/flower

**Features:**
- Real-time task monitoring
- Worker health and status
- Task history and details
- Retry failed tasks
- Performance graphs

### Health Check Endpoint

The add-on includes health checks:

```bash
curl http://localhost:3000/health
curl http://localhost:8001/api/health
```

Response:
```json
{
  "status": "healthy",
  "app": "Mise",
  "version": "2.0.0",
  "database": "postgresql",
  "redis": {
    "enabled": true,
    "connected": true
  },
  "worker": {
    "active": true,
    "concurrency": 2
  }
}
```

## Troubleshooting

### Add-on won't start

**Check logs:**
```bash
docker logs mise-addon
```

**Common issues:**
- Insufficient RAM (need 4GB minimum)
- PostgreSQL initialization failed
- Port conflicts (3000, 8001, 5432, 6379, 5555)

**Solutions:**
- Increase Home Assistant RAM allocation
- Check `/var/log/mise/postgres.log` for database errors
- Ensure ports are not used by other add-ons

### Database issues

**PostgreSQL not starting:**
```bash
# Check PostgreSQL logs
docker exec mise-addon cat /var/log/mise/postgres-error.log

# Check data directory permissions
docker exec mise-addon ls -la /data/postgres

# Manually test PostgreSQL
docker exec mise-addon su - postgres -c "psql -d mise -c 'SELECT version();'"
```

**Reset database (⚠️ DESTROYS ALL DATA):**
```bash
docker exec mise-addon rm -rf /data/postgres
docker restart mise-addon
```

### Can't import recipes

**Check background worker:**
```bash
# View worker logs
docker exec mise-addon tail -f /var/log/mise/worker.log

# Check Flower dashboard
open http://[homeassistant-ip]:5555
```

**Common issues:**
- Worker not running (check logs)
- LLM provider misconfigured
- API keys incorrect/missing
- Network connectivity issues

**Solutions:**
- Verify LLM configuration in add-on options
- Test Ollama connectivity: `curl http://ollama-url:11434/api/tags`
- Check worker is processing jobs in Flower dashboard
- Increase `celery_concurrency` if jobs are queuing

### Redis connection issues

**Test Redis:**
```bash
# Check Redis is running
docker exec mise-addon redis-cli ping

# View Redis logs
docker exec mise-addon cat /var/log/mise/redis.log

# Check Redis memory
docker exec mise-addon redis-cli INFO memory
```

### Slow performance

**Symptoms:**
- Slow page loads
- Long import times
- UI lag

**Solutions:**
1. **Increase RAM** - Ensure 4GB+ available
2. **Tune PostgreSQL:**
   ```yaml
   postgres_shared_buffers: "512MB"  # If you have 8GB+ RAM
   postgres_max_connections: 50      # Reduce if low RAM
   ```
3. **Increase Redis memory:**
   ```yaml
   redis_maxmemory: "512mb"
   ```
4. **Scale workers:**
   ```yaml
   celery_concurrency: 4  # If you have 8GB+ RAM and 4+ cores
   ```
5. **Use external Ollama** server
6. **Use smaller LLM model** (mistral instead of llama3:70b)
7. **Disable Flower** to save resources:
   ```yaml
   enable_flower_dashboard: false
   ```

### Migration from 1.x failed

**Check migration logs:**
```bash
docker exec mise-addon cat /var/log/mise/migration.log
```

**Manual recovery:**
1. Restore Home Assistant backup (includes MongoDB data from v1.x)
2. Extract MongoDB dump manually
3. Use standalone migration tool from GitHub repo
4. Report issue with logs attached

### WebSocket disconnections

**Symptoms:**
- Real-time updates not working
- Shopping list changes not syncing
- "Connection lost" messages

**Solutions:**
- Check Redis is running: `docker exec mise-addon redis-cli ping`
- Verify `REDIS_PUBSUB_ENABLED=true` in environment
- Check backend logs for Redis connection errors
- Ensure Home Assistant ingress not blocking WebSocket upgrades

## API Access

The backend API is available at port 8001 (if exposed) or via ingress at `/api/`.

Example API endpoints:
- `GET /api/health` - Health check
- `GET /api/recipes` - List recipes (requires auth)
- `POST /api/ai/import-url` - Import recipe from URL (background job)
- `GET /api/jobs/{job_id}` - Check background job status

**Using the API:**
```bash
# Get JWT token
curl -X POST http://localhost:8001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password"}'

# Import recipe (background job)
curl -X POST http://localhost:8001/api/ai/import-url \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/recipe"}'

# Check job status
curl http://localhost:8001/api/jobs/JOB_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Security

- All traffic uses Home Assistant ingress (HTTPS)
- JWT-based authentication with secure secrets
- Optional 2FA support
- Audit logging for sensitive actions
- PostgreSQL with password authentication
- Redis bound to localhost only (127.0.0.1)
- No external connections except configured LLM providers
- Background jobs run in isolated worker processes

## Performance Benchmarks

**Typical resource usage (4GB RAM system):**
- PostgreSQL: ~150MB RAM
- Redis: ~50MB RAM
- Backend API: ~200MB RAM
- Worker (2 concurrent): ~300MB RAM
- Flower: ~100MB RAM
- Nginx: ~20MB RAM
- **Total: ~820MB** (plus frontend assets)

**Job processing times:**
- Recipe import from URL: 10-30 seconds
- Meal plan generation (7 days): 15-45 seconds
- Fridge search: 5-15 seconds

*Times vary based on LLM provider, model size, and hardware.*

## Support

- Mise App: https://github.com/Domocn/Mise
- Add-on Issues: https://github.com/Domocn/mise-home-assistant-addon/issues
- Main App Documentation: https://github.com/Domocn/Mise/blob/main/README.md
- Background Jobs Guide: https://github.com/Domocn/Mise/blob/main/BACKGROUND_JOBS.md
- Redis Pub/Sub Guide: https://github.com/Domocn/Mise/blob/main/REDIS_PUBSUB.md

## Changelog

### 2.0.0 (Breaking Change)
- ✅ Migrated from MongoDB to PostgreSQL 15
- ✅ Added Redis 7 for Pub/Sub and job queue
- ✅ Added Celery worker for background job processing
- ✅ Added Flower dashboard for job monitoring
- ✅ Multi-instance WebSocket support via Redis Pub/Sub
- ✅ Non-blocking AI operations (imports, meal plans)
- ⚠️ Breaking: Requires data migration from v1.x
- ⚠️ Breaking: Minimum RAM increased to 4GB (was 2GB)
- 🔧 Configuration options added for PostgreSQL, Redis, Celery

### 1.0.0
- Initial release with MongoDB
- Basic recipe management
- AI-powered recipe import (blocking)
- Meal planning and shopping lists
