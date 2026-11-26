# -*- coding: utf-8 -*-
"""Adapter hình ảnh nội bộ (Local Template Adapter) — Cấu hình 1: Local / Miễn phí 0đ.
Sử dụng Pillow và bộ mẫu thẻ bài giảng Trường Xanh Tuệ Đức, chạy offline 100% không tốn chi phí.
"""
import os
import json
from pathlib import Path
from typing import Dict, Any, Optional
from PIL import Image, ImageDraw, ImageFont
from .base_adapter import BaseVisualAdapter


class LocalTemplateAdapter(BaseVisualAdapter):
    """Adapter cục bộ tạo khung hình bài giảng chuẩn nhận diện Trường Xanh Tuệ Đức."""

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        super().__init__("local_template", config)
        self.w = 1920
        self.h = 1080
        # Bảng màu chuẩn Tuệ Đức
        self.c_bg = (238, 246, 241)       # #EEF6F1
        self.c_card = (255, 255, 255)     # #FFFFFF
        self.c_primary = (31, 138, 76)    # #1F8A4C (Xanh Tuệ Đức)
        self.c_navy = (30, 58, 95)        # #1E3A5F (Xanh áo giáo sư)
        self.c_accent = (255, 200, 61)    # #FFC83D (Vàng cam)
        self.c_text = (20, 46, 38)        # #142E26 (Chữ xanh đen)
        self.c_border = (210, 230, 218)   # #D2E6DA

    def is_available(self) -> bool:
        """Adapter nội bộ luôn sẵn sàng vì không phụ thuộc mạng hay API key."""
        return True

    def _get_font(self, size: int, bold: bool = False):
        font_path = "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"
        if not os.path.exists(font_path):
            font_path = "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"
        try:
            return ImageFont.truetype(font_path, size)
        except Exception:
            return ImageFont.load_default()

    def generate_scene_asset(self, scene_id: str, scene_data: Dict[str, Any], output_dir: Path) -> Path:
        """Vẽ khung hình bài giảng đồ họa sắc nét."""
        output_dir.mkdir(parents=True, exist_ok=True)
        out_file = output_dir / f"{scene_id}.png"

        img = Image.new("RGB", (self.w, self.h), self.c_bg)
        d = ImageDraw.Draw(img)

        # 1. Hạt chấm bi trang trí nền (đặc trưng giao diện Trường Xanh)
        dot_color = (215, 233, 222)
        for gx in range(40, self.w, 40):
            for gy in range(40, self.h, 40):
                d.ellipse([gx - 2, gy - 2, gx + 2, gy + 2], fill=dot_color)

        # 2. Thanh tiêu đề trên cùng (Thương hiệu Trường Xanh)
        bar_h = 70
        d.rectangle([0, 0, self.w, bar_h], fill=self.c_primary)
        f_top = self._get_font(28, bold=True)
        d.text((60, 18), "TRƯỜNG XANH TUỆ ĐỨC · MAUSBOT VIDEO FACTORY", font=f_top, fill=(255, 255, 255))

        # 3. Thẻ nội dung chính (Bảng trắng bo góc)
        card_x, card_y, card_w, card_h = 100, 120, 1720, 880
        # Đổ bóng nhẹ
        d.rounded_rectangle([card_x + 6, card_y + 6, card_x + card_w + 6, card_y + card_h + 6],
                            radius=20, fill=(205, 222, 212))
        d.rounded_rectangle([card_x, card_y, card_x + card_w, card_y + card_h],
                            radius=20, fill=self.c_card, outline=self.c_border, width=3)

        # 4. Tiêu đề phân cảnh
        title = scene_data.get("title", f"Phân cảnh {scene_id}")
        f_title = self._get_font(48, bold=True)
        d.text((card_x + 60, card_y + 50), title, font=f_title, fill=self.c_navy)

        # Đường kẻ phân cách
        d.line([card_x + 60, card_y + 120, card_x + card_w - 60, card_y + 120], fill=self.c_border, width=2)

        # 5. Các ý bài học chính
        steps = scene_data.get("steps", [])
        f_body = self._get_font(36, bold=False)
        f_num = self._get_font(32, bold=True)
        sy = card_y + 160
        for i, step_text in enumerate(steps, 1):
            # Vòng tròn số thứ tự
            num_x, num_y = card_x + 70, sy + 5
            d.ellipse([num_x, num_y, num_x + 44, num_y + 44], fill=self.c_primary)
            d.text((num_x + 14, num_y + 2), str(i), font=f_num, fill=(255, 255, 255))
            # Nội dung dòng
            clean_text = str(step_text).replace("*", "")
            d.text((num_x + 65, sy + 6), clean_text, font=f_body, fill=self.c_text)
            sy += 90

        # 6. Ghi chú chân thẻ
        f_sub = self._get_font(22, bold=False)
        d.text((card_x + 60, card_y + card_h - 60),
               "Tự động sản xuất bởi MausBot · Cấu hình Local/Miễn phí · Giọng đọc Bắc chuẩn VieNeu-TTS Hải Đăng",
               font=f_sub, fill=(110, 130, 120))

        img.save(out_file, "PNG")
        return out_file
