# MausBot Video Factory — Gói cài đặt & vận hành cho giáo viên

> **Dự án:** Trường Xanh Tuệ Đức (`truongxanh.edu.vn`)  
> **Kiến trúc:** Modular Monolith · "Build to Own"  
> **Giấy phép:** MIT License  
> **Phát triển bởi:** Kỹ sư Hệ thống & Lập trình Khai (Đội ngũ Thoma.ND / MausBot)

---

## 1. Giới thiệu tổng quan
MausBot Video Factory là giải pháp tự động hóa sản xuất video bài giảng từ A đến Z dành cho giáo viên và nhân sự Trường Xanh Tuệ Đức. Hệ thống hoạt động theo mô hình 6 vai agent phối hợp nhịp nhàng:
1. **Video - Điều phối (Orchestrator):** Tiếp nhận yêu cầu, phân bổ công việc, theo dõi hàng đợi có checkpoint.
2. **Video - Sư phạm & Kiểm chứng (Pedagogy Gate):** Kiểm duyệt kiến thức, chặn rò rỉ dữ liệu cá nhân (CCCD, địa chỉ nhà), áp dụng cam kết hình ảnh học sinh (`parental_consent_on_file = 1`).
3. **Video - Biên kịch (Scriptwriter):** Phân cảnh bài giảng, viết lời thoại thuyết minh giọng Bắc truyền cảm.
4. **Video - Đạo diễn hình ảnh (Visual Director):** Thiết lập bố cục thẻ trắng-xanh chuẩn mực, nhân vật minh họa 2D hoặc gọi các adapter AI ảnh/video.
5. **Video - Kỹ sư dựng (Render Engineer):** Sinh giọng nói VieNeu-TTS v3 Turbo (Hải Đăng), phối âm lượng -14 LUFS, render video Full HD 1080p 30fps bằng FFmpeg.
6. **Video - Kiểm định chất lượng (QA Verifier):** Đo kiểm ffprobe, kiểm tra phụ đề SRT, rà soát thiếu câu, ký biên bản nghiệm thu trước khi bàn giao.

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
1. Tự sao chép / cài đặt FFmpeg vào thư mục độc lập `%LOCALAPPDATA%\MausBotVideoFactory\bin\`.
2. Tự tạo môi trường ảo Python venv tại `%LOCALAPPDATA%\MausBotVideoFactory\.venv\`.
3. Tự cài các gói thư viện đồ họa, âm thanh và TTS (`Pillow`, `numpy`, `scipy`, `vieneu`).
4. Tự sinh file cấu hình chuẩn `%LOCALAPPDATA%\MausBotVideoFactory\config.json`.
5. Tự động kích hoạt skill `xtd-video-factory` cho OpenMausBot.

---

## 4. Thiết lập Đội ngũ 6 Agent tự động
Sau khi cài đặt xong, thầy cô mở khung chat với MausBot và dán câu lệnh trong tệp:
👉 [PROMPT_THIET_LAP_DOI_NGU_AGENTS.md](PROMPT_THIET_LAP_DOI_NGU_AGENTS.md)

MausBot sẽ tự động khởi tạo đủ 6 trợ lý chuyên môn (`Video - Điều phối`, `Video - Sư phạm`, `Video - Biên kịch`, `Video - Đạo diễn`, `Video - Kỹ sư dựng`, `Video - Kiểm định`) vào đúng phòng ban mà thầy cô không cần thao tác thủ công.

---

## 5. Cách ra lệnh làm video
Thầy cô chỉ cần nhắn cho trợ lý "Video - Điều phối":
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
