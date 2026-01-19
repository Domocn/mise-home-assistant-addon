# Changelog

All notable changes to the Mise Home Assistant Add-on will be documented in this file.

## [3.0.4] - 2026-01-19

### Fixed
- Fixed AuthContext.js URL construction for extended user fetch (prevents invalid 'null/api/...' URLs in same-origin proxy mode)
- Fixed api.js to use window.location.hash instead of pathname for HashRouter compatibility
- Fixed run.sh to properly set MISE_HA_ADDON environment variable to 'true' (enables HA addon-specific features and debug logging)

### Added
- Comprehensive HA addon functionality tests covering environment config, debug router, Home Assistant integration endpoints, frontend API config, nginx configuration, and service startup

## [3.0.3] - 2026-01-19

### Added
- Comprehensive app functionality tests (30 tests total covering user registration, authentication, 2FA, recipe management, meal planning, shopping lists, and security features)

### Fixed
- Fixed outdated tests in test_refactor.py

## [3.0.2] - 2026-01-19

### Fixed
- Resolved startup issues with upload directory creation
- Fixed missing logger import causing startup failures

## [3.0.1] - 2026-01-19

### Fixed
- Ensured timezone-aware datetimes throughout codebase
- Fixed datetime objects for asyncpg compatibility

## [3.0.0] - 2026-01-19

### Added
- Quick accessibility toggle button in header navigation for easy access to accessibility settings
- User onboarding flow for new users to improve first-time experience

## [2.0.16] - 2026-01-19

### Fixed
- Updated outdated build information in README and .env.example

## [2.0.15] - 2026-01-19

### Added
- Comprehensive neurodiversity accessibility features
- User-specific accessibility settings with backend synchronization
- Enterprise-grade code quality improvements (A++ grade)

### Fixed
- Added dietaryRestrictions to JSON_FIELDS for proper serialization

## [2.0.14] - 2026-01-18

### Fixed
- Auto-convert ISO datetime strings to datetime objects for asyncpg compatibility

## [2.0.13] - 2026-01-18

### Fixed
- Updated database/__init__.py to use correct repository class names

## [2.0.12] - 2026-01-18

### Fixed
- Resolved import errors in database modules
- Cleaned up duplicate code

## [2.0.11] - 2026-01-18

### Fixed
- Various bug fixes and stability improvements

## [2.0.10] - 2026-01-18

### Fixed
- Database connection stability improvements

## [2.0.9] - 2026-01-18

### Fixed
- API endpoint response handling fixes

## [2.0.8] - 2026-01-18

### Fixed
- WebSocket connection reliability improvements

## [2.0.7] - 2026-01-18

### Fixed
- Background job processing fixes

## [2.0.6] - 2026-01-18

### Fixed
- Redis pub/sub stability improvements

## [2.0.5] - 2026-01-18

### Fixed
- PostgreSQL query optimization fixes

## [2.0.4] - 2026-01-18

### Fixed
- User authentication flow improvements

## [2.0.3] - 2026-01-18

### Fixed
- Session management bug fixes

## [2.0.2] - 2026-01-18

### Fixed
- Initial post-migration bug fixes

## [2.0.1] - 2026-01-18

### Fixed
- Database migration optimization for large recipe collections (1000+ recipes)
- Initial bug fixes after v2.0.0 release

## [2.0.0] - 2026-01-18

### Added
- **PostgreSQL 15 Database** - Replaces MongoDB for better performance and ACID compliance
- **Redis 7** - Real-time pub/sub synchronization for shopping lists and collaborative features
- **Celery + Flower** - Background job processing for non-blocking AI operations
- **Flower Dashboard** - Web-based job monitoring on port 5555
- New API endpoints:
  - `GET /api/jobs/{job_id}` - Check background job status
  - `DELETE /api/jobs/{job_id}` - Cancel background job
  - `GET /api/health` - Enhanced health check with service status
- New configuration options for PostgreSQL, Redis, and Celery tuning
- Automatic data migration from MongoDB to PostgreSQL

### Changed
- Minimum RAM requirement increased from 2GB to 4GB
- AI endpoints now return `job_id` for non-blocking operation
- Service architecture expanded from 3 to 6 services
- All users must re-authenticate after upgrade
- OAuth connections require re-authorization

### Fixed
- Race conditions with concurrent shopping list updates
- Data loss on network interruptions
- Corrupted recipe images after import
- WebSocket disconnections on Home Assistant ingress
- Memory leaks in long-running processes
- Slow recipe search with 500+ recipes
- UI freezing during AI operations

### Performance
- 3x faster database operations
- Better handling of concurrent users (50+ supported)
- Non-blocking AI operations with background processing

## [1.0.0] - 2025-01-18

### Added
- Initial Home Assistant add-on release
- Full recipe management functionality
- AI-powered recipe import from URLs
- Meal planning with weekly calendar
- Shopping list generation
- Step-by-step cooking mode
- Multi-user household support
- Support for multiple LLM providers:
  - Embedded (no external dependencies)
  - Ollama (local AI)
  - OpenAI
  - Anthropic Claude
  - Google AI
- OAuth support (Google, GitHub)
- Email notifications via SMTP
- Home Assistant ingress support
- Persistent data storage
- Automatic JWT secret generation
