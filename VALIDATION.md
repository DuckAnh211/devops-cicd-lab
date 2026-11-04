# Kết quả nghiệm thu lab CI/CD

Ngày kiểm tra: 4 tháng 11 năm 2026.

Đã hoàn thành kiểm tra mã nguồn, build/push image, deploy staging, SSH tunnel và rollback. File DOCX gốc được giữ nguyên; các điểm cần sửa được ghi tại REVIEW.md.

## Pipeline thành công

| Phiên bản ứng dụng | GitHub Actions | Kết quả |
| --- | --- | --- |
| eced8ece1f6e4f44ac009e63354812d3777b71ba | https://github.com/DuckAnh211/devops-cicd-lab/actions/runs/41824919867 | Cả ba job success |
| 87a5b09b2560ab1ee8631096a53de11d89292d6a | https://github.com/DuckAnh211/devops-cicd-lab/actions/runs/41825215978 | Cả ba job success |

Ứng dụng cuối cùng đang chạy SHA `87a5b09b2560ab1ee8631096a53de11d89292d6a`. Commit chỉ cập nhật tài liệu sau đó có thể khác SHA ứng dụng.

## Môi trường thực tế

Ubuntu 22.04 LTS x86_64, Docker Engine 29.9.3, Compose 5.7.0 từ nguồn Docker chính thức. Ubuntu 22.04 vẫn được hỗ trợ: https://docs.docker.com/engine/install/ubuntu/.

Docker Hub Public repository: duckanh/devops-cicd-lab. Đã cấu hình repository variable DOCKERHUB_USERNAME và repository secret DOCKERHUB_TOKEN.

Staging thuộc mạng riêng nên dùng self-hosted runner ubuntu-staging, label devops-staging cho deploy. Test và build chạy trên GitHub-hosted runner. Runner chạy dưới user deploy tại /opt/actions-runner, được cài thành systemd service, tự khởi động cùng máy.

User deploy được cấp nhóm Docker theo xác nhận người dùng. Quyền Docker tương đương root: người sửa workflow hoặc merge vào main có thể điều khiển máy staging. Job deploy hiện chỉ chạy khi push main; test PR chạy trên GitHub-hosted runner.

Thư mục triển khai: /opt/devops-cicd-lab. Compose được đồng bộ từ đúng commit; API chỉ bind 127.0.0.1:3000. Script kiểm tra version trả về đúng IMAGE_TAG trước khi lưu .env.

## Bằng chứng nghiệm thu

- npm ci, kiểm tra cú pháp và 2 test HTTP local: đạt.
- Docker build và smoke test container trên Ubuntu: đạt; container chạy uid=1000(node).
- Hai image full SHA được push lên Docker Hub và pull thành công.
- Compose staging báo healthy.
- GET /health qua SSH tunnel từ Windows: status ok.
- GET / qua tunnel: message Hello from Ubuntu staging!, version đúng SHA.
- Rollback 87a5b09 về eced8ec: healthy và API qua tunnel trả SHA cũ.
- Khôi phục eced8ec lên 87a5b09: healthy và API qua tunnel trả SHA mới.
- Kiểm tra cuối: .env lưu SHA 87a5b09 đầy đủ và dịch vụ runner active.

Digest image eced8ec: sha256:8aa768b85c36ae66dbc211cfbae5a8a8164058e5cbfb2392eb95847b79856b9c.
Digest image 87a5b09: sha256:ebd7421ac5de1e0ce37957c6e930c307ceadee5051d4c2f0429a8c03e0c09261.

## Dùng tiếp

Push code lên main sẽ chạy pipeline. Giữ Ubuntu có Internet và runner service hoạt động. README.md có lệnh mở tunnel, kiểm tra và rollback. Thay token Docker Hub trước khi hết hạn.

Healthcheck không tự rollback khi lỗi; thay một container có thể gián đoạn ngắn. Đây là nghiệm thu lab, chưa kiểm thử chịu tải hoặc triển khai production.

Mật khẩu, token và địa chỉ máy staging không được ghi trong repository.
