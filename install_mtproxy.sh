# #!/bin/bash

# # --- Biến toàn cục ---
# REPO_DIR_BASE="/opt/MTProxy_GetPageSpeed" # Thư mục gốc cài đặt MTProxy
# WORKING_DIR_EXEC="${REPO_DIR_BASE}/objs/bin" # Nơi chứa file thực thi và config chung
# CONFIG_FILES_STORAGE_DIR="${REPO_DIR_BASE}/configs" # Thư mục lưu file thông tin của từng instance
# PACKAGES_INSTALLED_MARKER="${REPO_DIR_BASE}/.packages_installed"
# MTPROXY_EXEC_FILENAME="mtproto-proxy"
# PROXY_EXEC_FULL_PATH="${WORKING_DIR_EXEC}/${MTPROXY_EXEC_FILENAME}"
# # URL Script trên GitHub của bạn (quan trọng để script tự lưu)
# YOUR_GITHUB_SCRIPT_URL="https://raw.githubusercontent.com/vuvanthe64/mtproxy/main/install_mtproxy.sh"
# # Đề xuất vị trí lưu script cục bộ
# LOCAL_SCRIPT_SUGGESTED_PATH="/usr/local/sbin/manage_mtproxy.sh"


# # --- Hàm tiện ích ---
# log_and_echo() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
# }

# # --- Hàm Xóa Instance MTProxy ---
# remove_mtproxy_instance() {
#     local PORT_NUMBER="$1"
#     local SERVICE_NAME_INSTANCE="mtproxy-${PORT_NUMBER}.service"
#     local SERVICE_FILE_PATH="/etc/systemd/system/${SERVICE_NAME_INSTANCE}"
#     local CONFIG_INFO_FILE_INSTANCE="${CONFIG_FILES_STORAGE_DIR}/mtproxy-${PORT_NUMBER}.info"

#     log_and_echo "=============================================================="
#     log_and_echo "Bắt đầu quá trình xóa instance MTProxy trên port ${PORT_NUMBER}"
#     log_and_echo "Dịch vụ tương ứng: ${SERVICE_NAME_INSTANCE}"
#     log_and_echo "=============================================================="

#     if systemctl is-active --quiet "${SERVICE_NAME_INSTANCE}"; then
#         log_and_echo "Đang dừng dịch vụ ${SERVICE_NAME_INSTANCE}..."
#         sudo systemctl stop "${SERVICE_NAME_INSTANCE}"; else log_and_echo "Thông báo: Dịch vụ ${SERVICE_NAME_INSTANCE} không active."; fi
#     if systemctl is-enabled --quiet "${SERVICE_NAME_INSTANCE}"; then
#         log_and_echo "Đang vô hiệu hóa dịch vụ ${SERVICE_NAME_INSTANCE}..."
#         sudo systemctl disable "${SERVICE_NAME_INSTANCE}"; else log_and_echo "Thông báo: Dịch vụ ${SERVICE_NAME_INSTANCE} không enabled."; fi
#     if [ -f "${SERVICE_FILE_PATH}" ]; then
#         log_and_echo "Đang xóa file dịch vụ ${SERVICE_FILE_PATH}..."
#         sudo rm -f "${SERVICE_FILE_PATH}"; else log_and_echo "Thông báo: File dịch vụ ${SERVICE_FILE_PATH} không tồn tại."; fi
    
#     log_and_echo "Đang kiểm tra và đóng port ${PORT_NUMBER}/tcp trên firewall UFW..."
#     if sudo ufw status verbose | grep -qw "${PORT_NUMBER}/tcp.*ALLOW IN"; then
#         sudo ufw delete allow "${PORT_NUMBER}/tcp" > /dev/null 2>&1
#         log_and_echo "Đã gửi lệnh xóa rule cho port ${PORT_NUMBER}/tcp."
#     else
#         log_and_echo "Thông báo: Rule cho port ${PORT_NUMBER}/tcp không được tìm thấy trong UFW."
#     fi

#     if [ -f "${CONFIG_INFO_FILE_INSTANCE}" ]; then
#         log_and_echo "Đang xóa file thông tin cấu hình ${CONFIG_INFO_FILE_INSTANCE}..."
#         sudo rm -f "${CONFIG_INFO_FILE_INSTANCE}"; else log_and_echo "Thông báo: File thông tin cấu hình ${CONFIG_INFO_FILE_INSTANCE} không tồn tại."; fi

#     log_and_echo "Đang tải lại cấu hình systemd và UFW..."
#     sudo systemctl daemon-reload
#     sudo ufw reload > /dev/null 2>&1
#     log_and_echo "=============================================================="
#     log_and_echo "Hoàn tất quá trình xóa instance MTProxy cho port ${PORT_NUMBER}."
#     log_and_echo "=============================================================="
# }

# # --- Hàm Cài Đặt Instance MTProxy Mới ---
# install_new_mtproxy_instance() {
#     log_and_echo "=================================================="
#     log_and_echo "Bắt đầu quá trình tạo INSTANCE MTProxy MỚI..."
#     log_and_echo "=================================================="
#     echo ""

#     # --- Tự động lưu script nếu chưa có bản cục bộ ---
#     if [ ! -f "${LOCAL_SCRIPT_SUGGESTED_PATH}" ]; then
#         log_and_echo "Lần đầu chạy hoặc file script cục bộ không tìm thấy tại ${LOCAL_SCRIPT_SUGGESTED_PATH}."
#         log_and_echo "Đang cố gắng tải và lưu script này để sử dụng sau..."
#         if sudo curl -sSL "${YOUR_GITHUB_SCRIPT_URL}?$(date +%s)" -o "${LOCAL_SCRIPT_SUGGESTED_PATH}"; then
#             sudo chmod +x "${LOCAL_SCRIPT_SUGGESTED_PATH}"
#             log_and_echo "✅ Script đã được lưu thành công vào: ${LOCAL_SCRIPT_SUGGESTED_PATH}"
#             log_and_echo "   Lần sau, bạn có thể chạy lệnh cài đặt bằng: sudo bash ${LOCAL_SCRIPT_SUGGESTED_PATH}"
#             log_and_echo "   Hoặc lệnh xóa bằng: sudo bash ${LOCAL_SCRIPT_SUGGESTED_PATH} remove <PORT>"
#         else
#             log_and_echo "⚠️ CẢNH BÁO: Không thể tự động lưu script vào ${LOCAL_SCRIPT_SUGGESTED_PATH}."
#             log_and_echo "   Bạn vẫn có thể chạy script qua curl từ GitHub."
#             log_and_echo "   Nếu muốn lưu thủ công, hãy chạy (thay thế URL nếu cần):"
#             echo "       sudo curl -sSL \"${YOUR_GITHUB_SCRIPT_URL}?$(date +%s)\" -o \"${LOCAL_SCRIPT_SUGGESTED_PATH}\" && sudo chmod +x \"${LOCAL_SCRIPT_SUGGESTED_PATH}\""
#         fi
#         echo ""
#     fi

#     mkdir -p "${CONFIG_FILES_STORAGE_DIR}"
#     # WORKING_DIR_BASE sẽ được tạo bởi git clone

#     # --- Bước 1: Cập nhật và cài đặt gói phụ thuộc (chỉ nếu cần) ---
#     if [ ! -f "${PACKAGES_INSTALLED_MARKER}" ]; then
#         log_and_echo "[1/9] Đang cập nhật hệ thống và cài đặt các gói phụ thuộc..."
#         export DEBIAN_FRONTEND=noninteractive
#         apt-get update -yqq > /dev/null 2>&1 || { log_and_echo "LỖI: apt-get update thất bại."; exit 1; }
#         apt-get install -y -qq git curl build-essential libssl-dev zlib1g-dev make ufw > /dev/null 2>&1 || { log_and_echo "LỖI: apt-get install thất bại."; exit 1; }
#         log_and_echo "Cài đặt gói phụ thuộc thành công."
#         sudo touch "${PACKAGES_INSTALLED_MARKER}"
#     else
#         log_and_echo "[1/9] Các gói phụ thuộc đã được cài đặt. Bỏ qua."
#     fi
#     echo ""

#     # --- Bước 2 & 3: Tải và biên dịch mã nguồn (chỉ nếu cần) ---
#     if [ ! -f "${PROXY_EXEC_FULL_PATH}" ]; then
#         log_and_echo "[2/9] Mã nguồn MTProxy chưa có. Tiến hành tải và biên dịch..."
#         if [ -d "$REPO_DIR_BASE" ]; then rm -rf "$REPO_DIR_BASE"; fi
#         mkdir -p "$REPO_DIR_BASE"
#         git clone "https://github.com/GetPageSpeed/MTProxy" "$REPO_DIR_BASE" > /dev/null 2>&1 || { log_and_echo "LỖI: git clone thất bại."; exit 1; }
#         log_and_echo "Tải mã nguồn thành công vào $REPO_DIR_BASE."
#         cd "$REPO_DIR_BASE" || { log_and_echo "LỖI: Không thể cd vào $REPO_DIR_BASE"; exit 1; }
#         log_and_echo "[3/9] Đang biên dịch MTProxy..."
#         make > /dev/null 2>&1 || { log_and_echo "LỖI: make thất bại."; exit 1; }
#         if [ ! -f "$PROXY_EXEC_FULL_PATH" ]; then log_and_echo "LỖI: Biên dịch MTProxy thất bại."; exit 1; fi
#         log_and_echo "Biên dịch thành công."
#     else
#         log_and_echo "[2/9] & [3/9] Mã nguồn MTProxy đã có. Bỏ qua tải và biên dịch."
#     fi
#     echo ""

#     # --- Bước 4: Chuẩn bị thư mục làm việc cho config chung ---
#     log_and_echo "[4/9] Chuẩn bị thư mục làm việc chung: $WORKING_DIR_EXEC"
#     cd "$WORKING_DIR_EXEC" || { log_and_echo "LỖI: Không thể cd vào $WORKING_DIR_EXEC"; exit 1; }
#     if [ ! -s "official-proxy-secret" ]; then
#         log_and_echo "Tải official-proxy-secret..."
#         curl -sS --fail https://core.telegram.org/getProxySecret -o official-proxy-secret || log_and_echo "CẢNH BÁO: Không tải được official-proxy-secret."
#     fi
#     if [ ! -s "proxy-multi.conf" ]; then
#         log_and_echo "Tải proxy-multi.conf..."
#         curl -sS --fail https://core.telegram.org/getProxyConfig -o proxy-multi.conf || { log_and_echo "LỖI QUAN TRỌNG: Không tải được proxy-multi.conf."; exit 1; }
#     fi
#     echo ""

#     # --- Bước 5: Tạo client secret mới ---
#     log_and_echo "[5/9] Đang tạo client secret mới..."
#     NEW_CLIENT_SECRET=$(head -c 16 /dev/urandom | xxd -p -c 16)
#     log_and_echo "Client Secret mới: $NEW_CLIENT_SECRET"
#     echo ""

#     # --- Bước 6: Tạo port ngẫu nhiên và kiểm tra ---
#     log_and_echo "[6/9] Đang tìm port ngẫu nhiên khả dụng..."
#     MAX_PORT_ATTEMPTS=10; CURRENT_ATTEMPT=0; RANDOM_PORT=""; SERVICE_NAME_FOR_NEW_INSTANCE=""
#     while [ $CURRENT_ATTEMPT -lt $MAX_PORT_ATTEMPTS ]; do
#         TEMP_PORT=$(shuf -i 10000-65535 -n 1)
#         TEMP_SERVICE_NAME="mtproxy-${TEMP_PORT}.service"
#         PORT_IN_USE=$(ss -tlpn | grep -q ":${TEMP_PORT}" && echo "true" || echo "false")
#         SERVICE_FILE_EXISTS=$(test -f "/etc/systemd/system/${TEMP_SERVICE_NAME}" && echo "true" || echo "false")
#         if [ "$PORT_IN_USE" = "false" ] && [ "$SERVICE_FILE_EXISTS" = "false" ]; then
#             RANDOM_PORT=$TEMP_PORT; SERVICE_NAME_FOR_NEW_INSTANCE=$TEMP_SERVICE_NAME; break
#         fi
#         CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1)); sleep 0.5
#     done
#     if [ -z "$RANDOM_PORT" ]; then log_and_echo "LỖI: Không tìm được port khả dụng."; exit 1; fi
#     log_and_echo "Port ngẫu nhiên được chọn: $RANDOM_PORT (Service: $SERVICE_NAME_FOR_NEW_INSTANCE)"
#     echo ""

#     # --- Bước 7: Mở port trên Firewall ---
#     log_and_echo "[7/9] Mở port $RANDOM_PORT trên Firewall (UFW)..."
#     if command -v ufw > /dev/null; then
#         if ! ufw status | grep -qw active; then ufw allow ssh > /dev/null 2>&1; ufw --force enable > /dev/null 2>&1; fi
#         ufw allow ${RANDOM_PORT}/tcp > /dev/null 2>&1; ufw reload > /dev/null 2>&1
#         log_and_echo "Đã thêm rule cho port $RANDOM_PORT/tcp và reload UFW."
#     else log_and_echo "Cảnh báo: ufw không được cài đặt."; fi
#     echo ""

#     # --- Bước 8: Lấy địa chỉ IP public ---
#     log_and_echo "[8/9] Lấy địa chỉ IP public..."
#     SERVER_IP=$(curl -s --max-time 10 ifconfig.me/ip || curl -s --max-time 10 api.ipify.org || hostname -I | awk '{print $1}')
#     if [ -z "$SERVER_IP" ]; then SERVER_IP="YOUR_SERVER_IP"; log_and_echo "CẢNH BÁO: Không thể lấy IP tự động."; fi
#     log_and_echo "Địa chỉ IP của máy chủ: $SERVER_IP"
#     echo ""

#     # --- Bước 9: Tạo và kích hoạt dịch vụ systemd ---
#     log_and_echo "[9/9] Tạo và kích hoạt dịch vụ systemd (${SERVICE_NAME_FOR_NEW_INSTANCE})..."
#     STATS_PORT_INSTANCE=$((RANDOM_PORT + 1)); if [ $STATS_PORT_INSTANCE -gt 65535 ]; then STATS_PORT_INSTANCE=$((RANDOM_PORT -1)); fi
#     if [ $STATS_PORT_INSTANCE -lt 1024 ]; then STATS_PORT_INSTANCE=8889; fi

#     PROXY_SYSTEMD_COMMAND="${PROXY_EXEC_FULL_PATH} -u nobody -p ${STATS_PORT_INSTANCE} -H ${RANDOM_PORT} -S ${NEW_CLIENT_SECRET} --aes-pwd ${WORKING_DIR_EXEC}/official-proxy-secret ${WORKING_DIR_EXEC}/proxy-multi.conf -M 1"
#     SERVICE_FILE_CONTENT="[Unit]
# Description=MTProxy (GetPageSpeed fork) instance on port ${RANDOM_PORT}
# After=network.target
# [Service]
# Type=simple
# User=nobody
# Group=nogroup
# WorkingDirectory=${WORKING_DIR_EXEC}
# ExecStart=${PROXY_SYSTEMD_COMMAND}
# Restart=always
# RestartSec=3
# StandardOutput=journal
# StandardError=journal
# [Install]
# WantedBy=multi-user.target"
#     echo "${SERVICE_FILE_CONTENT}" | sudo tee /etc/systemd/system/${SERVICE_NAME_FOR_NEW_INSTANCE} > /dev/null || { log_and_echo "LỖI: Không tạo được file systemd."; exit 1; }
#     sudo systemctl daemon-reload
#     sudo systemctl enable "${SERVICE_NAME_FOR_NEW_INSTANCE}"
#     sudo systemctl start "${SERVICE_NAME_FOR_NEW_INSTANCE}"
#     log_and_echo "Dịch vụ ${SERVICE_NAME_FOR_NEW_INSTANCE} đã được tạo và khởi động."
#     echo ""

#     # --- Lưu thông tin cấu hình ---
#     CONFIG_INFO_FILE_INSTANCE="${CONFIG_FILES_STORAGE_DIR}/mtproxy-${RANDOM_PORT}.info"
#     TG_LINK="tg://proxy?server=${SERVER_IP}&port=${RANDOM_PORT}&secret=${NEW_CLIENT_SECRET}"
#     log_and_echo "Lưu thông tin vào ${CONFIG_INFO_FILE_INSTANCE}..."
#     {
#         echo "SERVICE_NAME=${SERVICE_NAME_FOR_NEW_INSTANCE}"; echo "SERVER_IP=${SERVER_IP}"; echo "PORT=${RANDOM_PORT}"
#         echo "SECRET=${NEW_CLIENT_SECRET}"; echo "TG_LINK=${TG_LINK}"; echo "STATS_PORT=${STATS_PORT_INSTANCE}"
#     } > "${CONFIG_INFO_FILE_INSTANCE}"
#     log_and_echo "Thông tin cấu hình đã được lưu."
#     echo ""

#     # --- Bước 10 (Cuối): Kiểm tra và hiển thị ---
#     log_and_echo "[10/10] Kiểm tra trạng thái và hiển thị thông tin..."
#     if systemctl is-active --quiet "${SERVICE_NAME_FOR_NEW_INSTANCE}"; then
#         log_and_echo "✅ THÀNH CÔNG: Dịch vụ MTProxy (${SERVICE_NAME_FOR_NEW_INSTANCE}) đang hoạt động (Port: ${RANDOM_PORT})."
#     else
#         log_and_echo "⚠️ CẢNH BÁO: Dịch vụ MTProxy (${SERVICE_NAME_FOR_NEW_INSTANCE}) KHÔNG hoạt động."
#         log_and_echo "Kiểm tra log: sudo journalctl -u ${SERVICE_NAME_FOR_NEW_INSTANCE} -e"
#     fi

#     echo ""
#     log_and_echo "=================================================="
#     log_and_echo "Script đã hoàn tất việc tạo instance mới: $(date)"
#     log_and_echo "=================================================="
#     echo ""
#     log_and_echo "---------------------------------------------------------------------"
#     log_and_echo "Để TẠO THÊM một instance MTProxy MỚI KHÁC:"
#     log_and_echo "  CÁCH 1 (Luôn lấy bản mới nhất từ GitHub):"
#     echo "    curl -sSL \"${YOUR_GITHUB_SCRIPT_URL}?$(date +%s)\" | sudo bash"
#     log_and_echo "  CÁCH 2 (Nếu script đã được lưu cục bộ tại \"${LOCAL_SCRIPT_SUGGESTED_PATH}\"):"
#     echo "    sudo bash \"${LOCAL_SCRIPT_SUGGESTED_PATH}\""
#     log_and_echo "---------------------------------------------------------------------"
#     log_and_echo "Quản lý dịch vụ VỪA TẠO (${SERVICE_NAME_FOR_NEW_INSTANCE}):"
#     log_and_echo "  - Trạng thái: sudo systemctl status ${SERVICE_NAME_FOR_NEW_INSTANCE}"
#     log_and_echo "  - Dừng:       sudo systemctl stop ${SERVICE_NAME_FOR_NEW_INSTANCE}"
#     log_and_echo "  - Khởi động:  sudo systemctl start ${SERVICE_NAME_FOR_NEW_INSTANCE}"
#     log_and_echo "  - Xem log:   sudo journalctl -u ${SERVICE_NAME_FOR_NEW_INSTANCE} -f"
#     log_and_echo "---------------------------------------------------------------------"
#     log_and_echo "Để XÓA HOÀN TOÀN instance proxy VỪA TẠO (port ${RANDOM_PORT}):"
#     log_and_echo "  CÁCH 1: Chạy lại lệnh từ GitHub (luôn lấy bản mới nhất):"
#     echo "    curl -sSL \"${YOUR_GITHUB_SCRIPT_URL}?$(date +%s)\" | sudo bash -s remove ${RANDOM_PORT}"
#     log_and_echo "  CÁCH 2: Chạy từ file script đã được lưu cục bộ:"
#     echo "    sudo bash \"${LOCAL_SCRIPT_SUGGESTED_PATH}\" remove ${RANDOM_PORT}"
#     log_and_echo "---------------------------------------------------------------------"
#     log_and_echo "Thông tin cấu hình này lưu tại: ${CONFIG_INFO_FILE_INSTANCE}"
#     log_and_echo "Xem tất cả config đã lưu: ls -l ${CONFIG_FILES_STORAGE_DIR}"
#     log_and_echo "Xem tất cả service mtproxy: systemctl list-units 'mtproxy-*.service'"
#     log_and_echo "---------------------------------------------------------------------"
#     echo "" 
#     log_and_echo "🔗 LINK KẾT NỐI TELEGRAM CHO PROXY MỚI"
#     log_and_echo "${TG_LINK}"
#     log_and_echo "=================================================="
#     echo ""
#     log_and_echo "THÔNG TIN HỖ TRỢ & LIÊN HỆ:"
#     log_and_echo "Telegram: @thevv"
#     log_and_echo "Email: vuvanthe64@gmail.com"
#     log_and_echo "---------------------------------------------------------------------"
#     echo ""
# }


# # --- Xử lý Tham Số Đầu Vào ---
# ACTION="$1"
# ARG_PORT="$2"

# # Kiểm tra quyền root cho toàn bộ script
# if [ "$(id -u)" -ne 0 ]; then
#   log_and_echo "LỖI: Script này cần được chạy với quyền root hoặc sudo."
#   log_and_echo "Vui lòng chạy lại bằng cách pipe qua 'sudo bash': curl ... | sudo bash"
#   exit 1
# fi


# if [ "$ACTION" == "remove" ]; then
#     if [ -z "$ARG_PORT" ]; then
#         log_and_echo "LỖI: Để xóa, vui lòng cung cấp số PORT của instance MTProxy."
#         log_and_echo "Cách dùng: sudo bash $0 remove <PORT_NUMBER>"
#         log_and_echo "Hoặc: curl ... | sudo bash -s remove <PORT_NUMBER>"
#         exit 1
#     fi
#     if ! [[ "$ARG_PORT" =~ ^[0-9]+$ ]]; then # Kiểm tra port là số
#         log_and_echo "LỖI: Số PORT '$ARG_PORT' không hợp lệ. Vui lòng nhập một số."
#         exit 1
#     fi
#     remove_mtproxy_instance "${ARG_PORT}"
# elif [ -z "$ACTION" ] || [ "$ACTION" == "install" ]; then
#     install_new_mtproxy_instance
# else
#     log_and_echo "LỖI: Hành động không hợp lệ '$ACTION'."
#     log_and_echo "Hành động được hỗ trợ: "
#     log_and_echo "  (không có tham số) hoặc 'install' : để cài đặt instance MTProxy mới."
#     log_and_echo "  'remove <PORT_NUMBER>'           : để xóa instance MTProxy trên port cụ thể."
#     exit 1
# fi

# exit 0

#!/bin/bash

# Script tự động cài đặt, xóa, và quản lý NHIỀU INSTANCE MTProxy bằng systemd
# Repository: GetPageSpeed/MTProxy
# Script này sẽ cố gắng tự lưu một bản sao vào LOCAL_SCRIPT_SUGGESTED_PATH khi chạy install lần đầu.

# --- Biến toàn cục ---
REPO_DIR_BASE="/opt/MTProxy_GetPageSpeed" # Thư mục gốc cài đặt MTProxy
WORKING_DIR_EXEC="${REPO_DIR_BASE}/objs/bin" # Nơi chứa file thực thi và config chung
CONFIG_FILES_STORAGE_DIR="${REPO_DIR_BASE}/configs" # Thư mục lưu file thông tin của từng instance
# LOG_FILES_STORAGE_DIR="${REPO_DIR_BASE}/logs"     # Thư mục lưu log (hiện không dùng trực tiếp cho output proxy)
PACKAGES_INSTALLED_MARKER="${REPO_DIR_BASE}/.packages_installed"
MTPROXY_EXEC_FILENAME="mtproto-proxy"
PROXY_EXEC_FULL_PATH="${WORKING_DIR_EXEC}/${MTPROXY_EXEC_FILENAME}"
# URL Script trên GitHub của bạn (quan trọng để script tự lưu)
YOUR_GITHUB_SCRIPT_URL="https://raw.githubusercontent.com/vuvanthe64/mtproxy/main/install_mtproxy.sh"
# Đề xuất vị trí lưu script cục bộ
LOCAL_SCRIPT_SUGGESTED_PATH="/usr/local/sbin/manage_mtproxy.sh"


# --- Hàm tiện ích ---
log_and_echo() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# --- Hàm Xóa Instance MTProxy ---
remove_mtproxy_instance() {
    local PORT_NUMBER="$1"
    local SERVICE_NAME_INSTANCE="mtproxy-${PORT_NUMBER}.service"
    local SERVICE_FILE_PATH="/etc/systemd/system/${SERVICE_NAME_INSTANCE}"
    local CONFIG_INFO_FILE_INSTANCE="${CONFIG_FILES_STORAGE_DIR}/mtproxy-${PORT_NUMBER}.info"

    log_and_echo "=============================================================="
    log_and_echo "Bắt đầu quá trình xóa instance MTProxy trên port ${PORT_NUMBER}"
    log_and_echo "Dịch vụ tương ứng: ${SERVICE_NAME_INSTANCE}"
    log_and_echo "=============================================================="

    if systemctl is-active --quiet "${SERVICE_NAME_INSTANCE}"; then
        log_and_echo "Đang dừng dịch vụ ${SERVICE_NAME_INSTANCE}..."
        systemctl stop "${SERVICE_NAME_INSTANCE}"; else log_and_echo "Thông báo: Dịch vụ ${SERVICE_NAME_INSTANCE} không active."; fi
    if systemctl is-enabled --quiet "${SERVICE_NAME_INSTANCE}"; then
        log_and_echo "Đang vô hiệu hóa dịch vụ ${SERVICE_NAME_INSTANCE}..."
        systemctl disable "${SERVICE_NAME_INSTANCE}"; else log_and_echo "Thông báo: Dịch vụ ${SERVICE_NAME_INSTANCE} không enabled."; fi
    if [ -f "${SERVICE_FILE_PATH}" ]; then
        log_and_echo "Đang xóa file dịch vụ ${SERVICE_FILE_PATH}..."
        rm -f "${SERVICE_FILE_PATH}"; else log_and_echo "Thông báo: File dịch vụ ${SERVICE_FILE_PATH} không tồn tại."; fi
    
    log_and_echo "Đang kiểm tra và đóng port ${PORT_NUMBER}/tcp trên firewall UFW..."
    if ufw status verbose | grep -qw "${PORT_NUMBER}/tcp.*ALLOW IN"; then # Không cần sudo khi script đã chạy bằng sudo
        ufw delete allow "${PORT_NUMBER}/tcp" > /dev/null 2>&1
        log_and_echo "Đã gửi lệnh xóa rule cho port ${PORT_NUMBER}/tcp."
    else
        log_and_echo "Thông báo: Rule cho port ${PORT_NUMBER}/tcp không được tìm thấy trong UFW."
    fi

    if [ -f "${CONFIG_INFO_FILE_INSTANCE}" ]; then
        log_and_echo "Đang xóa file thông tin cấu hình ${CONFIG_INFO_FILE_INSTANCE}..."
        rm -f "${CONFIG_INFO_FILE_INSTANCE}"; else log_and_echo "Thông báo: File thông tin cấu hình ${CONFIG_INFO_FILE_INSTANCE} không tồn tại."; fi

    log_and_echo "Đang tải lại cấu hình systemd và UFW..."
    systemctl daemon-reload
    ufw reload > /dev/null 2>&1
    log_and_echo "=============================================================="
    log_and_echo "Hoàn tất quá trình xóa instance MTProxy cho port ${PORT_NUMBER}."
    log_and_echo "=============================================================="
}

# --- Hàm Cài Đặt Instance MTProxy Mới ---
install_new_mtproxy_instance() {
    log_and_echo "=================================================="
    log_and_echo "Bắt đầu quá trình tạo INSTANCE MTProxy MỚI..."
    log_and_echo "=================================================="
    echo ""

    # --- Tự động lưu script nếu chưa có bản cục bộ ---
    if [ ! -f "${LOCAL_SCRIPT_SUGGESTED_PATH}" ]; then
        log_and_echo "Lần đầu chạy hoặc file script cục bộ không tìm thấy tại ${LOCAL_SCRIPT_SUGGESTED_PATH}."
        log_and_echo "Đang cố gắng tải và lưu script này để sử dụng sau..."
        # Script đang chạy với sudo, nên curl và chmod không cần sudo nữa
        if curl -sSL "${YOUR_GITHUB_SCRIPT_URL}?$(date +%s)" -o "${LOCAL_SCRIPT_SUGGESTED_PATH}"; then
            chmod +x "${LOCAL_SCRIPT_SUGGESTED_PATH}"
            log_and_echo "✅ Script đã được lưu thành công vào: ${LOCAL_SCRIPT_SUGGESTED_PATH}"
            log_and_echo "   Lần sau, bạn có thể chạy lệnh cài đặt bằng: sudo bash ${LOCAL_SCRIPT_SUGGESTED_PATH}"
            log_and_echo "   Hoặc lệnh xóa bằng: sudo bash ${LOCAL_SCRIPT_SUGGESTED_PATH} remove <PORT>"
        else
            log_and_echo "⚠️ CẢNH BÁO: Không thể tự động lưu script vào ${LOCAL_SCRIPT_SUGGESTED_PATH}."
            log_and_echo "   Bạn vẫn có thể chạy script qua curl từ GitHub."
            log_and_echo "   Nếu muốn lưu thủ công, hãy chạy (thay thế URL nếu cần):"
            echo "       sudo curl -sSL \"${YOUR_GITHUB_SCRIPT_URL}?$(date +%s)\" -o \"${LOCAL_SCRIPT_SUGGESTED_PATH}\" && sudo chmod +x \"${LOCAL_SCRIPT_SUGGESTED_PATH}\""
        fi
        echo ""
    fi

    mkdir -p "${CONFIG_FILES_STORAGE_DIR}"
    # WORKING_DIR_BASE sẽ được tạo bởi git clone

    # --- Bước 1: Cập nhật và cài đặt gói phụ thuộc (chỉ nếu cần) ---
    if [ ! -f "${PACKAGES_INSTALLED_MARKER}" ]; then
        log_and_echo "[1/9] Đang cập nhật hệ thống và cài đặt các gói phụ thuộc..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -yqq > /dev/null 2>&1 || { log_and_echo "LỖI: apt-get update thất bại."; exit 1; }
        apt-get install -y -qq git curl build-essential libssl-dev zlib1g-dev make ufw > /dev/null 2>&1 || { log_and_echo "LỖI: apt-get install thất bại."; exit 1; }
        log_and_echo "Cài đặt gói phụ thuộc thành công."
        touch "${PACKAGES_INSTALLED_MARKER}" # Không cần sudo vì script đã chạy bằng sudo
    else
        log_and_echo "[1/9] Các gói phụ thuộc đã được cài đặt. Bỏ qua."
    fi
    echo ""

    # --- Bước 2 & 3: Tải và biên dịch mã nguồn (chỉ nếu cần) ---
    if [ ! -f "${PROXY_EXEC_FULL_PATH}" ]; then
        log_and_echo "[2/9] Mã nguồn MTProxy chưa có. Tiến hành tải và biên dịch..."
        if [ -d "$REPO_DIR_BASE" ]; then rm -rf "$REPO_DIR_BASE"; fi
        mkdir -p "$REPO_DIR_BASE"
        git clone "https://github.com/GetPageSpeed/MTProxy" "$REPO_DIR_BASE" > /dev/null 2>&1 || { log_and_echo "LỖI: git clone thất bại."; exit 1; }
        log_and_echo "Tải mã nguồn thành công vào $REPO_DIR_BASE."
        cd "$REPO_DIR_BASE" || { log_and_echo "LỖI: Không thể cd vào $REPO_DIR_BASE"; exit 1; }
        log_and_echo "[3/9] Đang biên dịch MTProxy..."
        make > /dev/null 2>&1 || { log_and_echo "LỖI: make thất bại."; exit 1; }
        if [ ! -f "$PROXY_EXEC_FULL_PATH" ]; then log_and_echo "LỖI: Biên dịch MTProxy thất bại."; exit 1; fi
        log_and_echo "Biên dịch thành công."
    else
        log_and_echo "[2/9] & [3/9] Mã nguồn MTProxy đã có. Bỏ qua tải và biên dịch."
    fi
    echo ""

    # --- Bước 4: Chuẩn bị thư mục làm việc cho config chung ---
    log_and_echo "[4/9] Chuẩn bị thư mục làm việc chung: $WORKING_DIR_EXEC"
    cd "$WORKING_DIR_EXEC" || { log_and_echo "LỖI: Không thể cd vào $WORKING_DIR_EXEC"; exit 1; }
    if [ ! -s "official-proxy-secret" ]; then
        log_and_echo "Tải official-proxy-secret..."
        curl -sS --fail https://core.telegram.org/getProxySecret -o official-proxy-secret || log_and_echo "CẢNH BÁO: Không tải được official-proxy-secret."
    fi
    if [ ! -s "proxy-multi.conf" ]; then
        log_and_echo "Tải proxy-multi.conf..."
        curl -sS --fail https://core.telegram.org/getProxyConfig -o proxy-multi.conf || { log_and_echo "LỖI QUAN TRỌNG: Không tải được proxy-multi.conf."; exit 1; }
    fi
    echo ""

    # --- Bước 5: Tạo client secret mới ---
    log_and_echo "[5/9] Đang tạo client secret mới..."
    NEW_CLIENT_SECRET=$(head -c 16 /dev/urandom | xxd -p -c 16)
    log_and_echo "Client Secret mới: $NEW_CLIENT_SECRET"
    echo ""

    # --- Bước 6: Tạo port ngẫu nhiên và kiểm tra ---
    log_and_echo "[6/9] Đang tìm port ngẫu nhiên khả dụng..."
    MAX_PORT_ATTEMPTS=10; CURRENT_ATTEMPT=0; RANDOM_PORT=""; SERVICE_NAME_FOR_NEW_INSTANCE=""
    while [ $CURRENT_ATTEMPT -lt $MAX_PORT_ATTEMPTS ]; do
        TEMP_PORT=$(shuf -i 10000-65535 -n 1)
        TEMP_SERVICE_NAME="mtproxy-${TEMP_PORT}.service"
        PORT_IN_USE=$(ss -tlpn | grep -q ":${TEMP_PORT}" && echo "true" || echo "false")
        SERVICE_FILE_EXISTS=$(test -f "/etc/systemd/system/${TEMP_SERVICE_NAME}" && echo "true" || echo "false")
        if [ "$PORT_IN_USE" = "false" ] && [ "$SERVICE_FILE_EXISTS" = "false" ]; then
            RANDOM_PORT=$TEMP_PORT; SERVICE_NAME_FOR_NEW_INSTANCE=$TEMP_SERVICE_NAME; break
        fi
        CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1)); sleep 0.5
    done
    if [ -z "$RANDOM_PORT" ]; then log_and_echo "LỖI: Không tìm được port khả dụng."; exit 1; fi
    log_and_echo "Port ngẫu nhiên được chọn: $RANDOM_PORT (Service: $SERVICE_NAME_FOR_NEW_INSTANCE)"
    echo ""

    # --- Bước 7: Mở port trên Firewall ---
    log_and_echo "[7/9] Mở port $RANDOM_PORT trên Firewall (UFW)..."
    if command -v ufw > /dev/null; then
        if ! ufw status | grep -qw active; then ufw allow ssh > /dev/null 2>&1; ufw --force enable > /dev/null 2>&1; fi
        ufw allow ${RANDOM_PORT}/tcp > /dev/null 2>&1; ufw reload > /dev/null 2>&1
        log_and_echo "Đã thêm rule cho port $RANDOM_PORT/tcp và reload UFW."
    else log_and_echo "Cảnh báo: ufw không được cài đặt."; fi
    echo ""

    # --- Bước 8: Lấy địa chỉ IP public ---
    log_and_echo "[8/9] Lấy địa chỉ IP public..."
    SERVER_IP=$(curl -s --max-time 10 ifconfig.me/ip || curl -s --max-time 10 api.ipify.org || hostname -I | awk '{print $1}')
    if [ -z "$SERVER_IP" ]; then SERVER_IP="YOUR_SERVER_IP"; log_and_echo "CẢNH BÁO: Không thể lấy IP tự động."; fi
    log_and_echo "Địa chỉ IP của máy chủ: $SERVER_IP"
    echo ""

    # --- Bước 9: Tạo và kích hoạt dịch vụ systemd ---
    log_and_echo "[9/9] Tạo và kích hoạt dịch vụ systemd (${SERVICE_NAME_FOR_NEW_INSTANCE})..."
    STATS_PORT_INSTANCE=$((RANDOM_PORT + 1)); if [ $STATS_PORT_INSTANCE -gt 65535 ]; then STATS_PORT_INSTANCE=$((RANDOM_PORT -1)); fi
    if [ $STATS_PORT_INSTANCE -lt 1024 ]; then STATS_PORT_INSTANCE=8889; fi

    PROXY_SYSTEMD_COMMAND="${PROXY_EXEC_FULL_PATH} -u nobody -p ${STATS_PORT_INSTANCE} -H ${RANDOM_PORT} -S ${NEW_CLIENT_SECRET} --aes-pwd ${WORKING_DIR_EXEC}/official-proxy-secret ${WORKING_DIR_EXEC}/proxy-multi.conf -M 1"
    SERVICE_FILE_CONTENT="[Unit]
Description=MTProxy (GetPageSpeed fork) instance on port ${RANDOM_PORT}
After=network.target
[Service]
Type=simple
User=nobody
Group=nogroup
WorkingDirectory=${WORKING_DIR_EXEC}
ExecStart=${PROXY_SYSTEMD_COMMAND}
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target"
    echo "${SERVICE_FILE_CONTENT}" | tee /etc/systemd/system/${SERVICE_NAME_FOR_NEW_INSTANCE} > /dev/null || { log_and_echo "LỖI: Không tạo được file systemd."; exit 1; } # Không cần sudo cho tee nếu script đã chạy bằng sudo
    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME_FOR_NEW_INSTANCE}"
    systemctl start "${SERVICE_NAME_FOR_NEW_INSTANCE}"
    log_and_echo "Dịch vụ ${SERVICE_NAME_FOR_NEW_INSTANCE} đã được tạo và khởi động."
    echo ""

    # --- Lưu thông tin cấu hình ---
    CONFIG_INFO_FILE_INSTANCE="${CONFIG_FILES_STORAGE_DIR}/mtproxy-${RANDOM_PORT}.info"
    TG_LINK="tg://proxy?server=${SERVER_IP}&port=${RANDOM_PORT}&secret=${NEW_CLIENT_SECRET}"
    log_and_echo "Lưu thông tin vào ${CONFIG_INFO_FILE_INSTANCE}..."
    {
        echo "SERVICE_NAME=${SERVICE_NAME_FOR_NEW_INSTANCE}"; echo "SERVER_IP=${SERVER_IP}"; echo "PORT=${RANDOM_PORT}"
        echo "SECRET=${NEW_CLIENT_SECRET}"; echo "TG_LINK=${TG_LINK}"; echo "STATS_PORT=${STATS_PORT_INSTANCE}"
    } > "${CONFIG_INFO_FILE_INSTANCE}" # Không cần sudo nếu script chạy bằng sudo và có quyền ghi vào đây
    log_and_echo "Thông tin cấu hình đã được lưu."
    echo ""

    # --- Bước 10 (Cuối): Kiểm tra và hiển thị ---
    log_and_echo "[10/10] Kiểm tra trạng thái và hiển thị thông tin..."
    if systemctl is-active --quiet "${SERVICE_NAME_FOR_NEW_INSTANCE}"; then
        log_and_echo "✅ THÀNH CÔNG: Dịch vụ MTProxy (${SERVICE_NAME_FOR_NEW_INSTANCE}) đang hoạt động (Port: ${RANDOM_PORT})."
    else
        log_and_echo "⚠️ CẢNH BÁO: Dịch vụ MTProxy (${SERVICE_NAME_FOR_NEW_INSTANCE}) KHÔNG hoạt động."
        log_and_echo "Kiểm tra log: sudo journalctl -u ${SERVICE_NAME_FOR_NEW_INSTANCE} -e"
    fi

    echo ""
    log_and_echo "=================================================="
    log_and_echo "Script đã hoàn tất việc tạo instance mới: $(date)"
    log_and_echo "=================================================="
    echo ""
    log_and_echo "---------------------------------------------------------------------"
    log_and_echo "Để TẠO THÊM một instance MTProxy MỚI KHÁC:"
    log_and_echo "  CÁCH 1 (Luôn lấy bản mới nhất từ GitHub):"
    echo "    curl -sSL \"${YOUR_GITHUB_SCRIPT_URL}?$(date +%s)\" | sudo bash"
    log_and_echo "  CÁCH 2 (Nếu script đã được lưu cục bộ tại \"${LOCAL_SCRIPT_SUGGESTED_PATH}\"):"
    echo "    sudo bash \"${LOCAL_SCRIPT_SUGGESTED_PATH}\""
    log_and_echo "---------------------------------------------------------------------"
    log_and_echo "Quản lý dịch vụ VỪA TẠO (${SERVICE_NAME_FOR_NEW_INSTANCE}):"
    log_and_echo "  - Trạng thái: sudo systemctl status ${SERVICE_NAME_FOR_NEW_INSTANCE}"
    log_and_echo "  - Dừng:       sudo systemctl stop ${SERVICE_NAME_FOR_NEW_INSTANCE}"
    log_and_echo "  - Khởi động:  sudo systemctl start ${SERVICE_NAME_FOR_NEW_INSTANCE}"
    log_and_echo "  - Xem log:   sudo journalctl -u ${SERVICE_NAME_FOR_NEW_INSTANCE} -f"
    log_and_echo "---------------------------------------------------------------------"
    log_and_echo "Để XÓA HOÀN TOÀN instance proxy VỪA TẠO (port ${RANDOM_PORT}):"
    log_and_echo "  CÁCH 1: Chạy lại lệnh từ GitHub (luôn lấy bản mới nhất):"
    # Sử dụng echo để dòng lệnh này có thể copy-paste trực tiếp
    echo "    curl -sSL \"${YOUR_GITHUB_SCRIPT_URL}?$(date +%s)\" | sudo bash -s remove ${RANDOM_PORT}"
    log_and_echo "  CÁCH 2: Chạy từ file script đã được lưu cục bộ (nếu có tại \"${LOCAL_SCRIPT_SUGGESTED_PATH}\"):"
    # Sử dụng echo để dòng lệnh này có thể copy-paste trực tiếp
    echo "    sudo bash \"${LOCAL_SCRIPT_SUGGESTED_PATH}\" remove ${RANDOM_PORT}"
    log_and_echo "       (Script này cố gắng tự lưu vào \"${LOCAL_SCRIPT_SUGGESTED_PATH}\" khi bạn chạy lệnh cài đặt lần đầu.)"
    log_and_echo "       (Nếu việc tự lưu không thành công, bạn có thể lưu thủ công bằng lệnh ở đầu output của script.)"
    log_and_echo "---------------------------------------------------------------------"
    log_and_echo "Thông tin cấu hình này lưu tại: ${CONFIG_INFO_FILE_INSTANCE}"
    log_and_echo "Xem tất cả config đã lưu: ls -l ${CONFIG_FILES_STORAGE_DIR}"
    log_and_echo "Xem tất cả service mtproxy: systemctl list-units 'mtproxy-*.service'"
    log_and_echo "---------------------------------------------------------------------"
    echo "" 
    log_and_echo "🔗 LINK KẾT NỐI TELEGRAM CHO PROXY MỚI"
    log_and_echo "${TG_LINK}"
    log_and_echo "=================================================="
    echo ""
    log_and_echo "THÔNG TIN HỖ TRỢ & LIÊN HỆ:"
    log_and_echo "Telegram: @thevv"
    log_and_echo "Email: vuvanthe64@gmail.com"
    log_and_echo "---------------------------------------------------------------------"
    echo ""
}


# --- Xử lý Tham Số Đầu Vào ---
ACTION="$1"
ARG_PORT="$2"

# Kiểm tra quyền root cho toàn bộ script
if [ "$(id -u)" -ne 0 ]; then
  log_and_echo "LỖI: Script này cần được chạy với quyền root hoặc sudo."
  log_and_echo "Vui lòng chạy lại bằng cách pipe qua 'sudo bash': curl ... | sudo bash"
  exit 1
fi


if [ "$ACTION" == "remove" ]; then
    if [ -z "$ARG_PORT" ]; then
        log_and_echo "LỖI: Để xóa, vui lòng cung cấp số PORT của instance MTProxy."
        log_and_echo "Cách dùng: sudo bash $0 remove <PORT_NUMBER>"
        log_and_echo "Hoặc: curl ... | sudo bash -s remove <PORT_NUMBER>"
        exit 1
    fi
    if ! [[ "$ARG_PORT" =~ ^[0-9]+$ ]]; then # Kiểm tra port là số
        log_and_echo "LỖI: Số PORT '$ARG_PORT' không hợp lệ. Vui lòng nhập một số."
        exit 1
    fi
    remove_mtproxy_instance "${ARG_PORT}"
elif [ -z "$ACTION" ] || [ "$ACTION" == "install" ]; then
    install_new_mtproxy_instance
else
    log_and_echo "LỖI: Hành động không hợp lệ '$ACTION'."
    log_and_echo "Hành động được hỗ trợ: "
    log_and_echo "  (không có tham số) hoặc 'install' : để cài đặt instance MTProxy mới."
    log_and_echo "  'remove <PORT_NUMBER>'           : để xóa instance MTProxy trên port cụ thể."
    exit 1
fi

exit 0
