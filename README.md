# Lab CI/CD Node.js

Project thực hành: Express → GitHub Actions → Docker Hub → Docker Compose trên Ubuntu.

## Chạy local trên Windows

```powershell
cd E:\devops\devops-cicd-lab
npm ci
npm run lint
npm test
npm start
```

Terminal khác: `curl.exe http://127.0.0.1:3000/health` và `curl.exe http://127.0.0.1:3000/`.
Commit cả package-lock.json để npm ci và Docker build hoạt động. Lệnh lint hiện chỉ kiểm tra cú pháp.

## Pipeline thực tế

- Pull request vào main: chạy kiểm tra cú pháp và test trên GitHub-hosted runner.
- Push main: test → build/push image `duckanh/devops-cicd-lab:<full-sha>` → deploy.
- Job deploy chạy trên self-hosted runner Linux x64 có label `devops-staging` trong mạng staging.
- Job deploy dùng environment `staging` và chỉ chạy khi push main. Runner không được dùng cho job test PR.
- Compose được đồng bộ từ đúng commit trước khi chạy container. Cổng API chỉ bind `127.0.0.1:3000` trên Ubuntu.

Đây là điều chỉnh so với tài liệu gốc dùng GitHub-hosted runner SSH tới staging: staging của lab dùng IP mạng riêng, nên dùng runner tại staging để không cần mở SSH public.

## Cấu hình GitHub và Docker Hub

Repository variable: `DOCKERHUB_USERNAME=duckanh`.
Repository secret: `DOCKERHUB_TOKEN`, là token Docker Hub có quyền Read & Write. Không đặt token ở Variables hoặc đặt tên environment thay cho secret. Token có hạn 30 ngày cần thay trước khi hết hạn.
Docker Hub repository `duckanh/devops-cicd-lab` phải Public cho mẫu deploy không đăng nhập registry trên staging này.

## Máy staging

Môi trường đã kiểm tra là Ubuntu 22.04 LTS x86_64, có Docker Engine và Compose từ repository Docker chính thức. Ubuntu 22.04 nằm trong danh sách hỗ trợ: https://docs.docker.com/engine/install/ubuntu/.

Runner được đặt tại `/opt/actions-runner`, chạy dưới user deploy. Thư mục triển khai là `/opt/devops-cicd-lab`. User deploy có quyền nhóm Docker, tương đương quyền root trên máy. Chỉ người tin cậy được phép sửa workflow hoặc merge code vào main. Điều kiện trong workflow hiện tại không ngăn người có quyền sửa workflow tạo job mới dùng runner.

Kiểm tra dịch vụ runner trên Ubuntu:

```bash
sudo systemctl list-units 'actions.runner.*'
sudo -u deploy docker compose -p devops-cicd-lab --project-directory /opt/devops-cicd-lab ps
```

## Kiểm tra qua SSH tunnel

Trên Windows, dừng npm start nếu đang chiếm cổng 3000, rồi chạy:

```powershell
ssh -N -L 3000:127.0.0.1:3000 user@STAGING_IP
```

Terminal khác:

```powershell
curl.exe http://127.0.0.1:3000/health
curl.exe http://127.0.0.1:3000/
```

`/health` phải trả status ok và `/` phải trả version đúng SHA của commit được deploy. Nếu cổng local 3000 đã dùng, đổi vế đầu sang 3001.

## Rollback

Mỗi lần deploy healthy, `.env` lưu tag đang chạy; nếu đã có bản trước, `.previous.env` lưu cấu hình trước lần deploy đó. Trên Ubuntu, chọn SHA cũ đã tồn tại trên Docker Hub:

```bash
cd /opt/devops-cicd-lab
sudo -u deploy env IMAGE_TAG=PREVIOUS_FULL_SHA docker compose -p devops-cicd-lab pull
sudo -u deploy env IMAGE_TAG=PREVIOUS_FULL_SHA docker compose -p devops-cicd-lab up -d --no-build --wait --wait-timeout 120
```

Sau khi healthy, cập nhật IMAGE_TAG trong .env cho khớp. Có thể chạy lại `deploy/deploy.sh` từ một checkout với `DOCKERHUB_USERNAME=duckanh` và `IMAGE_TAG=<sha>` để cập nhật cả container và .env.
Không tự động rollback khi healthcheck lỗi; single-container deployment có thể gián đoạn lúc thay container. Không dùng tag bootstrap khi registry chưa có image tương ứng.

## Các file cần xem

- `.github/workflows/main.yml`: 3 job CI/CD.
- `deploy/deploy.sh`: pull, đồng bộ compose, đợi healthy và lưu tag.
- `deploy/compose.yaml`: cấu hình ứng dụng staging và healthcheck.
- `REVIEW.md`: các điểm thiếu/cần sửa trong tài liệu gốc.
- `VALIDATION.md`: kết quả kiểm tra đã ghi nhận.
