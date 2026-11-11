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

  static const supportEmail = 'daotamhoang2005@gmail.com';

  static const InfoDocument terms = InfoDocument(
    title: 'Điều khoản sử dụng',
    updated: '10/11/2026',
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
        'Bạn đăng nhập bằng Google, Facebook, GitHub, email/mật khẩu hoặc tài khoản khách. Tài khoản khách không '
            'đăng nhập lại được sau khi đăng xuất, nên dữ liệu của nó sẽ không xem lại '
            'được.',
      ),
      InfoSection(
        'Dữ liệu của bạn',
        'Bạn có thể xuất dữ liệu ra CSV hoặc xoá dữ liệu chi tiêu '
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
    updated: '11/11/2026',
    intro:
        'Trang này nói rõ app lưu gì, gửi gì đi và bạn kiểm soát dữ liệu của mình '
        'thế nào.',
    sections: [
      InfoSection(
        'Đăng nhập và Facebook',
        'App dùng Firebase Authentication để đăng nhập và liên kết các cách đăng nhập. '
            'Với Facebook, app chỉ xin public_profile và email để nhận mã định danh, '
            'tên hiển thị và email nếu bạn cung cấp. Không có email vẫn dùng được app. '
            'Nhà cung cấp có thể trả đường dẫn ảnh đại diện trong hồ sơ đăng nhập; '
            'app không yêu cầu quyền đọc bài viết hay danh sách bạn bè. '
            'Hồ sơ trong Firestore lưu tên, email nếu có và trạng thái tài khoản. '
            'Meta và Google xử lý dữ liệu đăng nhập theo chính sách của họ. '
            'App tắt tự động ghi sự kiện và thu thập mã quảng cáo của Facebook SDK trên Android.',
      ),
      InfoSection(
        'Dữ liệu app lưu',
        'Khoản mua, món mong muốn, quyết định Mua/Chờ/Bỏ qua, lịch sử giá, ngân '
            'sách, chiêm nghiệm tháng, hồ sơ mua sắm và góp ý bạn gửi. Mỗi lần chia '
            'sẻ báo cáo PDF, app chỉ lưu tháng, số mục và dung lượng file; file không '
            'được tải lên. Đợt sale bạn báo (tên, ngày, nơi công bố) được lưu kèm mã '
            'tài khoản để nhóm kiểm tra và trả lời trong Hộp thư. Dữ liệu được '
            'lưu trên máy và đồng bộ với tài khoản của bạn trên Cloud Firestore khi có '
            'mạng. Quyền truy cập được kiểm soát bằng Firebase Authentication và '
            'Firestore Rules; quản trị viên có quyền theo chức năng quản trị. Giá '
            'bạn chủ động chia sẻ được dùng làm dữ liệu tham khảo cộng đồng. '
            'Nhóm không bán dữ liệu cá nhân.',
      ),
      InfoSection(
        'Dữ liệu gửi cho AI',
        'Khi tạo nhận định, app gửi cho Gemini (qua Firebase AI Logic) các con số '
            'đã tính sẵn và tên món liên quan, không gửi email hay tên tài khoản. Bạn '
            'có thể tắt các gợi ý AI; khi đó app dùng câu mẫu. Khi bạn chủ động '
            'chụp/chọn ảnh để tìm kiếm, ảnh được gửi cho dịch vụ AI để nhận diện '
            'món đồ. Tránh gửi ảnh có thông tin riêng tư không cần thiết.',
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
        'Nhắc ghi khoản mua, nhắc xem lại món và nhắc chiêm nghiệm cuối tháng là '
            'thông báo tạo ngay trên máy. Thông báo chung đã đọc được ghi nhớ trên máy. '
            'App cũng dùng Firebase Cloud Messaging để nhận thông báo từ hệ thống; '
            'mã thiết bị được lưu để gửi thông báo. '
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
        'File CSV và báo cáo PDF được tạo trên máy. Nút "Xoá toàn bộ dữ liệu" '
            'trong Cá nhân xoá các khoản mua, món mong muốn cùng lịch sử giá của '
            'chúng, quyết định, ngân sách, chiêm nghiệm, thông tin báo cáo PDF đã '
            'chia sẻ và đồ đã sở hữu; không thể hoàn tác. Nút này vẫn giữ tài khoản '
            'đăng nhập, hồ sơ và nhóm ngân sách; không phải chức năng xoá tài khoản. '
            'Dữ liệu khác như góp ý, phiên extension, giá đã chia sẻ, đợt sale bạn đã '
            'báo và tin trong Hộp thư không nằm trong thao tác này. Để yêu '
            'cầu xoá tài khoản và dữ liệu còn lại, liên hệ nhóm theo mục dưới.',
      ),
      _deletionContact,
    ],
  );

  static const _deletionContact = InfoSection(
    'Liên hệ và thời gian xử lý',
    'Gửi yêu cầu tới $supportEmail, ghi rõ muốn xoá dữ liệu hay '
        'xoá cả tài khoản Why I Buy?, kèm UID (nếu biết), tên hiển thị hoặc email '
        'đăng nhập để nhóm xác định tài khoản. Không gửi mật khẩu, mã OTP hay '
        'access token. Với Facebook không có email, hãy nêu rõ và liên hệ nhóm '
        'để xác minh quyền sở hữu. Nhóm sẽ xác nhận phạm vi và thông báo thời '
        'gian xử lý sau khi tiếp nhận, xác minh yêu cầu; hiện chưa công bố thời '
        'hạn cố định. Bản CSV/PDF bạn đã xuất cần được bạn tự xoá.',
  );

  static const InfoDocument dataDeletion = InfoDocument(
    title: 'Hướng dẫn xoá dữ liệu',
    updated: '11/11/2026',
    intro: 'Áp dụng cho tài khoản Why I Buy?, bao gồm đăng nhập Facebook.',
    sections: [
      InfoSection(
        'Xoá dữ liệu chi tiêu trong app',
        'Đăng nhập đúng tài khoản → Cá nhân → Xoá toàn bộ dữ liệu của tôi → '
            'đọc hộp thoại và xác nhận. Thao tác xoá khoản mua, món mong muốn '
            'và lịch sử giá của chúng, quyết định, ngân sách, chiêm nghiệm, '
            'thông tin báo cáo PDF đã chia sẻ và đồ đã sở hữu. Dữ liệu đã xoá '
            'không thể hoàn tác. Tài khoản đăng nhập, hồ sơ và nhóm ngân sách '
            'vẫn được giữ lại; góp ý, phiên extension, giá đã chia sẻ, đợt sale '
            'bạn đã báo và tin trong Hộp thư không được xoá bằng nút này.',
      ),
      InfoSection(
        'Yêu cầu xoá tài khoản và dữ liệu còn lại',
        'App hiện chưa có nút xoá tài khoản Firebase Authentication. Bạn có '
            'thể yêu cầu nhóm xử lý thủ công qua email bên dưới, bao gồm hồ sơ '
            'và dữ liệu liên quan còn lưu theo tài khoản. Nhóm cần xác minh '
            'quyền sở hữu trước khi xoá. Gỡ app khỏi điện thoại không xoá dữ '
            'liệu đã đồng bộ trên Firestore.',
      ),
      InfoSection(
        'Huỷ liên kết Facebook',
        'Cá nhân → Tài khoản liên kết → Facebook → Huỷ liên kết (phải còn ít '
            'nhất một cách đăng nhập khác). Bạn cũng có thể gỡ Why I Buy? '
            'trong mục Ứng dụng và trang web của Facebook. Huỷ liên kết hoặc '
            'gỡ quyền trên Facebook không tự xoá tài khoản hay dữ liệu Why I Buy?. '
            'Để xoá dữ liệu do Meta lưu, dùng công cụ của Facebook.',
      ),
      _deletionContact,
    ],
  );
}
