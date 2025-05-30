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

# Script tự động cài đặt, cấu hình và quản lý NHIỀU INSTANCE MTProxy bằng systemd
# Mỗi lần chạy sẽ cố gắng tạo một instance proxy mới trên một port ngẫu nhiên.
# Repository: GetPageSpeed/MTProxy

# --- Biến toàn cục ---
REPO_DIR="/opt/MTProxy_GetPageSpeed"
WORKING_DIR_BASE="${REPO_DIR}/objs/bin" # Thư mục chứa file thực thi và config chung
CONFIG_FILES_DIR="${REPO_DIR}/configs" # Thư mục lưu file thông tin của từng instance
LOG_FILES_DIR="${REPO_DIR}/logs"     # Thư mục lưu log (nếu không dùng journald hoàn toàn)

# --- Hàm tiện ích ---
log_and_echo() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# --- Bắt đầu Script ---
clear
log_and_echo "=================================================="
log_and_echo "Bắt đầu quá trình tạo INSTANCE MTProxy MỚI (GetPageSpeed fork) với systemd..."
log_and_echo "=================================================="
echo ""

# Tạo các thư mục cần thiết nếu chưa có
mkdir -p "${CONFIG_FILES_DIR}"
mkdir -p "${LOG_FILES_DIR}"
# WORKING_DIR_BASE sẽ được tạo bởi git clone

# --- Bước 1: Cập nhật hệ thống và cài đặt các gói cần thiết (chỉ chạy nếu cần) ---
PACKAGES_INSTALLED_MARKER="${REPO_DIR}/.packages_installed"
if [ ! -f "${PACKAGES_INSTALLED_MARKER}" ]; then
    log_and_echo "[1/9] Đang cập nhật hệ thống và cài đặt các gói phụ thuộc..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -yqq > /dev/null 2>&1 || { log_and_echo "LỖI: apt-get update thất bại."; exit 1; }
    apt-get install -y -qq git curl build-essential libssl-dev zlib1g-dev make ufw > /dev/null 2>&1 || { log_and_echo "LỖI: apt-get install thất bại."; exit 1; }
    log_and_echo "Cài đặt gói phụ thuộc thành công."
    touch "${PACKAGES_INSTALLED_MARKER}" # Đánh dấu đã cài đặt
    echo ""
else
    log_and_echo "[1/9] Các gói phụ thuộc cần thiết dường như đã được cài đặt trước đó. Bỏ qua bước này."
    echo ""
fi

# --- Bước 2: Tải mã nguồn MTProxy (chỉ chạy nếu cần) ---
PROXY_EXEC_PATH="${WORKING_DIR_BASE}/mtproto-proxy"
if [ ! -f "${PROXY_EXEC_PATH}" ]; then
    log_and_echo "[2/9] Mã nguồn MTProxy chưa được tải/biên dịch. Tiến hành..."
    if [ -d "$REPO_DIR" ]; then # Xóa thư mục repo cũ nếu có để đảm bảo sạch
      log_and_echo "Tìm thấy thư mục $REPO_DIR cũ. Đang xóa để tải lại..."
      rm -rf "$REPO_DIR"
    fi
    mkdir -p "$REPO_DIR"
    log_and_echo "Đang tải mã nguồn MTProxy (GetPageSpeed fork)..."
    git clone "https://github.com/GetPageSpeed/MTProxy" "$REPO_DIR" > /dev/null 2>&1 || { log_and_echo "LỖI: git clone thất bại."; exit 1; }
    log_and_echo "Tải mã nguồn thành công vào $REPO_DIR."
    echo ""

    # --- Bước 3: Biên dịch MTProxy ---
    log_and_echo "[3/9] Đang biên dịch MTProxy..."
    cd "$REPO_DIR" || { log_and_echo "LỖI: Không thể cd vào $REPO_DIR"; exit 1; }
    make > /dev/null 2>&1 || { log_and_echo "LỖI: make thất bại."; exit 1; }
    if [ ! -f "$PROXY_EXEC_PATH" ]; then
        log_and_echo "LỖI: Biên dịch MTProxy thất bại, không tìm thấy file thực thi."
        exit 1
    fi
    log_and_echo "Biên dịch thành công."
    echo ""
else
    log_and_echo "[2/9] & [3/9] Mã nguồn MTProxy đã được tải và biên dịch trước đó. Bỏ qua."
    echo ""
fi

# --- Bước 4: Chuẩn bị thư mục làm việc cho các file config chung ---
log_and_echo "[4/9] Đang chuẩn bị trong thư mục làm việc chung: $WORKING_DIR_BASE"
cd "$WORKING_DIR_BASE" || { log_and_echo "LỖI: Không thể cd vào $WORKING_DIR_BASE"; exit 1; }
# Tải official proxy secret/config nếu chưa có hoặc file rỗng
if [ ! -s "official-proxy-secret" ]; then
    log_and_echo "Tải official-proxy-secret (cho upstream connection)..."
    curl -sS --fail https://core.telegram.org/getProxySecret -o official-proxy-secret || log_and_echo "CẢNH BÁO: Không tải được official-proxy-secret."
fi
if [ ! -s "proxy-multi.conf" ]; then
    log_and_echo "Tải proxy-multi.conf..."
    curl -sS --fail https://core.telegram.org/getProxyConfig -o proxy-multi.conf || { log_and_echo "LỖI QUAN TRỌNG: Không tải được proxy-multi.conf. Không thể tiếp tục."; exit 1; }
fi
echo ""

# --- Bước 5: Tạo client secret mới ---
log_and_echo "[5/9] Đang tạo client secret mới..."
NEW_CLIENT_SECRET=$(head -c 16 /dev/urandom | xxd -p -c 16)
log_and_echo "Client Secret mới (sẽ được sử dụng): $NEW_CLIENT_SECRET"
echo ""

# --- Bước 6: Tạo port ngẫu nhiên và kiểm tra tính khả dụng ---
log_and_echo "[6/9] Đang tìm port ngẫu nhiên khả dụng..."
MAX_PORT_ATTEMPTS=10
CURRENT_ATTEMPT=0
RANDOM_PORT=""
SERVICE_NAME_INSTANCE=""

while [ $CURRENT_ATTEMPT -lt $MAX_PORT_ATTEMPTS ]; do
    RANDOM_PORT=$(shuf -i 10000-65535 -n 1)
    SERVICE_NAME_INSTANCE="mtproxy-${RANDOM_PORT}.service"
    log_and_echo "Thử nghiệm port: $RANDOM_PORT (Service: ${SERVICE_NAME_INSTANCE})"

    PORT_IN_USE=$(ss -tlpn | grep -q ":${RANDOM_PORT}" && echo "true" || echo "false")
    SERVICE_FILE_EXISTS=$(test -f "/etc/systemd/system/${SERVICE_NAME_INSTANCE}" && echo "true" || echo "false")

    if [ "$PORT_IN_USE" = "false" ] && [ "$SERVICE_FILE_EXISTS" = "false" ]; then
        log_and_echo "Port $RANDOM_PORT khả dụng và chưa có service tương ứng."
        break
    else
        if [ "$PORT_IN_USE" = "true" ]; then
            log_and_echo "Port $RANDOM_PORT đã được sử dụng."
        fi
        if [ "$SERVICE_FILE_EXISTS" = "true" ]; then
            log_and_echo "Service ${SERVICE_NAME_INSTANCE} đã tồn tại."
        fi
        RANDOM_PORT="" # Reset để vòng lặp tiếp tục
    fi
    CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
    sleep 1
done

if [ -z "$RANDOM_PORT" ]; then
    log_and_echo "LỖI: Không thể tìm thấy port ngẫu nhiên khả dụng sau $MAX_PORT_ATTEMPTS lần thử."
    exit 1
fi
log_and_echo "Port ngẫu nhiên được chọn: $RANDOM_PORT"
echo ""

# --- Bước 7: Mở port trên Firewall (UFW) ---
log_and_echo "[7/9] Đang mở port $RANDOM_PORT trên Firewall (UFW)..."
if ! command -v ufw > /dev/null; then
    log_and_echo "Cảnh báo: ufw chưa được cài đặt."
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
log_and_echo "[8/9] Đang lấy địa chỉ IP public của máy chủ..."
SERVER_IP=$(curl -s --max-time 10 ifconfig.me/ip || curl -s --max-time 10 api.ipify.org || hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    log_and_echo "CẢNH BÁO: Không thể tự động lấy địa chỉ IP. Link sẽ cần IP đúng."
    SERVER_IP="YOUR_SERVER_IP"
fi
log_and_echo "Địa chỉ IP của máy chủ: $SERVER_IP"
echo ""

# --- Bước 9: Tạo và kích hoạt dịch vụ systemd cho instance mới ---
log_and_echo "[9/9] Đang tạo và kích hoạt dịch vụ systemd (${SERVICE_NAME_INSTANCE})..."
STATS_PORT_INSTANCE=$((RANDOM_PORT + 1)) # Tạo port thống kê khác đi một chút
if [ $STATS_PORT_INSTANCE -gt 65535 ]; then STATS_PORT_INSTANCE=$((RANDOM_PORT - 1)); fi
if [ $STATS_PORT_INSTANCE -lt 1024 ]; then STATS_PORT_INSTANCE=8889; fi # Đảm bảo không phải port < 1024

PROXY_SYSTEMD_COMMAND="${PROXY_EXEC_PATH} -u nobody -p ${STATS_PORT_INSTANCE} -H ${RANDOM_PORT} -S ${NEW_CLIENT_SECRET} --aes-pwd ${WORKING_DIR_BASE}/official-proxy-secret ${WORKING_DIR_BASE}/proxy-multi.conf -M 1"

SERVICE_FILE_CONTENT="[Unit]
Description=MTProxy (GetPageSpeed fork) instance on port ${RANDOM_PORT}
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
WorkingDirectory=${WORKING_DIR_BASE}
ExecStart=${PROXY_SYSTEMD_COMMAND}
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target"

echo "${SERVICE_FILE_CONTENT}" | sudo tee /etc/systemd/system/${SERVICE_NAME_INSTANCE} > /dev/null
if [ $? -ne 0 ]; then log_and_echo "LỖI: Không thể tạo file dịch vụ systemd cho ${SERVICE_NAME_INSTANCE}."; exit 1; fi

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME_INSTANCE}"
sudo systemctl start "${SERVICE_NAME_INSTANCE}"

log_and_echo "Dịch vụ ${SERVICE_NAME_INSTANCE} đã được tạo và khởi động."
echo ""

# --- Lưu thông tin cấu hình cho instance này ---
CONFIG_INFO_FILE_INSTANCE="${CONFIG_FILES_DIR}/mtproxy-${RANDOM_PORT}.info"
TG_LINK="tg://proxy?server=${SERVER_IP}&port=${RANDOM_PORT}&secret=${NEW_CLIENT_SECRET}"
log_and_echo "Đang lưu thông tin cấu hình vào ${CONFIG_INFO_FILE_INSTANCE}..."
{
    echo "SERVICE_NAME=${SERVICE_NAME_INSTANCE}"
    echo "SERVER_IP=${SERVER_IP}"
    echo "PORT=${RANDOM_PORT}"
    echo "SECRET=${NEW_CLIENT_SECRET}"
    echo "TG_LINK=${TG_LINK}"
    echo "STATS_PORT=${STATS_PORT_INSTANCE}"
} > "${CONFIG_INFO_FILE_INSTANCE}"
log_and_echo "Thông tin cấu hình đã được lưu."
echo ""


# --- Bước 10 (Cuối): Kiểm tra trạng thái và hiển thị thông tin ---
log_and_echo "[10/10] Kiểm tra trạng thái cuối cùng và hiển thị thông tin cho instance mới..."

if systemctl is-active --quiet "${SERVICE_NAME_INSTANCE}"; then
    log_and_echo "✅ THÀNH CÔNG: Dịch vụ MTProxy (${SERVICE_NAME_INSTANCE}) đang hoạt động."
    log_and_echo "Lắng nghe trên port ${RANDOM_PORT}."
else
    log_and_echo "⚠️ CẢNH BÁO: Dịch vụ MTProxy (${SERVICE_NAME_INSTANCE}) KHÔNG hoạt động sau khi cố gắng khởi động."
    log_and_echo "Vui lòng kiểm tra log bằng lệnh: sudo journalctl -u ${SERVICE_NAME_INSTANCE} -e"
fi

echo ""
log_and_echo "=================================================="
log_and_echo "Script đã hoàn tất việc tạo instance mới: $(date)"
log_and_echo "=================================================="
# Phần hiển thị link và thông tin liên hệ được di chuyển xuống dưới
echo ""
log_and_echo "---------------------------------------------------------------------"
log_and_echo "Quản lý dịch vụ VỪA TẠO (${SERVICE_NAME_INSTANCE}):"
log_and_echo "  - Kiểm tra trạng thái: sudo systemctl status ${SERVICE_NAME_INSTANCE}"
log_and_echo "  - Dừng dịch vụ:       sudo systemctl stop ${SERVICE_NAME_INSTANCE}"
log_and_echo "  - Khởi động dịch vụ:  sudo systemctl start ${SERVICE_NAME_INSTANCE}"
log_and_echo "  - Xem log trực tiếp:   sudo journalctl -u ${SERVICE_NAME_INSTANCE} -f -n 100"
log_and_echo "---------------------------------------------------------------------"
log_and_echo "Thông tin cấu hình chi tiết của instance này đã được lưu tại: ${CONFIG_INFO_FILE_INSTANCE}"
log_and_echo "Để xem danh sách các file cấu hình đã tạo: ls -l ${CONFIG_FILES_DIR}"
log_and_echo "Để xem danh sách các service mtproxy đang chạy: systemctl list-units 'mtproxy-*.service' --state=active"
log_and_echo "---------------------------------------------------------------------"
echo "" # Thêm dòng trống trước link
log_and_echo "🔗 LINK KẾT NỐI TELEGRAM CHO PROXY MỚI"
log_and_echo "${TG_LINK}"
log_and_echo "=================================================="
echo ""
log_and_echo "THÔNG TIN HỖ TRỢ & LIÊN HỆ:"
log_and_echo "Telegram: @thevv"
log_and_echo "Email: vuvanthe64@gmail.com"
log_and_echo "---------------------------------------------------------------------"
echo ""

exit 0
