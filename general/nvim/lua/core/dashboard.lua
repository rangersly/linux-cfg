-- ~/.config/nvim/lua/plugins/dashboard.lua
-- 用途:启动时显示 "RANGERSLY" 彩色字符画 + 插件统计
-- 原理:VimEnter 事件触发浮动窗口,无边框,自定义粉/白/蓝高亮组

-- ============================================
-- 1. 定义自定义高亮颜色(粉、白、蓝)
-- ============================================
vim.api.nvim_set_hl(0, "DashboardPink", { fg = "#FF69B4", bold = true })  -- 亮粉色
vim.api.nvim_set_hl(0, "DashboardWhite", { fg = "#FFFFFF", bold = true }) -- 纯白色
vim.api.nvim_set_hl(0, "DashboardBlue", { fg = "#00BFFF", bold = true })  -- 深天蓝色
vim.api.nvim_set_hl(0, "DashboardDim", { fg = "#A888E8" })                -- 灰色用于统计信息

-- ============================================
-- 字符画:RANGERSLY(7行高,使用 █ 块绘制)
--    你可以自由修改每一行的字符串
-- ============================================
local ascii_art = {
    " ██████╗   █████╗  ███╗   ██╗  ██████╗  ███████╗ ██████╗  ███████╗  ██╗    ██╗   ██╗",
    " ██╔══██╗ ██╔══██╗ ████╗  ██║ ██╔════╝  ██╔════╝ ██╔══██╗ ██╔════╝  ██║    ╚██╗ ██╔╝",
    " ██████╔╝ ███████║ ██╔██╗ ██║ ██║  ███╗ █████╗   ██████╔╝ ███████╗  ██║     ╚████╔╝ ",
    " ██╔══██╗ ██╔══██║ ██║╚██╗██║ ██║   ██║ ██╔══╝   ██╔══██╗ ╚════██║  ██║      ╚██╔╝  ",
    " ██║  ██║ ██║  ██║ ██║ ╚████║ ╚██████╔╝ ███████╗ ██║  ██║ ███████║  ███████╗  ██║   ",
    " ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═══╝  ╚═════╝  ╚══════╝ ╚═╝  ╚═╝ ╚══════╝  ╚══════╝  ╚═╝   ",
}

-- ============================================
-- 3. 每行对应的颜色组(前两行粉,中两行白,后两行蓝)
-- ============================================
local art_colors = {
    "DashboardPink",
    "DashboardPink",
    "DashboardWhite",
    "DashboardWhite",
    "DashboardBlue",
    "DashboardBlue",
}

-- ============================================
-- 4. 生成插件统计与快捷键提示行
-- ============================================
local function get_info_lines()
    local stats = require("lazy").stats()
    return {
        "",
        string.format("         🚀 已加载插件:%d / %d              ⏱️  启动耗时:%.2f ms",
            stats.loaded, stats.count, stats.startuptime),
        "",
        "",
        "",
        "                           f               查找文件",
        "",
        "",
        "",
        "                           g               实时 grep",
        "",
        "",
        "",
        "                           l               打开 Lazy 面板",
        "",
        "",
        "",
        "                           c               打开配置文件夹",
        "",
        "",
        "",
        "                           <Esc>/q         关闭本画面",
    }
end

-- ============================================
-- 5. 创建无边框浮动窗口
-- ============================================
-- 延迟更新启动时间（100ms 后 lazy.nvim 统计数据就绪）

local function show_dashboard()
    local info_lines = get_info_lines()
    local total_lines = #ascii_art + #info_lines
    local width = 90 -- 根据你的字符画宽度调整
    local height = total_lines + 12

    -- 创建临时缓冲区
    local buf = vim.api.nvim_create_buf(false, true)

    -- 窗口参数(无边框,居中)
    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        row = math.max(0, math.floor((vim.o.lines - height) / 2 - 2)),
        style = "minimal",
        border = "none",
    }

    local win = vim.api.nvim_open_win(buf, true, win_opts)

    -- 修复点:通过窗口变量设置背景融合(去掉无边框窗口的背景差异)
    vim.wo[win].winhighlight = "Normal:Normal"

    -- 填充所有行
    local lines = {}
    for _, line in ipairs(ascii_art) do
        table.insert(lines, line)
    end
    for _, line in ipairs(info_lines) do
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- 为字符画各行添加颜色
    for i, _ in ipairs(ascii_art) do
        if art_colors[i] then
            vim.api.nvim_buf_add_highlight(buf, -1, art_colors[i], i - 1, 0, -1)
        end
    end

    -- 统计信息用灰色
    local info_start = #ascii_art
    for i = 0, #info_lines - 1 do
        vim.api.nvim_buf_add_highlight(buf, -1, "DashboardDim", info_start + i, 0, -1)
    end

    -- 缓冲区属性(只读,关闭时自动清除)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"

    -- ============================================
    -- 6. 快捷操作映射(按下后关闭窗口并执行动作)
    -- ============================================
    local function close_and_exec(action)
        vim.api.nvim_win_close(win, true)
        if type(action) == "string" then
            vim.cmd(action)
        elseif type(action) == "function" then
            action()
        end
    end

    -- f → 查找文件(触发你的 <leader>ff)
    vim.keymap.set("n", "f", function()
        close_and_exec(function()
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<leader>ff", true, false, true), "m", false
            )
        end)
    end, { buffer = buf, silent = true })

    -- g → 实时 grep(触发 <leader>fg)
    vim.keymap.set("n", "g", function()
        close_and_exec(function()
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<leader>fg", true, false, true), "m", false
            )
        end)
    end, { buffer = buf, silent = true })

    -- l → 打开 Lazy 面板(触发 <leader>l)
    vim.keymap.set("n", "l", function()
        close_and_exec(function()
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<leader>l", true, false, true), "m", false
            )
        end)
    end, { buffer = buf, silent = true })

    -- c → 打开 Neovim 配置文件夹（直接编辑目录）
    vim.keymap.set("n", "c", function()
        close_and_exec("NvimTreeOpen" .. vim.fn.stdpath("config"))
    end, { buffer = buf, silent = true })

    -- <Esc> 和 q 直接关闭
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
end

-- ============================================
-- 7. 启动时调用(无文件参数时显示)
-- ============================================
vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("Dashboard", { clear = true }),
    callback = function()
        if vim.fn.argc() == 0 and not vim.g.dashboard_shown then
            vim.defer_fn(function()
                show_dashboard()
            end, 80)
            vim.g.dashboard_shown = true
        end
    end,
})
