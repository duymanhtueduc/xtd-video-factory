# MausBot Video Factory — Gói cài đặt & vận hành cho giáo viên

> **Dự án:** Trường Xanh Tuệ Đức (`truongxanh.edu.vn`)  
> **Kiến trúc:** Modular Monolith · "Build to Own"  
> **Giấy phép:** MIT License  
> **Phát triển bởi:** Kỹ sư Hệ thống & Lập trình Khai (Đội ngũ Thoma.ND / MausBot)

---

## 1. Giới thiệu tổng quan
MausBot Video Factory là giải pháp tự động hóa sản xuất video bài giảng từ A đến Z dành cho giáo viên và nhân sự Trường Xanh Tuệ Đức. Hệ thống hoạt động theo mô hình 6 vai agent phối hợp nhịp nhàng:
1. **Điều phối (Orchestrator):** Tiếp nhận yêu cầu, phân bổ công việc, theo dõi hàng đợi có checkpoint.
2. **Sư phạm & Kiểm chứng (Pedagogy & Fact Gate):** Kiểm duyệt kiến thức, chặn rò rỉ dữ liệu cá nhân (CCCD, địa chỉ nhà), áp dụng cam kết hình ảnh học sinh (`parental_consent_on_file = 1`).
3. **Biên kịch (Scriptwriter):** Phân cảnh bài giảng, viết lời thoại thuyết minh giọng Bắc truyền cảm.
4. **Đạo diễn hình ảnh (Visual Director):** Thiết lập bố cục thẻ trắng-xanh chuẩn mực, nhân vật minh họa 2D hoặc gọi các adapter AI ảnh/video.
5. **Kỹ sư dựng (Render Engineer):** Sinh giọng nói VieNeu-TTS v3 Turbo (Hải Đăng), phối âm lượng -14 LUFS, render video Full HD 1080p 30fps bằng FFmpeg.
6. **Kiểm định chất lượng (QA Verifier):** Đo kiểm ffprobe, kiểm tra phụ đề SRT, rà soát thiếu câu, ký biên bản nghiệm thu trước khi bàn giao.

---

## 2. Hai cấu hình vận hành
- **Cấu hình 1: Local / Miễn phí 100% (Mặc định cho mọi giáo viên)**
  - Chạy hoàn toàn trên máy tính cá nhân, không tốn bất kỳ chi phí API nào.
  - Giọng đọc Bắc chuẩn VieNeu-TTS Hải Đăng + bộ mẫu bài giảng đồ họa sắc nét Tuệ Đức.
- **Cấu hình 2: Có Provider trả phí (Hybrid Provider-Enhanced)**
  - Kế thừa toàn bộ Cấu hình 1.
  - Cho phép giáo viên gắn thêm API key cá nhân của OpenAI (DALL-E 3), Midjourney, Kling AI, Runway, HeyGen để sinh b-roll sinh động.
  - Tự động fallback về Cấu hình 1 nếu hết quota hoặc mất mạng.

---

## 3. Cài đặt tự động trên máy tính mới
- **Cách 1 (Giáo viên tự bấm):** Bấm đúp chuột vào file `install.cmd`.
- **Cách 2 (MausBot tự động chạy):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\install.ps1
  ```
Trình cài đặt sẽ tự động:
1. Đo kiểm RAM, ổ cứng, nhận diện card đồ họa NVIDIA CUDA.
2. Kiểm tra và tự cài FFmpeg, Python 3.11+, trình duyệt Chromium/Edge.
3. Thiết lập môi trường Python venv và các thư viện cần thiết.
4. Tự động kích hoạt skill `xtd-video-factory` cho OpenMausBot.

---

## 4. Cách sử dụng
Sau khi cài đặt, giáo viên chỉ cần mở khung chat OpenMausBot và nhắn:
```text
Trợ lý Video Bài học, hãy tạo video bài giảng về "Quy tắc 3 gốc: Đạo đức - Trí tuệ - Nghị lực" cho học sinh khối 6.
- Thời lượng: khoảng 2 phút.
- Hồ sơ phong cách: Mặc định Trường Xanh Tuệ Đức.
- Đầu ra: Gửi tôi video MP4, phụ đề SRT, ảnh bìa và báo cáo QA.
```

Hệ thống sẽ tự động xuất gói bàn giao đầy đủ:
- `video.mp4` (Full HD 1080p, 30fps)
- `video.srt` (Phụ đề đồng bộ)
- `thumbnail.jpg` (Ảnh bìa)
- `script.json` (Kịch bản phân cảnh)
- `storyboard.json` (Bảng bố cục)
- `manifest.json` (Mã băm SHA-256)
- `QA_REPORT.md` (Báo cáo thẩm định chất lượng)
