class ServiceClient:
    def __init__(self, base_url: str, timeout_ms: int = 5000):
        self.base_url = base_url
        self.timeout_ms = timeout_ms
