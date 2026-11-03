import pytest
from artemis_client import ArtemisClient

@pytest.mark.asyncio
async def test_tc08_remote_config_verification(device_serial):
    """TC-08: Happy Path - Verify Remote Config parameter cooling_off_days applied on UI"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "Open ProfileScreen / Settings. Check displayed cooling off days parameter. "
        "Verify cooling_off_days value matches Remote Config (3 days default)."
    )
    assert result.status == "SUCCESS", result.error
    assert result.observation.get("cooling_off_days") == 3

@pytest.mark.asyncio
async def test_tc09_notification_permission(device_serial):
    """TC-09: Native Interaction - System runtime notification permission prompt"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "Trigger notification permission request on Android 13+. "
        "Verify system runtime permission dialog appears and accept permission."
    )
    assert result.status == "SUCCESS", result.error
    assert result.observation.get("permission_dialog") is True
