---
name: component-datasheet
description: 阅读元器件规格书/数据手册(PDF)，把长篇规格书整理成可决策的中文报告，提炼选型要点、关键参数、设计约束与常见陷阱。当用户给出 datasheet、规格书、数据手册 PDF，或提到读/整理/总结/提炼/讲解/选型某个芯片、IC、模块、传感器、电源、连接器时使用；即使用户只说“看看这个 datasheet”“这个芯片有什么重点”“能不能用在我的电路里”也应使用。
---

# 元器件数据手册整理

把规格书变成可决策的信息。核心不是复述，而是回答四件事：**它是什么、能不能用、边界在哪、哪里会踩坑**。

## 先判断产出形态

| 用户意图 | 产出 |
|----------|------|
| 问具体问题，如“3.3 V 能用吗”“待机电流多大” | 先用 3-5 行给结论和页码证据，再问是否需要完整报告 |
| 直接给 PDF，没说具体要什么 | 默认生成完整报告，对话里给 5-8 条摘要 |
| 选型 / 找替代品 | 以选型维度、替代品差异、生命周期为主，参数表从简 |
| 只读某一节 | 只抽该节并回答，不生成整本报告 |

## 先定位，再精读

数据手册有固定结构，不要从第一页顺序读到最后一页。先建页码地图，再只读相关页。

### 1. 准备环境

用 `$SKILL_DIR` 表示本 skill 所在目录（即本文件所在目录；在 opencode 中通常是 `~/.config/opencode/skills/component-datasheet`）：

```bash
export SKILL_DIR="/path/to/component-datasheet"
export PY="$SKILL_DIR/.venv/bin/python"

python "$SKILL_DIR/scripts/setup_env.py"
"$PY" "$SKILL_DIR/scripts/setup_env.py" --check
```

Windows 下把 `$PY` 换成 `$SKILL_DIR\.venv\Scripts\python.exe`；若系统没有 `python` 命令，把初始化命令里的 `python` 换成 `python3`。环境未就绪时不要继续抽取，先让用户执行初始化命令。

### 2. 首轮侦察

```bash
"$PY" "$SKILL_DIR/scripts/parse_pdf.py" "xxx.pdf" --toc --pages 1-3
```

重点看：

- `meta.type`、`meta.pages`、`meta.pdf_version`：数据手册、参考手册还是应用笔记。
- `meta.text_extractable`：为 `false` 时是扫描件，转第 5 步的渲染流程。
- `toc`：书签目录，用来快速定位章节。
- `first_page_title`、`first_page_lines`、`part_number_candidates`：确认型号、厂商、文档版本。
- `text`：前三页正文，用来确认器件定位和关键卖点。

确认型号、厂商、文档类型、版本/日期、生命周期状态（Active / NRND / Obsolete / Preliminary）。型号和版本决定后续参数是否可信，不要跳过。

### 3. 建页码地图

没有书签，或书签太粗时，用关键词检索：

```bash
"$PY" "$SKILL_DIR/scripts/search_pdf.py" "xxx.pdf" \
  "absolute maximum|recommended operating|electrical characteristics|dc characteristics|timing|pin configuration|pinout|package|typical application|layout|thermal|errata|ordering" \
  --pages 1-80 --context 100
```

中文手册同时搜“绝对最大”“推荐工作条件”“电气特性”“引脚”“封装”“典型应用”“布局”“勘误”“订购”。把命中页整理成：

| 章节 | PDF 页码 | 用途 |
|------|----------|------|
| Absolute Maximum Ratings | p.12 | 极限边界 |
| Electrical Characteristics | p.14-18 | 设计参数 |
| Pin Configuration | p.5 | 引脚/封装 |

只把地图里的页加入上下文，不要 `--all` 扫整本。

### 4. 抽取目标页

```bash
"$PY" "$SKILL_DIR/scripts/parse_pdf.py" "xxx.pdf" --pages 12-18 --layout
"$PY" "$SKILL_DIR/scripts/extract_tables.py" "xxx.pdf" --pages 12-18 --strategy lines --out tables.md
```

- 无框线表格用 `--strategy text`；仍失败时渲染页面用视觉读取。
- 跨页表格要两页都抽，报告里标注“续表”，不要假设第二页表头与第一页相同。
- 文本抽取出现列错乱、乱码或公式丢失时，不要硬读，渲染该页用视觉核对。
- 一次只抽一个主题的页，避免上下文被无关章节淹没。

### 5. 图表与引脚

引脚图、封装图、典型应用图、时序图通常无法靠文本还原：

```bash
"$PY" "$SKILL_DIR/scripts/extract_images.py" "xxx.pdf" --pages 4-5 --dpi 200
```

然后用 `read` 工具查看导出的 PNG。重点核对：

- 引脚编号、名称、类型（Power / I/O / NC / EP）。
- 顶视图还是底视图，BGA/QFN 的球位/焊盘编号。
- 多封装型号的引脚映射差异。
- 典型应用图中的外围元件值和连接方式。
- 时序图的时钟极性、建立/保持时间、上电顺序。

不要只凭正文文字推断引脚编号。

### 6. 按类型整理

读 `references/field_guide.md`，按元器件类型取维度。MCU、LDO、MOSFET、连接器、晶振的关键参数完全不同，不要拿 IC 模板套所有器件。

### 7. 读数的硬规则

- **Absolute Maximum 不是 Recommended Operating Conditions**。在两者之间不代表可以长期工作，只代表不立即损坏。
- **Typical 不是保证值**。设计裕量用 min/max，不要用 typ 做最坏情况计算。
- 每个数字都要有**单位、测试条件、页码**。手册没给条件时写“手册未给出测试条件”，不要自行补。
- 不要混用 min/typ/max 列；不要把“最大值”当成“推荐值”。
- 温度范围、降额曲线、热阻是规格的一部分，不是附录。
- 注意脚注、`Preliminary`、`NRND`、`Not recommended for new designs`、`Contact factory`。
- 查 Revision History 和 Errata；新版可能改过参数或修正过错误。
- 不同章节矛盾时，两处都列出并标页码，说明冲突，不要静默选一个。
- 区分 `[手册]` 与 `[外部知识]`。替代型号、供货、价格等外部信息必须标注来源类型，不能伪装成手册结论。

### 8. 校验

读 `references/review_checklist.md` 逐项过一遍。至少随机抽 5 个关键数字回原文核对单位、条件、页码。确认用户最初的问题已经被直接回答。

### 9. 输出

用 `references/summary_template.md` 生成中文 Markdown 报告，写到源 PDF 同目录的 `<pdf_stem>.md`，除非用户指定位置。

报告要求：

- **结论先行**：能不能用、适合什么场景、最大的两个风险。
- 参数表必须带测试条件和页码。
- 选型要点、关键警告、设计/布局注意事项、常见坑分开写。
- 末尾列“信息缺口”和“来源索引”。
- 页码统一用 PDF 物理页码；若与印刷页码不同，注明映射关系。

对话里只给 5-8 条摘要：一句话结论、2-3 个关键参数、2 个最重要的警告、信息缺口。不要把手册全文倒进聊天。

## 脚本

| 脚本 | 用途 |
|------|------|
| `setup_env.py` | 创建/检查 `.venv`，安装 PyMuPDF |
| `parse_pdf.py` | 元信息、目录、指定页文本；首轮侦察和精读都用它 |
| `search_pdf.py` | 正则检索并返回页码、行号、上下文 |
| `extract_tables.py` | 抽取表格为 JSON/Markdown，支持无框线策略 |
| `extract_images.py` | 渲染指定页为 PNG/JPG，供视觉核对 |
| `selftest.py` | 生成样例 PDF，端到端验证全部脚本 |

所有脚本约定：页码从 1 开始；成功返回码 0，失败返回码 1；JSON 输出到 stdout，错误输出到 stderr；加密 PDF 用 `--password`。修改脚本后先跑：

```bash
"$PY" "$SKILL_DIR/scripts/selftest.py"
```

## 边界情况

- **扫描件**：`text_extractable` 为 `false` 时，渲染 150-300 dpi 图片用视觉读取；需要全文检索时再调用 `pdf` skill 的 OCR 流程，并在报告中说明“数值由图像识读”。
- **超大参考手册**：只按目录和检索定位相关章节，禁止 `--all`。
- **无目录**：`toc_source` 为 `none` 时用关键词检索建图，不要假装有目录。
- **多份文档**：数据手册、参考手册、应用笔记、Errata 分开处理，需要时交叉引用。
- **非英文手册**：参数名和单位保留原文，解释用中文。
- **信息缺失**：写进“信息缺口”，不要用经验值填空。
- **停产/替代**：生命周期状态和替代型号属于选型结论，必须标注信息来源。

## 完成标准

- [ ] 用户的问题有直接回答，而不是只给一份报告。
- [ ] 关键数字都有单位、测试条件和页码。
- [ ] 绝对最大值、推荐工作条件、电气特性分开呈现。
- [ ] 引脚、封装、型号变体已核对。
- [ ] 风险、常见坑、信息缺口已列出。
- [ ] 没有编造手册中不存在的数值。
