// Thêm món cân nhắc (lib/screens/add_item_screen.dart) opened from the Android
// share sheet: ShareIntentService pre-fills title + link, ProductMetadataService
// then reads the Shopee page (image, shop, canonical URL). Price is never invented.
import { html, icon, appBar, button, field, motiveChip, snackbar } from './kit.js'

const ORDER = ['need', 'want', 'sale', 'emotion', 'social', 'convenience', 'ads', 'other']

export default {
  id: 'add-item',
  render() {
    return html`
      <div class="wib-screen scr-add">
        <style>
          .scr-add .ai-banner{display:flex;align-items:center;gap:12px;padding:12px 16px;margin-bottom:16px;border-radius:12px;background:rgba(255,222,2,.08);box-shadow:inset 0 0 0 1px rgba(255,222,2,.25);font-size:14px;font-weight:500;color:#C9A800}
          .scr-add .ai-spin{width:18px;height:18px;border-radius:50%;border:2px solid #0F172A;border-right-color:transparent;animation:wib-spin .8s linear infinite;flex:none}
          .scr-add .ai-preview{display:flex;gap:12px;padding:12px;margin-bottom:16px;border-radius:12px;background:#fff;box-shadow:inset 0 0 0 1px rgba(226,232,240,.6)}
          .scr-add .ai-img{width:68px;height:68px;border-radius:8px;flex:none;display:grid;place-items:center;color:#fff;background:linear-gradient(140deg,#1F2937,#4B5563 60%,#9CA3AF)}
          .scr-add .ai-tag{display:inline-block;padding:2px 6px;border-radius:4px;background:rgba(238,77,45,.12);color:#EE4D2D;font-size:11px;font-weight:700}
          .scr-add .ai-hint{display:flex;gap:12px;padding:16px;border-radius:12px;background:#F3E8FF;box-shadow:inset 0 0 0 1px rgba(168,85,247,.3);color:#A855F7;font-size:14px;line-height:1.4}
        </style>
        ${appBar({ title: 'Thêm món cân nhắc' })}
        <div class="wib-body">
          <div class="wib-scroll" data-k="scroll" style="padding-bottom:120px">
            <div class="ai-banner" data-k="banner"><span class="ai-spin"></span>Đang tự động lấy thông tin từ Shopee...</div>
            <div class="ai-preview" data-k="preview" style="display:none">
              <span class="ai-img">${icon('speaker_rounded', 34)}</span>
              <div class="wib-col" style="justify-content:center">
                <span><span class="ai-tag">Shopee</span></span>
                <span data-k="shopline" style="margin-top:4px;font-size:11px;font-weight:500;color:var(--text-2)">Shop: Góc Âm Thanh 79</span>
              </div>
            </div>
            ${field({ label: 'Tên sản phẩm *', value: 'Loa Bluetooth G63, Loa Chữ G Kèm Đồng Hồ', cls: 'f-title' })}
            <div style="height:16px"></div>
            ${field({ label: 'Giá dự kiến (không bắt buộc)', hint: 'Để trống nếu chưa biết giá', suffix: '₫', cls: 'f-price' })}
            <div style="height:16px"></div>
            ${field({ label: 'Link Shopee / Lazada (Tùy chọn)', value: 'https://vn.shp.ee/MG5chA9s', prefix: icon('link', 20), cls: 'f-link' })}
            <div style="height:16px"></div>
            ${field({ label: 'Tên cửa hàng / Shop (Tùy chọn)', hint: 'Ví dụ: Shopee Mall, Shop Thời Trang...', prefix: icon('storefront_outlined', 20), cls: 'f-shop' })}
            <div style="height:24px"></div>
            <div class="t-title-m">Mức ưu tiên</div>
            <div class="wib-row" style="color:#F59E0B;margin-left:-12px">
              ${[1, 2, 3].map(() => `<span class="wib-iconbtn" style="color:#F59E0B">${icon('star_rounded')}</span>`)}
              ${[4, 5].map(() => `<span class="wib-iconbtn" style="color:#F59E0B">${icon('star_outline_rounded')}</span>`)}
            </div>
            <div style="height:16px"></div>
            <div class="t-title-m">Tại sao bạn muốn mua món này? *</div>
            <div class="t-body-m" style="margin-top:4px">Chọn thật lòng động cơ thúc đẩy quyết định của bạn:</div>
            <div data-k="motives" style="display:flex;flex-wrap:wrap;gap:8px;margin-top:12px">
              ${ORDER.map((m) => motiveChip(m, { selected: m === 'emotion' }))}
            </div>
            <div class="ai-hint" data-k="hint" style="margin-top:20px">${icon('psychology', 24)}<span>Món này có 3 ngày cân nhắc trước khi quyết định (mọi động cơ trừ Nhu cầu).</span></div>
            <div style="height:32px"></div>
            ${button('Lưu vào Wishlist', { icon: icon('check', 20), cls: 'b-save' })}
          </div>
        </div>
        ${snackbar('Đã lưu vào danh sách cân nhắc. Thời gian cân nhắc: 3 ngày.')}
      </div>`
  },

  demo(tl, root, k) {
    const shop = k.q('.f-shop .wib-input__value')
    const link = k.q('.f-link .wib-input__value')
    k.reveal(tl, '.wib-field', { stagger: 0.05 })
    k.callout(tl, '.f-title', 'Tự điền từ link Shopee', { pos: 0.5 })
    // metadata resolves: banner out, preview + shop + canonical link in
    tl.to(k.q('[data-k="banner"]'), { opacity: 0, height: 0, marginBottom: 0, paddingTop: 0, paddingBottom: 0, duration: 0.35, ease: 'power2.in' }, 1.8)
    tl.set(k.q('[data-k="banner"]'), { display: 'none' })
    tl.set(k.q('[data-k="preview"]'), { display: 'flex' })
    tl.fromTo(k.q('[data-k="preview"]'), { opacity: 0, y: -8 }, { opacity: 1, y: 0, duration: 0.45, ease: 'power3.out' })
    k.text(tl, link, 'https://shopee.vn/Loa-Bluetooth-G63-i.12345.67890', '<')
    k.type(tl, shop, 'Góc Âm Thanh 79', { pos: '<+=0.1', cps: 30 })
    k.callout(tl, '.f-price', 'Không có giá thì để trống, không bịa', { pos: '+=0.1' })
    k.scroll(tl, '[data-k="scroll"]', 470, { pos: '+=1.1', duration: 1.1 })
    k.tap(tl, '[data-motive="emotion"]', { pos: '+=0.2' })
    k.callout(tl, '[data-k="hint"]', 'Mặc định hoãn 3 ngày', { pos: '+=0.1' })
    k.scroll(tl, '[data-k="scroll"]', 640, { pos: '+=0.5', duration: 0.7 })
    k.tap(tl, '.b-save', { pos: '+=0.2', then: (el) => el.classList.add('is-loading') })
    k.snack(tl, '.wib-snackbar', { pos: '+=0.7' })
    k.wait(tl, 1)
  },
}
