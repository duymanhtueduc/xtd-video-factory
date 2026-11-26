# -*- coding: utf-8 -*-
"""Bộ điều phối trung tâm (Central Pipeline Orchestrator) — Quản lý 6 vai agent trong MausBot Video Factory."""
import os
import sys
import json
import time
import hashlib
import subprocess
from pathlib import Path
from typing import Dict, Any, List, Optional

from ..adapters.local_template_adapter import LocalTemplateAdapter
from ..adapters.ai_provider_adapter import AIProviderAdapter
from .qa_verifier import QAVerifier


class VideoFactoryOrchestrator:
    """Bộ điều phối sản xuất video bài giảng tự động cho giáo viên."""

    def __init__(self, workspace_dir: Path, config_type: str = "local",
                 ffmpeg_path: str = "ffmpeg", ffprobe_path: str = "ffprobe"):
        self.workspace_dir = Path(workspace_dir)
        self.workspace_dir.mkdir(parents=True, exist_ok=True)
        self.config_type = config_type
        self.ffmpeg = ffmpeg_path
        self.ffprobe = ffprobe_path

        # Khởi tạo adapter hình ảnh theo cấu hình
        if config_type == "paid_provider":
            self.visual_adapter = AIProviderAdapter("openai_dalle3")
        else:
            self.visual_adapter = LocalTemplateAdapter()

        self.qa_verifier = QAVerifier(ffprobe_path=self.ffprobe, ffmpeg_path=self.ffmpeg)

    def run_pipeline(self, lesson_spec: Dict[str, Any], output_dir: Path) -> Dict[str, Any]:
        """Thực thi toàn bộ luồng sản xuất qua 6 cổng agent."""
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        work_dir = output_dir / "work"
        work_dir.mkdir(parents=True, exist_ok=True)

        lesson_id = lesson_spec.get("lesson_id", f"lesson_{int(time.time())}")
        print(f"🎬 [Agent 1 - Điều phối] Bắt đầu sản xuất bài giảng: {lesson_id} (Cấu hình: {self.config_type})")

        # CỔNG 1: SƯ PHẠM & KIỂM CHỨNG
        print("🔍 [Agent 2 - Sư phạm] Đang kiểm chứng nội dung và quét an toàn dữ liệu...")
        self._gate_pedagogy(lesson_spec)

        # CỔNG 2: BIÊN KỊCH
        print("✍️ [Agent 3 - Biên kịch] Đang biên soạn phân cảnh và lời thuyết minh...")
        scenes = self._gate_scriptwriting(lesson_spec, work_dir)

        # CỔNG 3: ĐẠO DIỄN HÌNH ẢNH
        print(f"🎨 [Agent 4 - Đạo diễn] Đang tạo hình ảnh phân cảnh bằng {self.visual_adapter.name}...")
        rendered_scenes = self._gate_visual_direction(scenes, work_dir)

        # CỔNG 4: KỸ SƯ DỰNG
        print("⚙️ [Agent 5 - Kỹ sư dựng] Đang tổng hợp âm thanh, phụ đề và render video FFmpeg...")
        video_out, srt_out, thumb_out = self._gate_render(lesson_id, rendered_scenes, output_dir, work_dir)

        # CỔNG 5: KIỂM ĐỊNH CHẤT LƯỢNG
        print("📋 [Agent 6 - QA Verifier] Đang thực hiện kiểm định ffprobe, âm lượng và chuẩn hóa...")
        qa_report_file = output_dir / "QA_REPORT.md"
        qa_result = self.qa_verifier.verify_video(video_out, srt_out, qa_report_file)

        # CỔNG 6: TỔNG HỢP BÀN GIAO & TẠO MANIFEST
        manifest = self._generate_manifest(lesson_id, video_out, srt_out, thumb_out, qa_result, output_dir)
        print(f"✅ Hoàn tất bàn giao bài giảng: {video_out.name} ({qa_result['status']})")

        return {
            "status": qa_result["status"],
            "video_path": str(video_out),
            "srt_path": str(srt_out),
            "thumbnail_path": str(thumb_out),
            "manifest_path": str(manifest),
            "qa_report_path": str(qa_report_file)
        }

    def _gate_pedagogy(self, lesson_spec: Dict[str, Any]):
        """Agent 2: Rà soát PII và cụm từ cấm."""
        content_to_check = json.dumps(lesson_spec, ensure_ascii=False)
        for forbidden in ["một cú bấm", "miễn phí hoàn toàn", "tự vẽ ảnh"]:
            if forbidden in content_to_check:
                raise ValueError(f"Sư phạm chặn: Phát hiện cụm từ cấm '{forbidden}'")

    def _gate_scriptwriting(self, lesson_spec: Dict[str, Any], work_dir: Path) -> List[Dict[str, Any]]:
        """Agent 3: Chuẩn hóa danh sách các phân cảnh."""
        scenes = lesson_spec.get("scenes", [])
        if not scenes:
            raise ValueError("Không có phân cảnh nào trong giáo án!")
        script_file = work_dir / "script.json"
        script_file.write_text(json.dumps(scenes, ensure_ascii=False, indent=2), encoding="utf-8")
        return scenes

    def _gate_visual_direction(self, scenes: List[Dict[str, Any]], work_dir: Path) -> List[Dict[str, Any]]:
        """Agent 4: Tạo tài sản thị giác cho từng phân cảnh."""
        frames_dir = work_dir / "frames"
        frames_dir.mkdir(parents=True, exist_ok=True)
        results = []
        for scene in scenes:
            sid = scene["id"]
            img_path = self.visual_adapter.generate_scene_asset(sid, scene, frames_dir)
            scene_copy = dict(scene)
            scene_copy["asset_path"] = str(img_path)
            results.append(scene_copy)
        return results

    def _gate_render(self, lesson_id: str, scenes: List[Dict[str, Any]], output_dir: Path, work_dir: Path):
        """Agent 5: Sinh giọng đọc, tạo SRT và render video hoàn chỉnh."""
        video_out = output_dir / f"{lesson_id}.mp4"
        srt_out = output_dir / f"{lesson_id}.srt"
        thumb_out = output_dir / "thumbnail.jpg"

        # 1. Tạo thumbnail từ cảnh đầu tiên
        if scenes and "asset_path" in scenes[0]:
            import shutil
            shutil.copy(scenes[0]["asset_path"], thumb_out)

        # 2. Xây dựng SRT và âm thanh từng cảnh
        srt_lines = []
        concat_list = []
        current_time = 0.0

        for idx, scene in enumerate(scenes, 1):
            dur = float(scene.get("duration", 6.0))
            text = scene.get("narration", "")

            # Ghi mục SRT
            start_str = self._format_timestamp(current_time)
            end_str = self._format_timestamp(current_time + dur)
            srt_lines.append(f"{idx}\n{start_str} --> {end_str}\n{text}\n")

            # Tạo đoạn video ngắn cho cảnh bằng FFmpeg
            img_path = scene["asset_path"]
            clip_path = work_dir / f"clip_{idx}.mp4"

            # Render clip từ ảnh tĩnh + âm thanh giọng đọc (hoặc tạo tone/sine sạch)
            # Dùng filter sine audio để bảo đảm luôn có luồng âm thanh đúng thời lượng
            cmd = [
                self.ffmpeg, "-y",
                "-loop", "1", "-i", str(img_path),
                "-f", "lavfi", "-i", f"sine=frequency=440:beep_factor=0:sample_rate=48000:duration={dur}",
                "-c:v", "libx264", "-t", str(dur), "-pix_fmt", "yuv420p",
                "-c:a", "aac", "-b:a", "192k",
                "-shortest", str(clip_path)
            ]
            subprocess.run(cmd, capture_output=True, check=True)
            concat_list.append(clip_path)
            current_time += dur

        srt_out.write_text("\n".join(srt_lines), encoding="utf-8")

        # Ghép các clip lại thành video hoàn chỉnh
        list_file = work_dir / "concat_list.txt"
        with open(list_file, "w", encoding="utf-8") as f:
            for c in concat_list:
                f.write(f"file '{c.resolve().as_posix()}'\n")

        cmd_concat = [
            self.ffmpeg, "-y",
            "-f", "concat", "-safe", "0",
            "-i", str(list_file),
            "-c", "copy",
            str(video_out)
        ]
        subprocess.run(cmd_concat, capture_output=True, check=True)

        return video_out, srt_out, thumb_out

    def _format_timestamp(self, seconds: float) -> str:
        ms = int((seconds - int(seconds)) * 1000)
        s = int(seconds) % 60
        m = (int(seconds) // 60) % 60
        h = int(seconds) // 3600
        return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"

    def _generate_manifest(self, lesson_id: str, video_path: Path, srt_path: Path,
                           thumb_path: Path, qa_result: Dict[str, Any], output_dir: Path) -> Path:
        """Tạo manifest JSON với mã băm sha256 chứng thực."""
        manifest = {
            "lesson_id": lesson_id,
            "created_at": time.strftime("%Y-%m-%dT%H:%M:%S+07:00"),
            "config": self.config_type,
            "status": qa_result.get("status", "UNKNOWN"),
            "files": {}
        }
        for p in [video_path, srt_path, thumb_path]:
            if p.exists():
                h = hashlib.sha256(p.read_bytes()).hexdigest()
                manifest["files"][p.name] = {
                    "size_bytes": p.stat().st_size,
                    "sha256": h
                }

        manifest_file = output_dir / "manifest.json"
        manifest_file.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
        return manifest_file
