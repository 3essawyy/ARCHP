"""Generate the ARCHP datapath schematic as draw.io (editable) and SVG (report).

One model (blocks + orthogonal wires with bus widths) -> two renderers, so the
editable diagram and the report figure can never disagree. Run:

    uv run python tools/gen_schematic.py

Outputs docs/architecture/schematic.drawio and docs/architecture/schematic.svg.
"""

from __future__ import annotations

import html
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "architecture"

W, H = 2060, 1170

# stage colours (fill) - pale, print-friendly
C_IF, C_ID, C_EX1, C_EX2, C_MEM, C_WB = (
    "#e8f1fb",
    "#eaf6ea",
    "#fdf3e1",
    "#f6e9f6",
    "#e9f4f4",
    "#f3f0e6",
)
C_REG = "#d9d9d9"
C_RAM = "#fff7c2"


@dataclass
class Block:
    key: str
    x: int
    y: int
    w: int
    h: int
    label: str
    fill: str = "#ffffff"
    dashed: bool = False
    bold: bool = False


@dataclass
class Wire:
    pts: list[tuple[int, int]]
    label: str = ""
    lpos: int = 0  # segment index for the label
    color: str = "#222222"
    dashed: bool = False
    arrow: bool = True


@dataclass
class Model:
    blocks: list[Block] = field(default_factory=list)
    wires: list[Wire] = field(default_factory=list)
    texts: list[tuple[int, int, str, int]] = field(default_factory=list)  # x, y, text, size

    def b(self, *a: object, **k: object) -> None:
        self.blocks.append(Block(*a, **k))  # type: ignore[arg-type]

    def w(self, pts: list[tuple[int, int]], label: str = "", lpos: int = 0, **k: object) -> None:
        self.wires.append(Wire(pts, label, lpos, **k))  # type: ignore[arg-type]

    def t(self, x: int, y: int, text: str, size: int = 13) -> None:
        self.texts.append((x, y, text, size))


def build() -> Model:
    m = Model()
    # ---------------------------------------------------------------- stage bands
    bands = [
        (30, 330, "1  FETCH (IF)", C_IF),
        (395, 335, "2  DECODE (ID)", C_ID),
        (770, 360, "3  EXECUTE-1 (EX1)", C_EX1),
        (1170, 300, "4  EXECUTE-2 (EX2)", C_EX2),
        (1510, 150, "5  MEMORY", C_MEM),
        (1700, 330, "6  WRITE-BACK", C_WB),
    ]
    for i, (x, w, name, col) in enumerate(bands):
        m.b(f"band{i}", x, 40, w, 860, "", fill=col)
        m.t(x + 10, 62, name, 15)
    # pipeline registers (tall bars)
    for key, x, name in [
        ("ifid", 352, "IF/ID"),
        ("idex1", 733, "ID/EX1"),
        ("ex1ex2", 1137, "EX1/EX2"),
        ("ex2mem", 1477, "EX2/MEM"),
        ("memwb", 1667, "MEM/WB"),
    ]:
        m.b(key, x, 80, 26, 800, "", fill=C_REG, bold=True)
        m.t(x - 8, 900, name, 12)

    # ---------------------------------------------------------------- IF
    m.b(
        "fctl",
        50,
        100,
        160,
        70,
        "Fetch control\nfetch_en = !mem_busy\n& !halted & !wait",
        fill="#fff",
    )
    m.b(
        "nmux",
        50,
        230,
        150,
        250,
        "Next-address\npriority mux\n12b\n\n1 WB pc-load\n2 EX2 redirect\n3 ID JMP/CALL\n4 replay id_pc\n5 PC",
    )
    m.b("pc", 245, 240, 80, 50, "PC\n12b", fill="#fff", bold=True)
    m.b("inc", 245, 400, 60, 40, "+1")
    m.b(
        "btb",
        50,
        540,
        160,
        90,
        "BTB 8 x (tag, target,\n2-bit counter)\nbonus: G_DYNAMIC_BP",
        dashed=True,
    )
    # ---------------------------------------------------------------- ID
    m.b(
        "cu",
        405,
        100,
        200,
        120,
        "Control unit\n+ micro-op sequencer\nphase / hw_phase\nwait / halted\nJMP-CALL redirect",
    )
    m.b("intr", 405, 232, 170, 48, "Interrupt latch\nINTR.IN edge -> int_pending")
    m.b("hdu", 620, 200, 100, 75, "Load-use HDU\n(loads in\nEX1, EX2)")
    m.b(
        "rf",
        405,
        300,
        200,
        130,
        "Register file\nR0..R7  8 x 32\n2 read / 1 write\n+ WB bypass",
        bold=True,
    )
    m.b("imm", 620, 425, 100, 60, "imm 16b\nret_pc 12b")
    # ---------------------------------------------------------------- EX1
    m.b("fwd", 785, 100, 150, 70, "Forwarding unit\nEX2 > MEM > WB")
    m.b("fma", 785, 230, 90, 90, "Fwd mux A\n4:1 x 32")
    m.b("fmb", 785, 360, 90, 90, "Fwd mux B\n4:1 x 32")
    m.b("ext", 785, 490, 90, 50, "ext 16->32\nsext/zext")
    m.b("bmux", 895, 370, 50, 70, "B\nmux")
    m.b(
        "alu",
        965,
        230,
        150,
        190,
        "ALU 32b\nADD/SUB/INC\n(one adder)\nAND NOT\nSHL SHR\nPASS A/B\nIN  SETC",
        bold=True,
    )
    m.b("ccr", 965, 500, 110, 60, "CCR\nC N Z", bold=True)
    # ---------------------------------------------------------------- EX2
    m.b("bru", 1185, 100, 160, 90, "Branch unit\ncond(Z/N/C)\nredirect =\ntaken xor pred")
    m.b("sp", 1185, 250, 90, 60, "SP 12b\nreset FFF", bold=True)
    m.b("spm", 1295, 250, 60, 60, "+1 / -1")
    m.b("amux", 1185, 360, 170, 70, "Address mux 12b\nSP | SP+1 | ALU")
    m.b("dmux", 1185, 480, 170, 80, "Data mux 32b\nB | ret_pc |\n{C N Z, ret_pc}")
    # ---------------------------------------------------------------- MEM
    m.b("own", 1520, 330, 130, 80, "Port owner\nmem_busy =\nmem_rd | mem_wr")
    # ---------------------------------------------------------------- WB
    m.b("wbm", 1715, 300, 120, 70, "WB data mux\nq | data")
    m.b("outp", 1715, 440, 120, 60, "OUT.PORT\nregister 32b", bold=True)
    m.b("pcl", 1715, 560, 160, 70, "PC load (q 11:0)\nRET RTI vectors\nRTI: CCR <- q 31:29")
    # ---------------------------------------------------------------- memory
    m.b("amem", 440, 975, 200, 80, "Memory address mux\nMEM busy ? EX2/MEM.addr\n: fetch address")
    m.b(
        "ram",
        700,
        960,
        520,
        120,
        "UNIFIED MEMORY  4096 x 32  (Von Neumann)\nM10K single port, synchronous read\n"
        "registered address -> data next cycle\nM[0] reset, M[1] interrupt, M[2..3] INT vectors",
        fill=C_RAM,
        bold=True,
    )

    # ---------------------------------------------------------------- wires
    k = "#1f4e9c"  # control
    r = "#b00020"  # redirect / stall
    f = "#7a5c00"  # forwarding
    # IF
    m.w([(130, 170), (130, 230)], "", color=k)
    m.w([(200, 420), (245, 420)], "target", 0)
    m.w([(275, 400), (275, 290)], "")
    m.t(282, 385, "next PC", 10)
    m.w([(245, 265), (200, 265)], "PC 12", 0)
    m.w([(200, 340), (352, 340)], "target 12 -> id_pc", 0)
    m.w([(210, 585), (290, 585), (290, 440)], "predicted target (bonus)", 0, dashed=True)
    m.w([(200, 470), (225, 470), (225, 1015), (440, 1015)], "fetch addr 12", 2)
    # IF/ID -> ID
    m.w([(378, 160), (405, 160)], "opcode", 0)
    m.w([(378, 360), (405, 360)], "Ra Rb", 0)
    m.w([(378, 455), (620, 455)], "imm 16", 0)
    # ID
    m.w([(605, 150), (733, 150)], "ctrl ~30", 0, color=k)
    m.w([(490, 232), (490, 220)], "", color=k)
    m.w([(620, 237), (595, 237), (595, 220)], "stall", 0, color=k)
    m.w([(746, 255), (720, 255)], "", color=k)
    m.w([(605, 350), (733, 350)], "A, B 32+32", 0)
    m.w([(720, 455), (733, 455)], "")
    m.w([(405, 205), (232, 205), (232, 300), (200, 300)], "JMP/CALL target, replay", 0, color=k)
    # EX1
    m.w([(759, 275), (785, 275)], "A", 0)
    m.w([(759, 405), (785, 405)], "B", 0)
    m.w([(759, 515), (785, 515)], "imm", 0)
    m.w([(860, 170), (860, 230)], "selA", 0, color=k)
    m.w([(925, 170), (925, 345), (830, 345), (830, 360)], "selB", 0, color=k)
    m.w([(875, 405), (895, 405)], "")
    m.w([(875, 515), (920, 515), (920, 440)], "")
    m.w([(875, 275), (965, 275)], "A 32", 0)
    m.w([(945, 405), (965, 405)], "B 32", 0)
    m.w([(875, 445), (1137, 445)], "B (store data) 32", 0)
    m.w([(1040, 420), (1040, 500)], "Z N C", 0, color=k)
    m.w([(1115, 300), (1137, 300)], "")
    m.w([(952, 890), (952, 415), (965, 415)], "IN.PORT 32 (pin)", 0)
    # forwarding bus
    m.w([(1150, 840), (778, 840)], "EX2 result", 0, color=f, arrow=False)
    m.w([(1490, 850), (778, 850)], "MEM data", 0, color=f, arrow=False)
    m.w([(1835, 345), (1905, 345), (1905, 860), (778, 860)], "WB data", 2, color=f, arrow=False)
    m.w([(778, 860), (778, 300), (785, 300)], "", color=f)
    m.w([(778, 430), (785, 430)], "", color=f)
    m.t(640, 845, "forwarding sources", 11)
    # EX2
    m.w([(1163, 145), (1185, 145)], "", color=k)
    m.w([(1075, 530), (1125, 530), (1125, 205), (1265, 205), (1265, 190)], "flags", 2, color=k)
    m.w(
        [(1265, 100), (1265, 80), (215, 80), (215, 250), (200, 250)],
        "EX2 redirect + target 12, flush ID/EX1",
        1,
        color=r,
    )
    m.w([(1275, 280), (1295, 280)], "")
    m.w([(1325, 310), (1325, 330), (1240, 330), (1240, 310)], "SP+-1", 0)
    m.w([(1230, 330), (1230, 360)], "")
    m.w([(1163, 300), (1172, 300), (1172, 395), (1185, 395)], "", 0)
    m.w([(1163, 445), (1175, 445), (1175, 520), (1185, 520)], "", 0)
    m.w([(1355, 395), (1477, 395)], "addr 12", 0)
    m.w([(1355, 520), (1477, 520)], "data 32", 0)
    # MEM
    m.w([(1503, 395), (1520, 370)], "")
    m.w(
        [(1585, 410), (1585, 915), (540, 915), (540, 975)], "EX2/MEM addr 12, data 32, we -> RAM", 1
    )
    m.w([(1650, 370), (1667, 370)], "")
    m.w(
        [(1540, 410), (1540, 905), (40, 905), (40, 150), (50, 150)],
        "mem_busy: fetch stalls (structural hazard)",
        2,
        color=r,
    )
    m.w([(640, 1015), (700, 1015)], "addr 12")
    m.w([(720, 960), (720, 895), (365, 895), (365, 880)], "q 32 = instruction (IR)", 1)
    # WB
    m.w([(1220, 1060), (1700, 1060), (1700, 330), (1715, 330)], "q 32 (load data / popped PC)", 0)
    m.w([(1693, 345), (1715, 345)], "")
    m.w(
        [(1835, 335), (1890, 335), (1890, 92), (612, 92), (612, 400), (605, 400)],
        "wdata 32 -> R[Rd] (write port)",
        1,
    )
    m.w([(1693, 470), (1715, 470)], "")
    m.w([(1835, 470), (1990, 470)], "OUT.PORT 32", 0)
    m.w(
        [(1795, 630), (1795, 930), (20, 930), (20, 320), (50, 320)],
        "PC load 12 (RET / RTI / vectors / reset)",
        1,
        color=r,
    )
    m.t(
        40,
        1120,
        "Bus widths in bits. Blue: control. Red: redirect / stall. Brown: forwarding "
        "sources (into the EX1 muxes). Dashed: bonus dynamic predictor (G_DYNAMIC_BP).",
        12,
    )
    m.t(
        40,
        1145,
        "Grey bars are pipeline registers (fields and sizes in the report, section 5). "
        "The RAM's registered address acts as the IF/ID instruction register.",
        12,
    )
    return m


# ------------------------------------------------------------------ renderers


def to_svg(m: Model) -> str:
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
        f'viewBox="0 0 {W} {H}" font-family="Helvetica, Arial, sans-serif">',
        '<defs><marker id="a" markerWidth="8" markerHeight="8" refX="7" refY="4" '
        'orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="context-stroke"/></marker></defs>',
        f'<rect width="{W}" height="{H}" fill="#ffffff"/>',
    ]
    for bl in m.blocks:
        dash = ' stroke-dasharray="6,4"' if bl.dashed else ""
        sw = 2.2 if bl.bold else 1.2
        stroke = "#999" if bl.key.startswith("band") else "#333"
        out.append(
            f'<rect x="{bl.x}" y="{bl.y}" width="{bl.w}" height="{bl.h}" rx="4" '
            f'fill="{bl.fill}" stroke="{stroke}" stroke-width="{sw}"{dash}/>'
        )
        lines = bl.label.split("\n") if bl.label else []
        y0 = bl.y + bl.h / 2 - (len(lines) - 1) * 7.5
        for i, ln in enumerate(lines):
            weight = "bold" if i == 0 else "normal"
            out.append(
                f'<text x="{bl.x + bl.w / 2}" y="{y0 + i * 15 + 4}" font-size="12" '
                f'text-anchor="middle" font-weight="{weight}">{html.escape(ln)}</text>'
            )
    for wr in m.wires:
        pts = " ".join(f"{x},{y}" for x, y in wr.pts)
        dash = ' stroke-dasharray="5,3"' if wr.dashed else ""
        mk = ' marker-end="url(#a)"' if wr.arrow else ""
        out.append(
            f'<polyline points="{pts}" fill="none" stroke="{wr.color}" stroke-width="1.6"{dash}{mk}/>'
        )
        if wr.label:
            (x1, y1), (x2, y2) = wr.pts[wr.lpos], wr.pts[min(wr.lpos + 1, len(wr.pts) - 1)]
            out.append(
                f'<text x="{(x1 + x2) / 2 + 3}" y="{(y1 + y2) / 2 - 4}" font-size="10.5" '
                f'fill="{wr.color}">{html.escape(wr.label)}</text>'
            )
    for x, y, text, size in m.texts:
        if text:
            out.append(
                f'<text x="{x}" y="{y}" font-size="{size}" font-weight="bold">'
                f"{html.escape(text)}</text>"
            )
    out.append("</svg>")
    return "\n".join(out) + "\n"


def to_drawio(m: Model) -> str:
    cells = ['<mxCell id="0"/>', '<mxCell id="1" parent="0"/>']
    n = 2
    for bl in m.blocks:
        style = (
            f"rounded=1;whiteSpace=wrap;html=1;fillColor={bl.fill};arcSize=4;"
            f"strokeColor={'#999999' if bl.key.startswith('band') else '#333333'};"
            f"strokeWidth={2 if bl.bold else 1};fontSize=12;"
            + ("dashed=1;" if bl.dashed else "")
            + ("verticalAlign=top;" if bl.key.startswith("band") else "")
        )
        val = html.escape(bl.label).replace("\n", "&lt;br&gt;")
        cells.append(
            f'<mxCell id="b{n}" value="{val}" style="{style}" vertex="1" parent="1">'
            f'<mxGeometry x="{bl.x}" y="{bl.y}" width="{bl.w}" height="{bl.h}" as="geometry"/></mxCell>'
        )
        n += 1
    for wr in m.wires:
        (sx, sy), (tx, ty) = wr.pts[0], wr.pts[-1]
        pts = "".join(f'<mxPoint x="{x}" y="{y}"/>' for x, y in wr.pts[1:-1])
        style = (
            f"edgeStyle=none;html=1;strokeColor={wr.color};strokeWidth=1.5;fontSize=10;"
            f"fontColor={wr.color};"
            + ("dashed=1;" if wr.dashed else "")
            + ("endArrow=block;endFill=1;" if wr.arrow else "endArrow=none;")
        )
        cells.append(
            f'<mxCell id="e{n}" value="{html.escape(wr.label)}" style="{style}" edge="1" parent="1">'
            f'<mxGeometry relative="1" as="geometry"><mxPoint x="{sx}" y="{sy}" as="sourcePoint"/>'
            f'<mxPoint x="{tx}" y="{ty}" as="targetPoint"/><Array as="points">{pts}</Array>'
            f"</mxGeometry></mxCell>"
        )
        n += 1
    for x, y, text, size in m.texts:
        if text:
            cells.append(
                f'<mxCell id="t{n}" value="{html.escape(text)}" style="text;html=1;fontSize={size};'
                f'fontStyle=1;align=left;" vertex="1" parent="1"><mxGeometry x="{x}" y="{y - 14}" '
                f'width="{max(80, len(text) * 7)}" height="20" as="geometry"/></mxCell>'
            )
            n += 1
    body = "".join(cells)
    return (
        '<mxfile host="archp-gen" type="device"><diagram id="datapath" name="ARCHP datapath">'
        f'<mxGraphModel dx="{W}" dy="{H}" grid="1" gridSize="10" guides="1" tooltips="1" '
        f'connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="{W}" '
        f'pageHeight="{H}" math="0" shadow="0"><root>{body}</root></mxGraphModel>'
        "</diagram></mxfile>\n"
    )


def main() -> None:
    m = build()
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "schematic.svg").write_text(to_svg(m), encoding="utf-8")
    (OUT / "schematic.drawio").write_text(to_drawio(m), encoding="utf-8")
    print(f"wrote {OUT / 'schematic.svg'} and {OUT / 'schematic.drawio'}")


if __name__ == "__main__":
    main()
