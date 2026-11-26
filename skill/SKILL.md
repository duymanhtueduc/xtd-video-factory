---
name: xtd-video-factory
description: "MausBot Video Factory — Nhà máy sản xuất video bài giảng tự động cho giáo viên Trường Xanh Tuệ Đức. Tự động điều phối 6 vai agent (Điều phối, Sư phạm, Biên kịch, Đạo diễn, Kỹ sư dựng, QA), dựng video Full HD 1080p bằng FFmpeg + template chuẩn Tuệ Đức, giọng đọc Hải Đăng Bắc chuẩn qua VieNeu-TTS v3, hỗ trợ cả 2 cấu hình Local/miễn phí và Provider trả phí (DALL-E, Kling, HeyGen). Đầu ra chuẩn: MP4 + SRT + Thumbnail + Manifest + QA Report."
---

# MAUSBOT VIDEO FACTORY — NHÀ MÁY SẢN XUẤT VIDEO BÀI GIẢNG TUỆ ĐỨC

Skill này trang bị cho MausBot năng lực vận hành một dây chuyền sản xuất video bài học hoàn chỉnh theo chuẩn **"Build to Own"**, thiết kế Modular Monolith dành riêng cho giáo viên Trường Xanh Tuệ Đức.

## 1. Sáu vai Agent trong dây chuyền sản xuất

```
[Giáo viên gửi giáo án] 
          │
          ▼
┌───────────────────────────┐
│ 1. ĐIỀU PHỐI (Orchestrator)│ ── Tiếp nhận lệnh, nạp Hồ sơ phong cách, điều khiển hàng đợi
└─────────────┬─────────────┘
              ▼
┌───────────────────────────┐
│ 2. SƯ PHẠM (Pedagogy Gate)│ ── Kiểm chứng kiến thức, chặn PII nhạy cảm, loại bỏ từ cấm
└─────────────┬─────────────┘
              ▼
┌───────────────────────────┐
│ 3. BIÊN KỊCH (Scriptwriter)│ ── Phân cảnh, viết lời thoại tự nhiên, canh nhịp thời lượng
└─────────────┬─────────────┘
              ▼
┌───────────────────────────┐
│ 4. ĐẠO DIỄN (Visual Dir.) │ ── Bố cục thẻ trắng-xanh, tư thế nhân vật, chọn Adapter visual
└─────────────┬─────────────┘
              ▼
┌───────────────────────────┐
│ 5. KỸ SƯ DỰNG (Renderer)  │ ── VieNeu-TTS v3 (Hải Đăng), mix audio, render FFmpeg 1080p 30fps
└─────────────┬─────────────┘
              ▼
┌───────────────────────────┐
│ 6. KIỂM ĐỊNH (QA Gate)    │ ── Thẩm định ffprobe, ASR soát câu, âm lượng -14 LUFS, đóng gói
└─────────────┬─────────────┘
              ▼
[Bàn giao gói MP4 + SRT + Thumbnail + Manifest + Báo cáo QA]
```

### Chi tiết nhiệm vụ từng vai:
1. **Agent 1: Điều phối (Orchestrator)**
   - Đọc Hồ sơ phong cách (`profiles/style_profile_xtd_default.json`).
   - Khởi tạo hàng đợi sản xuất có lưu vết checkpoint (nếu máy tắt đột ngột, khi bật lại tiếp tục từ cảnh chưa xong).
   - Tổng hợp kết quả và trả đường dẫn bàn giao cho giáo viên.
2. **Agent 2: Sư phạm & Kiểm chứng (Pedagogy & Fact Gate)**
   - Rà soát nội dung giáo án: mục tiêu bài học, tính chính xác khoa học, phù hợp lứa tuổi học sinh.
   - Quét an toàn thông tin: chặn cứng rò rỉ CCCD, địa chỉ nhà, SĐT riêng; áp dụng cờ `parental_consent_on_file = 1` để ảnh học sinh thông thường tự ĐẠT.
   - Loại trừ các cụm từ cấm gây hiểu lầm.
3. **Agent 3: Biên kịch (Scriptwriter)**
   - Tách bài giảng thành các phân cảnh sư phạm (Mở đầu / Thách thức / Khái niệm / Thực hành / Đúc kết).
   - Viết lời thoại thuyết minh bằng tiếng Việt thuần khiết, ngắt câu rõ ràng, đánh dấu từ khóa cần nhấn (`*từ khóa*`).
4. **Agent 4: Đạo diễn hình ảnh (Visual Director)**
   - Lựa chọn Adapter phù hợp:
     - Nếu chạy **Cấu hình 1 (Local/miễn phí):** Dùng bộ thẻ bài giảng `ai-video-studio` (#1F8A4C, #1E3A5F) + nhân vật minh họa 2D / Giáo sư Tuệ Đức.
     - Nếu chạy **Cấu hình 2 (Có Provider):** Gọi Adapter DALL-E 3 / Flux / Kling AI để sinh ảnh/video b-roll bám kịch bản (fallback về Local nếu hết quota/lỗi).
5. **Agent 5: Kỹ sư dựng (Render Engineer)**
   - Chạy `VieNeu-TTS v3 Turbo` sinh âm thanh từng câu thoại (giọng Nam miền Bắc "Hải Đăng").
   - Trích xuất thời điểm từng từ (`word-level timing`) để khớp hiệu ứng hiển thị.
   - Ghép âm thanh, nhạc nền nhẹ (-20 dBFS), tiếng hiệu ứng (SFX) chuyển cảnh.
   - Dùng FFmpeg render video chuẩn H.264 Full HD (1920x1080, 30fps).
6. **Agent 6: Kiểm định chất lượng (QA Verifier)**
   - Chạy `ffprobe` kiểm tra chuẩn khung hình, codec, tỷ lệ 16:9.
   - Đo âm lượng bằng bộ lọc `ebur128` bảo đảm chuẩn phát thanh `-14 LUFS` (peak ≤ -1 dBFS).
   - Dùng Whisper ASR nghe lại toàn bộ video để đối chiếu phát hiện câu bị cắt hay thiếu.
   - Ký biên bản nghiệm thu `QA_REPORT.md` (ĐẠT / CẦN SỬA).

---

## 2. Cách ra lệnh cho MausBot bằng tiếng Việt

Giáo viên chỉ cần gõ một câu lệnh tự nhiên trong khung chat:

```text
Trợ lý Video Bài học, hãy tạo video bài giảng hoàn chỉnh về "Phép cộng có nhớ trong phạm vi 100" cho học sinh lớp 2.
- Mục tiêu: Nắm chắc 3 bước đặt tính và tính đúng 2 bài tập ví dụ.
- Thời lượng: khoảng 2 phút.
- Tài liệu: Dùng giáo án đính kèm và Hồ sơ phong cách Trường Xanh Tuệ Đức mặc định.
- Yêu cầu: Tự điều phối các agent, tự sửa lỗi kỹ thuật, không đăng lên mạng.
- Đầu ra: Gửi tôi file video MP4, phụ đề SRT, ảnh bìa và báo cáo kiểm định.
```

---

## 3. Quy chuẩn gói đầu ra (Deliverables)

Mỗi lần chạy thành công, hệ thống tạo một thư mục riêng đặt tại `outputs/videos/[Mã_Bài_Học]/` gồm đúng 7 tệp:
1. `video.mp4`: Video Full HD 1080p, 30fps.
2. `video.srt`: Phụ đề đồng bộ từng câu thoại.
3. `thumbnail.jpg`: Ảnh bìa tỷ lệ 16:9 sắc nét.
4. `script.json`: Kịch bản phân cảnh chi tiết.
5. `storyboard.json`: Bảng phân cảnh hình ảnh và thời gian.
6. `manifest.json`: Bản kê kỹ thuật, mã băm SHA-256 bảo đảm nguyên bản.
7. `QA_REPORT.md`: Báo cáo thẩm định chất lượng có dấu ĐẠT.
