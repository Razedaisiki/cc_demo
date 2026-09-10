def parse_port(value: str) -> int:
    text = value.strip()
    if not text:
        raise ValueError("port must be a non-empty string")
    try:
        port = int(text)
    except ValueError:
        raise ValueError(f"port {text!r} is not a valid integer")
    if not (1 <= port <= 65535):
        raise ValueError(f"port {port} out of range (1-65535)")
    return port
