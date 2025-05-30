#!/bin/bash

# Script tự động cài đặt và khởi chạy MTProxy từ GitHub
# Script này sẽ chạy với quyền root (do được pipe qua sudo bash).

# Hàm ghi log và hiển thị ra màn hình
log_and_echo() {
    echo "$1"
    # Nếu bạn muốn ghi thêm vào file log trên VPS, có thể thêm vào đây
    # echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /root/mtproxy_installer.log
}

log_and_echo "=================================================="
log_and_echo "Bắt đầu quá trình cài đặt và khởi chạy MTProxy từ GitHub..."
log_and_echo "Thời gian bắt đầu: $(date)"
log_and_echo "=================================================="
echo ""

# --- Bước 1: Cập nhật hệ thống và cài đặt các gói cần thiết ---
log_and_echo "[1/8] Đang cập nhật hệ thống và cài đặt các gói phụ thuộc..."
export DEBIAN_FRONTEND=noninteractive # Tránh các câu hỏi tương tác từ apt
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

# --- Bước 2: Tải mã nguồn MTProxy ---
log_and_echo "[2/8] Đang tải mã nguồn MTProxy..."
REPO_URL="https://github.com/TelegramMessenger/MTProxy" # Sử dụng repo chính thức của Telegram
REPO_DIR="/opt/MTProxy_Official" # Cài vào /opt cho chuẩn hơn
# Xóa thư mục cũ nếu có để đảm bảo cài đặt sạch
if [ -d "$REPO_DIR" ]; then
  rm -rf "$REPO_DIR"
fi
git clone --recursive "$REPO_URL" "$REPO_DIR" > /dev/null 2>&1 # --recursive để lấy submodule crypto
if [ $? -ne 0 ]; then
    log_and_echo "LỖI: git clone thất bại. Kiểm tra URL repo hoặc kết nối mạng."
    exit 1
fi
log_and_echo "Tải mã nguồn thành công vào $REPO_DIR."
echo ""

# --- Bước 3: Biên dịch MTProxy ---
log_and_echo "[3/8] Đang biên dịch MTProxy..."
cd "$REPO_DIR" || { log_and_echo "LỖI: Không thể cd vào $REPO_DIR"; exit 1; }
# make clean > /dev/null 2>&1 # Không cần clean khi clone mới
make > /dev/null 2>&1
if [ ! -f "objs/bin/mtproto-proxy" ]; then
    log_and_echo "LỖI: Biên dịch MTProxy thất bại. Kiểm tra output của 'make' nếu chạy thủ công."
    cd / # Quay lại thư mục gốc
    exit 1
fi
log_and_echo "Biên dịch thành công."
echo ""

# --- Bước 4: Chuẩn bị file và thư mục thực thi ---
# Không cần di chuyển, sẽ chạy trực tiếp từ objs/bin
PROXY_EXEC_PATH="${REPO_DIR}/objs/bin/mtproto-proxy"
WORKING_DIR="${REPO_DIR}/objs/bin" # Nơi chứa secret và config
cd "$WORKING_DIR" || { log_and_echo "LỖI: Không thể cd vào $WORKING_DIR"; exit 1; }
log_and_echo "[4/8] Đang chuẩn bị trong thư mục: $(pwd)"
echo ""

# --- Bước 5: Tải proxy secret và config (nếu cần) hoặc tạo mới ---
log_and_echo "[5/8] Đang tạo proxy secret và tải/tạo config..."
# Tạo secret ngẫu nhiên
NEW_SECRET=$(head -c 16 /dev/urandom | xxd -p -c 16)
echo "${NEW_SECRET}" > proxy-secret # Lưu secret vào file để proxy đọc

# Tải config từ Telegram (hoặc có thể dùng config mặc định nếu muốn)
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
if [ ! -s proxy-multi.conf ]; then # Kiểm tra file có nội dung không
    log_and_echo "Cảnh báo: Không tải được proxy-multi.conf từ Telegram. Sẽ sử dụng config cơ bản."
    # Tạo một file config tối thiểu nếu tải thất bại
    echo "kcp = false;" > proxy-multi.conf
    echo "workers = 1;" >> proxy-multi.conf
    # Bạn có thể thêm các cài đặt khác nếu muốn
fi
log_and_echo "Tạo secret và tải/tạo file cấu hình thành công."
echo ""

# --- Bước 6: Tạo port ngẫu nhiên ---
log_and_echo "[6/8] Đang tạo port ngẫu nhiên..."
RANDOM_PORT=$(shuf -i 10000-65535 -n 1)
log_and_echo "Port ngẫu nhiên mới: $RANDOM_PORT"
echo ""

# --- Bước 7: Mở port trên Firewall (UFW) ---
log_and_echo "[7/8] Đang mở port $RANDOM_PORT trên Firewall (UFW)..."
if ! command -v ufw > /dev/null; then
    log_and_echo "Cảnh báo: ufw chưa được cài đặt (đã cố cài ở Bước 1)."
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
    SERVER_IP="YOUR_SERVER_IP" # Để người dùng tự thay thế
fi
log_and_echo "Địa chỉ IP của máy chủ: $SERVER_IP"
echo ""

# --- Hiển thị kết quả ---
# Chú ý: MTProxy của Telegram đọc secret từ file, không phải từ tham số -S như bản fork của GetPageSpeed
# Tham số --secret <hex_secret> hoặc --aes-pwd <secret_file> <config_file>
# Với repo chính thức, cách chạy hơi khác: ./mtproto-proxy <port> <secret_hex>
# Tuy nhiên, để dùng với proxy-multi.conf và các tính năng nâng cao, cần dùng cách khác.
# Repo chính thức của Telegram khuyến khích dùng:
# ./mtproto-proxy -u nobody -p <STAT_PORT> -H <PUBLIC_PORT> -S <SECRET_HEX_TRỰC_TIẾP> --aes-pwd proxy-secret proxy-multi.conf
# Hoặc đơn giản hơn nếu chỉ cần secret và port:
# ./mtproto-proxy -u nobody -H <PUBLIC_PORT> <SECRET_HEX_TRỰC_TIẾP>
# Ở đây ta sẽ dùng cách có proxy-multi.conf
# Lệnh chạy cho repo Telegram chính thức, đọc secret từ file `proxy-secret`
PROXY_RUN_COMMAND="${PROXY_EXEC_PATH} -u nobody -p $((RANDOM_PORT + 1)) -H ${RANDOM_PORT} --aes-pwd proxy-secret proxy-multi.conf -M 1"
# Port thống kê (-p) nên khác port public (-H)
TG_LINK_DD="tg://proxy?server=${SERVER_IP}&port=${RANDOM_PORT}&secret=dd${NEW_SECRET}" # dd secret cho client hỗ trợ
TG_LINK_NORMAL="tg://proxy?server=${SERVER_IP}&port=${RANDOM_PORT}&secret=${NEW_SECRET}"

LOG_PROXY_OUTPUT_FILE="${WORKING_DIR}/mtproxy_runtime.log"

log_and_echo "===================================================================="
log_and_echo "CÀI ĐẶT HOÀN TẤT! ĐANG CHUẨN BỊ KHỞI CHẠY..."
log_and_echo "===================================================================="
log_and_echo "LINK KẾT NỐI TELEGRAM CỦA BẠN (thử cả hai nếu một link không được):"
log_and_echo "   Link 1 (dd secret): ${TG_LINK_DD}"
log_and_echo "   Link 2 (normal secret): ${TG_LINK_NORMAL}"
log_and_echo "--------------------------------------------------------------------"
log_and_echo "Lệnh chạy proxy (sẽ tự động chạy ở nền):"
log_and_echo "   nohup ${PROXY_RUN_COMMAND} > ${LOG_PROXY_OUTPUT_FILE} 2>&1 &"
log_and_echo "   (Log của proxy sẽ được lưu tại: ${LOG_PROXY_OUTPUT_FILE})"
log_and_echo "--------------------------------------------------------------------"
echo ""

# --- BƯỚC CUỐI: TỰ ĐỘNG KHỞI CHẠY PROXY ---
log_and_echo "Đang khởi chạy proxy ở chế độ nền..."
cd "$WORKING_DIR" || exit # Đảm bảo đang ở đúng thư mục khi chạy nohup
nohup ${PROXY_RUN_COMMAND} > ${LOG_PROXY_OUTPUT_FILE} 2>&1 &

# Chờ và kiểm tra nhiều lần
PROXY_RUNNING=false
ATTEMPTS=0
MAX_ATTEMPTS=5
SLEEP_INTERVAL=4

log_and_echo "Đang kiểm tra trạng thái proxy (trong vòng $((MAX_ATTEMPTS * SLEEP_INTERVAL)) giây)..."
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    sleep $SLEEP_INTERVAL
    # Kiểm tra xem có tiến trình nào đang lắng nghe trên port không
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
    log_and_echo "Bạn có thể sử dụng link trên để kết nối."
else
    log_and_echo "⚠️ CẢNH BÁO: Script không thể tự động xác nhận proxy đang chạy trên port ${RANDOM_PORT}."
    log_and_echo "Tuy nhiên, proxy CÓ THỂ VẪN ĐANG HOẠT ĐỘNG BÌNH THƯỜNG."
    log_and_echo "HÃY THỬ KẾT NỐI BẰNG LINK TELEGRAM ĐƯỢC CUNG CẤP."
    log_and_echo "Nếu không kết nối được, vui lòng kiểm tra file log: cat ${LOG_PROXY_OUTPUT_FILE}"
fi

echo ""
log_and_echo "=================================================="
log_and_echo "Script đã hoàn tất: $(date)"
log_and_echo "=================================================="

exit 0
