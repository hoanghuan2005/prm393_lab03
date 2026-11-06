/// One heading + paragraph of an [InfoDocument]
class InfoSection {
  final String heading;
  final String body;

  const InfoSection(this.heading, this.body);
}

/// Static text shown by InfoTextScreen
class InfoDocument {
  final String title;
  final String updated;
  final String intro;
  final List<InfoSection> sections;

  const InfoDocument({
    required this.title,
    required this.updated,
    required this.intro,
    required this.sections,
  });
}

/// Texts of Cá nhân → Hỗ trợ & thông tin. They describe what the app actually does
/// (see docs/data-model.md, docs/decisions.md); update them when that changes.
class LegalTexts {
  LegalTexts._();

  static const InfoDocument terms = InfoDocument(
    title: 'Điều khoản sử dụng',
    updated: '02/11/2026',
    intro:
        'Why I Buy? là ứng dụng của nhóm sinh viên môn PRM393, giúp bạn ghi lại '
        'vì sao mình mua và nhìn lại thói quen mua sắm. Khi dùng app, bạn đồng ý '
        'với các điều dưới đây.',
    sections: [
      InfoSection(
        'Mục đích của app',
        'App là công cụ tự chiêm nghiệm. Nhãn trên Thẻ Quyết Định, gói mua và '
            'các nhận định chỉ là quan sát từ dữ liệu bạn ghi, không phải lời khuyên '
            'tài chính. Quyết định mua, chờ hay bỏ qua luôn là của bạn.',
      ),
      InfoSection(
        'Nội dung do AI viết',
        'Một số câu chữ được viết bởi AI (Gemini qua Firebase AI Logic) và có nhãn '
            '"AI". Mọi con số do app tự tính; câu AI có thể chưa chính xác, khi đó app '
            'dùng câu mẫu có nhãn "Câu mẫu".',
      ),
      InfoSection(
        'Tài khoản',
        'Bạn đăng nhập bằng Google hoặc tài khoản khách. Tài khoản khách không '
            'đăng nhập lại được sau khi đăng xuất, nên dữ liệu của nó sẽ không xem lại '
            'được.',
      ),
      InfoSection(
        'Dữ liệu của bạn',
        'Bạn có thể xuất dữ liệu ra CSV hoặc xoá toàn bộ dữ liệu bất cứ lúc nào '
            'trong Cá nhân. Xem thêm ở Chính sách quyền riêng tư.',
      ),
      InfoSection(
        'Thay đổi',
        'App đang trong giai đoạn học tập và thử nghiệm, tính năng có thể thay đổi '
            'hoặc gián đoạn. Điều khoản sẽ được cập nhật khi cách app hoạt động thay đổi.',
      ),
    ],
  );

  static const InfoDocument privacy = InfoDocument(
    title: 'Chính sách quyền riêng tư',
    updated: '02/11/2026',
    intro:
        'Trang này nói rõ app lưu gì, gửi gì đi và bạn kiểm soát dữ liệu của mình '
        'thế nào.',
    sections: [
      InfoSection(
        'Dữ liệu app lưu',
        'Khoản mua, món mong muốn, quyết định Mua/Chờ/Bỏ qua, lịch sử giá, ngân '
            'sách, chiêm nghiệm tháng, hồ sơ mua sắm và góp ý bạn gửi. Dữ liệu được '
            'lưu trên máy và đồng bộ với tài khoản của bạn trên Cloud Firestore khi có '
            'mạng. Chỉ tài khoản của bạn đọc được dữ liệu này.',
      ),
      InfoSection(
        'Dữ liệu gửi cho AI',
        'Khi tạo nhận định, app gửi cho Gemini (qua Firebase AI Logic) các con số '
            'đã tính sẵn và tên món liên quan, không gửi email hay tên tài khoản. Bạn '
            'có thể tắt AI; khi đó app chỉ dùng câu mẫu.',
      ),
      InfoSection(
        'Thống kê và lỗi',
        'App dùng Firebase Analytics để đếm cách các màn hình được dùng và Firebase '
            'Crashlytics để ghi lỗi, giúp nhóm sửa app. Sự kiện thống kê chỉ ghi khoảng '
            'số tiền (ví dụ "dưới 100 nghìn"), không ghi số tiền chính xác, tên món hay '
            'ghi chú của bạn.',
      ),
      InfoSection(
        'Thông báo',
        'Nhắc ghi khoản mua và nhắc xem lại món là thông báo tạo ngay trên máy. '
            'Bạn bật hoặc tắt chúng trong Cá nhân hoặc cài đặt của máy.',
      ),
      InfoSection(
        'Extension trình duyệt',
        'Extension chỉ đọc trang sản phẩm Shopee đang mở khi bạn bấm vào biểu '
            'tượng Why I Buy?, và chỉ liên kết với tài khoản sau khi bạn đồng ý trên '
            'điện thoại. Bạn có thể huỷ liên kết trong Cá nhân.',
      ),
      InfoSection(
        'Xuất và xoá dữ liệu',
        'File CSV và báo cáo PDF được tạo trên máy, không tải lên máy chủ. "Xoá '
            'toàn bộ dữ liệu" trong Cá nhân xoá vĩnh viễn dữ liệu của bạn khỏi tài '
            'khoản và không thể hoàn tác.',
      ),
    ],
  );
}
