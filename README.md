# Script Tự Động Cài Đặt & Quản Lý Nhiều Instance MTProxy cho Telegram

Script này giúp bạn tự động hóa hoàn toàn quá trình cài đặt và quản lý **nhiều instance MTProxy độc lập** trên các VPS chạy hệ điều hành Linux (khuyến nghị Ubuntu/Debian). Mỗi instance sẽ chạy trên một port riêng, với secret riêng và được quản lý bởi dịch vụ `systemd` riêng, đảm bảo hoạt động 24/7 và tự khởi động lại sau khi server reboot.

## 🧩 Tính năng chính

* **Tạo Nhiều Instance:** Dễ dàng tạo nhiều proxy riêng biệt trên cùng một VPS.
* **Quản Lý Bằng `systemd`:** Mỗi instance MTProxy được quản lý như một dịch vụ hệ thống (`mtproxy-<PORT>.service`).
* **Tự động Hoàn toàn:** Từ cập nhật hệ thống, cài đặt phụ thuộc, đến khởi chạy.
* **Sử dụng Repo GetPageSpeed:** Ổn định và đã được kiểm chứng.
* **Secret & Port Ngẫu Nhiên:** Tự động sinh, tránh trùng lặp port.
* **Tự động Mở Firewall:** Dùng `ufw` để mở port tương ứng.
* **Cài đặt & Xóa Dễ Dàng:** Hỗ trợ qua tham số dòng lệnh (`install`, `remove`).
* **Tự Lưu Script (Tùy chọn):** Tự động lưu vào `/usr/local/sbin/manage_mtproxy.sh`.
* **Lưu Thông Tin Cấu Hình:** Tại `/opt/MTProxy_GetPageSpeed/configs/`.
* **Hiển thị Link Kết Nối:** Tự động tạo link `tg://proxy?...`.

## 🛠️ Yêu cầu hệ thống

* VPS chạy Ubuntu/Debian.
* Có quyền root hoặc sudo không cần mật khẩu.
* Kết nối Internet ổn định.

## 🚀 Cách sử dụng

### 1. Cài đặt một instance MTProxy mới

**Từ GitHub (luôn lấy bản mới nhất):**
```bash
curl -sSL https://raw.githubusercontent.com/vuvanthe64/mtproxy/main/install_mtproxy.sh | sudo bash
```

**Hoặc:**
```bash
curl -sSL https://raw.githubusercontent.com/vuvanthe64/mtproxy/main/install_mtproxy.sh | sudo bash -s install
```

**Từ file cục bộ đã lưu:**
```bash
sudo bash /usr/local/sbin/manage_mtproxy.sh
# hoặc
sudo bash /usr/local/sbin/manage_mtproxy.sh install
```

### 2. Xóa một instance MTProxy đã cài

Biết port của instance cần xóa:
```bash
sudo bash /usr/local/sbin/manage_mtproxy.sh remove <PORT_NUMBER>
```

Hoặc:
```bash
curl -sSL https://raw.githubusercontent.com/vuvanthe64/mtproxy/main/install_mtproxy.sh | sudo bash -s remove <PORT_NUMBER>
```

## 📌 Sau khi cài đặt

- Link kết nối Telegram sẽ hiện ngay sau khi cài.
- Dịch vụ `systemd` tên `mtproxy-<PORT>.service`.
- Cấu hình lưu tại `/opt/MTProxy_GetPageSpeed/configs/mtproxy-<PORT>.info`.

## 🧰 Quản lý và Gỡ lỗi

**Xem trạng thái:**
```bash
sudo systemctl status mtproxy-<PORT>.service
```

**Xem log:**
```bash
sudo journalctl -u mtproxy-<PORT>.service -e
```

**Theo dõi log realtime:**
```bash
sudo journalctl -u mtproxy-<PORT>.service -f
```

**Dừng dịch vụ:**
```bash
sudo systemctl stop mtproxy-<PORT>.service
```

**Khởi động lại:**
```bash
sudo systemctl restart mtproxy-<PORT>.service
```

**Liệt kê toàn bộ MTProxy đang chạy:**
```bash
systemctl list-units 'mtproxy-*.service' --state=active
```

## 🤝 Đóng góp

Nếu bạn có ý tưởng cải thiện, hãy mở Issue hoặc Pull Request trên GitHub.
