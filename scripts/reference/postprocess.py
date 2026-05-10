#!/usr/bin/env python3
"""Пост-обработка docx после pandoc:

- таблицы растягиваются на всю ширину страницы (tblW pct=5000);
- ячейки header'а (где <w:tblHeader/>) получают явный фон, белый жирный текст,
  центрирование — это надёжнее, чем полагаться на наследование из tblStylePr.

Реализовано через zipfile + lxml (без python-docx),
чтобы не зависеть от валидности [Content_Types].xml в reference docx.

Запуск: ./postprocess.py <input.docx> [output.docx]
По умолчанию модифицирует файл на месте.
"""

from __future__ import annotations

import shutil
import sys
import zipfile
from pathlib import Path

from lxml import etree

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": W}
DOC_PART = "word/document.xml"

HEADER_BG = "434343"
HEADER_FG = "ffffff"


def W_(tag: str) -> str:
    return f"{{{W}}}{tag}"


def make_el(tag: str, **attrs) -> etree._Element:
    el = etree.SubElement(etree.Element("root"), W_(tag))
    el.getparent().remove(el)
    for k, v in attrs.items():
        el.set(W_(k), v)
    return el


def replace_or_append(parent: etree._Element, tag: str, new_el: etree._Element):
    existing = parent.find(W_(tag))
    if existing is not None:
        parent.replace(existing, new_el)
    else:
        parent.append(new_el)


def ensure_child(parent: etree._Element, tag: str) -> etree._Element:
    el = parent.find(W_(tag))
    if el is None:
        el = etree.SubElement(parent, W_(tag))
    return el


def stretch_table(tbl: etree._Element):
    tbl_pr = tbl.find(W_("tblPr"))
    if tbl_pr is None:
        tbl_pr = etree.SubElement(tbl, W_("tblPr"))
        tbl.insert(0, tbl_pr)

    tbl_w = make_el("tblW", type="pct", w="5000")
    replace_or_append(tbl_pr, "tblW", tbl_w)

    layout = make_el("tblLayout", type="autofit")
    replace_or_append(tbl_pr, "tblLayout", layout)


def is_header_row(tr: etree._Element) -> bool:
    tr_pr = tr.find(W_("trPr"))
    if tr_pr is None:
        return False
    return tr_pr.find(W_("tblHeader")) is not None


def style_header_row(tr: etree._Element, *, fill: str = HEADER_BG, fg: str = HEADER_FG):
    for tc in tr.findall(W_("tc")):
        tc_pr = ensure_child(tc, "tcPr")
        # tcPr должен быть первым ребёнком tc
        if list(tc).index(tc_pr) != 0:
            tc.remove(tc_pr)
            tc.insert(0, tc_pr)

        shd = make_el("shd", val="clear", color="auto", fill=fill)
        replace_or_append(tc_pr, "shd", shd)

        valign = make_el("vAlign", val="center")
        replace_or_append(tc_pr, "vAlign", valign)

        # Каждый абзац ячейки: центрирование + жирный белый текст в рунах
        for p in tc.findall(W_("p")):
            ppr = ensure_child(p, "pPr")
            if list(p).index(ppr) != 0:
                p.remove(ppr)
                p.insert(0, ppr)
            jc = make_el("jc", val="center")
            replace_or_append(ppr, "jc", jc)

            for r in p.findall(W_("r")):
                rpr = r.find(W_("rPr"))
                if rpr is None:
                    rpr = etree.SubElement(r, W_("rPr"))
                    r.insert(0, rpr)

                color = make_el("color", val=fg)
                replace_or_append(rpr, "color", color)

                b = make_el("b", val="1")
                replace_or_append(rpr, "b", b)


def process_xml(xml_bytes: bytes) -> tuple[bytes, int]:
    parser = etree.XMLParser(remove_blank_text=False)
    root = etree.fromstring(xml_bytes, parser)

    n = 0
    for tbl in root.iter(W_("tbl")):
        stretch_table(tbl)
        for tr in tbl.findall(W_("tr")):
            if is_header_row(tr):
                style_header_row(tr)
                break
        n += 1

    out = etree.tostring(root, xml_declaration=True, encoding="UTF-8", standalone=True)
    return out, n


def process_docx(src: Path, dst: Path) -> int:
    # Переписываем .docx как новый zip с заменённым document.xml
    tmp = dst.with_suffix(dst.suffix + ".tmp")
    n = 0
    with zipfile.ZipFile(src, "r") as zin, zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == DOC_PART:
                data, n = process_xml(data)
            zout.writestr(item, data)
    shutil.move(tmp, dst)
    return n


def main():
    if len(sys.argv) < 2:
        print("Использование: postprocess.py <input.docx> [output.docx]", file=sys.stderr)
        sys.exit(1)
    inp = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else inp

    n = process_docx(inp, out)
    print(f"Обработано таблиц: {n} → {out}")


if __name__ == "__main__":
    main()
