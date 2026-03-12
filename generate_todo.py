#!/usr/bin/env python3
"""Generate TeleDesk task todo list PDF."""

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable, Table, TableStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
import os

OUTPUT = os.path.join(os.path.dirname(__file__), "TeleDesk_TODO.pdf")

# ── Colours ────────────────────────────────────────────────────────────────────
INDIGO       = colors.HexColor("#6366F1")
INDIGO_LIGHT = colors.HexColor("#EEF2FF")
INDIGO_DARK  = colors.HexColor("#4338CA")
SLATE        = colors.HexColor("#334155")
SLATE_LIGHT  = colors.HexColor("#94A3B8")
GREEN        = colors.HexColor("#10B981")
GREEN_LIGHT  = colors.HexColor("#ECFDF5")
AMBER        = colors.HexColor("#F59E0B")
AMBER_LIGHT  = colors.HexColor("#FFFBEB")
RED          = colors.HexColor("#EF4444")
RED_LIGHT    = colors.HexColor("#FEF2F2")
GRAY_LIGHT   = colors.HexColor("#F8FAFC")
BORDER       = colors.HexColor("#E2E8F0")

base = getSampleStyleSheet()

TITLE_STYLE = ParagraphStyle("Title", parent=base["Normal"],
    fontSize=28, leading=36, textColor=INDIGO, fontName="Helvetica-Bold",
    alignment=TA_CENTER, spaceAfter=4)
SUB_STYLE = ParagraphStyle("Sub", parent=base["Normal"],
    fontSize=11, leading=16, textColor=SLATE_LIGHT, fontName="Helvetica",
    alignment=TA_CENTER, spaceAfter=20)
SECTION_STYLE = ParagraphStyle("Section", parent=base["Normal"],
    fontSize=13, leading=18, textColor=INDIGO_DARK, fontName="Helvetica-Bold",
    spaceBefore=16, spaceAfter=6)
ITEM_STYLE = ParagraphStyle("Item", parent=base["Normal"],
    fontSize=9.5, leading=14, textColor=SLATE, fontName="Helvetica",
    leftIndent=0, spaceAfter=0)
NOTE_STYLE = ParagraphStyle("Note", parent=base["Normal"],
    fontSize=8, leading=12, textColor=colors.HexColor("#92400E"),
    fontName="Helvetica-Oblique",
    backColor=AMBER_LIGHT, leftIndent=6, borderPad=4, spaceAfter=4)

def hr():
    return HRFlowable(width="100%", thickness=0.5, color=INDIGO_LIGHT,
                      spaceAfter=6, spaceBefore=2)

def sp(n=8):
    return Spacer(1, n)

def section(title):
    return Paragraph(title, SECTION_STYLE)

STATUS_DONE   = ("✓", GREEN,       GREEN_LIGHT,  colors.HexColor("#166534"))
STATUS_PARTIAL= ("~", AMBER,       AMBER_LIGHT,  colors.HexColor("#92400E"))
STATUS_TODO   = ("○", SLATE_LIGHT, GRAY_LIGHT,   SLATE)

def task_row(num, text, status, note=None):
    """Build a single task row as a small Table for alignment."""
    sym, border_c, bg_c, text_c = status

    badge = ParagraphStyle("Badge", parent=base["Normal"],
        fontSize=9, fontName="Helvetica-Bold", textColor=border_c,
        alignment=TA_CENTER)
    num_style = ParagraphStyle("Num", parent=base["Normal"],
        fontSize=8.5, fontName="Helvetica-Bold", textColor=SLATE_LIGHT,
        alignment=TA_CENTER)
    item_s = ParagraphStyle("ItemRow", parent=base["Normal"],
        fontSize=9.5, leading=14, textColor=text_c, fontName="Helvetica")
    note_s = ParagraphStyle("NoteRow", parent=base["Normal"],
        fontSize=8, leading=12, textColor=colors.HexColor("#92400E"),
        fontName="Helvetica-Oblique")

    num_cell  = Paragraph(str(num), num_style)
    sym_cell  = Paragraph(sym, badge)
    if note:
        text_cell = [Paragraph(text, item_s), Spacer(1, 2), Paragraph(note, note_s)]
    else:
        text_cell = Paragraph(text, item_s)

    data = [[num_cell, sym_cell, text_cell]]
    col_widths = [1.0*cm, 0.8*cm, 13.8*cm]

    t = Table(data, colWidths=col_widths, rowHeights=None)
    t.setStyle(TableStyle([
        ("BACKGROUND",   (0, 0), (-1, -1), bg_c),
        ("ROUNDEDCORNERS", [4]),
        ("BOX",          (0, 0), (-1, -1), 0.5, border_c),
        ("VALIGN",       (0, 0), (-1, -1), "TOP"),
        ("ALIGN",        (0, 0), (0, 0),   "CENTER"),
        ("ALIGN",        (1, 0), (1, 0),   "CENTER"),
        ("TOPPADDING",   (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING",(0, 0), (-1, -1), 6),
        ("LEFTPADDING",  (0, 0), (0, 0),   6),
        ("RIGHTPADDING", (-1, 0), (-1, -1), 8),
        ("LEFTPADDING",  (2, 0), (2, 0),   8),
    ]))
    return t

# ── Tasks data ─────────────────────────────────────────────────────────────────
# (num, text, status, note_or_None)
TASKS = [
    # Project Setup
    ("PROJECT SETUP", None, None, None),
    (1,  "Rename project from flutter_project to teledesk (44 Dart files updated)", STATUS_DONE, None),
    (2,  "Add config/app_config.json with TELEGRAM_BOT_TOKEN, POLLING_TIMEOUT_SECONDS, POLLING_INTERVAL_MS", STATUS_DONE, "Gitignored — each developer provides their own bot token"),
    (3,  "Load secrets via --dart-define-from-file (Config.dart constants)", STATUS_DONE, None),
    (4,  "Add dependencies: drift, control, octopus, freezed, file_picker, image_picker, cached_network_image, flutter_local_notifications, crypto, http", STATUS_DONE, None),

    # Database
    ("DATABASE & MODELS", None, None, None),
    (5,  "Workers table — id, username, passwordHash, displayName, role, colorCode, status, isActive, createdAt, updatedAt", STATUS_DONE, None),
    (6,  "Conversations table — id, telegramUserId (UNIQUE), status (open/in_progress/finish_requested/finished), assignedWorkerId, canUserFinish, unreadCount, lastMessageAt, lastMessagePreview", STATUS_DONE, None),
    (7,  "Messages table — id, conversationId, messageType, messageText, fileId, fileName, fileMimeType, isFromBot, isNote, sentByWorkerId, isRead, sentAt", STATUS_DONE, None),
    (8,  "QuickReplies table — id, title, content, createdByWorkerId", STATUS_DONE, None),
    (9,  "BotSettings table — key-value store for welcome_message, auto_reply, description, short_description", STATUS_DONE, None),
    (10, "Drift database with schemaVersion 2 and migration strategy", STATUS_DONE, None),

    # Authentication
    ("AUTHENTICATION", None, None, None),
    (11, "SHA-256 password hashing via CryptoUtil", STATUS_DONE, None),
    (12, "First-launch admin account creation (signup screen)", STATUS_DONE, None),
    (13, "Worker login screen with username + password", STATUS_DONE, None),
    (14, "AuthenticationController with states: idle, inProgress, authenticated, needsSetup, error", STATUS_DONE, None),
    (15, "AuthenticationScope InheritedWidget — workerOf(), controllerOf()", STATUS_DONE, None),
    (16, "Auto-login on app open (persist session across restarts)", STATUS_DONE, None),
    (17, "Auto-logout when app is paused or detached (WidgetsBindingObserver)", STATUS_DONE, None),
    (18, "Separate admin and worker roles with role-based UI differences", STATUS_DONE, None),

    # Routing
    ("ROUTING & NAVIGATION", None, None, None),
    (19, "Octopus declarative router with named routes: signin, signup, dashboard, chats, conversation, botSettings, workers, settings", STATUS_DONE, None),
    (20, "AuthenticationGuard — redirect unauthenticated users to signin, new installs to signup", STATUS_DONE, None),
    (21, "Responsive navigation: NavigationRail (desktop/tablet) and NavigationBar (mobile)", STATUS_DONE, None),
    (22, "Open-chat count badge on Chats nav item", STATUS_DONE, None),

    # Telegram Integration
    ("TELEGRAM INTEGRATION", None, None, None),
    (23, "TelegramRepositoryImpl — direct HTTP calls to Telegram Bot API", STATUS_DONE, None),
    (24, "Long-polling getUpdates loop (30s timeout, 500ms interval) via TelegramPollingController", STATUS_DONE, None),
    (25, "Incoming message processing: create/find conversation, save message to DB", STATUS_DONE, None),
    (26, "Handle /cancel command from user (if canUserFinish = true, finish the conversation)", STATUS_DONE, None),
    (27, "Send text messages via bot identity", STATUS_DONE, None),
    (28, "Send photos, videos, documents, audio via multipart upload", STATUS_DONE, None),
    (29, "Send media by Telegram file_id (resend without re-upload)", STATUS_DONE, None),
    (30, "Polling starts/stops with authentication state (AuthenticationScope)", STATUS_DONE, None),

    # Chats Feature
    ("CHATS LIST FEATURE", None, None, None),
    (31, "Open Queue tab — all unassigned conversations visible to all workers", STATUS_DONE, None),
    (32, "My Chats tab — conversations assigned to the logged-in worker", STATUS_DONE, None),
    (33, "Chat claiming: opening a conversation locks it to that worker (status → in_progress)", STATUS_DONE, None),
    (34, "Reactive conversation list via Drift watchConversations() streams", STATUS_DONE, None),
    (35, "Last message preview, unread count badge, timestamp on each chat tile", STATUS_DONE, None),
    (36, "Responsive layout: two-panel desktop, push navigation on mobile", STATUS_DONE, None),

    # Conversation Feature
    ("CONVERSATION / CHAT VIEW", None, None, None),
    (37, "Message bubbles — user messages (left) and bot/worker messages (right)", STATUS_DONE, None),
    (38, "Rich message display: text, images, videos, documents, audio, stickers", STATUS_DONE, None),
    (39, "Message input bar with send button and file attachment picker", STATUS_DONE, None),
    (40, "Internal notes — leave team-only notes on a conversation (visually distinct)", STATUS_DONE, None),
    (41, "Quick replies — type # to search saved templates and insert", STATUS_DONE, None),
    (42, "Allow User to Finish action — sets canUserFinish = true, status → finish_requested", STATUS_DONE, None),
    (43, "Finish Chat action — closes conversation (status → finished)", STATUS_DONE, None),
    (44, "Chat transfer — reassign conversation to another worker", STATUS_DONE, None),
    (45, "Real-time message updates via Drift watchMessages() stream", STATUS_DONE, None),

    # Dashboard
    ("DASHBOARD", None, None, None),
    (46, "Live stats: open chats, in-progress chats, finished today, total messages", STATUS_DONE, None),

    # Quick Replies
    ("QUICK REPLIES", None, None, None),
    (47, "Quick replies CRUD — create, edit, delete saved reply templates", STATUS_DONE, None),
    (48, "# trigger in message input to open quick reply search popup", STATUS_DONE, None),
    (49, "Reactive quick replies list via watchAll() stream", STATUS_DONE, None),

    # Bot Settings
    ("BOT SETTINGS", None, None, None),
    (50, "Set bot commands (/start, /help, /status, /cancel + custom) from within the app", STATUS_DONE, None),
    (51, "Set welcome message sent when user starts a conversation", STATUS_DONE, None),
    (52, "Set auto-reply message", STATUS_DONE, None),
    (53, "Set bot description and short description via Telegram API", STATUS_DONE, None),

    # Worker Management
    ("WORKER MANAGEMENT", None, None, None),
    (54, "Worker list screen — view all workers with role and status", STATUS_DONE, None),
    (55, "Add new worker (admin only) with username, display name, role, password", STATUS_DONE, None),
    (56, "Change worker password", STATUS_DONE, None),
    (57, "Deactivate/reactivate worker accounts", STATUS_DONE, None),

    # Settings & Theme
    ("SETTINGS & THEME", None, None, None),
    (58, "Light / Dark theme toggle persisted to SharedPreferences", STATUS_DONE, None),
    (59, "Material 3 design with Indigo (#6366F1) primary seed color", STATUS_DONE, None),
    (60, "App info screen (version, OS, open-source notice)", STATUS_DONE, None),
    (61, "macOS sandbox entitlements for file picker access", STATUS_DONE, None),

    # Documentation
    ("DOCUMENTATION", None, None, None),
    (62, "README.md — setup guide, architecture overview, chat lifecycle, bot commands, backend export instructions", STATUS_DONE, None),
    (63, "TeleDesk_Developer_Documentation.pdf — 18-section technical PDF for developer handoff", STATUS_DONE, None),

    # Pending / Remaining
    ("PENDING / NOT YET IMPLEMENTED", None, None, None),
    (64, "Broadcast message — send a message to all users who have ever started a conversation (admin only)", STATUS_TODO, "Repository method planned; UI screen not yet built"),
    (65, "Desktop notifications — wire flutter_local_notifications to polling controller for new message alerts", STATUS_TODO, "Package added to pubspec but not connected"),
    (66, "Conversation search UI — search bar wired to searchConversations() repository method", STATUS_TODO, "Repository method exists; UI not built"),
    (67, "Working hours / availability schedule — configure hours when bot auto-replies vs. live agent", STATUS_TODO, "Requested feature; not yet implemented"),
]

# ── Build document ─────────────────────────────────────────────────────────────
doc = SimpleDocTemplate(
    OUTPUT,
    pagesize=A4,
    leftMargin=2*cm, rightMargin=2*cm,
    topMargin=2*cm, bottomMargin=2*cm,
    title="TeleDesk — Task List",
    author="TeleDesk",
)

story = []

# Cover header
story.append(sp(20))
story.append(Paragraph("TeleDesk", TITLE_STYLE))
story.append(Paragraph("Complete Task List", SUB_STYLE))
story.append(Paragraph("All features requested and their current implementation status", ParagraphStyle(
    "Desc", parent=base["Normal"], fontSize=9, leading=14, textColor=SLATE_LIGHT,
    alignment=TA_CENTER, spaceAfter=4)))
story.append(sp(6))
story.append(hr())
story.append(sp(10))

# Legend
legend_title = ParagraphStyle("LegTitle", parent=base["Normal"],
    fontSize=9, fontName="Helvetica-Bold", textColor=SLATE, alignment=TA_CENTER)
legend_item  = ParagraphStyle("LegItem",  parent=base["Normal"],
    fontSize=8.5, fontName="Helvetica", textColor=SLATE, alignment=TA_CENTER)

legend_data = [[
    Paragraph("✓  Done", ParagraphStyle("L1", parent=base["Normal"],
        fontSize=9, fontName="Helvetica-Bold", textColor=GREEN, alignment=TA_CENTER)),
    Paragraph("~  Partial", ParagraphStyle("L2", parent=base["Normal"],
        fontSize=9, fontName="Helvetica-Bold", textColor=AMBER, alignment=TA_CENTER)),
    Paragraph("○  Not done", ParagraphStyle("L3", parent=base["Normal"],
        fontSize=9, fontName="Helvetica-Bold", textColor=SLATE_LIGHT, alignment=TA_CENTER)),
]]
legend_table = Table(legend_data, colWidths=[5.27*cm, 5.27*cm, 5.27*cm])
legend_table.setStyle(TableStyle([
    ("BACKGROUND",    (0, 0), (0, 0), GREEN_LIGHT),
    ("BACKGROUND",    (1, 0), (1, 0), AMBER_LIGHT),
    ("BACKGROUND",    (2, 0), (2, 0), GRAY_LIGHT),
    ("BOX",           (0, 0), (0, 0), 0.5, GREEN),
    ("BOX",           (1, 0), (1, 0), 0.5, AMBER),
    ("BOX",           (2, 0), (2, 0), 0.5, SLATE_LIGHT),
    ("TOPPADDING",    (0, 0), (-1, -1), 6),
    ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ("LEFTPADDING",   (0, 0), (-1, -1), 10),
    ("RIGHTPADDING",  (0, 0), (-1, -1), 10),
    ("INNERGRID",     (0, 0), (-1, -1), 0, colors.white),
    ("COLPADDING",    (0, 0), (-1, -1), 4),
]))
story.append(legend_table)
story.append(sp(16))

# Tasks
current_section = None
for row in TASKS:
    num, text, status, note = row
    if status is None:
        # Section header — section name is stored in num
        story.append(sp(4))
        story.append(Paragraph(num, SECTION_STYLE))
        story.append(hr())
    else:
        story.append(task_row(num, text, status, note))
        story.append(sp(4))

# Summary footer
story.append(sp(16))
story.append(hr())

done_count    = sum(1 for r in TASKS if r[2] == STATUS_DONE)
partial_count = sum(1 for r in TASKS if r[2] == STATUS_PARTIAL)
todo_count    = sum(1 for r in TASKS if r[2] == STATUS_TODO)
total         = done_count + partial_count + todo_count

summary_style = ParagraphStyle("Sum", parent=base["Normal"],
    fontSize=9, leading=14, textColor=SLATE, alignment=TA_CENTER)
story.append(Paragraph(
    f"<b>{done_count}</b> completed &nbsp;·&nbsp; "
    f"<b>{partial_count}</b> partial &nbsp;·&nbsp; "
    f"<b>{todo_count}</b> remaining &nbsp;·&nbsp; "
    f"<b>{total}</b> total tasks",
    summary_style))

doc.build(story)
print(f"✅  PDF generated: {OUTPUT}")
