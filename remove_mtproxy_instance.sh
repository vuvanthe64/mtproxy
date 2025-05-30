#!/bin/bash

# Script để xóa hoàn toàn một instance MTProxy được quản lý bởi systemd
# Cách dùng: sudo /đường_dẫn_tới_script/remove_mtproxy_instance.sh <PORT_NUMBER>

# Hàm ghi log và hiển thị ra màn hình
log_and_echo() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Kiểm tra xem có quyền root không
if [ "$(id -u)" -ne 0 ]; then
  log_and_echo "LỖI: Script này cần được chạy với quyền root hoặc sudo."
  exit 1
fi

# Kiểm tra xem có cung cấp port number không
if [ -z "$1" ]; then
    log_and_echo "LỖI: Vui lòng cung cấp số PORT của instance MTProxy cần xóa."
    log_and_echo "Cách dùng: $0 <PORT_NUMBER>"
    exit 1
fi

PORT_NUMBER="$1"
# Kiểm tra xem PORT_NUMBER có phải là số không
if ! [[ "$PORT_NUMBER" =~ ^[0-9]+$ ]]; then
    log_and_echo "LỖI: Số PORT cung cấp không hợp lệ: '$PORT_NUMBER'. Vui lòng nhập một số."
    exit 1
fi

SERVICE_NAME="mtproxy-${PORT_NUMBER}.service"
SERVICE_FILE_PATH="/etc/systemd/system/${SERVICE_NAME}"
CONFIG_FILES_DIR_BASE="/opt/MTProxy_GetPageSpeed/configs" # Thư mục gốc lưu config
CONFIG_INFO_FILE="${CONFIG_FILES_DIR_BASE}/mtproxy-${PORT_NUMBER}.info"

log_and_echo "=============================================================="
log_and_echo "Bắt đầu quá trình xóa instance MTProxy trên port ${PORT_NUMBER}"
log_and_echo "Dịch vụ tương ứng: ${SERVICE_NAME}"
log_and_echo "=============================================================="

# Dừng dịch vụ nếu đang chạy
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    log_and_echo "Đang dừng dịch vụ ${SERVICE_NAME}..."
    systemctl stop "${SERVICE_NAME}"
    if [ $? -eq 0 ]; then
        log_and_echo "Dịch vụ ${SERVICE_NAME} đã được dừng."
    else
        log_and_echo "Cảnh báo: Có lỗi khi cố gắng dừng dịch vụ ${SERVICE_NAME} (có thể nó không thực sự chạy)."
    fi
else
    log_and_echo "Thông báo: Dịch vụ ${SERVICE_NAME} không ở trạng thái active."
fi

# Vô hiệu hóa dịch vụ (để không tự khởi động khi boot)
if systemctl is-enabled --quiet "${SERVICE_NAME}"; then
    log_and_echo "Đang vô hiệu hóa dịch vụ ${SERVICE_NAME}..."
    systemctl disable "${SERVICE_NAME}"
    if [ $? -eq 0 ]; then
        log_and_echo "Dịch vụ ${SERVICE_NAME} đã được vô hiệu hóa."
    else
        log_and_echo "Cảnh báo: Có lỗi khi cố gắng vô hiệu hóa dịch vụ ${SERVICE_NAME}."
    fi
else
    log_and_echo "Thông báo: Dịch vụ ${SERVICE_NAME} không ở trạng thái enabled."
fi

# Xóa file unit của dịch vụ
if [ -f "${SERVICE_FILE_PATH}" ]; then
    log_and_echo "Đang xóa file dịch vụ ${SERVICE_FILE_PATH}..."
    rm -f "${SERVICE_FILE_PATH}"
    if [ $? -eq 0 ]; then
        log_and_echo "Đã xóa file dịch vụ thành công."
    else
        log_and_echo "LỖI: Không thể xóa file dịch vụ ${SERVICE_FILE_PATH}."
    fi
else
    log_and_echo "Thông báo: File dịch vụ ${SERVICE_FILE_PATH} không tồn tại."
fi

# Đóng port trên firewall UFW
log_and_echo "Đang kiểm tra và đóng port ${PORT_NUMBER}/tcp trên firewall UFW..."
# Kiểm tra xem rule có tồn tại không trước khi xóa để tránh lỗi "ERROR: Rule not found"
# Lệnh `ufw status numbered` cần tương tác hoặc output phức tạp, dùng cách kiểm tra rule đơn giản hơn
RULE_EXISTS=$(ufw status verbose | grep -qw "${PORT_NUMBER}/tcp.*ALLOW IN" && echo "true" || echo "false")
if [ "$RULE_EXISTS" = "true" ]; then
    ufw delete allow "${PORT_NUMBER}/tcp"
    log_and_echo "Đã gửi lệnh xóa rule cho port ${PORT_NUMBER}/tcp."
else
    log_and_echo "Thông báo: Rule cho port ${PORT_NUMBER}/tcp không được tìm thấy trong UFW hoặc đã được xóa."
fi

# Xóa file thông tin cấu hình
if [ -f "${CONFIG_INFO_FILE}" ]; then
    log_and_echo "Đang xóa file thông tin cấu hình ${CONFIG_INFO_FILE}..."
    rm -f "${CONFIG_INFO_FILE}"
    if [ $? -eq 0 ]; then
        log_and_echo "Đã xóa file thông tin cấu hình thành công."
    else
        log_and_echo "LỖI: Không thể xóa file thông tin cấu hình ${CONFIG_INFO_FILE}."
    fi
else
    log_and_echo "Thông báo: File thông tin cấu hình ${CONFIG_INFO_FILE} không tồn tại."
fi

# Tải lại cấu hình systemd và firewall
log_and_echo "Đang tải lại cấu hình systemd và UFW..."
systemctl daemon-reload
ufw reload

log_and_echo "=============================================================="
log_and_echo "Hoàn tất quá trình xóa instance MTProxy cho port ${PORT_NUMBER}."
log_and_echo "Để chắc chắn, bạn có thể kiểm tra lại bằng các lệnh sau:"
log_and_echo "  systemctl list-units 'mtproxy-${PORT_NUMBER}.service' --all"
log_and_echo "  sudo ufw status"
log_and_echo "=============================================================="
exit 0
