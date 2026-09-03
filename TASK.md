# Task

Add timeout configuration support to the existing service configuration system.

Requirements:
- ServiceConfig must include timeout_ms (int, 1..60000, default 5000)
- JSON config may provide timeout_ms
- SERVICE_TIMEOUT_MS env var overrides JSON
- Invalid timeout raises ValueError
- Existing base_url behavior must remain unchanged
- ServiceClient must consume the resolved timeout
- Add/update tests
