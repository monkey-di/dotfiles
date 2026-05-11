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


def get_page_content_width(root: etree._Element) -> int:
    """Ширина области текста страницы в dxa: pgSz.w - pgMar.left - pgMar.right.
    Fallback: A4 portrait c полями 1" = 11906 - 2880 = 9026 dxa."""
    sect_pr = root.find(f".//{W_('sectPr')}")
    if sect_pr is None:
        return 9026
    pg_sz = sect_pr.find(W_("pgSz"))
    pg_mar = sect_pr.find(W_("pgMar"))
    if pg_sz is None or pg_mar is None:
        return 9026
    try:
        w = int(pg_sz.get(W_("w"), "11906"))
        left = int(pg_mar.get(W_("left"), "1440"))
        right = int(pg_mar.get(W_("right"), "1440"))
        return max(1000, w - left - right)
    except (ValueError, TypeError):
        return 9026


def stretch_table(tbl: etree._Element, page_width_dxa: int):
    """Растянуть таблицу на всю ширину страницы.

    Используем dxa, а не pct: LibreOffice игнорирует pct у tcW, когда tblGrid
    задан в dxa. Также фиксируем layout=fixed, иначе Word/LO могут ужимать
    колонки по содержимому."""
    tbl_pr = tbl.find(W_("tblPr"))
    if tbl_pr is None:
        tbl_pr = etree.SubElement(tbl, W_("tblPr"))
        tbl.insert(0, tbl_pr)

    tbl_w = make_el("tblW", type="dxa", w=str(page_width_dxa))
    replace_or_append(tbl_pr, "tblW", tbl_w)

    layout = make_el("tblLayout", type="fixed")
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


def _cell_text_length(tc: etree._Element) -> int:
    """Длина текста в ячейке (сумма всех <w:t>)."""
    return sum(len(t.text or "") for t in tc.iter(W_("t")))


def compute_column_widths(tbl: etree._Element, page_width_dxa: int) -> list[int]:
    """Распределить ширину страницы по колонкам пропорционально содержимому.

    Вес колонки = максимальная длина текста в её ячейках. Заголовок учитывается
    наравне с обычными ячейками — обычно он короче содержимого, и это нормально.
    Минимальный пол (min_chars) защищает узкие колонки от схлопывания в ноль."""
    rows = tbl.findall(W_("tr"))
    if not rows:
        return []
    n_cols = max(len(r.findall(W_("tc"))) for r in rows)
    if n_cols == 0:
        return []

    max_lens = [0] * n_cols
    for tr in rows:
        for i, tc in enumerate(tr.findall(W_("tc"))):
            if i < n_cols:
                max_lens[i] = max(max_lens[i], _cell_text_length(tc))

    import math
    min_chars = 6  # минимум, чтобы колонка не схлопнулась
    # √-сглаживание: длинная колонка получает больше места, но не в линейной
    # пропорции — иначе короткие колонки превращаются в полоски в 5–7%
    weights = [math.sqrt(max(c, min_chars)) for c in max_lens]
    total = sum(weights)

    widths = [int(page_width_dxa * w / total) for w in weights]
    # Округлительный остаток отдаём самой "тяжёлой" колонке
    diff = page_width_dxa - sum(widths)
    if diff:
        widths[weights.index(max(weights))] += diff
    return widths


def set_cell_widths_dxa(tbl: etree._Element, widths: list[int]):
    """Прописать ширину каждой ячейки и обновить tblGrid."""
    rows = tbl.findall(W_("tr"))
    if not rows or not widths:
        return

    # Обновляем tblGrid под новые значения
    grid = tbl.find(W_("tblGrid"))
    if grid is not None:
        cols = grid.findall(W_("gridCol"))
        for i, c in enumerate(cols):
            if i < len(widths):
                c.set(W_("w"), str(widths[i]))

    for tr in rows:
        for i, tc in enumerate(tr.findall(W_("tc"))):
            if i >= len(widths):
                continue
            tc_pr = ensure_child(tc, "tcPr")
            if list(tc).index(tc_pr) != 0:
                tc.remove(tc_pr)
                tc.insert(0, tc_pr)
            tc_w = make_el("tcW", type="dxa", w=str(widths[i]))
            replace_or_append(tc_pr, "tcW", tc_w)


def process_xml(xml_bytes: bytes) -> tuple[bytes, int]:
    parser = etree.XMLParser(remove_blank_text=False)
    root = etree.fromstring(xml_bytes, parser)

    page_width = get_page_content_width(root)
    n = 0
    for tbl in root.iter(W_("tbl")):
        stretch_table(tbl, page_width)
        widths = compute_column_widths(tbl, page_width)
        set_cell_widths_dxa(tbl, widths)
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
