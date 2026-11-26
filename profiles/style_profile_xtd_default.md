# Hồ sơ phong cách Trường Xanh Tuệ Đức (Style Profile v1.0)

Hồ sơ này định nghĩa bộ nhận diện, quy tắc thẩm mỹ và tiêu chuẩn an toàn cho toàn bộ video sản xuất bằng **MausBot Video Factory**.

## 1. Màu sắc thương hiệu
- **Xanh chủ đạo (Primary):** `#1F8A4C` (Xanh lá Trường Xanh Tuệ Đức)
- **Xanh đậm phụ trợ (Navy):** `#1E3A5F` (Áo choàng trí tuệ & mũ giáo sư)
- **Điểm nhấn (Accent):** `#FFC83D` (Vàng cam ấm áp, tôn vinh từ khóa)
- **Nền sáng (Background):** `#EEF6F1` (Nền dịu mắt, có hạt chấm bi chuyển động nhẹ)
- **Thẻ nội dung (Card):** `#FFFFFF` (Bảng trắng bo góc bán kính 16px)
- **Màu chữ (Ink):** `#142E26` (Xanh đen đậm, độ tương phản cao, chống lóa)

## 2. Giọng đọc thuyết minh (Voiceover)
- **Công cụ:** VieNeu-TTS v3 Turbo (chạy trực tiếp trên máy).
- **Giọng đọc:** Giọng **Hải Đăng** (giọng Nam miền Bắc chuẩn, truyền cảm, dứt khoát).
- **Quy chuẩn âm thanh:**
  - Chuẩn âm lượng phát thanh truyền hình: `-14 LUFS` (dung sai ±1.5 LUFS).
  - Đỉnh âm lượng cao nhất (`True Peak`): `≤ -1.0 dBFS`.
  - Khoảng ngắt nghỉ giữa các câu: `0.30 giây`, đầu video `0.55 giây`, kết video `0.75 giây`.

## 3. Tiêu chuẩn dựng hình (Video Standards)
- **Độ phân giải:** `1920 × 1080` (Full HD 16:9).
- **Tốc độ khung hình:** `30 khung hình / giây` (`30 fps`).
- **Mã hóa:** Video `H.264` (`yuv420p`), Audio `AAC` 48kHz mono/stereo.
- **Vùng an toàn phụ đề:** Y từ `130px` đến `1000px`, không bị che khuất bởi logo hay thanh điều khiển phát video.

## 4. An toàn dữ liệu & Cổng kiểm soát (Safety Gates)
- **Cam kết hình ảnh học sinh:** Bật cờ `parental_consent_on_file = 1` mặc định theo quyết định ngày 23/11/2026 của anh Mạnh; ảnh hoạt động thông thường của học sinh tự ĐẠT, không cản trở quy trình dựng.
- **Chặn rò rỉ dữ liệu nhạy cảm (PII):** Tự động phát hiện và chặn xuất bản nếu phát hiện căn cước công dân (CCCD), địa chỉ nhà riêng, sổ hộ khẩu hoặc số tài khoản ngân hàng cá nhân.
- **Cụm từ cấm:** Tự động quét kịch bản và phụ đề để loại bỏ các cụm từ gây hiểu lầm như *"một cú bấm"*, *"miễn phí hoàn toàn"*, *"tự động đăng youtube"*, *"tự vẽ ảnh"*.

## 5. Bộ tài sản bàn giao (Deliverables)
Mỗi bài giảng sau khi hoàn tất phải xuất đủ 7 thành phần:
1. `[Tên_Video].mp4`: Video hoàn chỉnh.
2. `[Tên_Video].srt`: Tệp phụ đề đồng bộ chuẩn xác.
3. `thumbnail.jpg`: Ảnh bìa 1920x1080 bắt mắt.
4. `script.json`: Kịch bản phân cảnh chi tiết.
5. `storyboard.json`: Bảng phân cảnh hình ảnh & thời điểm.
6. `manifest.json`: Bản kê kỹ thuật, mã băm sha256.
7. `QA_REPORT.md`: Báo cáo thẩm định chất lượng có dấu ĐẠT/KHÔNG ĐẠT.
