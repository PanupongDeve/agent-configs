#!/bin/bash

# URL ของโฟลเดอร์ที่ต้องการ
BASE_URL="https://api.github.com/repos/UKGovernmentBEIS/inspect_ai/contents/examples/skills/skills"
TARGET_ROOT="skills_downloaded"

download_recursive() {
    local api_url=$1
    local dest_path=$2

    echo "Checking: $dest_path"
    mkdir -p "$dest_path"

    # ดึงข้อมูล JSON ทั้งหมดมาเก็บไว้ในตัวแปรเดียว เพื่อป้องกันการอ่านไฟล์ข้ามลูป
    local response=$(curl -s "$api_url")

    # ตรวจสอบว่าได้ข้อมูลมาไหม
    if [[ $response == *"message"* ]] && [[ $response == *"rate limit"* ]]; then
        echo "Error: Hit GitHub API rate limit."
        return
    fi

    # ใช้ Python ช่วยดึงรายการชื่อไฟล์/โฟลเดอร์ออกมาเป็นลิสต์ที่ Bash อ่านง่ายๆ
    local items=$(echo "$response" | python3 -c "import sys, json; [print(f'{item[\"type\"]} {item[\"name\"]} {item[\"url\"]} {item.get(\"download_url\", \"None\")}') for item in json.load(sys.stdin)]")

    # วนลูปประมวลผลทีละรายการ
    while read -r type name url d_url; do
        if [ "$type" == "dir" ]; then
            # ถ้าเป็นโฟลเดอร์ ให้เรียกตัวเอง (Recursive)
            download_recursive "$url" "$dest_path/$name"
        elif [ "$type" == "file" ]; then
            echo "  --> Downloading: $dest_path/$name"
            curl -L -s -o "$dest_path/$name" "$d_url"
        fi
    done <<< "$items"
}

# เริ่มทำงาน
download_recursive "$BASE_URL" "$TARGET_ROOT"
echo "------------------------------------------"
echo "Done! ทุกไฟล์ถูกโหลดไปที่: $TARGET_ROOT"