# Task

Implement `normalize_slug(value: str) -> str` in `src/slug.py`.

Behavior:
- Trim leading and trailing whitespace
- Lowercase the result
- Collapse runs of whitespace into "-"
- Reject empty or whitespace-only input with ValueError
- Preserve already-valid hyphens
- Do not make unrelated changes

Validation:
- Run the repository's full automated test suite
