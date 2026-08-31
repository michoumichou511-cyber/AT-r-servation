# -*- coding: utf-8 -*-
"""
fix_v7_final.py — 3 corrections finales sur Memoir V7
1. titlePg + firstHeader vide sur les sectPr des chapitres
2. Placeholder TOC plus propre
3. Fusion du seul orphelin [81→82]
"""
import zipfile, shutil, os, tempfile
from lxml import etree

SRC = r"C:\Users\loulou\Downloads\Memoir_AT_Reservations_V7.docx"
DST = r"C:\Users\loulou\Downloads\Memoir_AT_Reservations_V7.docx"  # overwrite

WNS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
RNS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
ns = {"w": WNS, "r": RNS}

# Chapter header rIds that need titlePg
CHAPTER_RIDS = {"rId17", "rId25", "rId42", "rId43"}
EMPTY_HEADER_RID = "rId10"  # header2.xml (vide)

# Work in a temp copy
tmp = tempfile.mktemp(suffix=".docx")
shutil.copy2(SRC, tmp)

# Read the docx
zin = zipfile.ZipFile(tmp, 'r')
doc_xml = zin.read("word/document.xml")
tree = etree.fromstring(doc_xml)
body = tree.find(f"{{{WNS}}}body")

# ═══════════════════════════════════════
# FIX 1: titlePg + firstHeader on chapter sectPr
# ═══════════════════════════════════════
print("=== FIX 1: titlePg on chapter separators ===")
fix1_count = 0

for sectPr in tree.iter(f"{{{WNS}}}sectPr"):
    hdr_refs = sectPr.findall(f"{{{WNS}}}headerReference")
    has_chapter_header = False
    has_first_header = False
    has_titlePg = sectPr.find(f"{{{WNS}}}titlePg") is not None

    for href in hdr_refs:
        rid = href.get(f"{{{RNS}}}id", "")
        htype = href.get(f"{{{WNS}}}type", "")
        if rid in CHAPTER_RIDS and htype == "default":
            has_chapter_header = True
        if htype == "first":
            has_first_header = True

    if has_chapter_header:
        # Add titlePg if not present
        if not has_titlePg:
            titlePg = etree.SubElement(sectPr, f"{{{WNS}}}titlePg")
            print(f"  Added <w:titlePg/> to sectPr with chapter header")

        # Add first header reference if not present
        if not has_first_header:
            first_ref = etree.SubElement(sectPr, f"{{{WNS}}}headerReference")
            first_ref.set(f"{{{WNS}}}type", "first")
            first_ref.set(f"{{{RNS}}}id", EMPTY_HEADER_RID)
            print(f"  Added firstHeader ref (rId10) to sectPr")

        fix1_count += 1

print(f"  Fixed {fix1_count} sectPr elements")

# ═══════════════════════════════════════
# FIX 2: TOC placeholder text
# ═══════════════════════════════════════
print("\n=== FIX 2: TOC placeholder text ===")
fix2_count = 0

PLACEHOLDER_OLD = "[Actualiser : Ctrl+A puis F9]"
TOC_PLACEHOLDERS = {
    ' TOC \\o "1-3" \\h \\z \\u ': "Ouvrir dans Word et appuyer sur F9 pour actualiser le sommaire",
    ' TOC \\c "Figure" \\h ': "Ouvrir dans Word et appuyer sur F9 pour actualiser la liste des figures",
    ' TOC \\c "Tableau" \\h ': "Ouvrir dans Word et appuyer sur F9 pour actualiser la liste des tableaux",
}

for p in body.iter(f"{{{WNS}}}p"):
    instrs = p.findall(f".//{{{WNS}}}instrText")
    if not instrs:
        continue

    instr_text = ""
    for instr in instrs:
        if instr.text:
            instr_text = instr.text.strip()

    if not instr_text:
        continue

    # Find the matching TOC type
    new_placeholder = None
    for key, val in TOC_PLACEHOLDERS.items():
        if key.strip() == instr_text:
            new_placeholder = val
            break

    if new_placeholder is None:
        continue

    # Find the text between "separate" and "end" fldChar and replace it
    in_result = False
    for r in p.findall(f"{{{WNS}}}r"):
        fc = r.find(f"{{{WNS}}}fldChar")
        if fc is not None:
            ftype = fc.get(f"{{{WNS}}}fldCharType", "")
            if ftype == "separate":
                in_result = True
                continue
            elif ftype == "end":
                in_result = False
                continue

        if in_result:
            t = r.find(f"{{{WNS}}}t")
            if t is not None:
                t.text = new_placeholder
                # Ensure italic
                rPr = r.find(f"{{{WNS}}}rPr")
                if rPr is None:
                    rPr = etree.SubElement(r, f"{{{WNS}}}rPr")
                    r.insert(0, rPr)
                i_el = rPr.find(f"{{{WNS}}}i")
                if i_el is None:
                    etree.SubElement(rPr, f"{{{WNS}}}i")
                # Gray color
                col = rPr.find(f"{{{WNS}}}color")
                if col is None:
                    col = etree.SubElement(rPr, f"{{{WNS}}}color")
                col.set(f"{{{WNS}}}val", "808080")
                # Font
                rFonts = rPr.find(f"{{{WNS}}}rFonts")
                if rFonts is None:
                    rFonts = etree.SubElement(rPr, f"{{{WNS}}}rFonts")
                rFonts.set(f"{{{WNS}}}ascii", "Times New Roman")
                rFonts.set(f"{{{WNS}}}hAnsi", "Times New Roman")

                fix2_count += 1
                print(f"  Replaced placeholder for: {instr_text.strip()}")

print(f"  Fixed {fix2_count} TOC placeholders")

# ═══════════════════════════════════════
# FIX 3: Merge orphan paragraph [81→82]
# ═══════════════════════════════════════
print("\n=== FIX 3: Merge orphan paragraphs ===")

# Find paragraph pairs to merge by scanning all <w:p> in body
all_paras = body.findall(f"{{{WNS}}}p")

def get_text(p_el):
    texts = []
    for t in p_el.iter(f"{{{WNS}}}t"):
        if t.text:
            texts.append(t.text)
    return "".join(texts).strip()

def get_style(p_el):
    pPr = p_el.find(f"{{{WNS}}}pPr")
    if pPr is not None:
        ps = pPr.find(f"{{{WNS}}}pStyle")
        if ps is not None:
            return ps.get(f"{{{WNS}}}val", "")
    return ""

merged = 0
i = 0
while i < len(all_paras) - 1:
    p1 = all_paras[i]
    p2 = all_paras[i + 1]
    t1 = get_text(p1)
    t2 = get_text(p2)
    s1 = get_style(p1)
    s2 = get_style(p2)

    # Only merge body text paragraphs
    body_styles = {"", "NormalWeb", "Corpsdetexte"}
    if s1 not in body_styles or s2 not in body_styles:
        i += 1
        continue

    if not t1 or not t2:
        i += 1
        continue

    # Check merge condition: p1 doesn't end with punctuation, p2 starts lowercase, p2 is short
    if (not t1.endswith(('.', ':', ';', '!', '?', ')')) and
        t2[0].islower() and len(t2) < 80):

        # Merge: append a space + p2's runs to p1, then remove p2
        # Add space to last run of p1
        runs1 = p1.findall(f"{{{WNS}}}r")
        if runs1:
            last_run = runs1[-1]
            last_t = last_run.find(f"{{{WNS}}}t")
            if last_t is not None and last_t.text:
                last_t.text = last_t.text + " "
                last_t.set("{http://www.w3.org/XML/1998/namespace}space", "preserve")

        # Move runs from p2 to p1
        runs2 = p2.findall(f"{{{WNS}}}r")
        for r in runs2:
            p1.append(r)

        # Remove p2
        body.remove(p2)
        all_paras = body.findall(f"{{{WNS}}}p")  # refresh list

        merged += 1
        print(f"  Merged: '...{t1[-30:]}' + '{t2[:40]}'")
        # Don't increment i — check the new next paragraph too
    else:
        i += 1

print(f"  Merged {merged} orphan paragraphs")

# ═══════════════════════════════════════
# SAVE
# ═══════════════════════════════════════
print("\n=== SAVING ===")

# Write modified document.xml back
new_doc_xml = etree.tostring(tree, xml_declaration=True, encoding="UTF-8", standalone=True)

# Create new zip with modified document.xml
tmp_out = tempfile.mktemp(suffix=".docx")
with zipfile.ZipFile(tmp, 'r') as zin:
    with zipfile.ZipFile(tmp_out, 'w', zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            if item.filename == "word/document.xml":
                zout.writestr(item, new_doc_xml)
            else:
                zout.writestr(item, zin.read(item.filename))

# Move to destination
shutil.move(tmp_out, DST)
os.remove(tmp)

fsize = os.path.getsize(DST)
print(f"  Saved: {DST}")
print(f"  Size: {fsize:,} bytes")
print("\nDONE.")
