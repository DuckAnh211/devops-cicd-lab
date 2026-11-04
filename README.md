# Thực hành CI/CD Node.js

Project được tách từ tài liệu LAB, có ứng dụng Express, test, Dockerfile và workflow staging. Chưa triển khai lên dịch vụ bên ngoài.

## Chạy trên Windows PowerShell

```powershell
cd E:\devops\devops-cicd-lab
npm ci
npm run lint
npm test
npm start
```

Ở terminal khác chạy `curl.exe http://127.0.0.1:3000/health` và `curl.exe http://127.0.0.1:3000/`.
Commit cả `package-lock.json`; Dockerfile và workflow dùng `npm ci` nên bắt buộc cần file này.

## Docker local

Cần Docker Desktop chạy Linux containers hoặc Docker Engine trên Ubuntu.

```powershell
docker build -t devops-cicd-lab:local .
docker run --rm -p 127.0.0.1:3000:3000 --name devops-lab-local devops-cicd-lab:local
```

## Chuẩn bị staging

Dùng các bước cài Docker chính thức ở https://docs.docker.com/engine/install/ubuntu/ và tạo user deploy như tài liệu gốc. Quyền nhóm docker tương đương quyền root trên host.

User deploy bị khóa mật khẩu nên lần đầu không dùng ssh-copy-id khi chưa có phương thức đăng nhập. Đăng nhập bằng tài khoản quản trị Ubuntu hiện có, rồi cài PUBLIC key:

```bash
sudo install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
sudo touch /home/deploy/.ssh/authorized_keys
printf '%s\n' 'THAY_BANG_NOI_DUNG_PUBLIC_KEY' | sudo tee -a /home/deploy/.ssh/authorized_keys >/dev/null
sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

Giữ private key ở máy của bạn và GitHub Secret; không commit. Trên Windows không có ssh-copy-id mặc định.

Ubuntu phải nhận được kết nối SSH từ GitHub-hosted runner. Máy ảo NAT chỉ truy cập được từ laptop chưa đáp ứng điều kiện này; cần mạng truy cập được từ runner hoặc self-hosted runner phù hợp. Không mở port 3000 public.

Sao chép `deploy/compose.yaml` thành `/opt/devops-cicd-lab/compose.yaml`; tạo `.env` tại đó:

```dotenv
DOCKERHUB_USERNAME=YOUR_DOCKERHUB_USER
IMAGE_TAG=bootstrap
```

`bootstrap` chỉ là placeholder; không chạy pull cho tới khi có image SHA thực tế. Chạy `chmod 600 .env`. Repository Docker Hub cần public, hoặc phải login Docker Hub riêng trên server nếu private. Mẫu build mặc định là linux/amd64; server ARM cần thêm build đa kiến trúc.

## GitHub

Tạo environment `staging`. Đặt variables `DOCKERHUB_USERNAME`, `STAGING_HOST`, `STAGING_USER` ở repository; secrets `DOCKERHUB_TOKEN`, `STAGING_SSH_KEY`, `STAGING_KNOWN_HOSTS` ở repository hoặc environment staging phù hợp với job dùng chúng. Token Docker Hub dùng ở job build nên phải khả dụng cho job build.

Lấy host public key qua kênh quản trị server đáng tin cậy, đối chiếu fingerprint (`sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` trên server). Nếu dùng `ssh-keyscan -H SERVER_IP`, phải đối chiếu fingerprint trước khi lưu kết quả vào STAGING_KNOWN_HOSTS. Chỉ keyscan không xác thực danh tính server.

Tạo repository GitHub đích rồi push project với nhánh main theo tài liệu gốc. Không đưa token vào URL Git. Workflow chạy test trên PR, build và deploy khi push main. Compose đang được chép thủ công; khi sửa compose phải đồng bộ lại server.

## Nghiệm thu và rollback

Kiểm tra cả ba job, image SHA trên Docker Hub và `docker compose ps` trên server. Dùng tunnel:

```powershell
ssh -N -i "$HOME/.ssh/devops_lab_deploy" -L 3000:127.0.0.1:3000 deploy@SERVER_IP
```

Dừng npm start local trước khi mở tunnel hoặc đổi cổng local sang 3001. Xác nhận `/` trả đúng version SHA, `/health` trả status ok.

Rollback trong thư mục `/opt/devops-cicd-lab` trên Ubuntu:

```bash
export IMAGE_TAG=PREVIOUS_FULL_SHA
docker compose pull && docker compose up -d --no-build --wait --wait-timeout 120 && sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=${IMAGE_TAG}/" .env
unset IMAGE_TAG
```

Thay PREVIOUS_FULL_SHA bằng SHA đã push thành công. `--wait` kiểm tra sức khỏe nhưng không tự rollback khi lỗi. Cách deploy này có thể gián đoạn trong lúc thay container.
