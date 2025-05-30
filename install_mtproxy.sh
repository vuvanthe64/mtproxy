#!/bin/bash

# Script tự động cài đặt và khởi chạy MTProxy từ GitHub
# PHIÊN BẢN NÀY ĐƯỢC TỐI ƯU DỰA TRÊN PHẢN HỒI:
# - Sử dụng repository GetPageSpeed/MTProxy
# - Xử lý secret và chạy lệnh tương tự phiên bản cũ
# - Kiểm tra kỹ việc tải file proxy-multi.conf

# Hàm ghi log và hiển thị ra màn hình
log_and_echo() {
    echo "$1"
}

log_and_echo "=================================================="
log_and_echo "Bắt đầu quá trình cài đặt MTProxy (GetPageSpeed fork)..."
log_and_echo "Thời gian bắt đầu: $(date)"
log_and_echo "=================================================="
echo ""

# --- Bước 1: Cập nhật hệ thống và cài đặt các gói cần thiết ---
log_and_echo "[1/8] Đang cập nhật hệ thống và cài đặt các gói phụ thuộc..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -yqq > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_and_echo "LỖI: apt-get update thất bại."
    exit 1
fi
apt-get install -y -qq git curl build-essential libssl-dev zlib1g-dev make ufw > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_and_echo "LỖI: apt-get install thất bại."
    exit 1
fi
log_and_echo "Cài đặt gói phụ thuộc thành công."
echo ""

# --- Bước 2: Tải mã nguồn MTProxy (GetPageSpeed fork) ---
log_and_echo "[2/8] Đang tải mã nguồn MTProxy (GetPageSpeed fork)..."
REPO_URL="https://github.com/GetPageSpeed/MTProxy"
REPO_DIR="/opt/MTProxy_GetPageSpeed"
if [ -d "$REPO_DIR" ]; then
  rm -rf "$REPO_DIR"
fi
git clone "$REPO_URL" "$REPO_DIR" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log_and_echo "LỖI: git clone thất bại. Kiểm tra URL repo hoặc kết nối mạng."
    exit 1
fi
log_and_echo "Tải mã nguồn thành công vào $REPO_DIR."
echo ""

# --- Bước 3: Biên dịch MTProxy ---
log_and_echo "[3/8] Đang biên dịch MTProxy..."
cd "$REPO_DIR" || { log_and_echo "LỖI: Không thể cd vào $REPO_DIR"; exit 1; }
make > /dev/null 2>&1
if [ ! -f "objs/bin/mtproto-proxy" ]; then
    log_and_echo "LỖI: Biên dịch MTProxy thất bại."
    cd /
    exit 1
fi
log_and_echo "Biên dịch thành công."
echo ""

# --- Bước 4: Chuẩn bị file và thư mục thực thi ---
PROXY_EXEC_PATH="${REPO_DIR}/objs/bin/mtproto-proxy"
WORKING_DIR="${REPO_DIR}/objs/bin"
cd "$WORKING_DIR" || { log_and_echo "LỖI: Không thể cd vào $WORKING_DIR"; exit 1; }
log_and_echo "[4/8] Đang chuẩn bị trong thư mục: $(pwd)"
echo ""

# --- Bước 5: Tạo client secret và tải official proxy secret/config ---
log_and_echo "[5/8] Đang tạo client secret và tải official proxy secret/config..."
NEW_CLIENT_SECRET=$(head -c 16 /dev/urandom | xxd -p -c 16)

log_and_echo "Tải official-proxy-secret từ core.telegram.org..."
curl -sS --fail https://core.telegram.org/getProxySecret -o official-proxy-secret
if [ $? -ne 0 ] || [ ! -s official-proxy-secret ]; then
    log_and_echo "CẢNH BÁO QUAN TRỌNG: Không tải được official-proxy-secret."
    log_and_echo "Proxy có thể không hoạt động đúng nếu không có file này."
    # Không exit, nhưng cảnh báo rõ
fi

log_and_echo "Tải proxy-multi.conf từ core.telegram.org..."
curl -sS --fail https://core.telegram.org/getProxyConfig -o proxy-multi.conf
if [ $? -ne 0 ] || [ ! -s proxy-multi.conf ]; then # Check curl exit status AND if file is not empty
    log_and_echo "LỖI QUAN TRỌNG: Không tải được proxy-multi.conf từ Telegram."
    log_and_echo "Proxy sẽ không thể hoạt động nếu không có file này hoặc file này không đúng."
    log_and_echo "Vui lòng kiểm tra kết nối mạng của VPS và thử chạy lại script."
    log_and_echo "Bạn cũng có thể thử tải thủ công: curl -o ${WORKING_DIR}/proxy-multi.conf https://core.telegram.org/getProxyConfig"
    exit 1 # Thoát script vì đây là lỗi nghiêm trọng
fi
log_and_echo "Tạo client secret và tải file cấu hình thành công."
log_and_echo "Client Secret mới: $NEW_CLIENT_SECRET"
echo ""

# --- Bước 6: Tạo port ngẫu nhiên ---
log_and_echo "[6/8] Đang tạo port ngẫu nhiên..."
RANDOM_PORT=$(shuf -i 10000-65535 -n 1)
log_and_echo "Port ngẫu nhiên mới: $RANDOM_PORT"
echo ""

# --- Bước 7: Mở port trên Firewall (UFW) ---
log_and_echo "[7/8] Đang mở port $RANDOM_PORT trên Firewall (UFW)..."
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
log_and_echo "[8/8] Đang lấy địa chỉ IP public của máy chủ..."
SERVER_IP=$(curl -s --max-time 10 ifconfig.me/ip || curl -s --max-time 10 api.ipify.org || hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    log_and_echo "CẢNH BÁO: Không thể tự động lấy địa chỉ IP. Link có thể không chính xác."
    SERVER_IP="YOUR_SERVER_IP"
fi
log_and_echo "Địa chỉ IP của máy chủ: $SERVER_IP"
echo ""

# --- Chuẩn bị thông tin chạy và link ---
PROXY_RUN_COMMAND="${PROXY_EXEC_PATH} -u nobody -p 8888 -H ${RANDOM_PORT} -S ${NEW_CLIENT_SECRET} --aes-pwd official-proxy-secret proxy-multi.conf -M 1"
TG_LINK="tg://proxy?server=${SERVER_IP}&port=${RANDOM_PORT}&secret=${NEW_CLIENT_SECRET}"
LOG_PROXY_OUTPUT_FILE="${WORKING_DIR}/mtproxy_runtime.log"

log_and_echo "===================================================================="
log_and_echo "CÀI ĐẶT HOÀN TẤT! ĐANG CHUẨN BỊ KHỞI CHẠY..."
log_and_echo "===================================================================="
log_and_echo "--------------------------------------------------------------------"
log_and_echo "Lệnh chạy proxy (sẽ tự động chạy ở nền):"
log_and_echo "   nohup ${PROXY_RUN_COMMAND} > ${LOG_PROXY_OUTPUT_FILE} 2>&1 &"
log_and_echo "   (Log của proxy sẽ được lưu tại: ${LOG_PROXY_OUTPUT_FILE})"
log_and_echo "--------------------------------------------------------------------"
echo ""

# --- BƯỚC CUỐI: TỰ ĐỘNG KHỞI CHẠY PROXY ---
log_and_echo "Đang khởi chạy proxy ở chế độ nền..."
cd "$WORKING_DIR" || exit
# Xóa log cũ trước khi chạy mới
if [ -f "${LOG_PROXY_OUTPUT_FILE}" ]; then
    rm -f "${LOG_PROXY_OUTPUT_FILE}"
fi
nohup ${PROXY_RUN_COMMAND} > ${LOG_PROXY_OUTPUT_FILE} 2>&1 &

# Chờ và kiểm tra nhiều lần
PROXY_RUNNING=false
ATTEMPTS=0
MAX_ATTEMPTS=5
SLEEP_INTERVAL=4

log_and_echo "Đang kiểm tra trạng thái proxy (trong vòng $((MAX_ATTEMPTS * SLEEP_INTERVAL)) giây)..."
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    sleep $SLEEP_INTERVAL
    if ss -tlpn | grep -q ":${RANDOM_PORT}"; then
        PROXY_RUNNING=true
        break
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; then
      log_and_echo "Kiểm tra lần $((ATTEMPTS +1 ))... (đã chờ $(($ATTEMPTS * $SLEEP_INTERVAL)) giây)"
    fi
done

if ${PROXY_RUNNING}; then
    log_and_echo "✅ THÀNH CÔNG: Proxy MTProto dường như đã được khởi chạy và đang lắng nghe trên port ${RANDOM_PORT}."
else
    log_and_echo "⚠️ CẢNH BÁO: Script không thể tự động xác nhận proxy đang chạy trên port ${RANDOM_PORT}."
    log_and_echo "Tuy nhiên, proxy CÓ THỂ VẪN ĐANG HOẠT ĐỘNG BÌNH THƯỜNG NẾU KHÔNG CÓ LỖI NGHIÊM TRỌNG TRONG LOG."
    log_and_echo "HÃY THỬ KẾT NỐI BẰNG LINK TELEGRAM ĐƯỢC CUNG CẤP (sẽ hiển thị ở cuối)."
    log_and_echo "KIỂM TRA KỸ file log để biết chi tiết:"
    log_and_echo "   cat ${LOG_PROXY_OUTPUT_FILE}"
fi

echo ""
log_and_echo "=================================================="
log_and_echo "Script đã hoàn tất: $(date)"
log_and_echo "=================================================="
echo ""
echo ""
log_and_echo "*********************************************************************"
log_and_echo "* LINK KẾT NỐI TELEGRAM CỦA BẠN:                                   *"
log_and_echo "* ===>   ${TG_LINK}   <===                                          *"
log_and_echo "*********************************************************************"
echo ""
log_and_echo "---------------------------------------------------------------------"
log_and_echo "THÔNG TIN HỖ TRỢ & LIÊN HỆ:"
log_and_echo "Telegram: @thevv"
log_and_echo "Email: vuvanthe64@gmail.com"
log_and_echo "---------------------------------------------------------------------"
echo ""

exit 0
