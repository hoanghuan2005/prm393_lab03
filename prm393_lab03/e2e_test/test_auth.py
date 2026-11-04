import pytest
from artemis_client import ArtemisClient

@pytest.mark.asyncio
async def test_tc01_google_signin(device_serial):
    """TC-01: Native Interaction - Google Sign-in and navigate to Home"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "Open Why I Buy app. On LoginScreen, tap 'Đăng nhập với Google' and select test account. "
        "Verify navigation to HomeScreen and bottom navigation bar is visible."
    )
    assert result.status == "SUCCESS", result.error
    assert result.observation.get("view") == "HomeScreen"
    assert result.observation.get("auth_state") == "authenticated"

@pytest.mark.asyncio
async def test_tc10_sign_out(device_serial):
    """TC-10: Happy Path - Sign out and clean up local session"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "On ProfileScreen, tap 'Đăng xuất tài khoản'. "
        "Verify session data is cleared and app routes back to LoginScreen."
    )
    assert result.status == "SUCCESS", result.error
    assert result.observation.get("view") == "LoginScreen"
    assert result.observation.get("auth_state") == "unauthenticated"
