# -*- coding: utf-8 -*-
"""Định nghĩa lớp cơ sở (Base Adapter) cho các nhà cung cấp hình ảnh và video trong MausBot Video Factory."""
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from pathlib import Path


class BaseVisualAdapter(ABC):
    """Lớp giao diện chuẩn cho adapter tạo hình ảnh/video cảnh quay."""

    def __init__(self, name: str, config: Optional[Dict[str, Any]] = None):
        self.name = name
        self.config = config or {}

    @abstractmethod
    def is_available(self) -> bool:
        """Kiểm tra xem adapter có đủ điều kiện vận hành (môi trường, API key, kết nối) không."""
        pass

    @abstractmethod
    def generate_scene_asset(self, scene_id: str, scene_data: Dict[str, Any], output_dir: Path) -> Path:
        """Sinh tài sản thị giác (ảnh PNG/JPG hoặc video MP4) cho một phân cảnh bài học.
        Trả về đường dẫn tới file tài sản đã tạo.
        """
        pass
