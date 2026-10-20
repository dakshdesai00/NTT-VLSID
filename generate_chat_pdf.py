#!/usr/bin/env python3
"""
generate_chat_pdf.py
Extracts the full conversation transcript and exports it into a professionally formatted PDF.
"""

import json
import re
import os
import sys

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, Preformatted, HRFlowable
)
from reportlab.pdfgen import canvas

TRANSCRIPT_PATH = "/Users/dakshdesai/.gemini/antigravity/brain/d13df715-b153-4a93-9962-81be31e67a1f/.system_generated/logs/transcript_full.jsonl"
OUTPUT_PDF = "/Users/dakshdesai/Desktop/VLSI/Project Files/docs/BUIM_Project_Chat_Transcript.pdf"
ROOT_PDF = "/Users/dakshdesai/Desktop/VLSI/BUIM_Project_Chat_Transcript.pdf"

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            super().showPage()
        super().save()

    def draw_page_number(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#718096"))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(54, 755, "HRCIM-NTT: BUIM Implementation — Discussion & Code Transcript")
            self.setStrokeColor(colors.HexColor("#E2E8F0"))
            self.setLineWidth(0.5)
            self.line(54, 747, 558, 747)
            
        # Footer
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(558, 36, page_str)
        self.drawString(54, 36, "Confidential — VLSI Design Course Project (IITGN)")
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(54, 48, 558, 48)
        self.restoreState()

def clean_user_content(text):
    m = re.search(r"<USER_REQUEST>(.*?)</USER_REQUEST>", text, re.DOTALL)
    if m:
        text = m.group(1).strip()
    return text.strip()

def escape_xml(text):
    text = text.replace("&", "&amp;")
    text = text.replace("<", "&lt;")
    text = text.replace(">", "&gt;")
    return text

def format_inline_markdown(text):
    # Escape special XML chars first
    text = escape_xml(text)
    
    # Bold: **text** -> <b>text</b>
    text = re.sub(r"\*\*(.*?)\*\*", r"<b>\1</b>", text)
    # Inline code: `text` -> <font face="Courier" color="#805AD5"><b>\1</b></font>
    text = re.sub(r"`(.*?)`", r'<font face="Courier" color="#805AD5"><b>\1</b></font>', text)
    # Math inline: $...$ -> <i>...</i>
    text = re.sub(r"\$(.*?)\$", r'<font face="Helvetica-Oblique" color="#2B6CB0">\1</font>', text)
    # Italic: *text* -> <i>text</i>
    text = re.sub(r"(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)", r"<i>\1</i>", text)
    # Markdown links: [text](url) -> <u>text</u>
    text = re.sub(r"\[(.*?)\]\((.*?)\)", r'<u>\1</u>', text)
    return text

def parse_markdown_table(lines, styles):
    data = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        # Split by |
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 2:
            if parts[0] == "":
                parts = parts[1:]
            if parts and parts[-1] == "":
                parts = parts[:-1]
            # Check if separator row
            if all(re.match(r"^:?-+:?$", p) for p in parts if p):
                continue
            data.append(parts)
            
    if not data or len(data) < 2:
        return None
        
    num_cols = max(len(row) for row in data)
    col_width = (504.0) / num_cols
    
    table_flowable_data = []
    for r_idx, row in enumerate(data):
        row_cells = []
        for c_idx in range(num_cols):
            cell_text = row[c_idx] if c_idx < len(row) else ""
            fmt_text = format_inline_markdown(cell_text)
            if r_idx == 0:
                p = Paragraph(f"<b>{fmt_text}</b>", styles["TableHeader"])
            else:
                p = Paragraph(fmt_text, styles["TableCell"])
            row_cells.append(p)
        table_flowable_data.append(row_cells)
        
    t = Table(table_flowable_data, colWidths=[col_width] * num_cols)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#2B6CB0")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E0")),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor("#F7FAFC")]),
    ]))
    return t

def markdown_to_flowables(text, styles):
    flowables = []
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        
        # Blank line
        if not line:
            flowables.append(Spacer(1, 4))
            i += 1
            continue
            
        # Code block
        if line.startswith("```"):
            code_lines = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                code_lines.append(lines[i])
                i += 1
            i += 1  # skip ending ```
            # Limit code block line length
            wrapped_code_lines = []
            for cl in code_lines:
                while len(cl) > 85:
                    wrapped_code_lines.append(cl[:85])
                    cl = "    " + cl[85:]
                wrapped_code_lines.append(cl)
            code_str = "\n".join(wrapped_code_lines)
            
            p_code = Preformatted(code_str, styles["CodeBlock"])
            code_table = Table([[p_code]], colWidths=[504])
            code_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F7FAFC")),
                ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
                ('TOPPADDING', (0, 0), (-1, -1), 6),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                ('LEFTPADDING', (0, 0), (-1, -1), 8),
                ('RIGHTPADDING', (0, 0), (-1, -1), 8),
            ]))
            flowables.append(code_table)
            flowables.append(Spacer(1, 4))
            continue
            
        # Markdown table
        if line.startswith("|") and i + 1 < len(lines) and "|" in lines[i+1]:
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                table_lines.append(lines[i])
                i += 1
            tbl = parse_markdown_table(table_lines, styles)
            if tbl:
                flowables.append(tbl)
                flowables.append(Spacer(1, 6))
            continue
            
        # Horizontal rule
        if re.match(r"^(\-{3,}|\*{3,}|_{3,})$", line.strip()):
            flowables.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#E2E8F0"), spaceAfter=6, spaceBefore=6))
            i += 1
            continue
            
        # Headers
        if line.startswith("# "):
            fmt = format_inline_markdown(line[2:].strip())
            flowables.append(Paragraph(fmt, styles["MyH1"]))
            flowables.append(Spacer(1, 4))
            i += 1
            continue
        elif line.startswith("## "):
            fmt = format_inline_markdown(line[3:].strip())
            flowables.append(Paragraph(fmt, styles["MyH2"]))
            flowables.append(Spacer(1, 4))
            i += 1
            continue
        elif line.startswith("### "):
            fmt = format_inline_markdown(line[4:].strip())
            flowables.append(Paragraph(fmt, styles["MyH3"]))
            flowables.append(Spacer(1, 4))
            i += 1
            continue
        elif line.startswith("#### "):
            fmt = format_inline_markdown(line[5:].strip())
            flowables.append(Paragraph(fmt, styles["MyH4"]))
            flowables.append(Spacer(1, 4))
            i += 1
            continue
            
        # Bullet list
        bullet_match = re.match(r"^(\s*)([-*+]|\d+\.)\s+(.*)$", line)
        if bullet_match:
            indent, marker, item_text = bullet_match.groups()
            fmt = format_inline_markdown(item_text)
            bullet_char = "&bull;&nbsp;&nbsp;" if marker in ["-", "*", "+"] else f"{marker}&nbsp;&nbsp;"
            bullet_p = Paragraph(f"{bullet_char}{fmt}", styles["BulletItem"])
            flowables.append(bullet_p)
            i += 1
            continue
            
        # Normal paragraph
        fmt = format_inline_markdown(line)
        flowables.append(Paragraph(fmt, styles["NormalText"]))
        i += 1

    return flowables

def build_pdf():
    print(f"Reading transcript from {TRANSCRIPT_PATH}...")
    dialogue = []
    with open(TRANSCRIPT_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            e = json.loads(line)
            source = e.get("source", "")
            type_ = e.get("type", "")
            content = e.get("content", "")
            
            if source == "USER_EXPLICIT" and type_ == "USER_INPUT":
                clean_text = clean_user_content(content)
                dialogue.append({"role": "User", "text": clean_text})
            elif source == "MODEL" and type_ == "PLANNER_RESPONSE":
                if isinstance(content, str) and content.strip():
                    if content.strip().startswith("I have set the remote to `git@github.com"):
                        continue
                    dialogue.append({"role": "Assistant", "text": content.strip()})

    print(f"Total conversation turns extracted: {len(dialogue)}")

    doc = SimpleDocTemplate(
        OUTPUT_PDF,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()
    
    # Custom styles
    styles.add(ParagraphStyle(
        name="DocTitle",
        fontName="Helvetica-Bold",
        fontSize=20,
        leading=24,
        textColor=colors.HexColor("#1A365D"),
        alignment=0,
        spaceAfter=6
    ))
    styles.add(ParagraphStyle(
        name="DocSubtitle",
        fontName="Helvetica",
        fontSize=11,
        leading=15,
        textColor=colors.HexColor("#4A5568"),
        spaceAfter=14
    ))
    styles.add(ParagraphStyle(
        name="MetaBox",
        fontName="Helvetica",
        fontSize=9,
        leading=13,
        textColor=colors.HexColor("#2D3748")
    ))
    styles.add(ParagraphStyle(
        name="UserBadge",
        fontName="Helvetica-Bold",
        fontSize=10,
        leading=13,
        textColor=colors.HexColor("#2B6CB0"),
        spaceAfter=2
    ))
    styles.add(ParagraphStyle(
        name="UserText",
        fontName="Helvetica-Bold",
        fontSize=10.5,
        leading=14.5,
        textColor=colors.HexColor("#1A202C")
    ))
    styles.add(ParagraphStyle(
        name="AssistantBadge",
        fontName="Helvetica-Bold",
        fontSize=10,
        leading=13,
        textColor=colors.HexColor("#2C7A7B"),
        spaceAfter=4
    ))
    styles.add(ParagraphStyle(
        name="MyH1",
        fontName="Helvetica-Bold",
        fontSize=13,
        leading=17,
        textColor=colors.HexColor("#1A365D"),
        spaceBefore=8,
        spaceAfter=4
    ))
    styles.add(ParagraphStyle(
        name="MyH2",
        fontName="Helvetica-Bold",
        fontSize=11,
        leading=15,
        textColor=colors.HexColor("#2B6CB0"),
        spaceBefore=6,
        spaceAfter=3
    ))
    styles.add(ParagraphStyle(
        name="MyH3",
        fontName="Helvetica-Bold",
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#2D3748"),
        spaceBefore=5,
        spaceAfter=2
    ))
    styles.add(ParagraphStyle(
        name="MyH4",
        fontName="Helvetica-Bold",
        fontSize=9,
        leading=13,
        textColor=colors.HexColor("#4A5568"),
        spaceBefore=4,
        spaceAfter=2
    ))
    styles.add(ParagraphStyle(
        name="NormalText",
        fontName="Helvetica",
        fontSize=9.5,
        leading=13.5,
        textColor=colors.HexColor("#2D3748"),
        spaceAfter=3
    ))
    styles.add(ParagraphStyle(
        name="BulletItem",
        fontName="Helvetica",
        fontSize=9.5,
        leading=13.5,
        textColor=colors.HexColor("#2D3748"),
        leftIndent=12,
        spaceAfter=2
    ))
    styles.add(ParagraphStyle(
        name="TableHeader",
        fontName="Helvetica-Bold",
        fontSize=8.5,
        leading=11,
        textColor=colors.white,
        alignment=0
    ))
    styles.add(ParagraphStyle(
        name="TableCell",
        fontName="Helvetica",
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor("#2D3748"),
        alignment=0
    ))
    styles.add(ParagraphStyle(
        name="CodeBlock",
        fontName="Courier",
        fontSize=7.5,
        leading=10,
        textColor=colors.HexColor("#1A202C")
    ))

    story = []

    # Title & Metadata Header
    story.append(Paragraph("HRCIM-NTT: Butterfly Unit in Memory (BUIM)", styles["DocTitle"]))
    story.append(Paragraph("Complete Technical Discussion, Verification &amp; Implementation Transcript", styles["DocSubtitle"]))

    meta_text = (
        "<b>Project:</b> VLSI Design Course Project — Autumn 2026<br/>"
        "<b>Authors:</b> Daksh Desai (24110098) &amp; Mitwa Goswami (24110205) — IITGN<br/>"
        "<b>Reference Paper:</b> X. Zhang et al., <i>'HRCIM-NTT: An Efficient Compute-in-Memory NTT Accelerator With Hybrid-Redundant Numbers,'</i> IEEE TCAS-I 2025.<br/>"
        "<b>Repository:</b> <code>git@github.com:dakshdesai00/NTT-VLSID.git</code> | <b>Target PDK:</b> 45 nm CMOS (gpdk045)<br/>"
        "<b>Verification Status:</b> 50/50 BUIM System Test Vectors Passed (100% Modulo Accuracy)"
    )
    meta_table = Table([[Paragraph(meta_text, styles["MetaBox"])]], colWidths=[504])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#EDF2F7")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#CBD5E0")),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 14))

    # Dialogue Iteration
    turn_num = 1
    for item in dialogue:
        role = item["role"]
        text = item["text"]

        if role == "User":
            user_title = f"User Question #{turn_num}"
            badge_p = Paragraph(f"<b>{user_title.upper()}</b>", styles["UserBadge"])
            text_p = Paragraph(format_inline_markdown(text), styles["UserText"])
            
            user_box = Table([[badge_p], [text_p]], colWidths=[504])
            user_box.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#EBF8FF")),
                ('LINEBEFORE', (0, 0), (-1, -1), 3.5, colors.HexColor("#2B6CB0")),
                ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#BEE3F8")),
                ('TOPPADDING', (0, 0), (-1, -1), 6),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                ('LEFTPADDING', (0, 0), (-1, -1), 10),
                ('RIGHTPADDING', (0, 0), (-1, -1), 10),
            ]))
            story.append(Spacer(1, 6))
            story.append(user_box)
            story.append(Spacer(1, 8))
            turn_num += 1
        else:
            badge_p = Paragraph("<b>ASSISTANT (Antigravity VLSI Engineering System)</b>", styles["AssistantBadge"])
            story.append(badge_p)
            story.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#CBD5E0"), spaceAfter=6, spaceBefore=2))
            
            flowables = markdown_to_flowables(text, styles)
            story.extend(flowables)
            story.append(Spacer(1, 12))

    print("Building PDF...")
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Generated PDF successfully at: {OUTPUT_PDF}")

    # Copy to root as well
    import shutil
    shutil.copyfile(OUTPUT_PDF, ROOT_PDF)
    print(f"Copied to root: {ROOT_PDF}")

if __name__ == "__main__":
    build_pdf()
