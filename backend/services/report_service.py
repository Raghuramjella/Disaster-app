"""
PDF report generation service using ReportLab.
"""
import io
from datetime import datetime

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    HRFlowable,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

_GREEN = colors.HexColor("#1B5E20")
_BLUE = colors.HexColor("#1565C0")
_LIGHT_GREEN = colors.HexColor("#F1F8E9")
_LIGHT_BLUE = colors.HexColor("#E3F2FD")

_TIER_COLORS = {
    "No Loss":    colors.HexColor("#1B5E20"),
    "Minor":      colors.HexColor("#43A047"),
    "Moderate":   colors.HexColor("#FB8C00"),
    "High":       colors.HexColor("#E53935"),
    "Severe":     colors.HexColor("#880E4F"),
    "Total Loss": colors.HexColor("#6A1B9A"),
    "Pending":    colors.HexColor("#546E7A"),
}

_MULTIPLIERS = {
    "No Loss":    0.00,
    "Minor":      0.15,
    "Moderate":   0.40,
    "High":       0.70,
    "Severe":     0.90,
    "Total Loss": 1.00,
    "Pending":    0.00,
}


def generate_pdf_report(
    claim_data: dict,
    report_data: dict,
    user_name: str = "Claimant",
) -> bytes:
    """Build and return a PDF compensation report as bytes."""
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=2 * cm,
        leftMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        "CustomTitle",
        parent=styles["Heading1"],
        fontSize=18,
        spaceAfter=4,
        textColor=_GREEN,
        alignment=TA_CENTER,
    )
    sub_style = ParagraphStyle(
        "Sub",
        parent=styles["Normal"],
        fontSize=10,
        textColor=colors.grey,
        alignment=TA_CENTER,
        spaceAfter=16,
    )
    section_style = ParagraphStyle(
        "Section",
        parent=styles["Heading2"],
        fontSize=12,
        textColor=_GREEN,
        spaceBefore=14,
        spaceAfter=6,
    )
    footer_style = ParagraphStyle(
        "Footer",
        parent=styles["Normal"],
        fontSize=8,
        textColor=colors.grey,
        alignment=TA_CENTER,
    )

    story = []

    # ── Header ────────────────────────────────────────────────────────────────
    story.append(Paragraph("LIVELIHOOD LOSS COMPENSATION REPORT", title_style))
    story.append(
        Paragraph(
            f"Generated on {datetime.now().strftime('%d %b %Y, %I:%M %p')}",
            sub_style,
        )
    )
    story.append(HRFlowable(width="100%", thickness=1.5, color=_GREEN))
    story.append(Spacer(1, 10))

    # ── Claim Information ─────────────────────────────────────────────────────
    story.append(Paragraph("Claim Information", section_style))

    claim_rows = [
        ["Field", "Details"],
        ["Claimant Name", user_name],
        ["Disaster Type", claim_data.get("disaster_type", "—")],
        ["Location", claim_data.get("location", "—")],
        ["Property Type", claim_data.get("property_type", "—")],
        ["Incident Date", claim_data.get("incident_date", "—")],
        ["Claim Status", "VERIFIED ✓"],
    ]
    _add_table(story, claim_rows, col_widths=[5 * cm, 11 * cm], header_color=_GREEN)

    # ── AI Damage Assessment ──────────────────────────────────────────────────
    story.append(Paragraph("AI Damage Assessment", section_style))

    damage_tier = report_data.get("damage_tier", "Unknown")
    sim = report_data.get("similarity_score", 0)
    loss = report_data.get("loss_percentage", 0)

    auth_score = report_data.get("authenticity_score")
    photo_verified = report_data.get("photo_verified")
    auth_row = []
    if auth_score is not None:
        verified_text = "✓ Genuine" if photo_verified else "✗ Suspicious"
        auth_row = [["Photo Authenticity", f"{verified_text} ({auth_score * 100:.1f}% match)"]]

    assessment_rows = [
        ["Metric", "Value"],
        ["Satellite Similarity Score", f"{sim * 100:.1f}%"],
        ["Estimated Loss Percentage", f"{loss:.1f}%"],
        ["Damage Tier", damage_tier],
        *auth_row,
    ]
    _add_table(
        story, assessment_rows, col_widths=[8 * cm, 8 * cm], header_color=_BLUE
    )

    # ── Compensation Calculation ───────────────────────────────────────────────
    story.append(Paragraph("Compensation Estimate", section_style))

    property_value = claim_data.get("property_value", 0)
    multiplier = _MULTIPLIERS.get(damage_tier, 0)
    compensation = report_data.get("compensation_amount", 0)

    comp_rows = [
        ["Declared Property Value", f"\u20b9 {property_value:,.0f}"],
        ["Damage Tier Multiplier", f"{multiplier * 100:.0f}%"],
        ["", ""],
        ["ESTIMATED COMPENSATION", f"\u20b9 {compensation:,.0f}"],
    ]
    comp_table = Table(comp_rows, colWidths=[10 * cm, 6 * cm])
    comp_table.setStyle(
        TableStyle(
            [
                ("FONTSIZE", (0, 0), (-1, -1), 10),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ("PADDING", (0, 0), (-1, -1), 8),
                ("ROWBACKGROUNDS", (0, 0), (-1, 2), [colors.white, _LIGHT_GREEN, colors.white]),
                ("LINEBELOW", (0, 1), (-1, 1), 0.5, colors.grey),
                ("BACKGROUND", (0, 3), (-1, 3), _GREEN),
                ("TEXTCOLOR", (0, 3), (-1, 3), colors.white),
                ("FONTNAME", (0, 3), (-1, 3), "Helvetica-Bold"),
                ("FONTSIZE", (0, 3), (-1, 3), 13),
                ("ALIGN", (1, 0), (1, -1), "RIGHT"),
            ]
        )
    )
    story.append(comp_table)

    # ── Footer ────────────────────────────────────────────────────────────────
    story.append(Spacer(1, 20))
    story.append(HRFlowable(width="100%", thickness=0.5, color=colors.lightgrey))
    story.append(Spacer(1, 6))
    story.append(
        Paragraph(
            "Auto-generated by the Livelihood Loss Compensation System · "
            "RGUKT — Department of Computer Science & Engineering",
            footer_style,
        )
    )

    doc.build(story)
    return buffer.getvalue()


def _add_table(story, rows, col_widths, header_color):
    tbl = Table(rows, colWidths=col_widths)
    tbl.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), header_color),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 10),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F5F5")]),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
                ("PADDING", (0, 0), (-1, -1), 7),
            ]
        )
    )
    story.append(tbl)
