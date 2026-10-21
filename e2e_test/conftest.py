import pytest
import os

# Pytest fixture scaffolding for Google ARTEMIS testing client
# Uses environment variables for API key and device serial

@pytest.fixture(scope="session")
def device_serial():
    return os.environ.get("ANDROID_SERIAL", "emulator-5554")

@pytest.fixture(scope="session")
def model_api_key():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        pytest.skip("GEMINI_API_KEY environment variable is not set")
    return api_key
