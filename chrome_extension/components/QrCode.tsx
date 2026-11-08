// Mã QR (SVG, vẽ trong extension, không gọi dịch vụ ngoài). Nền trắng cố định để camera đọc được cả ở giao diện tối.
import { useMemo } from 'react';
import qrcode from 'qrcode-generator';

export function QrCode({ value, size = 200 }: { value: string; size?: number }) {
  const { n, path } = useMemo(() => {
    const qr = qrcode(0, 'M');
    qr.addData(value);
    qr.make();
    const n = qr.getModuleCount();
    let path = '';
    for (let r = 0; r < n; r++) for (let c = 0; c < n; c++) if (qr.isDark(r, c)) path += `M${c} ${r}h1v1h-1z`;
    return { n, path };
  }, [value]);
  const q = 4; // vùng trắng quanh mã theo chuẩn QR
  return (
    <svg width={size} height={size} viewBox={`${-q} ${-q} ${n + q * 2} ${n + q * 2}`} shapeRendering="crispEdges"
      role="img" aria-label="Mã QR liên kết" style={{ background: '#fff', borderRadius: 12, display: 'block' }}>
      <rect x={-q} y={-q} width={n + q * 2} height={n + q * 2} fill="#fff" />
      <path d={path} fill="#111" />
    </svg>
  );
}
