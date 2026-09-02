def greet(name: str) -> str:
    cleaned = name.strip()
    if not cleaned:
        raise ValueError("name cannot be empty")
    return f"Hello, {cleaned}!"
