---
name: eda-schematic
description: 解析立创EDA(EasyEDA)/通用电路原理图,把元件、引脚和网络连接转为结构化文本供分析。优先支持嘉立创EDA专业版网表 .enet(JSON)。当用户提到电路原理图、schematic、立创EDA、嘉立创EDA、EasyEDA、网表、netlist、.enet/.epro/.eprj/.json 原理图文件,或需要"读懂/分析/检查/讲解"某块电路时使用。
---

# EDA 原理图解析

帮助用户读懂电路原理图。目标是先得到**精确的连接关系**,再回答任何关于电路的问题。

## 0. 输入类型检测

先确认用户提供了什么。优先顺序:

| 优先级 | 输入 | 解析方式 | 精度 |
|--------|------|----------|------|
| 1 | 嘉立创EDA专业版网表 `.enet`(JSON,含 `version`/`components`) | JSON 结构化解析(**推荐首选**) | 最高 |
| 2 | EasyEDA 标准版 JSON 源码 (`.json` 含 `head.docType` 或 `element` 数组) | 结构化解析 | 高 |
| 3 | 立创EDA专业版工程 (`.epro` / `.eprj`) | 解压/提取 JSON | 高 |
| 4 | PADS 网表 (`.asc`) | 纯文本解析 | 高 |
| 5 | Allegro 网表 (`.tel`) | 纯文本解析 | 高 |
| 6 | Protel / Altium 网表 (`.net`) | 纯文本解析 | 中 |
| 7 | 图片 / PDF 截图 | 视觉识别 | 低,仅作辅助 |

关键判据(按文件内容而非扩展名):**以 `{` 开头且含 `"components"` → `.enet`**(嘉立创EDA专业版网表);含 `"head"`/`"element"` → 标准版 JSON;以 `$PACKAGES`/`$NETS` 开头 → PADS 风格纯文本网表。

若用户只有图片/PDF,**主动提示**导出 `.enet` 或 JSON 可大幅提升精度,并说明导出路径(见下)。

## 1. 获取源文件

若用户还没有导出文件,引导其按格式操作:

- **嘉立创EDA专业版 .enet 网表(首选)**:顶部菜单 `文件 > 导出 > 网表`,在弹窗中把"网表类型"选为 **嘉立创EDA(专业版)(.enet)**,可同时选页面范围,导出得到 `.enet`。该格式为 JSON,包含元件属性、引脚网络、设计规则、差分对、网络类、等长组,信息最全。
- **EasyEDA 标准版 JSON**:原理图内 `File > EasyEDA File Source > Download` 得到 `.json`(网页版可在项目列表右键项目 `Download` 得到 zip,解压后是 `.json`)。
- **其他网表**:原理图内 `文件 > 导出 > 网表`,类型可选 Allegro(`.tel`)、PADS(`.asc`)、Protel2(`.net`)。
- **立创EDA 专业版工程**:项目导出/备份得到 `.epro` 或 `.eprj`,其为内嵌 JSON 的文本或 zip。

## 2. 结构化解析

拿到文件后,按类型解析。**只要用户能给 `.enet`,就优先用它**——它是 JSON,字段稳定、无歧义,优于任何纯文本网表。

### `.enet` 网表(嘉立创EDA专业版,首选)

`.enet` 是**纯 JSON**(`.enet` 是扩展名,内容不是普通文本网表)。顶层结构:

```json
{
  "version": "2.0.0",
  "components": { "<唯一ID>": { "props": {...}, "pinInfoMap": {...} } },
  "designRule": { "trackPhysics": {...}, "netRule": {...} },
  "differentialPair": {...},
  "netClass": {...},
  "equalLengthNetGroup": {...}
}
```

解析只需三步,核心是 `components`:

1. **元件表**:遍历 `components`,每个键是元件唯一 ID(如 `gge1`),值里 `props` 是键值对属性(值均为字符串):
   - `Designator` 位号(如 `R1`、`U2`)——**主键**
   - `Value` 值(如 `10K`、`10uF`);`Name` 常为引用表达式 `={Value}`,解析时若见到 `={...}` 取其 `Value`
   - `DeviceName` 器件名、`FootprintName` 封装名
   - `Supplier`/`Supplier Part`(立创料号 `Cxxxxx`)、`Manufacturer Part`
   - `Add into BOM` / `Convert to PCB`(`yes`/`no`)、`NO_CONNECT`(`yes` 表示存在未连接脚)
   - `Multi-Part Group`(多 Part 器件分组)、`Channel ID`(复用通道,如 `$1I2`)
2. **引脚表**:每个元件的 `pinInfoMap`,键为引脚标识,值为 `{name, number, net, props}`:
   - `number` 引脚号、`name` 引脚名、`net` 该脚所连网络名
   - **`net` 为空字符串 `""` 表示该引脚未连接(NC)**,不要当成网络名为空的网络
3. **网络映射**:把所有引脚的 `net` 按同名归并,得到"网络 → 引脚(位号.引脚号)列表"。网络命名规则:
   - 用户命名网络:如 `VCC`、`GND`、`+12V`、`EDP_TX_D0P`
   - **自动生成网络:以 `$` 开头**,格式 `$<页面编号>N<序号>`(如 `$1N2`、`$10N639`),是未命名网络,按连接关系理解其用途即可
   - 同名网络即短接(全局/跨页同理)

对设计规则类信息(通常非用户提问重点,可按需读取):
`designRule.trackPhysics.*.strokeValue.common.{min,max,default}` 走线宽度;
`designRule.netRule[net]` 每个网络的规则映射;
`differentialPair` 差分对;`netClass` 网络类;`equalLengthNetGroup` 等长网络组。为空对象 `{}` 表示未定义。

**推荐做法**:直接用自带脚本一键生成结构化摘要,再在其上分析:

```bash
python3 scripts/enet_to_summary.py <file.enet>                 # Markdown 摘要
python3 scripts/enet_to_summary.py <file.enet> --format json   # JSON,便于程序处理
python3 scripts/enet_to_summary.py <file.enet> --net VCC       # 查询单个网络
```

脚本输出元件清单、电源/地网络、信号网络、NC 引脚、差分对/网络类/等长组。文件很大时脚本比手工读取更可靠。

若需手工解析:`.enet` 单行可能极长,先用 `grep` 统计 `"Designator"`、`"pinInfoMap"`、`"net"` 的出现次数判断规模,再决定全量读取还是用脚本。

### 其他 JSON 源码(EasyEDA 标准版)

遍历 `element` 数组,过滤 `head`/`wire`/`text`/`image` 等绘图对象,提取 `prefix`(如 `R`、`C`、`U`)、`name`/`value`、`designator`;每个元件的 `pins` 记录引脚 `number`/`name`;用**同名网络标签**隐式连接——收集所有 `netlabel` 及 `pin` 关联的 `net` 字段,同名归并。元件值可能放在 `value` 或 `name`,两者都查。

### 纯文本网表(非 .enet)

`.enet` 之外的网表是纯文本,**先找元件清单段,再找网络清单段**,构建"网络 → 引脚 → 元件"映射。两种常见风格:

- **PADS 风格**(`.asc`,部分 `.net`):
  ```
  *PADS-POWERPCB*
  *PART*  <位号> <封装>
  *NET*   <网络名> <位号>.<引脚> <位号>.<引脚> ...
  ```
- **Protel 风格**(`.net`):
  ```
  [
  <位号>
  <封装>
  ]
  (
  <网络名>
  <位号>-<引脚> <位号>-<引脚>
  )
  ```
- **Allegro 风格**(`.tel`):`$PACKAGES` 段每行按 `!` 分段给封装/值/位号;`$NETS` 段每行 `'网络名' ; 位号.引脚 ...`。位号/连接可能跨行延续,注意合并。

解析要点:引脚格式可能是 `位号.引脚` 或 `位号-引脚`,一律拆成"元件 + 引脚号";`$1Nxxxxx`/`N-xxxx` 之类是自动网络;若封装段与网络段信息冲突,以数据为准并记录疑点。

### 图片/PDF

用 Read 工具读图;若图复杂,先放大局部逐块读。只用于确认整体布局与大致拓扑,具体引脚连接以导出文件为准。

## 3. 输出结构化摘要

解析后,先向用户输出一份**电路摘要**(中文 Markdown),包含:

1. **元件清单**:位号 | 型号/值 | 器件/封装 | 立创料号 | 作用(电阻/电容/电源芯片/MCU/传感器…)
2. **电源树**:所有电源/地网络(VCC/3V3/5V/GND 等),哪些元件引脚连到哪个电源,是否有 DCDC/LDO、去耦电容
3. **关键信号网络**:MCU 引脚分配(UART/SPI/I2C/GPIO/PWM/ADC)、时钟、复位、BOOT;自动网络(`$…`)按连通关系推断用途
4. **接口与外设**:连接器、按键、LED、传感器等外部接口接线
5. **未连接引脚 / 疑点**:`.enet` 的 `NO_CONNECT` 与 `net==""` 引脚、未命名网络、重复网络等

## 4. 回答问题

在摘要基础上回答用户的问题。常见问题与答题要点:

- **"这块电路怎么工作"**:按信号流向讲——电源输入 → 稳压 → MCU 供电;外设 → MCU 引脚 → 软件控制。
- **"某引脚接在哪/某网络连了谁"**:直接查网络映射表给出确切元件与引脚(可用 `--net` 查询)。
- **"检查有没有设计错误"**:检查电源接反、高低压混接、同名网络误连、上拉/下拉缺失、去耦缺失、方向接错、疑似 NC 引脚、单点网络等。
- **"帮我把原理图翻译成代码"**:给出引脚配置、外设初始化所需信息(GPIO 号、复用功能、上拉电阻值)。

## 5. 关键注意事项

- **一切连接关系以数据为准**,不要凭经验脑补某个 IC 的引脚定义;拿不准的封装/引脚归属,用 `.enet` 的 `pinInfoMap` 或 JSON 的 `pins` 数据核对。
- `.enet` 中 **`net: ""` 是未连接,不是网络名为空**;`$` 开头是自动网络名;`Designator` 才是位号,`Name` 常是 `={Value}` 引用需回退到 `Value`。
- 网络标签同名即短接(尤其 `GND`/`VCC`/`3V3` 这类全局网络,可能跨多页);多页原理图的同名网络跨页相连,解析时合并。
- 立创EDA 元件值可能放在 `value` 或 `name` 字段,两者都查。
- `.enet` 体积可能很大(几百元件可达 MB 级),优先用 `scripts/enet_to_summary.py` 解析而非整文件读入上下文。
- 若解析过程中字段结构与本说明不符(版本升级等),按文件实际结构自适应,并把关键字段名的发现过程简短记录在回答里。
