import pytest
from artemis_client import ArtemisClient

@pytest.mark.asyncio
async def test_tc06_make_decision_skip(device_serial):
    """TC-06: Happy Path - Update decision to Skip with SnackBar confirmation"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "Open ItemDetailScreen for an item. Tap 'Bỏ qua'. "
        "Verify item status updates to 'Bỏ qua' and SnackBar confirms 'Đã chuyển món sang Bỏ qua.'."
    )
    assert result.status == "SUCCESS", result.error
    assert result.observation.get("status_updated") == "skip"

@pytest.mark.asyncio
async def test_tc07_export_pdf_report(device_serial):
    """TC-07: Happy Path - Generate and share PDF monthly reflection report"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "Navigate to MonthlyReflectionScreen. Tap 'Xuất và chia sẻ PDF'. "
        "Verify PDF report 'why-i-buy_2026-11.pdf' is generated and system share sheet opens."
    )
    assert result.status == "SUCCESS", result.error
    assert result.observation.get("pdf_generated") is True
