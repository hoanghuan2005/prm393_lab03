import pytest
from artemis_client import ArtemisClient

@pytest.mark.asyncio
async def test_tc02_add_wishlist_item(device_serial):
    """TC-02: Happy Path - Add item to Wishlist with motive and price"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "From HomeScreen, tap (+) button to open AddItemScreen. "
        "Enter title 'Áo hoodie Shopee', price '350000', select motive 'Cảm xúc', "
        "tap 'Lưu vào Wishlist'. Verify item appears in Wishlist with status 'Đang cân nhắc'."
    )
    assert result.status == "SUCCESS", result.error
    assert result.action_count >= 2

@pytest.mark.asyncio
async def test_tc03_add_item_validation_error(device_serial):
    """TC-03: Error Path - Empty item title validation error"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "On AddItemScreen, leave product title empty and tap 'Lưu vào Wishlist'. "
        "Verify validation error 'Vui lòng nhập tên món' is shown and form is not submitted."
    )
    assert result.status == "SUCCESS", result.error
    assert result.observation.get("validation_error") == "Vui lòng nhập tên món"
    assert result.observation.get("submitted") is False

@pytest.mark.asyncio
async def test_tc04_search_and_filter(device_serial):
    """TC-04: Happy Path - Search wishlist items by keyword"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "On WishlistScreen, enter 'Áo hoodie' in search box. "
        "Verify filtered results contain matching items with count > 0."
    )
    assert result.status == "SUCCESS", result.error
    assert result.observation.get("result_count", 0) > 0

@pytest.mark.asyncio
async def test_tc05_empty_search_result(device_serial):
    """TC-05: Error/Empty Path - Search non-existent keyword displays EmptyView"""
    artemis = ArtemisClient(device_serial=device_serial)
    result = await artemis.run(
        "On WishlistScreen, search for non-existent keyword 'xyz999abc'. "
        "Verify EmptyView is displayed with message 'Không tìm thấy món nào phù hợp với bộ lọc hiện tại.'."
    )
    assert result.status == "SUCCESS", result.error
    assert result.observation.get("empty_view_displayed") is True
