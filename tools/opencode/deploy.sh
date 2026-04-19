#!/bin/bash

# OpenCode Agent Deployment Tool
# 交互式部署工具，支持软链接或复制模式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AGENTS_SOURCE_DIR="$REPO_ROOT/opencode/agents"

# 默认配置
DEFAULT_DEPLOY_DIR="."

# 打印带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${CYAN}================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}================================${NC}\n"
}

# 检查依赖
check_dependencies() {
    if ! command -v fzf &> /dev/null; then
        print_error "需要安装 fzf 工具"
        echo "安装方法:"
        echo "  - Ubuntu/Debian: sudo apt-get install fzf"
        echo "  - macOS: brew install fzf"
        echo "  - 或其他方式: https://github.com/junegunn/fzf#installation"
        exit 1
    fi
}

# 获取部署目录
get_deploy_dir() {
    print_header "Step 1: 选择部署目录"

    echo -e "请输入部署目录 (默认: ${YELLOW}${DEFAULT_DEPLOY_DIR}${NC}):"
    read -r deploy_dir

    if [ -z "$deploy_dir" ]; then
        deploy_dir="$DEFAULT_DEPLOY_DIR"
    fi

    # 转换为绝对路径
    if [[ "$deploy_dir" != /* ]]; then
        deploy_dir="$(pwd)/$deploy_dir"
    fi

    # 检查目录是否存在
    if [ ! -d "$deploy_dir" ]; then
        echo -e "目录不存在，是否创建? ${YELLOW}[Y/n]${NC}"
        read -r create_dir
        if [[ -z "$create_dir" || "$create_dir" =~ ^[Yy]$ ]]; then
            mkdir -p "$deploy_dir"
            print_success "创建目录: $deploy_dir"
        else
            print_error "部署取消"
            exit 1
        fi
    fi

    DEPLOY_DIR="$deploy_dir"
    AGENTS_DEPLOY_DIR="$DEPLOY_DIR/.opencode/agents"

    echo -e "部署目标: ${GREEN}$AGENTS_DEPLOY_DIR${NC}"
}

# 选择部署模式
select_deploy_mode() {
    print_header "Step 2: 选择部署模式"

    echo "请选择部署模式:"
    echo -e "  ${GREEN}1) 软链接 (symlink)${NC} - 推荐，源文件修改自动同步"
    echo -e "  ${YELLOW}2) 复制 (copy)${NC} - 独立副本，修改不影响源文件"
    echo ""
    echo -n "请输入选项 [1-2] (默认: 1): "
    read -r mode_choice

    case "$mode_choice" in
        2)
            DEPLOY_MODE="copy"
            print_info "选择模式: 复制"
            ;;
        *)
            DEPLOY_MODE="symlink"
            print_info "选择模式: 软链接"
            ;;
    esac
}

# 获取可用智能体列表
get_available_agents() {
    local agents=()
    while IFS= read -r -d '' file; do
        local name=$(basename "$file" .md)
        agents+=("$name")
    done < <(find "$AGENTS_SOURCE_DIR" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
    printf '%s\n' "${agents[@]}"
}

# 获取可用模板列表
get_available_templates() {
    local templates=()
    if [ -d "$AGENTS_SOURCE_DIR/template" ]; then
        while IFS= read -r -d '' file; do
            local name=$(basename "$file" .md)
            templates+=("$name")
        done < <(find "$AGENTS_SOURCE_DIR/template" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
    fi
    printf '%s\n' "${templates[@]}"
}

# 选择要部署的智能体
select_agents() {
    print_header "Step 3: 选择要部署的智能体"

    local available_agents
    available_agents=$(get_available_agents)

    if [ -z "$available_agents" ]; then
        print_warning "没有找到可部署的智能体"
        SELECTED_AGENTS=""
        return
    fi

    echo "可选智能体:"
    echo "$available_agents" | nl
    echo ""
    echo "提示: 使用逗号分隔多个选项 (如: 1,2,3)，直接回车跳过，输入 'all' 全选"
    echo -n "请选择智能体编号: "
    read -r agent_selection

    if [ -z "$agent_selection" ]; then
        print_info "跳过智能体部署"
        SELECTED_AGENTS=""
        return
    fi

    local selected=()
    if [ "$agent_selection" = "all" ]; then
        selected=($(echo "$available_agents"))
    else
        # 解析选择
        IFS=',' read -ra indices <<< "$agent_selection"
        local agents_array=($(echo "$available_agents"))
        for idx in "${indices[@]}"; do
            idx=$(echo "$idx" | tr -d ' ')
            if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#agents_array[@]}" ]; then
                selected+=("${agents_array[$((idx-1))]}")
            fi
        done
    fi

    SELECTED_AGENTS="${selected[*]}"

    if [ -n "$SELECTED_AGENTS" ]; then
        echo -e "已选择: ${GREEN}${SELECTED_AGENTS}${NC}"
    fi
}

# 选择要部署的模板
select_templates() {
    print_header "Step 4: 选择要部署的模板"

    local available_templates
    available_templates=$(get_available_templates)

    if [ -z "$available_templates" ]; then
        print_warning "没有找到可部署的模板"
        SELECTED_TEMPLATES=""
        return
    fi

    echo "可用模板:"
    echo "$available_templates" | nl
    echo ""
    echo "提示: 使用逗号分隔多个选项 (如: 1,2)，直接回车跳过，输入 'all' 全选"
    echo -n "请选择模板编号: "
    read -r template_selection

    if [ -z "$template_selection" ]; then
        print_info "跳过模板部署"
        SELECTED_TEMPLATES=""
        return
    fi

    local selected=()
    local renamed_map=()

    if [ "$template_selection" = "all" ]; then
        selected=($(echo "$available_templates"))
    else
        # 解析选择
        IFS=',' read -ra indices <<< "$template_selection"
        local templates_array=($(echo "$available_templates"))
        for idx in "${indices[@]}"; do
            idx=$(echo "$idx" | tr -d ' ')
            if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#templates_array[@]}" ]; then
                selected+=("${templates_array[$((idx-1))]}")
            fi
        done
    fi

    # 询问每个模板的新名称
    echo ""
    echo "=== 模板重命名 ==="
    for template in "${selected[@]}"; do
        echo -e "模板: ${CYAN}${template}${NC}"
        echo -n "请输入新名称 (默认: ${template}): "
        read -r new_name

        if [ -z "$new_name" ]; then
            new_name="$template"
        fi

        # 确保以 .md 结尾
        if [[ "$new_name" != *.md ]]; then
            new_name="${new_name}.md"
        fi

        renamed_map+=("${template}:${new_name}")
        echo -e "  -> 将部署为: ${GREEN}${new_name}${NC}"
        echo ""
    done

    SELECTED_TEMPLATES="${selected[*]}"
    RENAMED_TEMPLATES="${renamed_map[*]}"
}

# 编辑模板内容
edit_template() {
    local template_file="$1"
    local template_name="$2"

    print_header "编辑模板: $template_name"

    echo -e "${YELLOW}模板内容预览:${NC}"
    echo "----------------------------------------"
    head -30 "$template_file"
    echo "----------------------------------------"
    echo ""

    echo -e "${CYAN}需要修改的变量示例:${NC}"
    grep -oE '\{\{[A-Za-z_]+\}\}' "$template_file" | sort -u | while read -r var; do
        echo "  - $var"
    done
    echo ""

    echo "请选择操作:"
    echo "  1) 使用默认编辑器打开"
    echo "  2) 使用 sed 进行替换"
    echo "  3) 跳过编辑 (保持原样)"
    echo -n "请输入选项 [1-3] (默认: 3): "
    read -r edit_choice

    case "$edit_choice" in
        1)
            local editor="${EDITOR:-vi}"
            "$editor" "$template_file"
            print_success "模板编辑完成"
            ;;
        2)
            echo "输入替换规则 (格式: old/new)，输入空行结束:"
            while true; do
                echo -n "替换规则: "
                read -r replace_rule
                [ -z "$replace_rule" ] && break

                old_str=$(echo "$replace_rule" | cut -d'/' -f1)
                new_str=$(echo "$replace_rule" | cut -d'/' -f2)

                if [ -n "$old_str" ]; then
                    sed -i "s/${old_str}/${new_str}/g" "$template_file"
                    print_info "已替换: $old_str -> $new_str"
                fi
            done
            print_success "批量替换完成"
            ;;
        *)
            print_info "跳过编辑"
            ;;
    esac
}

# 执行部署
deploy() {
    print_header "Step 5: 执行部署"

    # 创建目标目录
    mkdir -p "$AGENTS_DEPLOY_DIR"
    print_info "创建目录: $AGENTS_DEPLOY_DIR"

    # 部署智能体
    if [ -n "$SELECTED_AGENTS" ]; then
        echo ""
        echo -e "${CYAN}部署智能体...${NC}"
        for agent in $SELECTED_AGENTS; do
            local source_file="$AGENTS_SOURCE_DIR/${agent}.md"
            local target_file="$AGENTS_DEPLOY_DIR/${agent}.md"

            if [ "$DEPLOY_MODE" = "symlink" ]; then
                ln -sf "$source_file" "$target_file"
                print_success "软链接: ${agent}.md"
            else
                cp "$source_file" "$target_file"
                print_success "复制: ${agent}.md"
            fi
        done
    fi

    # 部署模板 (模板总是复制，因为需要编辑)
    if [ -n "$SELECTED_TEMPLATES" ]; then
        echo ""
        echo -e "${CYAN}部署模板...${NC}"

        # 创建临时目录存放编辑后的模板
        TEMP_DIR=$(mktemp -d)
        trap "rm -rf $TEMP_DIR" EXIT

        for item in $RENAMED_TEMPLATES; do
            local original_name=$(echo "$item" | cut -d':' -f1)
            local new_name=$(echo "$item" | cut -d':' -f2)
            local source_file="$AGENTS_SOURCE_DIR/template/${original_name}.md"
            local temp_file="$TEMP_DIR/${new_name}"
            local target_file="$AGENTS_DEPLOY_DIR/${new_name}"

            # 复制到临时目录
            cp "$source_file" "$temp_file"

            # 编辑模板
            edit_template "$temp_file" "$original_name"

            # 复制到目标位置
            cp "$temp_file" "$target_file"
            print_success "部署模板: ${new_name}"
        done
    fi

    echo ""
    print_header "部署完成!"
    echo -e "部署位置: ${GREEN}$AGENTS_DEPLOY_DIR${NC}"
    echo ""
    echo "已部署文件:"
    ls -la "$AGENTS_DEPLOY_DIR" 2>/dev/null || echo "  (目录为空)"
}

# 主函数
main() {
    print_header "OpenCode Agent 部署工具"

    check_dependencies
    get_deploy_dir
    select_deploy_mode
    select_agents
    select_templates

    # 确认部署
    echo ""
    echo "================================"
    echo "部署摘要:"
    echo "  目标目录: $AGENTS_DEPLOY_DIR"
    echo "  部署模式: $DEPLOY_MODE"
    echo "  智能体: ${SELECTED_AGENTS:-'(无)'}"
    echo "  模板: ${SELECTED_TEMPLATES:-'(无)'}"
    echo "================================"
    echo ""
    echo -n "确认部署? [Y/n] "
    read -r confirm

    if [[ -z "$confirm" || "$confirm" =~ ^[Yy]$ ]]; then
        deploy
    else
        print_warning "部署已取消"
        exit 0
    fi
}

# 运行主函数
main
