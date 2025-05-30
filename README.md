
# 🚀 Script Tự Động Cài Đặt MTProxy cho Telegram

[![Ngôn ngữ](https://img.shields.io/badge/Ngôn%20ngữ-Bash-blue.svg)](https://www.gnu.org/software/bash/)
[![Giấy phép](https://img.shields.io/badge/Giấy%20phép-MIT-green.svg)](LICENSE)

Script này giúp bạn **tự động hóa hoàn toàn** quá trình cài đặt một máy chủ MTProxy trên các VPS chạy hệ điều hành Linux (khuyến nghị Ubuntu/Debian).  
Chỉ với **một dòng lệnh**, bạn sẽ có ngay một **proxy Telegram riêng tư và an toàn**.

---

## 🌟 Tính năng chính

- ✅ **Tự động hoàn toàn**: Cập nhật hệ thống, cài đặt phụ thuộc, tải mã nguồn, biên dịch, cấu hình, khởi chạy proxy.
- 📦 **Sử dụng Repo Chính Thức**: Lấy mã nguồn trực tiếp từ Telegram.
- 🔐 **Secret & Port Ngẫu Nhiên**: Tăng tính bảo mật.
- 🔥 **Tự động mở Firewall**: Cấu hình `ufw` để mở port cần thiết.
- 🌀 **Tự động chạy nền**: Proxy sẽ tự động chạy ở chế độ background.
- 🔗 **Hiển thị Link Kết Nối Telegram**: Dễ dàng click để dùng.
- 👨‍💻 **Dễ sử dụng**: Một dòng lệnh là đủ.

---

## 🧰 Yêu cầu hệ thống

- VPS chạy **Ubuntu (18.04/20.04/22.04)** hoặc **Debian (9/10/11)**.
- Có quyền `sudo` hoặc `root`.
- Kết nối internet ổn định.

---

## 🚀 Cách sử dụng

Đăng nhập VPS của bạn và chạy một trong hai lệnh sau:

### ✅ Cách 1: Sử dụng `curl` (Khuyến nghị)

```bash
curl -sSL https://raw.githubusercontent.com/vuvanthe64/mtproxy/main/install_mtproxy.sh | sudo bash
```

### ✅ Cách 2: Sử dụng `wget`

```bash
wget -qO - https://raw.githubusercontent.com/vuvanthe64/mtproxy/main/install_mtproxy.sh | sudo bash
```

---

## ✅ Sau khi cài đặt thành công

Bạn sẽ thấy các thông tin sau:

#### 🔗 Link kết nối Telegram:

```
tg://proxy?server=YOUR_SERVER_IP&port=RANDOM_PORT&secret=YOUR_SECRET
```

Copy link và dán vào Telegram để sử dụng. Proxy sẽ tự động chạy nền.

---

## 🛠️ Kiểm tra & Gỡ lỗi

**Kiểm tra log:**

```bash
cat /opt/MTProxy_Official/objs/bin/mtproxy_runtime.log
```

**Kiểm tra port:**

```bash
sudo ss -tlpn | grep <PORT_CUA_PROXY>
```

**Dừng proxy:**

```bash
sudo kill $(pgrep -f 'mtproto-proxy -H <PORT_CUA_PROXY>')
```

**Chạy lại proxy:**

```bash
cd /opt/MTProxy_Official/objs/bin/
nohup ./mtproto-proxy -u nobody -p <PORT> -H 443 -S <SECRET> --aes-pwd proxy-secret proxy-multi.conf -M 1 > mtproxy_runtime.log 2>&1 &
```

---

## 🤝 Đóng góp

- Tạo **Issue** hoặc **Pull Request** trên GitHub để đóng góp ý tưởng và cải tiến.
- Mọi sự đóng góp đều được hoan nghênh!

---

**Chúc bạn thành công 🎉 và có một proxy Telegram riêng tư và ổn định!**
