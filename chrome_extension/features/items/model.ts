// 8 động cơ (thứ tự theo Figma EXT-4) và 6 nhóm ngân sách mặc định (Spec mục 599, "Nhóm quyết").
export const MOTIVES = [
  { id: 'nhu-cau', label: 'Nhu cầu', icon: 'shield' },
  { id: 'mong-muon', label: 'Mong muốn', icon: 'sparkles' },
  { id: 'khuyen-mai', label: 'Khuyến mãi', icon: 'tag' },
  { id: 'cam-xuc', label: 'Cảm xúc', icon: 'heart' },
  { id: 'anh-huong-mxh', label: 'Ảnh hưởng MXH', icon: 'users' },
  { id: 'tien-loi', label: 'Tiện lợi', icon: 'zap' },
  { id: 'quang-cao', label: 'Quảng cáo', icon: 'megaphone' },
  { id: 'khac', label: 'Khác', icon: 'more' },
] as const;

export const CATEGORIES = [
  { id: 'an-uong', label: 'Ăn uống' },
  { id: 'thoi-trang', label: 'Thời trang' },
  { id: 'cong-nghe', label: 'Công nghệ' },
  { id: 'lam-dep', label: 'Làm đẹp' },
  { id: 'hoc-tap', label: 'Học tập' },
  { id: 'khac', label: 'Khác' },
] as const;

export const categoryLabel = (id?: string) => CATEGORIES.find((c) => c.id === id)?.label;
export const motiveLabel = (id?: string) => MOTIVES.find((m) => m.id === id)?.label;
