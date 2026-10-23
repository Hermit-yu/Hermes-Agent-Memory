#!/bin/bash
# 中国天气网查询脚本 - 不依赖大模型
# 使用方法: ./weather-cn.sh 城市名

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CITY_CODE_FILE="$SCRIPT_DIR/weather_codes.txt"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印错误信息
error() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 查找城市代码
find_city_code() {
    local city="$1"
    local code

    # 查找精确匹配
    code=$(grep -i "^${city}," "$CITY_CODE_FILE" 2>/dev/null | cut -d',' -f2 | head -1)

    if [ -z "$code" ]; then
        # 尝试模糊匹配
        code=$(grep -i "${city}" "$CITY_CODE_FILE" 2>/dev/null | head -1 | cut -d',' -f2)
    fi

    echo "$code"
}

# 获取天气数据
fetch_weather() {
    local city_code="$1"
    local url="https://www.weather.com.cn/weather/${city_code}.shtml"

    # 获取HTML内容
    local html
    html=$(curl -s --max-time 10 "$url" 2>/dev/null)

    if [ -z "$html" ]; then
        error "无法获取天气数据，请检查网络连接"
    fi

    echo "$html"
}

# 解析天气信息
parse_weather() {
    local html="$1"

    # 保存到临时文件
    local tmpfile=$(mktemp)
    echo "$html" > "$tmpfile"

    # 提取温度 - 使用更灵活的模式
    local temp
    temp=$(cat "$tmpfile" | grep -oE '[0-9]+/-?[0-9]+℃' | head -1)

    # 提取天气 - 从标题和meta标签
    local weather
    weather=$(cat "$tmpfile" | grep -o '<title>[^<]*</title>' | sed 's/<title>//' | sed 's/天气预报.*//' | head -1)

    # 如果标题中没有，尝试从HTML内容中提取
    if [ -z "$weather" ] || [ "$weather" = "未知" ]; then
        weather=$(cat "$tmpfile" | grep -oE '(晴转多云|多云转晴|晴|多云|阴|小雨|大雨|雪|雷阵雨)' | head -1)
    fi

    # 尝试提取生活指数 - 通过更宽松的关键词/兜底规则
    local cold_index=""
    local sport_index=""
    local dress_index=""
    local wash_index=""
    local uv_index=""

    # 1) 官方关键词（页面结构变动时也尽量能命中）
    if echo "$html" | grep -Eq "(极易发感冒|极易发)"; then
        cold_index="极易发"
    elif echo "$html" | grep -Eq "(较易发感冒|较易发)"; then
        cold_index="较易发"
    elif echo "$html" | grep -Eq "(易发感冒|易发)"; then
        cold_index="易发"
    elif echo "$html" | grep -Eq "(少发感冒|不易发|较不易发)"; then
        cold_index="少发"
    fi

    if echo "$html" | grep -Eq "(不宜运动)"; then
        sport_index="不宜"
    elif echo "$html" | grep -Eq "(较不宜运动)"; then
        sport_index="较不宜"
    elif echo "$html" | grep -Eq "(适宜运动)"; then
        sport_index="适宜"
    elif echo "$html" | grep -Eq "(较适宜运动)"; then
        sport_index="较适宜"
    fi

    if echo "$html" | grep -Eq "(强紫外线|紫外线强)"; then
        uv_index="强"
    elif echo "$html" | grep -Eq "(中等紫外线|紫外线中等)"; then
        uv_index="中等"
    elif echo "$html" | grep -Eq "(弱紫外线|紫外线弱)"; then
        uv_index="弱"
    fi

    if echo "$html" | grep -Eq "(不宜洗车)"; then
        wash_index="不宜"
    elif echo "$html" | grep -Eq "(较适宜洗车)"; then
        wash_index="较适宜"
    elif echo "$html" | grep -Eq "(适宜洗车)"; then
        wash_index="适宜"
    fi

    # 2) 如果抓不到，按温度/天气做兜底（保证不断供）
    # 解析温度数值，用于穿衣/感冒的粗略兜底
    local hi="" lo=""
    if echo "$temp" | grep -Eq '^[0-9]+/-?[0-9]+℃$'; then
        hi=$(echo "$temp" | cut -d'/' -f1)
        lo=$(echo "$temp" | cut -d'/' -f2 | tr -d '℃')
    fi

    # 穿衣兜底：只要没抓到就按最低温估
    if [ -z "$dress_index" ]; then
        if [ -n "$lo" ] && [ "$lo" -le 8 ]; then
            dress_index="寒冷"
        elif [ -n "$lo" ] && [ "$lo" -le 15 ]; then
            dress_index="较冷"
        elif [ -n "$lo" ] && [ "$lo" -le 22 ]; then
            dress_index="舒适"
        else
            dress_index="偏热"
        fi
    fi

    # 感冒兜底：低温/昼夜温差大 -> 更容易
    if [ -z "$cold_index" ]; then
        if [ -n "$hi" ] && [ -n "$lo" ] && [ $((hi-lo)) -ge 10 ]; then
            cold_index="较易发"
        elif [ -n "$lo" ] && [ "$lo" -le 12 ]; then
            cold_index="较易发"
        else
            cold_index="较适宜"
        fi
    fi

    # 运动兜底：有雨/雷则不宜，否则较适宜
    if [ -z "$sport_index" ]; then
        if echo "$WEATHER" | grep -Eq '(雨|雷|雪)'; then
            sport_index="较不宜"
        else
            sport_index="较适宜"
        fi
    fi

    # 洗车兜底：有雨/雪 -> 不宜
    if [ -z "$wash_index" ]; then
        if echo "$WEATHER" | grep -Eq '(雨|雪)'; then
            wash_index="不宜"
        else
            wash_index="适宜"
        fi
    fi

    # 紫外线兜底：晴/多云偏强，阴雨偏弱
    if [ -z "$uv_index" ]; then
        if echo "$WEATHER" | grep -Eq '(雨|雪|阴)'; then
            uv_index="弱"
        else
            uv_index="中等"
        fi
    fi

    # 清理临时文件
    rm -f "$tmpfile"

    # 输出结果
    echo "WEATHER=${weather:-未知}"
    echo "TEMP=${temp:-未知}"
    echo "COLD_INDEX=${cold_index}"
    echo "SPORT_INDEX=${sport_index}"
    echo "DRESS_INDEX=${dress_index}"
    echo "WASH_INDEX=${wash_index}"
    echo "UV_INDEX=${uv_index}"
}

# 格式化输出
format_output() {
    local city="$1"
    shift
    local data="$@"

    # 解析数据
    eval "$data"

    # 天气图标映射
    local weather_icon="🌤️"
    local weather="${WEATHER:-未知}"

    # 清理weather内容
    weather=$(echo "$weather" | tr -d '[:space:]')

    case "$weather" in
        *晴*阴*) weather_icon="🌤️" ;;
        *晴*多云*) weather_icon="🌤️" ;;
        *多云*晴*) weather_icon="🌤️" ;;
        *多云*阴*) weather_icon="☁️" ;;
        *晴*) weather_icon="☀️" ;;
        *多云*) weather_icon="⛅" ;;
        *阴*) weather_icon="☁️" ;;
        *雨*) weather_icon="🌧️" ;;
        *雪*) weather_icon="❄️" ;;
    esac

    # 输出
    echo ""
    echo -e "${GREEN}═════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  ${city}天气${NC}"
    echo -e "${GREEN}═════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}📍 今日天气（$(date +%Y-%m-%d)）${NC}"
    echo "  ${weather_icon} ${WEATHER:-未知}  |  ${BLUE}温度：${TEMP:-未知}${NC}"
    echo ""
    echo -e "${YELLOW}📊 生活指数${NC}"
    echo "  🤧 感冒：${COLD_INDEX}"
    echo "  🏃 运动：${SPORT_INDEX}"
    echo "  👔 穿衣：${DRESS_INDEX}"
    echo "  🚗 洗车：${WASH_INDEX}"
    echo "  ☀️ 紫外线：${UV_INDEX}"
    echo ""
    echo -e "${GREEN}═════════════════════════════════════════════════${NC}"
    echo ""
}

# 主函数
main() {
    local city="$1"

    # 检查参数
    if [ -z "$city" ]; then
        error "请输入城市名称，例如：./weather-cn.sh 成都"
    fi

    # 检查城市代码文件
    if [ ! -f "$CITY_CODE_FILE" ]; then
        error "城市代码文件不存在：$CITY_CODE_FILE"
    fi

    # 查找城市代码
    local city_code
    city_code=$(find_city_code "$city")

    if [ -z "$city_code" ]; then
        error "未找到城市 '$city'，请检查城市名称或手动添加到城市代码文件"
    fi

    # 获取天气数据
    local html
    html=$(fetch_weather "$city_code")

    # 解析天气
    local weather_data
    weather_data=$(parse_weather "$html")

    # 格式化输出
    format_output "$city" "$weather_data"
}

# 执行主函数
main "$@"
