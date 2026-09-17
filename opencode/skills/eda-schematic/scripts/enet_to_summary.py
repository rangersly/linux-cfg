#!/usr/bin/env python3
"""把嘉立创EDA专业版 .enet 网表解析为结构化摘要。

用法:
    python3 enet_to_summary.py <file.enet> [--format md|json] [--net NET] [--out FILE]

.enet 顶层字段: version / components / designRule / differentialPair / netClass / equalLengthNetGroup
components[<uid>] = { props: {...}, pinInfoMap: { <pinKey>: {name, number, net, props} } }
网络名以 $ 开头为自动生成网络; net 为空字符串表示该引脚未连接(NC)。
"""

import argparse
import json
import re
import sys
from collections import defaultdict

POWER_PATTERNS = [
    r"^(VCC|VDD|VBAT|VBUS|VIN|VSYS|V_\w+)$",
    r"^[+-]?\d+(\.\d+)?V$",
    r"^(3V3|3\.3V|5V|1V8|1\.8V|1V2|1\.2V|2V5|2\.5V)$",
    r"^(GND|AGND|DGND|PGND|VSS|GNDA|GNDD)$",
]


def is_power_net(net):
    return any(re.match(p, net, re.IGNORECASE) for p in POWER_PATTERNS)


def is_auto_net(net):
    return net.startswith("$")


def natkey(s):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", s or "")]


def load(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except UnicodeDecodeError:
        with open(path, encoding="utf-8-sig") as f:
            return json.load(f)


def build(data):
    comps = data.get("components", {}) or {}
    rows = []
    nets = defaultdict(list)
    nc_pins = []
    for uid, comp in comps.items():
        props = comp.get("props", {}) or {}
        des = props.get("Designator", "") or uid
        row = {
            "uid": uid,
            "designator": des,
            "value": props.get("Value", ""),
            "name": props.get("Name", ""),
            "device": props.get("DeviceName", ""),
            "footprint": props.get("FootprintName", ""),
            "lcsc": props.get("Supplier Part", ""),
            "manufacturer_part": props.get("Manufacturer Part", ""),
            "bom": props.get("Add into BOM", ""),
            "to_pcb": props.get("Convert to PCB", ""),
            "no_connect": props.get("NO_CONNECT", ""),
            "multipart": props.get("Multi-Part Group", ""),
            "channel": props.get("Channel ID", ""),
        }
        rows.append(row)
        for pin_key, pin in (comp.get("pinInfoMap") or {}).items():
            if not isinstance(pin, dict):
                continue
            net = pin.get("net", "") or ""
            num = pin.get("number", pin_key)
            pname = pin.get("name", "")
            entry = {
                "designator": des,
                "uid": uid,
                "pin_number": num,
                "pin_name": pname,
            }
            if net == "":
                nc_pins.append(entry)
            else:
                nets[net].append(entry)

    rows.sort(key=lambda r: natkey(r["designator"]))
    for net in nets:
        nets[net].sort(key=lambda e: (natkey(e["designator"]), natkey(str(e["pin_number"]))))
    return {
        "version": data.get("version", ""),
        "components": rows,
        "nets": dict(nets),
        "nc_pins": nc_pins,
        "design_rule": data.get("designRule", {}),
        "differential_pair": data.get("differentialPair", {}),
        "net_class": data.get("netClass", {}),
        "equal_length": data.get("equalLengthNetGroup", {}),
    }


def fmt_component(r):
    name = r["name"]
    if name.startswith("={") and name.endswith("}"):
        name = r["value"]
    parts = [p for p in (r["value"], r["device"], r["footprint"]) if p]
    label = " / ".join(parts)
    extras = []
    if r["lcsc"]:
        extras.append(r["lcsc"])
    if r["multipart"]:
        extras.append(f"多Part:{r['multipart']}")
    if r["bom"] == "no":
        extras.append("不入BOM")
    if r["to_pcb"] == "no":
        extras.append("不转PCB")
    if r["no_connect"] == "yes":
        extras.append("含NC脚")
    suffix = f" ({', '.join(extras)})" if extras else ""
    return f"- **{r['designator']}** {label}{suffix}"


def to_markdown(s, net_query=None):
    out = []
    out.append(f"# .enet 网表摘要 (version {s['version'] or '?'})\n")
    out.append(f"- 元件数: **{len(s['components'])}**")
    out.append(f"- 网络数: **{len(s['nets'])}**")
    out.append(f"- 未连接引脚数: **{len(s['nc_pins'])}**\n")

    groups = defaultdict(list)
    for r in s["components"]:
        prefix = re.match(r"[A-Za-z]+", r["designator"])
        groups[prefix.group(0) if prefix else "?"].append(r)

    out.append("## 元件清单\n")
    out.append("| 位号 | 值 | 器件 | 封装 | 立创料号 |")
    out.append("|------|----|------|------|----------|")
    for r in s["components"]:
        out.append(
            f"| {r['designator']} | {r['value']} | {r['device']} | {r['footprint']} | {r['lcsc']} |"
        )

    power = [(n, pins) for n, pins in s["nets"].items() if is_power_net(n)]
    signal = [(n, pins) for n, pins in s["nets"].items() if not is_power_net(n)]
    power.sort(key=lambda kv: natkey(kv[0]))
    signal.sort(key=lambda kv: (is_auto_net(kv[0]), natkey(kv[0])))

    out.append("\n## 电源 / 地网络\n")
    if power:
        for net, pins in power:
            members = ", ".join(f"{p['designator']}.{p['pin_number']}" for p in pins)
            out.append(f"- **{net}** ({len(pins)} 脚): {members}")
    else:
        out.append("- 未识别到电源/地网络")

    out.append("\n## 信号网络\n")
    if signal:
        for net, pins in signal:
            tag = " [自动命名]" if is_auto_net(net) else ""
            members = ", ".join(f"{p['designator']}.{p['pin_number']}" for p in pins)
            out.append(f"- **{net}**{tag} ({len(pins)} 脚): {members}")
    else:
        out.append("- 无")

    if s["nc_pins"]:
        out.append("\n## 未连接引脚 (NC)\n")
        for p in s["nc_pins"]:
            out.append(f"- {p['designator']}.{p['pin_number']} ({p['pin_name']})")

    if s["differential_pair"]:
        out.append("\n## 差分对\n")
        for name in s["differential_pair"]:
            out.append(f"- {name}")
    if s["net_class"]:
        out.append("\n## 网络类\n")
        for name in s["net_class"]:
            out.append(f"- {name}")
    if s["equal_length"]:
        out.append("\n## 等长网络组\n")
        for name in s["equal_length"]:
            out.append(f"- {name}")

    if net_query:
        out.append(f"\n## 网络查询: {net_query}\n")
        pins = s["nets"].get(net_query)
        if pins:
            out.append(f"| 位号 | 引脚号 | 引脚名 |")
            out.append("|------|--------|--------|")
            for p in pins:
                out.append(f"| {p['designator']} | {p['pin_number']} | {p['pin_name']} |")
        else:
            out.append("未找到该网络")

    return "\n".join(out) + "\n"


def main():
    ap = argparse.ArgumentParser(description="解析嘉立创EDA专业版 .enet 网表")
    ap.add_argument("path", help=".enet 文件路径")
    ap.add_argument("--format", choices=["md", "json"], default="md")
    ap.add_argument("--net", help="查询某个网络的连接")
    ap.add_argument("--out", help="输出文件(默认 stdout)")
    args = ap.parse_args()

    summary = build(load(args.path))
    if args.format == "json":
        text = json.dumps(summary, ensure_ascii=False, indent=2)
    else:
        text = to_markdown(summary, args.net)

    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
