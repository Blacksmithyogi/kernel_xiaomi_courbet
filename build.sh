#!/bin/bash

# --- KONFIGURASI TELEGRAM ---
TG_TOKEN="8647652050:AAG0ZKtMuE4NhlOKx8EHz4VHfgPLlguMTqw"
TG_CHAT_ID="7540957411"
# ----------------------------

SECONDS=0 
DEVICE="courbet"
export ARCH=arm64
export KBUILD_BUILD_USER=esteh
export KBUILD_BUILD_HOST=TUF-FA5093
export PATH="/mnt/d/pt/kernel/linux-x86/clang+llvm-14.0.0-x86_64-linux-gnu-ubuntu-18.04/bin/:$PATH"

ZIPNAME="${DEVICE}-$(date '+%Y%m%d-%H%M').zip"

# Fungsi untuk mengirim pesan pertama dan mendapatkan MESSAGE_ID
tg_send_sticky() {
    res=$(curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d text="$1" \
        -d parse_mode="Markdown")
    MESSAGE_ID=$(echo $res | grep -oP '(?<="message_id":)\d+')
}

# Fungsi untuk mengedit pesan yang sudah ada (update status)
tg_update() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/editMessageText" \
        -d chat_id="$TG_CHAT_ID" \
        -d message_id="$MESSAGE_ID" \
        -d text="$1" \
        -d parse_mode="Markdown" > /dev/null
}

# --- MULAI PROSES ---
echo "KUDA ASELI NAIL KUDA BESI"
tg_send_sticky "🛠 **Kernel Build Update**
📱 **Device**: \`$DEVICE\`
👤 **User**: \`$KBUILD_BUILD_USER\`
⏳ **Status**: nyapu lingkungan..."

# 1. Step: Cleaning
if [[ $1 = "-c" || $1 = "--clean" ]]; then
    tg_update "🛠 **Kernel Build Update**
⏳ **Status**: resik-resik folder out..."
    rm -rf out
fi

# 2. Step: Config
tg_update "🛠 **Kernel Build Update**
⏳ **Status**: delok \`${DEVICE}_defconfig\`..."
make O=out ARCH=arm64 ${DEVICE}_defconfig

# 3. Step: Compiling (Ini tahap terlama)
tg_update "🛠 **Kernel Build Update**
⏳ **Status**: Sedang Kompilasi (Mengebut dengan Ninja 2T Olsam Motul... ⚡"
make O=out ARCH=arm64 ${DEVICE}_defconfig
make -j$(nproc --all) \
    O=out \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    
kernel="out/arch/arm64/boot/Image.gz"
dtbo="out/arch/arm64/boot/dtbo.img"
dtb="out/arch/arm64/boot/dtb.img"

# Cek Gagal
if [ ! -f "$kernel" ]; then
    tg_update "❌ **Anjir Gagal cok**
Error opokih. Log e rametu jing"
    exit 1
fi

# 4. Step: Zipping
tg_update "🛠 **Kernel Build Update**
⏳ **Status**: Sek kompile sabar"
[ -d "AnyKernel3" ] && rm -rf AnyKernel3
git clone -q https://github.com/basamaryan/AnyKernel3 -b master AnyKernel3
sed -i "s/device\.name1=.*/device.name1=${DEVICE}/" AnyKernel3/anykernel.sh
sed -i "s/device\.name2=.*/device.name2=${DEVICE}in/" AnyKernel3/anykernel.sh
cp $kernel AnyKernel3/
[ -f "$dtbo" ] && cp $dtbo AnyKernel3/
[ -f "$dtb" ] && cp $dtb AnyKernel3/

cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x .git
cd ..
rm -rf AnyKernel3

# 5. Step: Final (Kirim File)
DURATION="$((SECONDS / 60)) menit $((SECONDS % 60)) detik"
tg_update "🛠 **Kernel Build Update**
✅ **Status**: Sampe gus $DURATION! Sek upload gus.."

curl -F document=@"$ZIPNAME" \
     -F chat_id="$TG_CHAT_ID" \
     -F caption="✅ **Allhamdullilah!**
📦 **File**: \`$ZIPNAME\`
⏱ **Durasi**: $DURATION
👤 **User**: $KBUILD_BUILD_USER" \
     -F parse_mode="Markdown" \
     "https://api.telegram.org/bot$TG_TOKEN/sendDocument"

echo -e "\nSelesai!"