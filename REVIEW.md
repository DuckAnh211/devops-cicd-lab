# Kết quả rà soát tài liệu

Kiến trúc Node.js → GitHub Actions → Docker Hub → Ubuntu Compose hợp lý cho lab. API, Dockerfile chạy user node, tag theo SHA, bind loopback và SSH strict host key checking là các lựa chọn phù hợp. Chưa đủ điều kiện khẳng định toàn bộ pipeline đã hoạt động.

Các điểm cần bổ sung hoặc sửa:

1. Không bắt buộc hai máy vật lý: một laptop có thể chạy thêm Ubuntu VM; cần phân biệt hai môi trường với hai thiết bị vật lý.
2. Thiếu hướng dẫn rõ ràng tạo và commit package-lock.json. `npm install` ở bước local sẽ tạo file, nhưng cần commit để `npm ci` và cache npm trên Actions hoạt động.
3. User deploy khóa mật khẩu và chưa có key không thể tự bootstrap bằng ssh-copy-id. Cài public key qua tài khoản quản trị hiện có; Windows không có sẵn ssh-copy-id.
4. Thiếu cách tạo STAGING_KNOWN_HOSTS và xác minh fingerprint qua kênh đáng tin cậy.
5. Ubuntu VM nội bộ có SSH từ laptop chưa có nghĩa GitHub runner truy cập được. Cần cấu hình mạng phù hợp hoặc runner trong mạng đó.
6. IMAGE_TAG=bootstrap chưa tồn tại trên registry. Chỉ pull sau khi push SHA thực tế.
7. Lệnh `lint` chỉ kiểm tra cú pháp JavaScript, chưa phải lint quy tắc chất lượng code.
8. Compose không được đồng bộ tự động trong workflow; sửa compose phải chép lại server. Health check không tự rollback và single container có thể downtime.
9. Private Docker Hub repository cần đăng nhập riêng trên server. Nhóm docker có quyền tương đương root. Server ARM cần image cùng kiến trúc.
10. Biến môi trường `.env` không được Node tự nạp bằng npm start hiện tại; mẫu chỉ có tác dụng khi truyền biến trực tiếp hoặc chạy Node với --env-file.

Không kết luận các tag Docker Actions v4/v7 sai: ví dụ upstream hiện có setup-buildx-action@v4, login-action@v4 và build-push-action@v7. setup-node@v4 là phiên bản cũ; project giữ phiên bản tài liệu để hạn chế thay đổi chưa cần thiết.

Nguồn đối chiếu:

- https://docs.docker.com/engine/install/ubuntu/
- https://docs.docker.com/reference/cli/docker/compose/up/
- https://github.com/docker/build-push-action
- https://github.com/actions/setup-node

Mã nguồn đã được tách thành file giữ nguyên xuống dòng và thụt đầu dòng từ DOCX. Không sửa file DOCX gốc.
