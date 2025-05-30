# #!/bin/bash

# # Hàm ghi log và hiển thị ra màn hình
# log_and_echo() {
#     echo "$1"
# }

# log_and_echo "=================================================="
# log_and_echo "Bắt đầu quá trình cài đặt MTProxy (GetPageSpeed fork)..."
# log_and_echo "Thời gian bắt đầu: $(date)"
# log_and_echo "=================================================="
# echo ""

# # --- Bước 1: Cập nhật hệ thống và cài đặt các gói cần thiết ---
# log_and_echo "[1/8] Đang cập nhật hệ thống và cài đặt các gói phụ thuộc..."
# export DEBIAN_FRONTEND=noninteractive
# apt-get update -yqq > /dev/null 2>&1
# if [ $? -ne 0 ]; then
#     log_and_echo "LỖI: apt-get update thất bại."
#     exit 1
# fi
# apt-get install -y -qq git curl build-essential libssl-dev zlib1g-dev make ufw > /dev/null 2>&1
# if [ $? -ne 0 ]; then
#     log_and_echo "LỖI: apt-get install thất bại."
#     exit 1
# fi
# log_and_echo "Cài đặt gói phụ thuộc thành công."
# echo ""

# # --- Bước 2: Tải mã nguồn MTProxy (GetPageSpeed fork) ---
# log_and_echo "[2/8] Đang tải mã nguồn MTProxy (GetPageSpeed fork)..."
# REPO_URL="https://github.com/GetPageSpeed/MTProxy"
# REPO_DIR="/opt/MTProxy_GetPageSpeed"
# if [ -d "$REPO_DIR" ]; then
#   rm -rf "$REPO_DIR"
# fi
# git clone "$REPO_URL" "$REPO_DIR" > /dev/null 2>&1
# if [ $? -ne 0 ]; then
#     log_and_echo "LỖI: git clone thất bại. Kiểm tra URL repo hoặc kết nối mạng."
#     exit 1
# fi
# log_and_echo "Tải mã nguồn thành công vào $REPO_DIR."
# echo ""

# # --- Bước 3: Biên dịch MTProxy ---
# log_and_echo "[3/8] Đang biên dịch MTProxy..."
# cd "$REPO_DIR" || { log_and_echo "LỖI: Không thể cd vào $REPO_DIR"; exit 1; }
# make > /dev/null 2>&1
# if [ ! -f "objs/bin/mtproto-proxy" ]; then
#     log_and_echo "LỖI: Biên dịch MTProxy thất bại."
#     cd /
#     exit 1
# fi
# log_and_echo "Biên dịch thành công."
# echo ""

# # --- Bước 4: Chuẩn bị file và thư mục thực thi ---
# PROXY_EXEC_PATH="${REPO_DIR}/objs/bin/mtproto-proxy"
# WORKING_DIR="${REPO_DIR}/objs/bin"
# cd "$WORKING_DIR" || { log_and_echo "LỖI: Không thể cd vào $WORKING_DIR"; exit 1; }
# log_and_echo "[4/8] Đang chuẩn bị trong thư mục: $(pwd)"
# echo ""

# # --- Bước 5: Tạo client secret và tải official proxy secret/config ---
# log_and_echo "[5/8] Đang tạo client secret và tải official proxy secret/config..."
# NEW_CLIENT_SECRET=$(head -c 16 /dev/urandom | xxd -p -c 16)

# log_and_echo "Tải official-proxy-secret từ core.telegram.org..."
# curl -sS --fail https://core.telegram.org/getProxySecret -o official-proxy-secret
# if [ $? -ne 0 ] || [ ! -s official-proxy-secret ]; then
#     log_and_echo "CẢNH BÁO QUAN TRỌNG: Không tải được official-proxy-secret."
#     log_and_echo "Proxy có thể không hoạt động đúng nếu không có file này."
#     # Không exit, nhưng cảnh báo rõ
# fi

# log_and_echo "Tải proxy-multi.conf từ core.telegram.org..."
# curl -sS --fail https://core.telegram.org/getProxyConfig -o proxy-multi.conf
# if [ $? -ne 0 ] || [ ! -s proxy-multi.conf ]; then # Check curl exit status AND if file is not empty
#     log_and_echo "LỖI QUAN TRỌNG: Không tải được proxy-multi.conf từ Telegram."
#     log_and_echo "Proxy sẽ không thể hoạt động nếu không có file này hoặc file này không đúng."
#     log_and_echo "Vui lòng kiểm tra kết nối mạng của VPS và thử chạy lại script."
#     log_and_echo "Bạn cũng có thể thử tải thủ công: curl -o ${WORKING_DIR}/proxy-multi.conf https://core.telegram.org/getProxyConfig"
#     exit 1 # Thoát script vì đây là lỗi nghiêm trọng
# fi
# log_and_echo "Tạo client secret và tải file cấu hình thành công."
# log_and_echo "Client Secret mới: $NEW_CLIENT_SECRET"
# echo ""

# # --- Bước 6: Tạo port ngẫu nhiên ---
# log_and_echo "[6/8] Đang tạo port ngẫu nhiên..."
# RANDOM_PORT=$(shuf -i 10000-65535 -n 1)
# log_and_echo "Port ngẫu nhiên mới: $RANDOM_PORT"
# echo ""

# # --- Bước 7: Mở port trên Firewall (UFW) ---
# log_and_echo "[7/8] Đang mở port $RANDOM_PORT trên Firewall (UFW)..."
# if ! command -v ufw > /dev/null; then
#     log_and_echo "Cảnh báo: ufw chưa được cài đặt."
# else
#     if ! ufw status | grep -qw active; then
#         log_and_echo "UFW chưa active. Đang kích hoạt và cho phép SSH..."
#         ufw allow ssh > /dev/null 2>&1
#         ufw --force enable > /dev/null 2>&1
#     fi
#     ufw allow ${RANDOM_PORT}/tcp > /dev/null 2>&1
#     ufw reload > /dev/null 2>&1
#     log_and_echo "Đã thêm rule cho port $RANDOM_PORT/tcp và reload UFW."
# fi
# echo ""

# # --- Bước 8: Lấy địa chỉ IP public của máy chủ ---
# log_and_echo "[8/8] Đang lấy địa chỉ IP public của máy chủ..."
# SERVER_IP=$(curl -s --max-time 10 ifconfig.me/ip || curl -s --max-time 10 api.ipify.org || hostname -I | awk '{print $1}')
# if [ -z "$SERVER_IP" ]; then
#     log_and_echo "CẢNH BÁO: Không thể tự động lấy địa chỉ IP. Link có thể không chính xác."
#     SERVER_IP="YOUR_SERVER_IP"
# fi
# log_and_echo "Địa chỉ IP của máy chủ: $SERVER_IP"
# echo ""

# # --- Chuẩn bị thông tin chạy và link ---
# PROXY_RUN_COMMAND="${PROXY_EXEC_PATH} -u nobody -p 8888 -H ${RANDOM_PORT} -S ${NEW_CLIENT_SECRET} --aes-pwd official-proxy-secret proxy-multi.conf -M 1"
# TG_LINK="tg://proxy?server=${SERVER_IP}&port=${RANDOM_PORT}&secret=${NEW_CLIENT_SECRET}"
# LOG_PROXY_OUTPUT_FILE="${WORKING_DIR}/mtproxy_runtime.log"

# log_and_echo "===================================================================="
# log_and_echo "CÀI ĐẶT HOÀN TẤT! ĐANG CHUẨN BỊ KHỞI CHẠY..."
# log_and_echo "===================================================================="
# log_and_echo "--------------------------------------------------------------------"
# log_and_echo "Lệnh chạy proxy (sẽ tự động chạy ở nền):"
# log_and_echo "   nohup ${PROXY_RUN_COMMAND} > ${LOG_PROXY_OUTPUT_FILE} 2>&1 &"
# log_and_echo "   (Log của proxy sẽ được lưu tại: ${LOG_PROXY_OUTPUT_FILE})"
# log_and_echo "--------------------------------------------------------------------"
# echo ""

# # --- BƯỚC CUỐI: TỰ ĐỘNG KHỞI CHẠY PROXY ---
# log_and_echo "Đang khởi chạy proxy ở chế độ nền..."
# cd "$WORKING_DIR" || exit
# # Xóa log cũ trước khi chạy mới
# if [ -f "${LOG_PROXY_OUTPUT_FILE}" ]; then
#     rm -f "${LOG_PROXY_OUTPUT_FILE}"
# fi
# nohup ${PROXY_RUN_COMMAND} > ${LOG_PROXY_OUTPUT_FILE} 2>&1 &

# # Chờ và kiểm tra nhiều lần
# PROXY_RUNNING=false
# ATTEMPTS=0
# MAX_ATTEMPTS=5
# SLEEP_INTERVAL=4

# log_and_echo "Đang kiểm tra trạng thái proxy (trong vòng $((MAX_ATTEMPTS * SLEEP_INTERVAL)) giây)..."
# while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
#     sleep $SLEEP_INTERVAL
#     if ss -tlpn | grep -q ":${RANDOM_PORT}"; then
#         PROXY_RUNNING=true
#         break
#     fi
#     ATTEMPTS=$((ATTEMPTS + 1))
#     if [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; then
#       log_and_echo "Kiểm tra lần $((ATTEMPTS +1 ))... (đã chờ $(($ATTEMPTS * $SLEEP_INTERVAL)) giây)"
#     fi
# done

# if ${PROXY_RUNNING}; then
#     log_and_echo "✅ THÀNH CÔNG: Proxy MTProto dường như đã được khởi chạy và đang lắng nghe trên port ${RANDOM_PORT}."
# else
#     log_and_echo "⚠️ CẢNH BÁO: Script không thể tự động xác nhận proxy đang chạy trên port ${RANDOM_PORT}."
#     log_and_echo "Tuy nhiên, proxy CÓ THỂ VẪN ĐANG HOẠT ĐỘNG BÌNH THƯỜNG NẾU KHÔNG CÓ LỖI NGHIÊM TRỌNG TRONG LOG."
#     log_and_echo "HÃY THỬ KẾT NỐI BẰNG LINK TELEGRAM ĐƯỢC CUNG CẤP (sẽ hiển thị ở cuối)."
#     log_and_echo "KIỂM TRA KỸ file log để biết chi tiết:"
#     log_and_echo "   cat ${LOG_PROXY_OUTPUT_FILE}"
# fi

# echo ""
# log_and_echo "=================================================="
# log_and_echo "Script đã hoàn tất: $(date)"
# log_and_echo "=================================================="
# log_and_echo "🔗 LINK KẾT NỐI TELEGRAM"
# log_and_echo "${TG_LINK}"
# log_and_echo "=================================================="
# echo ""
# log_and_echo "---------------------------------------------------------------------"
# log_and_echo "THÔNG TIN HỖ TRỢ & LIÊN HỆ:"
# log_and_echo "Telegram: @thevv"
# log_and_echo "Email: vuvanthe64@gmail.com"
# echo ""

# exit 0



#!/bin/bash

# Script tự động cài đặt, cấu hình và quản lý MTProxy bằng systemd
# Repository: GetPageSpeed/MTProxy

# --- Biến toàn cục ---
SERVICE_NAME="mtproxy.service"
REPO_DIR="/opt/MTProxy_GetPageSpeed"
WORKING_DIR="${REPO_DIR}/objs/bin"
PROXY_EXEC_PATH="${WORKING_DIR}/mtproto-proxy"
CONFIG_INFO_FILE="${REPO_DIR}/mtproxy_config.info" # File lưu thông tin cấu hình

# --- Hàm tiện ích ---
log_and_echo() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# --- Bắt đầu Script ---
clear
log_and_echo "=================================================="
log_and_echo "Bắt đầu quá trình cài đặt MTProxy (GetPageSpeed fork) với systemd..."
log_and_echo "=================================================="
echo ""

# --- Bước 0: Kiểm tra dịch vụ MTProxy hiện có ---
log_and_echo "[0/10] Kiểm tra dịch vụ MTProxy (${SERVICE_NAME})..."
REINSTALL_NEEDED=true
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    log_and_echo "✅ Dịch vụ MTProxy (${SERVICE_NAME}) đang hoạt động."
    if [ -f "${CONFIG_INFO_FILE}" ]; then
        log_and_echo "--- Thông tin cấu hình hiện tại ---"
        cat "${CONFIG_INFO_FILE}"
        echo "-----------------------------------"
    else
        log_and_echo "Không tìm thấy file thông tin cấu hình (${CONFIG_INFO_FILE})."
        log_and_echo "Link kết nối đã được cung cấp khi dịch vụ được cài đặt lần đầu."
    fi
    log_and_echo "Để quản lý dịch vụ, sử dụng: sudo systemctl [status|stop|start|restart] ${SERVICE_NAME}"
    log_and_echo "Để xem log: sudo journalctl -u ${SERVICE_NAME} -f"
    REINSTALL_NEEDED=false
    read -p "Dịch vụ đã chạy. Bạn có muốn dừng và cài đặt lại hoàn toàn không? (y/N): " confirm_overwrite
    if [[ "$confirm_overwrite" == "y" || "$confirm_overwrite" == "Y" ]]; then
        log_and_echo "Đang dừng và vô hiệu hóa dịch vụ cũ..."
        sudo systemctl stop "${SERVICE_NAME}" > /dev/null 2>&1
        sudo systemctl disable "${SERVICE_NAME}" > /dev/null 2>&1
        REINSTALL_NEEDED=true
    else
        exit 0
    fi
elif systemctl list-unit-files --all | grep -q "^${SERVICE_NAME}"; then # Kiểm tra cả service inactive
    log_and_echo "⚠️ Dịch vụ MTProxy (${SERVICE_NAME}) đã được cài đặt nhưng KHÔNG chạy."
    read -p "Bạn có muốn tiếp tục cài đặt lại (sẽ ghi đè dịch vụ và cấu hình cũ)? (y/N): " confirm_reinstall
    if [[ "$confirm_reinstall" != "y" && "$confirm_reinstall" != "Y" ]]; then
        log_and_echo "Đã hủy cài đặt lại. Bạn có thể thử: sudo systemctl start ${SERVICE_NAME}"
        exit 0
    fi
    log_and_echo "Tiến hành cài đặt lại..."
    REINSTALL_NEEDED=true
else
    log_and_echo "Không tìm thấy dịch vụ MTProxy (${SERVICE_NAME}). Tiếp tục cài đặt mới..."
    REINSTALL_NEEDED=true
fi
echo ""

# --- Bước 1: Cập nhật hệ thống và cài đặt các gói cần thiết ---
if [ "$REINSTALL_NEEDED" = true ]; then
    log_and_echo "[1/10] Đang cập nhật hệ thống và cài đặt các gói phụ thuộc..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -yqq > /dev/null 2>&1 || { log_and_echo "LỖI: apt-get update thất bại."; exit 1; }
    apt-get install -y -qq git curl build-essential libssl-dev zlib1g-dev make ufw > /dev/null 2>&1 || { log_and_echo "LỖI: apt-get install thất bại."; exit 1; }
    log_and_echo "Cài đặt gói phụ thuộc thành công."
    echo ""

    # --- Bước 2: Tải mã nguồn MTProxy ---
    log_and_echo "[2/10] Đang tải mã nguồn MTProxy (GetPageSpeed fork)..."
    if [ -d "$REPO_DIR" ]; then
      log_and_echo "Tìm thấy thư mục cài đặt cũ $REPO_DIR. Đang xóa..."
      rm -rf "$REPO_DIR"
    fi
    mkdir -p "$REPO_DIR" # Tạo thư mục nếu chưa có
    git clone "https://github.com/GetPageSpeed/MTProxy" "$REPO_DIR" > /dev/null 2>&1 || { log_and_echo "LỖI: git clone thất bại."; exit 1; }
    log_and_echo "Tải mã nguồn thành công vào $REPO_DIR."
    echo ""

    # --- Bước 3: Biên dịch MTProxy ---
    log_and_echo "[3/10] Đang biên dịch MTProxy..."
    cd "$REPO_DIR" || { log_and_echo "LỖI: Không thể cd vào $REPO_DIR"; exit 1; }
    make > /dev/null 2>&1 || { log_and_echo "LỖI: make thất bại."; exit 1; }
    if [ ! -f "$PROXY_EXEC_PATH" ]; then
        log_and_echo "LỖI: Biên dịch MTProxy thất bại, không tìm thấy file thực thi."
        exit 1
    fi
    log_and_echo "Biên dịch thành công."
    echo ""

    # --- Bước 4: Chuẩn bị thư mục làm việc ---
    log_and_echo "[4/10] Đang chuẩn bị trong thư mục làm việc: $WORKING_DIR"
    cd "$WORKING_DIR" || { log_and_echo "LỖI: Không thể cd vào $WORKING_DIR"; exit 1; }
    echo ""

    # --- Bước 5: Tạo client secret và tải official proxy secret/config ---
    log_and_echo "[5/10] Đang tạo client secret và tải official proxy secret/config..."
    NEW_CLIENT_SECRET=$(head -c 16 /dev/urandom | xxd -p -c 16)

    log_and_echo "Tải official-proxy-secret (cho upstream connection)..."
    curl -sS --fail https://core.telegram.org/getProxySecret -o official-proxy-secret
    if [ $? -ne 0 ] || [ ! -s official-proxy-secret ]; then
        log_and_echo "CẢNH BÁO: Không tải được official-proxy-secret. Proxy có thể không hoạt động đúng."
    fi

    log_and_echo "Tải proxy-multi.conf..."
    curl -sS --fail https://core.telegram.org/getProxyConfig -o proxy-multi.conf
    if [ $? -ne 0 ] || [ ! -s proxy-multi.conf ]; then
        log_and_echo "LỖI QUAN TRỌNG: Không tải được proxy-multi.conf từ Telegram. Proxy sẽ không thể hoạt động."
        exit 1
    fi
    log_and_echo "Tạo client secret và tải file cấu hình thành công."
    log_and_echo "Client Secret mới (sẽ được sử dụng): $NEW_CLIENT_SECRET"
    echo ""

    # --- Bước 6: Tạo port ngẫu nhiên ---
    log_and_echo "[6/10] Đang tạo port ngẫu nhiên..."
    RANDOM_PORT=$(shuf -i 10000-65535 -n 1)
    log_and_echo "Port ngẫu nhiên mới (sẽ được sử dụng): $RANDOM_PORT"
    echo ""

    # --- Bước 7: Mở port trên Firewall (UFW) ---
    log_and_echo "[7/10] Đang mở port $RANDOM_PORT trên Firewall (UFW)..."
    if ! command -v ufw > /dev/null; then
        log_and_echo "Cảnh báo: ufw chưa được cài đặt (đã cố gắng cài ở Bước 1)."
    else
        if ! ufw status | grep -qw active; then
            log_and_echo "UFW chưa active. Đang kích hoạt và cho phép SSH..."
            ufw allow ssh > /dev/null 2>&1
            ufw --force enable > /dev/null 2>&1
        fi
        ufw allow ${RANDOM_PORT}/tcp > /dev/null 2>&1
        ufw reload > /dev/null 2>&1
        log_and_echo "Đã thêm rule cho port $RANDOM_PORT/tcp và reload UFW."
    fi
    echo ""

    # --- Bước 8: Lấy địa chỉ IP public của máy chủ ---
    log_and_echo "[8/10] Đang lấy địa chỉ IP public của máy chủ..."
    SERVER_IP=$(curl -s --max-time 10 ifconfig.me/ip || curl -s --max-time 10 api.ipify.org || hostname -I | awk '{print $1}')
    if [ -z "$SERVER_IP" ]; then
        log_and_echo "CẢNH BÁO: Không thể tự động lấy địa chỉ IP. Link sẽ cần IP đúng."
        SERVER_IP="YOUR_SERVER_IP" # Placeholder
    fi
    log_and_echo "Địa chỉ IP của máy chủ: $SERVER_IP"
    echo ""

    # --- Bước 9: Tạo và kích hoạt dịch vụ systemd ---
    log_and_echo "[9/10] Đang tạo và kích hoạt dịch vụ systemd (${SERVICE_NAME})..."
    # Cấu hình port thống kê, có thể để cố định hoặc ngẫu nhiên khác
    STATS_PORT=8888
    if [ "$STATS_PORT" = "$RANDOM_PORT" ]; then
        STATS_PORT=$((RANDOM_PORT + 1)) # Đảm bảo khác port public
        if [ $STATS_PORT -gt 65535 ]; then STATS_PORT=$((RANDOM_PORT -1)); fi # Xử lý nếu vượt quá
    fi

    PROXY_SYSTEMD_COMMAND="${PROXY_EXEC_PATH} -u nobody -p ${STATS_PORT} -H ${RANDOM_PORT} -S ${NEW_CLIENT_SECRET} --aes-pwd ${WORKING_DIR}/official-proxy-secret ${WORKING_DIR}/proxy-multi.conf -M 1"

    # Tạo nội dung file service
    SERVICE_FILE_CONTENT="[Unit]
Description=MTProxy (GetPageSpeed fork)
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
WorkingDirectory=${WORKING_DIR}
ExecStart=${PROXY_SYSTEMD_COMMAND}
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target"

    # Ghi file service
    echo "${SERVICE_FILE_CONTENT}" | sudo tee /etc/systemd/system/${SERVICE_NAME} > /dev/null
    if [ $? -ne 0 ]; then
        log_and_echo "LỖI: Không thể tạo file dịch vụ systemd."
        exit 1
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable "${SERVICE_NAME}"
    # Dừng service cũ nếu có (trường hợp reinstall mà service vẫn kẹt)
    sudo systemctl stop "${SERVICE_NAME}" > /dev/null 2>&1
    sudo systemctl start "${SERVICE_NAME}"

    log_and_echo "Dịch vụ ${SERVICE_NAME} đã được tạo và khởi động."
    echo ""

    # --- Lưu thông tin cấu hình ---
    log_and_echo "Đang lưu thông tin cấu hình vào ${CONFIG_INFO_FILE}..."
    TG_LINK="tg://proxy?server=${SERVER_IP}&port=${RANDOM_PORT}&secret=${NEW_CLIENT_SECRET}"
    {
        echo "SERVICE_NAME=${SERVICE_NAME}"
        echo "SERVER_IP=${SERVER_IP}"
        echo "PORT=${RANDOM_PORT}"
        echo "SECRET=${NEW_CLIENT_SECRET}"
        echo "TG_LINK=${TG_LINK}"
        echo "STATS_PORT=${STATS_PORT}"
        echo "CONFIG_FILE_PATH=${WORKING_DIR}/proxy-multi.conf"
        echo "SECRET_FILE_PATH=${WORKING_DIR}/official-proxy-secret"
        echo "LOG_COMMAND=sudo journalctl -u ${SERVICE_NAME} -f -n 50"
        echo "STATUS_COMMAND=sudo systemctl status ${SERVICE_NAME}"
        echo "STOP_COMMAND=sudo systemctl stop ${SERVICE_NAME}"
        echo "START_COMMAND=sudo systemctl start ${SERVICE_NAME}"
    } > "${CONFIG_INFO_FILE}"
    log_and_echo "Thông tin cấu hình đã được lưu."
    echo ""

else
    log_and_echo "Không thực hiện cài đặt lại. Dịch vụ đã tồn tại."
fi # Kết thúc khối if [ "$REINSTALL_NEEDED" = true ];

# --- Bước 10 (Cuối): Kiểm tra trạng thái và hiển thị thông tin ---
log_and_echo "[10/10] Kiểm tra trạng thái cuối cùng và hiển thị thông tin..."

# Lấy lại thông tin từ file config nếu không phải là lần cài đặt mới
if [ "$REINSTALL_NEEDED" = false ] && [ -f "${CONFIG_INFO_FILE}" ]; then
    # Source the file to get variables
    . "${CONFIG_INFO_FILE}"
elif [ "$REINSTALL_NEEDED" = true ]; then
    # Variables SERVER_IP, RANDOM_PORT, NEW_CLIENT_SECRET, TG_LINK, SERVICE_NAME already set
    # TG_LINK được định nghĩa lại ở đây để đảm bảo nó có giá trị nếu không qua bước cài đặt mới
    # nhưng vẫn cần thông tin từ các biến đã tạo.
    TG_LINK="tg://proxy?server=${SERVER_IP}&port=${RANDOM_PORT}&secret=${NEW_CLIENT_SECRET}"
else
    log_and_echo "Không thể xác định cấu hình proxy để hiển thị link."
    # Cố gắng tạo một link rỗng để tránh lỗi biến không xác định
    TG_LINK="tg://proxy?server=ERROR&port=0&secret=ERROR_CHECK_CONFIG_FILE"
fi


# Kiểm tra trạng thái dịch vụ
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    log_and_echo "✅ THÀNH CÔNG: Dịch vụ MTProxy (${SERVICE_NAME}) đang hoạt động."
    # Lấy port từ biến RANDOM_PORT nếu vừa cài, hoặc từ file config nếu không cài lại
    CURRENT_PORT=${RANDOM_PORT:-$(grep "^PORT=" "${CONFIG_INFO_FILE}" 2>/dev/null | cut -d= -f2)}
    log_and_echo "Lắng nghe trên port ${CURRENT_PORT:-Không xác định}."
else
    log_and_echo "⚠️ CẢNH BÁO: Dịch vụ MTProxy (${SERVICE_NAME}) KHÔNG hoạt động sau khi cố gắng khởi động."
    log_and_echo "Vui lòng kiểm tra log bằng lệnh: sudo journalctl -u ${SERVICE_NAME} -e"
    log_and_echo "Và kiểm tra lại file cấu hình MTProxy tại ${WORKING_DIR}"
fi

echo ""
log_and_echo "=================================================="
log_and_echo "Script đã hoàn tất: $(date)"
log_and_echo "=================================================="
echo ""
log_and_echo "🔗 LINK KẾT NỐI TELEGRAM"
log_and_echo "${TG_LINK:-Không thể tạo link, vui lòng kiểm tra ${CONFIG_INFO_FILE}}"
log_and_echo "=================================================="
echo ""
log_and_echo "---------------------------------------------------------------------"
log_and_echo "Quản lý dịch vụ:"
log_and_echo "  - Kiểm tra trạng thái: sudo systemctl status ${SERVICE_NAME}"
log_and_echo "  - Dừng dịch vụ:       sudo systemctl stop ${SERVICE_NAME}"
log_and_echo "  - Khởi động dịch vụ:  sudo systemctl start ${SERVICE_NAME}"
log_and_echo "  - Xem log trực tiếp:   sudo journalctl -u ${SERVICE_NAME} -f -n 100"
log_and_echo "  - Xem tất cả log:      sudo journalctl -u ${SERVICE_NAME}"
log_and_echo "---------------------------------------------------------------------"
log_and_echo "Thông tin cấu hình đã được lưu tại: ${CONFIG_INFO_FILE}"
log_and_echo "---------------------------------------------------------------------"
log_and_echo "THÔNG TIN HỖ TRỢ & LIÊN HỆ:"
log_and_echo "Telegram: @thevv"
log_and_echo "Email: vuvanthe64@gmail.com"
log_and_echo "---------------------------------------------------------------------"
echo ""

exit 0

