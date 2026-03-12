#!/usr/bin/env python3
"""Generate TeleDesk developer documentation PDF using ReportLab."""

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.units import cm, mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak, Preformatted, KeepTogether
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os

# ── Output path ────────────────────────────────────────────────────────────────
OUTPUT = os.path.join(os.path.dirname(__file__), "TeleDesk_Developer_Documentation.pdf")

# ── Colours ────────────────────────────────────────────────────────────────────
INDIGO       = colors.HexColor("#6366F1")
INDIGO_LIGHT = colors.HexColor("#EEF2FF")
INDIGO_DARK  = colors.HexColor("#4338CA")
SLATE        = colors.HexColor("#334155")
SLATE_LIGHT  = colors.HexColor("#94A3B8")
BG_CODE      = colors.HexColor("#1E293B")
BG_CODE_TEXT = colors.HexColor("#E2E8F0")
BG_TABLE_HDR = colors.HexColor("#6366F1")
BG_TABLE_ALT = colors.HexColor("#F8FAFC")
AMBER        = colors.HexColor("#F59E0B")
GREEN        = colors.HexColor("#10B981")
RED          = colors.HexColor("#EF4444")
BLUE         = colors.HexColor("#3B82F6")

PAGE_W, PAGE_H = A4
MARGIN = 2 * cm

# ── Styles ─────────────────────────────────────────────────────────────────────
base = getSampleStyleSheet()

def style(name, parent="Normal", **kw):
    return ParagraphStyle(name, parent=base[parent], **kw)

COVER_TITLE  = style("CoverTitle",  fontSize=36, leading=44, textColor=INDIGO,      alignment=TA_CENTER, fontName="Helvetica-Bold",  spaceAfter=8)
COVER_SUB    = style("CoverSub",    fontSize=16, leading=24, textColor=SLATE,       alignment=TA_CENTER, fontName="Helvetica",        spaceAfter=6)
COVER_SMALL  = style("CoverSmall",  fontSize=10, leading=14, textColor=SLATE_LIGHT, alignment=TA_CENTER, fontName="Helvetica")

H1           = style("H1",  parent="Heading1", fontSize=20, leading=26, textColor=INDIGO,  fontName="Helvetica-Bold",  spaceBefore=20, spaceAfter=8,  borderPad=4)
H2           = style("H2",  parent="Heading2", fontSize=14, leading=20, textColor=INDIGO_DARK, fontName="Helvetica-Bold",  spaceBefore=14, spaceAfter=6)
H3           = style("H3",  parent="Heading3", fontSize=11, leading=16, textColor=SLATE,   fontName="Helvetica-Bold",  spaceBefore=10, spaceAfter=4)
BODY         = style("Body", fontSize=9.5, leading=15, textColor=SLATE, alignment=TA_JUSTIFY, spaceAfter=4)
BODY_BOLD    = ParagraphStyle("BodyBold", parent=BODY, fontName="Helvetica-Bold", textColor=SLATE)
BULLET       = ParagraphStyle("Bullet",   parent=BODY, leftIndent=16, bulletIndent=6, spaceAfter=3)
CODE_STYLE   = style("Code", fontName="Courier", fontSize=7.8, leading=11, textColor=BG_CODE_TEXT,
                     backColor=BG_CODE, leftIndent=8, rightIndent=8, borderPad=6,
                     spaceAfter=8, spaceBefore=4)
LABEL_INDIGO = style("LabelIndigo", fontName="Helvetica-Bold", fontSize=8, textColor=colors.white,
                     backColor=INDIGO, borderPad=3, spaceAfter=2)
NOTE_STYLE   = style("Note", fontSize=8.5, leading=13, textColor=colors.HexColor("#92400E"),
                     backColor=colors.HexColor("#FFFBEB"), leftIndent=10, borderPad=5, spaceAfter=6)

def h1(t): return Paragraph(t, H1)
def h2(t): return Paragraph(t, H2)
def h3(t): return Paragraph(t, H3)
def p(t):  return Paragraph(t, BODY)
def pb(t): return Paragraph(t, BODY_BOLD)
def sp(n=6): return Spacer(1, n)
def hr(): return HRFlowable(width="100%", thickness=0.5, color=INDIGO_LIGHT, spaceAfter=6, spaceBefore=4)
def note(t): return Paragraph(f"<b>Note:</b> {t}", NOTE_STYLE)

def code(text):
    return Preformatted(text.strip(), CODE_STYLE)

def bullet(items):
    return [Paragraph(f"• {i}", BULLET) for i in items]

def table(headers, rows, col_widths=None):
    data = [[Paragraph(str(h), style("TH", fontName="Helvetica-Bold", fontSize=8.5,
                                      textColor=colors.white)) for h in headers]]
    for i, row in enumerate(rows):
        styled = [Paragraph(str(c), style(f"TD{i}", fontSize=8, leading=12, textColor=SLATE)) for c in row]
        data.append(styled)
    usable = PAGE_W - 2 * MARGIN
    if col_widths is None:
        col_widths = [usable / len(headers)] * len(headers)
    t = Table(data, colWidths=col_widths, repeatRows=1)
    row_bg = [(i % 2 == 0 and BG_TABLE_ALT or colors.white) for i in range(len(rows))]
    style_cmds = [
        ("BACKGROUND", (0, 0), (-1, 0), BG_TABLE_HDR),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [BG_TABLE_ALT, colors.white]),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E2E8F0")),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ]
    t.setStyle(TableStyle(style_cmds))
    return t

# ── Build story ────────────────────────────────────────────────────────────────
def build():
    story = []
    usable_w = PAGE_W - 2 * MARGIN

    # ── Cover page ──────────────────────────────────────────────────────────────
    story += [
        Spacer(1, 3*cm),
        Paragraph("TeleDesk", COVER_TITLE),
        Paragraph("Developer Documentation", COVER_SUB),
        Spacer(1, 0.4*cm),
        HRFlowable(width="60%", thickness=2, color=INDIGO, hAlign="CENTER", spaceAfter=12),
        Paragraph("Telegram Bot Admin Panel — Flutter Application", COVER_SUB),
        Spacer(1, 1.5*cm),
        Paragraph("Complete architecture reference for contributors and maintainers", COVER_SMALL),
        Spacer(1, 0.6*cm),
        Paragraph("March 2026 · v0.0.1", COVER_SMALL),
        PageBreak(),
    ]

    # ── 1. Overview ─────────────────────────────────────────────────────────────
    story += [h1("1. Project Overview"), hr()]
    story += [p(
        "TeleDesk is an open-source Flutter application that turns a Telegram Bot into a full "
        "customer support platform. End-users chat with your bot through the standard Telegram app; "
        "your support team manages and replies to those conversations through the TeleDesk admin panel. "
        "All replies are sent on behalf of the bot, so the user always sees a single unified identity."
    ), sp()]
    story += bullet([
        "<b>Multi-worker</b> — Admin and worker roles, each with a separate login",
        "<b>Chat queue</b> — Open chats visible to everyone; claimed chats locked to one worker",
        "<b>Rich messaging</b> — Text, photos, videos, GIFs, stickers, documents, audio, voice, video notes",
        "<b>Quick replies</b> — Type <font face='Courier'>#</font> to search saved reply templates",
        "<b>Internal notes</b> — Amber-coloured team-only messages, invisible to the Telegram user",
        "<b>Chat transfer</b> — Reassign any conversation to another worker",
        "<b>Bot configuration</b> — Set commands, welcome message, auto-reply, description from inside the app",
        "<b>Dashboard</b> — Live stats: open, in-progress, finished today, total messages",
        "<b>Light / Dark theme</b> — Material 3, persisted via SharedPreferences",
        "<b>Responsive</b> — Desktop two-panel rail, tablet adapted, mobile bottom-nav + push navigation",
        "<b>Auto-logout</b> — Signs out when app is paused or detached (WidgetsBindingObserver)",
        "<b>Backend-ready</b> — Every repository sits behind an interface; swap SQLite for REST with zero UI changes",
    ])
    story.append(sp(12))

    # ── 2. Tech Stack ────────────────────────────────────────────────────────────
    story += [h1("2. Technology Stack"), hr()]
    story += [h2("Core Packages")]
    story.append(table(
        ["Package", "Version", "Purpose"],
        [
            ["flutter / dart", "^3.38.3 / ^3.10.1", "Framework & language"],
            ["octopus", "^0.0.9", "Declarative URL-based router with guards"],
            ["control", "^0.2.0", "StateController base class for BLoC-style controllers"],
            ["freezed_annotation + freezed", "^3.1.0", "Sealed / union state classes (code-generated)"],
            ["drift + drift_flutter", "^2.28.2 / ^0.2.7", "SQLite ORM with reactive Dart streams"],
            ["sqlite3_flutter_libs", "^0.5.30", "Bundled SQLite native libraries"],
            ["shared_preferences", "^2.5.4", "Lightweight key-value store (theme mode)"],
            ["http", "^1.3.0", "HTTP client for Telegram Bot API calls"],
            ["telegram", "^1.0.0", "Telegram Bot API wrapper (MIT, 2025)"],
            ["crypto", "^3.0.6", "SHA-256 password hashing"],
            ["file_picker", "^10.1.9", "Cross-platform file selection for media sending"],
            ["image_picker", "^1.1.2", "Mobile camera / gallery access"],
            ["cached_network_image", "^3.4.1", "Network image widget with caching"],
            ["flutter_local_notifications", "^19.0.0", "Desktop / mobile notifications (wired in future)"],
            ["rxdart", "^0.28.0", "Reactive stream extensions (log buffering)"],
            ["intl", "any", "Date / time formatting"],
            ["l", "^5.0.0", "Structured logging"],
            ["platform_info", "^5.0.0", "Runtime platform & OS information"],
            ["window_manager", "^0.5.1", "Desktop window title / size control"],
        ],
        col_widths=[usable_w*0.28, usable_w*0.18, usable_w*0.54],
    ))
    story.append(sp(8))

    story += [h2("Dev / Code-generation Packages")]
    story += bullet([
        "<font face='Courier'>build_runner ^2.5.4</font> — Runs all code generators",
        "<font face='Courier'>drift_dev ^2.30.0</font> — Generates Drift query code from table definitions",
        "<font face='Courier'>freezed ^3.1.0</font> — Generates sealed state classes",
        "<font face='Courier'>json_serializable ^6.9.5</font> — JSON serialisation",
        "<font face='Courier'>flutter_gen_runner ^5.9.0</font> — Typed asset references",
        "<font face='Courier'>pubspec_generator ^5.0.0</font> — Typed pubspec access",
    ])
    story.append(sp(6))
    story.append(note(
        "After modifying any Drift table or adding a @freezed class, run: "
        "dart run build_runner build --delete-conflicting-outputs"
    ))
    story.append(PageBreak())

    # ── 3. Configuration ─────────────────────────────────────────────────────────
    story += [h1("3. Configuration & Secrets"), hr()]
    story += [p(
        "Secrets are loaded at compile time via Flutter's <font face='Courier'>--dart-define-from-file</font> flag. "
        "The file is <b>gitignored</b> and must be created manually by each developer."
    ), sp(6)]
    story += [h2("config/app_config.json")]
    story.append(code("""{
  "TELEGRAM_BOT_TOKEN": "YOUR_BOT_TOKEN_HERE",
  "POLLING_TIMEOUT_SECONDS": 30,
  "POLLING_INTERVAL_MS": 500
}"""))
    story += [h2("Run Command")]
    story.append(code("flutter run --dart-define-from-file=config/app_config.json"))
    story += [h2("Config Class (lib/src/common/constant/config.dart)")]
    story += [p("The <font face='Courier'>Config</font> abstract class exposes compile-time constants:")]
    story += bullet([
        "<font face='Courier'>Config.telegramBotToken</font> — Bot API token (String)",
        "<font face='Courier'>Config.pollingTimeoutSeconds</font> — Long-poll wait time, default 30 (int)",
        "<font face='Courier'>Config.pollingIntervalMs</font> — Retry delay between polls, default 500 (int)",
        "<font face='Courier'>Config.environment</font> — development / production (EnvironmentFlavor enum)",
        "<font face='Courier'>Config.databaseName</font> — SQLite filename, default 'teledesk_db' (String)",
        "<font face='Courier'>Config.inMemoryDatabase</font> — Use in-memory DB for testing (bool)",
    ])
    story.append(sp(8))
    story.append(note(
        "TELEGRAM_BOT_TOKEN defaults to an empty string. If no token is supplied "
        "all Telegram API calls will fail silently (getUpdates returns empty list). "
        "The app still launches and local features work."
    ))
    story.append(PageBreak())

    # ── 4. Database Schema ───────────────────────────────────────────────────────
    story += [h1("4. Database Schema (Drift / SQLite)"), hr()]
    story += [p(
        "The app uses a local SQLite database (via Drift) at schema version <b>2</b>. "
        "All repositories operate through interfaces, making it straightforward to swap "
        "the implementation for a remote backend. Each table below maps directly to a Drift "
        "<font face='Courier'>Table</font> class in <font face='Courier'>lib/src/common/database/tables/</font>."
    ), sp(6)]

    story += [h2("workers"), hr()]
    story.append(table(
        ["Column", "Type", "Constraints / Default", "Notes"],
        [
            ["id", "INTEGER", "PK, AutoIncrement", ""],
            ["username", "TEXT", "Unique, 1–50 chars", "Login identifier"],
            ["passwordHash", "TEXT", "NOT NULL", "SHA-256 hex string"],
            ["displayName", "TEXT", "1–100 chars", "Shown in UI"],
            ["role", "TEXT", "Default: 'worker'", "'admin' or 'worker'"],
            ["colorCode", "TEXT", "Default: '#2196F3'", "Hex colour for avatar"],
            ["status", "TEXT", "Default: 'offline'", "'online' 'away' 'busy' 'offline'"],
            ["isActive", "BOOL", "Default: true", "Soft-delete flag"],
            ["createdAt", "INTEGER", "NOT NULL", "Unix timestamp"],
            ["updatedAt", "INTEGER", "NOT NULL", "Unix timestamp"],
        ],
        col_widths=[usable_w*0.2, usable_w*0.12, usable_w*0.28, usable_w*0.4],
    ))
    story.append(sp(10))

    story += [h2("conversations"), hr()]
    story.append(table(
        ["Column", "Type", "Constraints / Default", "Notes"],
        [
            ["id", "INTEGER", "PK, AutoIncrement", ""],
            ["telegramUserId", "INTEGER", "UNIQUE, NOT NULL", "Telegram chat_id"],
            ["telegramUsername", "TEXT", "Nullable", "@username if set"],
            ["firstName", "TEXT", "Nullable", ""],
            ["lastName", "TEXT", "Nullable", ""],
            ["status", "TEXT", "Default: 'open'", "'open' 'in_progress' 'finish_requested' 'finished'"],
            ["assignedWorkerId", "INTEGER", "FK → workers.id, Nullable", "Set when claimed"],
            ["canUserFinish", "BOOL", "Default: false", "Unlocks /cancel for user"],
            ["unreadCount", "INTEGER", "Default: 0", "Unread messages count"],
            ["lastMessageAt", "INTEGER", "NOT NULL", "Unix timestamp"],
            ["lastMessagePreview", "TEXT", "Nullable", "Truncated preview"],
            ["createdAt", "INTEGER", "NOT NULL", ""],
            ["updatedAt", "INTEGER", "NOT NULL", ""],
        ],
        col_widths=[usable_w*0.22, usable_w*0.12, usable_w*0.28, usable_w*0.38],
    ))
    story.append(sp(10))

    story += [h2("messages"), hr()]
    story.append(table(
        ["Column", "Type", "Constraints / Default", "Notes"],
        [
            ["id", "INTEGER", "PK, AutoIncrement", ""],
            ["conversationId", "INTEGER", "FK → conversations.id", ""],
            ["telegramMessageId", "INTEGER", "Nullable", "Null for notes & outgoing"],
            ["messageType", "TEXT", "NOT NULL", "'text' 'photo' 'video' 'gif' 'sticker' 'document' 'voice' 'video_note' 'audio' 'note'"],
            ["messageText", "TEXT", "Nullable", "Text or caption"],
            ["fileId", "TEXT", "Nullable", "Telegram file_id for re-sending"],
            ["fileName", "TEXT", "Nullable", "Original file name"],
            ["fileMimeType", "TEXT", "Nullable", "e.g. video/mp4"],
            ["fileSize", "INTEGER", "Nullable", "Bytes"],
            ["isFromBot", "BOOL", "Default: false", "True = admin/worker sent it"],
            ["isNote", "BOOL", "Default: false", "True = internal note only"],
            ["sentByWorkerId", "INTEGER", "FK → workers.id, Nullable", "Which worker sent it"],
            ["isRead", "BOOL", "Default: false", ""],
            ["sentAt", "INTEGER", "NOT NULL", "Unix timestamp"],
            ["createdAt", "INTEGER", "NOT NULL", ""],
        ],
        col_widths=[usable_w*0.22, usable_w*0.12, usable_w*0.24, usable_w*0.42],
    ))
    story.append(sp(10))

    story += [h2("quick_replies"), hr()]
    story.append(table(
        ["Column", "Type", "Constraints / Default", "Notes"],
        [
            ["id", "INTEGER", "PK, AutoIncrement", ""],
            ["title", "TEXT", "1–100 chars", "Shown in # picker"],
            ["content", "TEXT", "NOT NULL", "Full reply text"],
            ["createdByWorkerId", "INTEGER", "FK → workers.id, Nullable", ""],
            ["createdAt", "INTEGER", "NOT NULL", ""],
            ["updatedAt", "INTEGER", "NOT NULL", ""],
        ],
        col_widths=[usable_w*0.22, usable_w*0.12, usable_w*0.28, usable_w*0.38],
    ))
    story.append(sp(10))

    story += [h2("bot_settings"), hr()]
    story.append(table(
        ["Column", "Type", "Constraints", "Known Keys"],
        [
            ["key", "TEXT", "PRIMARY KEY", "'welcome_message' 'auto_reply' 'description' 'short_description'"],
            ["value", "TEXT", "NOT NULL", ""],
            ["updatedAt", "INTEGER", "NOT NULL", ""],
        ],
        col_widths=[usable_w*0.18, usable_w*0.1, usable_w*0.2, usable_w*0.52],
    ))
    story.append(PageBreak())

    # ── 5. Architecture ──────────────────────────────────────────────────────────
    story += [h1("5. Architecture & Patterns"), hr()]
    story += [h2("Layer Structure (per feature)")]
    story.append(code("""lib/src/feature/<feature_name>/
  ├── controller/    # StateController subclasses + freezed states
  ├── data/          # Repository interfaces + SQLite/HTTP implementations
  ├── model/         # Plain Dart models (immutable, copyWith)
  └── widget/
        ├── desktop/ # Widget for >= 1024 dp
        ├── tablet/  # Widget for 600-1023 dp  (shares desktop where identical)
        ├── mobile/  # Widget for <= 600 dp
        └── <feature>_config_widget.dart   # Init + InheritedWidget injection"""))
    story.append(sp(6))

    story += [h2("Key Architectural Rules")]
    story += bullet([
        "<b>Controllers</b> extend <font face='Courier'>StateController&lt;State&gt;</font> from the <font face='Courier'>control</font> package. "
        "Use <font face='Courier'>SequentialControllerHandler</font> (queue operations) or "
        "<font face='Courier'>DroppableControllerHandler</font> (drop if busy).",
        "<b>States</b> are <font face='Courier'>@freezed</font> sealed classes — generated by build_runner. "
        "Each state variant is a separate factory constructor.",
        "<b>UI state</b> (selected tab, search query, quick-reply filter) uses plain <font face='Courier'>ChangeNotifier</font> "
        "in a separate data controller, not in the main StateController.",
        "<b>InheritedWidget</b> propagates dependencies. Each config widget creates an InheritedWidget "
        "so its children can call <font face='Courier'>ChatsInhWidget.of(context)</font> etc.",
        "<b>Never call dependOnInheritedWidgetOfExactType in initState()</b> — use "
        "<font face='Courier'>didChangeDependencies()</font> with an <font face='Courier'>_initialized</font> guard flag.",
        "<b>DependenciesScope</b> uses <font face='Courier'>getElementForInheritedWidgetOfExactType</font> "
        "(non-subscribing lookup) — safe in initState.",
        "<b>Responsive layout</b> is handled via <font face='Courier'>context.screenSizeMaybeWhen()</font> "
        "extension on BuildContext.",
        "<b>copyWith on nullable fields</b> uses <font face='Courier'>ValueGetter&lt;T?&gt;</font> pattern to "
        "distinguish between 'set to null' and 'keep existing value'.",
    ])
    story.append(sp(8))

    story += [h2("Dependency Injection Flow")]
    story.append(code("""main.dart
  └─ appZone() → $initializeDependencies()
       └─ creates Dependencies object (all repos + controllers)
            └─ DependenciesScope.inject(child: App())
                 └─ SettingsScope (theme)
                      └─ MaterialApp.router
                           └─ AuthenticationScope (auth state + polling)
                                └─ Screen widgets
                                     └─ Dependencies.of(context)  ← read anywhere"""))
    story.append(PageBreak())

    # ── 6. Authentication ────────────────────────────────────────────────────────
    story += [h1("6. Authentication Flow"), hr()]
    story += [p(
        "Authentication is entirely local — no external auth service. "
        "Workers are stored in the SQLite database with SHA-256 hashed passwords. "
        "The <font face='Courier'>AuthenticationController</font> uses <font face='Courier'>DroppableControllerHandler</font> "
        "(drops if a call is already in progress)."
    ), sp(6)]

    story += [h2("AuthenticationState (Freezed)")]
    story.append(code("""idle()              — no session, show sign-in
inProgress()        — async operation running
error(String?)      — login failed, message shown in SnackBar
authenticated(Worker) — active session, polling running
needsSetup()        — zero workers in DB, show first-admin form"""))
    story.append(sp(6))

    story += [h2("State Transitions")]
    story.append(table(
        ["Event / Action", "From", "To", "Side-effect"],
        [
            ["App launches → checkSetup()", "idle", "inProgress → idle or needsSetup", "Count workers in DB"],
            ["User submits sign-in form → signIn()", "idle / error", "inProgress → authenticated or error", "Hash password, query DB"],
            ["Admin fills setup form → createFirstAdmin()", "needsSetup", "inProgress → authenticated", "Insert admin worker, status=online"],
            ["Auto-logout (app paused/detached)", "authenticated", "idle", "Update status=offline in DB, stop polling"],
            ["Manual sign out → signOut()", "authenticated", "idle", "Update status=offline in DB, stop polling"],
            ["Sign-in credentials wrong", "inProgress", "error('Invalid...')", "—"],
        ],
        col_widths=[usable_w*0.3, usable_w*0.15, usable_w*0.25, usable_w*0.3],
    ))
    story.append(sp(8))

    story += [h2("AuthenticationScope")]
    story += [p(
        "<font face='Courier'>AuthenticationScope</font> is an InheritedWidget wrapper that "
        "sits above <font face='Courier'>MaterialApp</font>. It listens to the controller and:"
    )]
    story += bullet([
        "Calls <font face='Courier'>TelegramPollingController.startPolling()</font> when authenticated",
        "Calls <font face='Courier'>TelegramPollingController.stopPolling()</font> when idle/error",
        "Exposes <font face='Courier'>AuthenticationScope.workerOf(context)</font> (subscribing)",
        "Exposes <font face='Courier'>AuthenticationScope.controllerOf(context)</font> (non-subscribing)",
        "Triggers <font face='Courier'>controller.checkSetup()</font> on first mount",
    ])
    story.append(sp(8))

    story += [h2("Password Hashing (CryptoUtil)")]
    story.append(code("""// lib/src/common/util/crypto_util.dart
static String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);   // dart:crypto
  return digest.toString();               // 64-char hex string
}
static bool verifyPassword(String password, String hash) =>
    hashPassword(password) == hash;"""))
    story.append(PageBreak())

    # ── 7. Telegram Layer ────────────────────────────────────────────────────────
    story += [h1("7. Telegram Integration"), hr()]
    story += [p(
        "TeleDesk communicates with Telegram via the "
        "<b>Telegram Bot API</b> (<font face='Courier'>api.telegram.org</font>). "
        "All calls use the standard <font face='Courier'>http</font> package — no webhook server required. "
        "The <font face='Courier'>telegram ^1.0.0</font> package is listed as a dependency but the core "
        "integration is implemented directly in <font face='Courier'>TelegramRepositoryImpl</font> "
        "for full control over multipart uploads and long-polling."
    ), sp(6)]

    story += [h2("ITelegramRepository — Interface Methods")]
    story.append(table(
        ["Method", "Description"],
        [
            ["getUpdates(offset, timeoutSeconds)", "Long-poll for updates. Returns [] on timeout or error. Never throws."],
            ["sendMessage(chatId, text, parseMode?)", "Send plain text or HTML/Markdown formatted message"],
            ["sendPhoto(chatId, photoBytes, fileName?, caption?)", "Multipart upload — send image from device"],
            ["sendPhotoByFileId(chatId, fileId, caption?)", "Re-send photo already on Telegram servers"],
            ["sendVideoByFileId(chatId, fileId, caption?)", "Re-send video using Telegram file_id"],
            ["sendDocument(chatId, fileBytes, fileName, caption?)", "Multipart upload — send any file type"],
            ["sendDocumentByFileId(chatId, fileId, fileName?, caption?)", "Re-send document using file_id"],
            ["sendMediaByFileId(chatId, fileId, messageType, caption?)", "Smart dispatch: maps type → correct API method"],
            ["setMyCommands(commands)", "Push List<BotCommand> to Telegram (visible in bot menu)"],
            ["getMyCommands()", "Fetch current commands from Telegram API"],
            ["setMyDescription(description)", "Set long bot description visible in profile"],
            ["setMyShortDescription(shortDescription)", "Set short description shown before /start"],
            ["getMe()", "Returns Map with bot info (id, username, name)"],
            ["deleteMessage(chatId, messageId)", "Delete a previously sent message"],
            ["sendChatAction(chatId, action)", "Send typing / upload_photo / etc. indicator"],
            ["getFileUrl(fileId)", "Returns full download URL for a Telegram file_id"],
        ],
        col_widths=[usable_w*0.42, usable_w*0.58],
    ))
    story.append(sp(10))

    story += [h2("TelegramPollingController — Long-Poll Loop")]
    story += [p(
        "The polling controller manages a continuous background loop. "
        "It is a <font face='Courier'>ChangeNotifier</font> (not a StateController) so the UI "
        "can listen with <font face='Courier'>ListenableBuilder</font> for the <i>isPolling</i> flag."
    ), sp(4)]
    story.append(code("""startPolling()
  → _isPolling = true
  → _poll() loop:
      while (_isPolling):
        updates = getUpdates(offset: lastId+1, timeout: 30s)
        for each update:
          lastId = max(lastId, update.updateId)
          _processUpdate(update)
        on error: delay 2s, retry

_processUpdate(TelegramUpdate):
  1. Skip if no .message field (ignore callback_query etc.)
  2. Skip if from.isBot == true
  3. createOrGetConversation(userId, username, firstName, lastName)
  4. If text == '/cancel' AND canUserFinish == true:
       → finishConversation()
       → sendMessage("Your conversation has been closed...")
       → return
  5. saveIncomingMessage(conversationId, messageId, type, text, fileId, ...)
  6. updateLastMessage(conversationId, preview, sentAt)
     ↳ increments unreadCount in conversations table
     ↳ Drift stream triggers → UI rebuilds automatically

stopPolling()
  → _isPolling = false  (loop exits on next iteration)"""))
    story.append(sp(6))
    story += [h2("TelegramIncomingMessage — Type Detection")]
    story.append(table(
        ["Field present", "messageType", "fileId source"],
        [
            ["animation != null", "gif", "animation.fileId"],
            ["photo != null", "photo", "photo.last.fileId (highest res)"],
            ["video != null", "video", "video.fileId"],
            ["document != null", "document", "document.fileId"],
            ["sticker != null", "sticker", "sticker.fileId"],
            ["voice != null", "voice", "voice.fileId"],
            ["video_note != null", "video_note", "videoNote.fileId"],
            ["audio != null", "audio", "audio.fileId"],
            ["text != null (no media)", "text", "null"],
        ],
        col_widths=[usable_w*0.3, usable_w*0.2, usable_w*0.5],
    ))
    story.append(PageBreak())

    # ── 8. Feature: Chats ────────────────────────────────────────────────────────
    story += [h1("8. Feature: Chats"), hr()]
    story += [p(
        "The Chats feature provides the conversation list with two tabs: "
        "<b>Open Queue</b> (all unassigned conversations) and <b>Mine</b> (current worker's assigned conversations). "
        "Both lists are powered by Drift reactive streams and update automatically."
    ), sp(6)]

    story += [h2("Chat Lifecycle")]
    story.append(code("""User sends first message
    → TelegramPollingController creates Conversation (status: 'open')
    → Appears in Open Queue for all workers

Worker taps conversation (in Open Queue)
    → ConversationController.initialize()
    → assignConversation(conversationId, workerId)   ← status: 'in_progress'
    → markMessagesRead()
    → Disappears from Open Queue, appears in Mine tab

Worker replies to user
    → sendText / sendPhoto / sendDocument / sendMediaByFileId
    → Message saved as isFromBot=true

Admin/Worker clicks "Allow User to Finish"
    → allowUserToFinish()  → canUserFinish = true
    → Bot sends: "You can now close this conversation by typing /cancel"
    → User types /cancel → finishConversation()

Admin/Worker clicks "Finish Chat"
    → finishConversation()  → status: 'finished'
    → Bot sends goodbye message
    → Conversation removed from all active lists"""))
    story.append(sp(6))

    story += [h2("ChatsController State (Freezed)")]
    story.append(code("""ChatsState.idle(
  openConversations: List<Conversation>,   // status='open', all workers see these
  myConversations:   List<Conversation>,   // assigned to current workerId
)
ChatsState.loading()
ChatsState.error(String message)"""))
    story.append(sp(6))

    story += [h2("ChatsDataController (ChangeNotifier — UI only)")]
    story += bullet([
        "<font face='Courier'>selectedTab</font> — ChatsTab.open or ChatsTab.mine",
        "<font face='Courier'>searchQuery</font> — current search text",
        "<font face='Courier'>isSearching</font> — true if query is non-empty",
        "<font face='Courier'>searchResults</font> — List&lt;Conversation&gt; from DB search",
        "<font face='Courier'>selectTab()</font>, <font face='Courier'>setSearchQuery()</font>, <font face='Courier'>clearSearch()</font>",
    ])
    story.append(sp(6))

    story += [h2("Responsive Layout")]
    story.append(table(
        ["Screen Size", "Widget", "Layout"],
        [
            ["Desktop / Tablet\n(>= 600 dp)", "ChatsDesktopWidget", "Two-column: chat list (left) | conversation placeholder (right). Tap opens ConversationScreen pushed to router."],
            ["Mobile\n(<= 600 dp)", "ChatsMobileWidget", "Full-screen list. Tap pushes ConversationScreen via Octopus router."],
        ],
        col_widths=[usable_w*0.2, usable_w*0.25, usable_w*0.55],
    ))
    story.append(sp(6))

    story += [h2("Conversation Tile — Displayed Data")]
    story += bullet([
        "Circular avatar with initials (coloured from worker's colorCode or Conversation.initials)",
        "Display name (firstName + lastName, or @username, or 'User #id')",
        "Last message preview (truncated)",
        "Time since last message (formatted)",
        "Unread badge (red dot with count when unreadCount > 0)",
        "Status dot: blue = open, orange = in progress, green = finished",
    ])
    story.append(PageBreak())

    # ── 9. Feature: Conversation ─────────────────────────────────────────────────
    story += [h1("9. Feature: Conversation"), hr()]
    story += [p(
        "The Conversation screen is the core interaction surface. "
        "Messages stream from Drift in real-time. Workers can send any media type, "
        "add internal notes, transfer the chat, or finish it."
    ), sp(6)]

    story += [h2("ConversationController — Actions")]
    story.append(table(
        ["Method", "Telegram API Call", "DB Effect"],
        [
            ["sendText(text)", "sendMessage(chatId, text)", "saveOutgoingMessage(type='text')"],
            ["sendPhoto(bytes, fileName)", "sendPhoto(multipart)", "saveOutgoingMessage(type='photo')"],
            ["sendDocument(bytes, fileName)", "sendDocument(multipart)", "saveOutgoingMessage(type='document')"],
            ["addNote(text)", "none", "saveNote(isNote=true, type='note')"],
            ["allowUserToFinish()", "sendMessage('You can /cancel...')", "canUserFinish = true"],
            ["finishConversation()", "sendMessage(goodbye)", "status = 'finished'"],
            ["transferTo(newWorkerId)", "none", "assignedWorkerId = newWorkerId"],
            ["sendTypingAction()", "sendChatAction('typing')", "none"],
        ],
        col_widths=[usable_w*0.3, usable_w*0.32, usable_w*0.38],
    ))
    story.append(sp(8))

    story += [h2("Message Bubble Rendering")]
    story.append(table(
        ["isFromBot", "isNote", "Bubble Style", "Alignment"],
        [
            ["false", "false", "Grey surface, user initials avatar", "Left"],
            ["true", "false", "Primary (Indigo), 'Bot' label", "Right"],
            ["any", "true", "Amber/yellow, lock icon, 'Internal Note' label, worker name", "Full-width card"],
        ],
        col_widths=[usable_w*0.13, usable_w*0.12, usable_w*0.5, usable_w*0.25],
    ))
    story.append(sp(8))

    story += [h2("Message Input Bar")]
    story += bullet([
        "<b>Text field</b> — multiline, expands to 4 lines. In note mode: amber background + lock icon.",
        "<b># shortcut</b> — typing <font face='Courier'>#</font> opens quick replies popup above the input. "
        "Further characters filter by title or content. Selecting a reply replaces the input text.",
        "<b>Attach button</b> — opens <font face='Courier'>FilePicker</font>. Any file type allowed. "
        "Images sent as photo, others as document.",
        "<b>Note toggle</b> — lock icon button toggles between message mode and internal note mode.",
        "<b>Send button</b> — disabled while empty or while ConversationState is sending.",
        "<b>Typing indicator</b> — <font face='Courier'>sendTypingAction()</font> called when user starts typing (debounced).",
    ])
    story.append(sp(8))

    story += [h2("ConversationDataController (ChangeNotifier — UI only)")]
    story += bullet([
        "<font face='Courier'>messageText</font> — current input text",
        "<font face='Courier'>showQuickReplies</font> — true when # pattern detected",
        "<font face='Courier'>filteredReplies</font> — quick replies matching the query",
        "<font face='Courier'>isNoteMode</font> — toggle between message and note input",
        "<font face='Courier'>setMessageText(text, allReplies)</font> — updates text and triggers # filtering",
        "<font face='Courier'>selectQuickReply(reply)</font> — sets text to reply.content, hides popup",
        "<font face='Courier'>toggleNoteMode()</font>",
        "<font face='Courier'>clearMessage()</font>",
    ])
    story.append(PageBreak())

    # ── 10. Feature: Bot Settings ─────────────────────────────────────────────────
    story += [h1("10. Feature: Bot Settings"), hr()]
    story += [p(
        "Accessible to admin users only. Configures bot metadata and behaviour "
        "through a combination of Telegram Bot API calls and local SQLite caching."
    ), sp(6)]

    story += [h2("BotSettingsState (Freezed)")]
    story.append(code("""BotSettingsState.idle(
  commands:       List<BotCommand>,    // Current slash commands
  welcomeMessage: String?,             // Sent on /start
  autoReply:      String?,             // Sent when all workers busy
  description:    String?,             // Bot profile description
  botUsername:    String?,             // @username from getMe()
)
BotSettingsState.loading()
BotSettingsState.saving()
BotSettingsState.error(String message)
BotSettingsState.saved()              // Transient — emitted after save, then back to idle"""))
    story.append(sp(8))

    story += [h2("BotCommand Model")]
    story.append(code("""class BotCommand {
  final String command;      // e.g. 'start', 'help', 'cancel'  (no leading slash)
  final String description;  // e.g. 'Start support chat'
}"""))
    story.append(sp(6))

    story += [h2("Storage Split")]
    story.append(table(
        ["Setting", "Stored in", "Mechanism"],
        [
            ["Bot commands", "Telegram API", "setMyCommands() / getMyCommands()"],
            ["Bot description", "Telegram API + BotSettingsTbl", "setMyDescription() + saveSetting('description', ...)"],
            ["Short description", "Telegram API + BotSettingsTbl", "setMyShortDescription()"],
            ["Welcome message", "BotSettingsTbl only", "saveSetting('welcome_message', ...)"],
            ["Auto-reply message", "BotSettingsTbl only", "saveSetting('auto_reply', ...)"],
        ],
        col_widths=[usable_w*0.25, usable_w*0.3, usable_w*0.45],
    ))
    story.append(sp(8))
    story.append(note(
        "Welcome messages and auto-reply are stored locally only. "
        "The polling controller is responsible for sending the welcome message on /start "
        "and the auto-reply when no worker is available (future implementation hook)."
    ))
    story.append(PageBreak())

    # ── 11. Feature: Workers ──────────────────────────────────────────────────────
    story += [h1("11. Feature: Workers"), hr()]
    story += [p(
        "Worker management is an admin-only screen. "
        "Workers are stored in the local SQLite database. "
        "Because all access goes through <font face='Courier'>IWorkerRepository</font>, "
        "this can be swapped for a backend API without touching the UI."
    ), sp(6)]

    story += [h2("Worker Model")]
    story.append(code("""class Worker {
  final int id;
  final String username;       // login name
  final String displayName;    // shown in UI
  final IdentityRole role;       // IdentityRole.admin | IdentityRole.worker
  final String colorCode;      // hex: '#6366F1'
  final IdentityStatus status;   // online | away | busy | offline
  final bool isActive;
  final DateTime createdAt;

  String get initials { ... }  // 'JD' from 'John Doe'
  bool get isAdmin => role == IdentityRole.admin;
}"""))
    story.append(sp(6))

    story += [h2("WorkersController Actions")]
    story.append(table(
        ["Method", "Effect"],
        [
            ["load()", "Fetch all active workers → WorkersState.idle(workers)"],
            ["addWorker(username, password, displayName, role, colorCode)", "Hash password, insert into DB, reload list"],
            ["changePassword(workerId, newPassword)", "Hash + update in DB only"],
            ["deactivate(workerId)", "Soft delete: isActive = false, reload list"],
        ],
        col_widths=[usable_w*0.45, usable_w*0.55],
    ))
    story.append(sp(8))

    story += [h2("Preset Worker Colours")]
    story += bullet([
        "<font face='Courier'>#6366F1</font> — Indigo (default admin)",
        "<font face='Courier'>#3B82F6</font> — Blue",
        "<font face='Courier'>#10B981</font> — Green",
        "<font face='Courier'>#F59E0B</font> — Amber",
        "<font face='Courier'>#EF4444</font> — Red",
        "<font face='Courier'>#8B5CF6</font> — Purple",
    ])
    story.append(PageBreak())

    # ── 12. Navigation ─────────────────────────────────────────────────────────────
    story += [h1("12. Navigation & Routing"), hr()]
    story += [h2("Routes (Octopus)")]
    story.append(table(
        ["Route name", "Path segment", "Screen", "Notes"],
        [
            ["signin", "/signin", "SignInScreen", "Auth-only route"],
            ["signup", "/signup", "SignUpScreen", "Auth-only; first-admin setup"],
            ["dashboard", "/dashboard", "DashboardScreen", "Default post-login route"],
            ["chats", "/chats", "ChatsScreen", "Chat list with Open/Mine tabs"],
            ["conversation", "/conversation", "ConversationScreen", "Takes ?id= argument (conversationId)"],
            ["bot-settings", "/bot-settings", "BotSettingsScreen", "Admin only"],
            ["workers", "/workers", "WorkersScreen", "Admin only"],
            ["settings", "/settings", "SettingsScreen", "Theme, profile, sign out"],
            ["developer", "/developer", "DeveloperScreen", "Dev-mode log viewer"],
        ],
        col_widths=[usable_w*0.18, usable_w*0.2, usable_w*0.25, usable_w*0.37],
    ))
    story.append(sp(8))

    story += [h2("AuthenticationGuard Logic")]
    story.append(code("""call(history, state, context):
  if authenticated:
    → block signin/signup routes (redirect to lastNavigation)
    → save current state as lastNavigation
    → allow all other routes
  if needsSetup:
    → always redirect to signup
  if idle / error / inProgress:
    → if currently on auth screen: allow it
    → otherwise redirect to signin"""))
    story.append(sp(8))

    story += [h2("MainNavigation Widget")]
    story += [p(
        "Shared shell widget used by Dashboard, Chats, and Settings screens. "
        "Provides persistent navigation while swapping the content area."
    ), sp(4)]
    story.append(table(
        ["Screen Size", "Widget Used", "Destinations", "Badge"],
        [
            ["Desktop / Tablet\n(>= 600 dp)", "NavigationRail (left sidebar)", "Dashboard | Chats | Settings", "Open-chat count on Chats icon"],
            ["Mobile\n(<= 600 dp)", "NavigationBar (bottom)", "Dashboard | Chats | Settings", "Open-chat count on Chats icon"],
        ],
        col_widths=[usable_w*0.22, usable_w*0.28, usable_w*0.3, usable_w*0.2],
    ))
    story.append(sp(6))
    story.append(note(
        "The open-chat badge count is read from ChatsController state. "
        "MainNavigation subscribes to the controller and rebuilds when the count changes."
    ))
    story.append(sp(6))

    story += [h2("Navigating to a Conversation")]
    story.append(code("""// Push conversation screen with conversationId argument
Octopus.of(context).setState((state) =>
  state..add(
    Routes.conversation.node()
      ..arguments['id'] = conversationId.toString()
  )
);"""))
    story.append(PageBreak())

    # ── 13. Settings & Theme ──────────────────────────────────────────────────────
    story += [h1("13. Settings & Theme"), hr()]
    story += [h2("SettingsScope")]
    story += [p(
        "<font face='Courier'>SettingsScope</font> is an InheritedWidget that wraps the entire app "
        "(placed above <font face='Courier'>MaterialApp</font>). It holds the theme mode and provides "
        "Material 3 <font face='Courier'>ThemeData</font> objects for light and dark."
    ), sp(4)]
    story += bullet([
        "<font face='Courier'>SettingsScope.themeOf(context)</font> → <font face='Courier'>AppThemeData</font> (light, dark, mode)",
        "<font face='Courier'>SettingsScope.themeModeOf(context)</font> → <font face='Courier'>ThemeMode</font>",
        "<font face='Courier'>SettingsScope.setThemeMode(context, ThemeMode.dark)</font> → persists to SharedPreferences",
    ])
    story.append(sp(6))

    story += [h2("Material 3 Theme Tokens")]
    story.append(table(
        ["Token", "Value"],
        [
            ["Seed colour", "Indigo #6366F1"],
            ["Border radius (cards, buttons, inputs)", "12 dp"],
            ["Font family", "Inter (system fallback)"],
            ["Persistence key", "'theme_mode' in SharedPreferences"],
            ["Default mode", "Light"],
        ],
        col_widths=[usable_w*0.4, usable_w*0.6],
    ))
    story.append(sp(8))

    story += [h2("Settings Screen Sections")]
    story.append(table(
        ["Section", "Content", "Access"],
        [
            ["Profile", "Avatar (initials), display name, role badge, username", "All workers"],
            ["Appearance", "Light / Dark toggle switch", "All workers"],
            ["Admin", "Bot Settings link, Manage Workers link", "Admin role only"],
            ["About", "App name, version from metadata, platform OS", "All workers"],
            ["Sign Out", "Red button, calls AuthenticationController.signOut()", "All workers"],
        ],
        col_widths=[usable_w*0.2, usable_w*0.55, usable_w*0.25],
    ))
    story.append(PageBreak())

    # ── 14. Initialization Sequence ───────────────────────────────────────────────
    story += [h1("14. Initialization Sequence"), hr()]
    story += [p(
        "Initialization is a sequential pipeline defined in "
        "<font face='Courier'>lib/src/feature/initialization/data/initialize_dependencies.dart</font>. "
        "Each step receives the partially-built <font face='Courier'>Dependencies</font> object and populates one field."
    ), sp(6)]
    story.append(table(
        ["Step", "Action", "Mode"],
        [
            ["1", "Platform pre-initialization (window setup, etc.)", "All"],
            ["2", "Create AppMetadata (name, version, OS, screen size, locale)", "All"],
            ["3", "Set Controller.observer for state-change logging", "All"],
            ["4", "Load SharedPreferences", "All"],
            ["5", "Open SQLite database ('teledesk_db')", "All"],
            ["6", "Create TelegramRepositoryImpl with bot token", "All"],
            ["7", "Create WorkerRepositoryImpl", "All"],
            ["8", "Create ConversationRepositoryImpl", "All"],
            ["9", "Create QuickReplyRepositoryImpl", "All"],
            ["10", "Create BotSettingsRepositoryImpl", "All"],
            ["11", "Create TelegramPollingController (not started yet)", "All"],
            ["12", "Create AuthenticationController", "All"],
            ["13", "VACUUM database, prune old logs", "Dev only"],
            ["14", "Buffer existing logs, start live log listener", "Dev only"],
        ],
        col_widths=[usable_w*0.06, usable_w*0.76, usable_w*0.18],
    ))
    story.append(sp(8))
    story.append(note(
        "TelegramPollingController is created but NOT started during initialization. "
        "Polling starts only when the user authenticates (AuthenticationScope._listener). "
        "This prevents polling with an empty/invalid token on first launch."
    ))
    story.append(PageBreak())

    # ── 15. File Structure ────────────────────────────────────────────────────────
    story += [h1("15. Complete File Structure"), hr()]
    story.append(code("""teledesk/
├── config/
│   ├── app_config.json          ← GITIGNORED — your bot token here
│   └── README.md
├── lib/
│   ├── main.dart
│   └── src/
│       ├── common/
│       │   ├── constant/
│       │   │   ├── config.dart              ← Config class (dart-define values)
│       │   │   └── pubspec.yaml.g.dart      ← Generated: typed pubspec access
│       │   ├── database/
│       │   │   ├── database.dart            ← AppDatabase @DriftDatabase
│       │   │   ├── database.g.dart          ← Generated by drift_dev
│       │   │   └── tables/
│       │   │       ├── workers_table.dart
│       │   │       ├── conversations_table.dart
│       │   │       ├── messages_table.dart
│       │   │       ├── quick_replies_table.dart
│       │   │       ├── bot_settings_table.dart
│       │   │       └── log_table.dart
│       │   ├── model/
│       │   │   └── app_metadata.dart
│       │   ├── router/
│       │   │   ├── routes.dart              ← All Routes enum
│       │   │   ├── authentication_guard.dart
│       │   │   └── router_state_mixin.dart
│       │   ├── util/
│       │   │   ├── crypto_util.dart         ← SHA-256 hashing
│       │   │   ├── screen_util.dart         ← Responsive breakpoints
│       │   │   └── extensions.dart
│       │   └── widget/
│       │       └── main_navigation.dart     ← NavigationRail / NavigationBar
│       └── feature/
│           ├── authentication/
│           │   ├── controller/authentication_controller.dart
│           │   ├── data/worker_repository.dart
│           │   ├── model/worker.dart
│           │   └── widget/
│           │       ├── authentication_scope.dart
│           │       ├── signin_screen.dart
│           │       └── signup_screen.dart
│           ├── telegram/
│           │   ├── controller/telegram_polling_controller.dart
│           │   ├── data/telegram_repository.dart
│           │   └── model/
│           │       ├── telegram_user.dart
│           │       ├── telegram_message.dart
│           │       └── telegram_update.dart
│           ├── chats/
│           │   ├── controller/chats_controller.dart
│           │   ├── data/conversation_repository.dart
│           │   ├── model/conversation.dart
│           │   ├── model/chat_message.dart
│           │   └── widget/
│           │       ├── chats_screen.dart
│           │       ├── chats_config_widget.dart     ← InheritedWidget setup
│           │       ├── controllers/chats_data_controller.dart
│           │       ├── desktop/chats_desktop_widget.dart
│           │       └── mobile/chats_mobile_widget.dart
│           ├── conversation/
│           │   ├── controller/conversation_controller.dart
│           │   └── widget/
│           │       ├── conversation_screen.dart
│           │       ├── conversation_config_widget.dart
│           │       ├── controllers/conversation_data_controller.dart
│           │       ├── desktop/conversation_desktop_widget.dart
│           │       └── mobile/conversation_mobile_widget.dart
│           ├── dashboard/
│           │   └── widget/dashboard_screen.dart
│           ├── bot_settings/
│           │   ├── controller/bot_settings_controller.dart
│           │   ├── data/bot_settings_repository.dart
│           │   ├── model/bot_command.dart
│           │   └── widget/bot_settings_screen.dart
│           ├── workers/
│           │   ├── controller/workers_controller.dart
│           │   └── widget/workers_screen.dart
│           ├── quick_replies/
│           │   ├── data/quick_reply_repository.dart
│           │   └── model/quick_reply.dart
│           ├── settings/
│           │   └── widget/
│           │       ├── settings_scope.dart
│           │       └── settings_screen.dart
│           └── initialization/
│               ├── data/initialize_dependencies.dart  ← 14-step init pipeline
│               ├── models/dependencies.dart
│               └── widget/
│                   ├── app.dart                       ← Root App widget
│                   ├── dependencies_scope.dart
│                   └── initialization_splash_screen.dart"""))
    story.append(PageBreak())

    # ── 16. Adding a New Feature ──────────────────────────────────────────────────
    story += [h1("16. How to Add a New Feature"), hr()]
    story += [p("Follow this checklist when adding a feature to maintain consistency:"), sp(4)]
    story += [h2("Step 1 — Create the Feature Folder")]
    story.append(code("""lib/src/feature/my_feature/
  controller/my_feature_controller.dart
  data/my_feature_repository.dart
  model/my_feature_model.dart
  widget/my_feature_screen.dart
  widget/my_feature_config_widget.dart  (if needs init)
  widget/desktop/my_feature_desktop_widget.dart
  widget/mobile/my_feature_mobile_widget.dart"""))
    story.append(sp(6))

    story += [h2("Step 2 — Controller")]
    story.append(code("""part 'my_feature_controller.freezed.dart';

@freezed
sealed class MyFeatureState with _$MyFeatureState {
  const factory MyFeatureState.idle(MyModel data) = MyFeature$IdleState;
  const factory MyFeatureState.loading()           = MyFeature$LoadingState;
  const factory MyFeatureState.error(String msg)   = MyFeature$ErrorState;
}

final class MyFeatureController extends StateController<MyFeatureState>
    with SequentialControllerHandler {
  MyFeatureController({required IMyFeatureRepository repo})
      : _repo = repo, super(initialState: const MyFeatureState.loading());
  final IMyFeatureRepository _repo;

  void load() => handle(() async {
    setState(const MyFeatureState.loading());
    final data = await _repo.getAll();
    setState(MyFeatureState.idle(data));
  }, error: (e, _) async => setState(MyFeatureState.error(e.toString())));
}"""))
    story.append(sp(6))

    story += [h2("Step 3 — Add Repository to Dependencies")]
    story += bullet([
        "Add <font face='Courier'>late final IMyFeatureRepository myFeatureRepository;</font> to <font face='Courier'>Dependencies</font>",
        "Add initialization step to <font face='Courier'>_initializationSteps</font> map in <font face='Courier'>initialize_dependencies.dart</font>",
    ])
    story.append(sp(6))

    story += [h2("Step 4 — Add Route")]
    story += bullet([
        "Add new enum value to <font face='Courier'>Routes</font> in <font face='Courier'>lib/src/common/router/routes.dart</font>",
        "Add case to the <font face='Courier'>builder</font> switch",
    ])
    story.append(sp(6))

    story += [h2("Step 5 — Run Code Generation")]
    story.append(code("dart run build_runner build --delete-conflicting-outputs"))
    story.append(sp(6))

    story += [h2("InheritedWidget Init Pattern (important)")]
    story.append(code("""class MyConfigWidgetState extends State<MyConfigWidget> {
  MyController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // ONLY non-InheritedWidget init here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;           // ← guard: run only once
    _initialized = true;
    // Safe to call Dependencies.of() and AuthenticationScope.workerOf() HERE
    final deps = Dependencies.of(context);
    _controller = MyController(repo: deps.myFeatureRepository)..load();
  }
}"""))
    story.append(PageBreak())

    # ── 17. Backend Export Guide ──────────────────────────────────────────────────
    story += [h1("17. Exporting to a Backend"), hr()]
    story += [p(
        "Every repository is behind a Dart abstract interface. "
        "To replace SQLite with a REST backend, implement the interface and swap "
        "the implementation in the initialization step — no UI code changes required."
    ), sp(6)]
    story += [h2("Interfaces to Implement")]
    story.append(table(
        ["Interface", "File location", "Methods"],
        [
            ["IWorkerRepository", "authentication/data/worker_repository.dart", "9 methods"],
            ["IConversationRepository", "chats/data/conversation_repository.dart", "17 methods"],
            ["IQuickReplyRepository", "quick_replies/data/quick_reply_repository.dart", "4 methods"],
            ["IBotSettingsRepository", "bot_settings/data/bot_settings_repository.dart", "10 methods"],
            ["ITelegramRepository", "telegram/data/telegram_repository.dart", "16 methods (keep as-is)"],
        ],
        col_widths=[usable_w*0.28, usable_w*0.44, usable_w*0.28],
    ))
    story.append(sp(8))

    story += [h2("Swap in initialize_dependencies.dart")]
    story.append(code("""// Replace:
dependencies.workerRepository = WorkerRepositoryImpl(database: dependencies.database);

// With:
dependencies.workerRepository = WorkerRepositoryApiImpl(
  apiClient: dependencies.apiClient,
  authToken: Config.apiToken,
);"""))
    story.append(sp(6))
    story.append(note(
        "IConversationRepository returns Drift Streams (Stream<List<Conversation>>). "
        "Your backend implementation should use a StreamController that polls or uses websockets "
        "to push updates — the UI StreamBuilder widgets will continue to work unchanged."
    ))
    story.append(PageBreak())

    # ── 18. Quick Reference ───────────────────────────────────────────────────────
    story += [h1("18. Quick Reference"), hr()]
    story += [h2("Useful Commands")]
    story.append(table(
        ["Command", "Purpose"],
        [
            ["flutter run --dart-define-from-file=config/app_config.json", "Run with bot token"],
            ["dart run build_runner build --delete-conflicting-outputs", "Regenerate all code-gen files"],
            ["dart analyze lib/", "Check for errors and warnings"],
            ["dart format lib/", "Format all Dart files"],
            ["flutter build apk --dart-define-from-file=config/app_config.json", "Android release build"],
            ["flutter build macos --dart-define-from-file=config/app_config.json", "macOS release build"],
        ],
        col_widths=[usable_w*0.55, usable_w*0.45],
    ))
    story.append(sp(10))

    story += [h2("Key Context Accessors")]
    story.append(table(
        ["Expression", "Returns", "Safe in initState?"],
        [
            ["Dependencies.of(context)", "Dependencies", "Yes (uses getElement, not depend)"],
            ["AuthenticationScope.workerOf(context)", "Worker?", "NO — use in build() or didChangeDependencies()"],
            ["AuthenticationScope.controllerOf(context)", "AuthenticationController", "Yes (listen: false)"],
            ["SettingsScope.themeOf(context)", "AppThemeData", "No — use in build()"],
            ["SettingsScope.setThemeMode(context, mode)", "void", "No — call from gesture handlers"],
            ["context.screenSizeMaybeWhen(...)", "T", "No — use in build()"],
        ],
        col_widths=[usable_w*0.38, usable_w*0.27, usable_w*0.35],
    ))
    story.append(sp(10))

    story += [h2("ConversationStatus Values")]
    story.append(table(
        ["Status", "Meaning", "Worker visibility"],
        [
            ["open", "New conversation, not yet assigned", "Shown to all in Open Queue tab"],
            ["in_progress", "Assigned to a specific worker", "Shown only in that worker's Mine tab"],
            ["finish_requested", "Reserved for future use", "—"],
            ["finished", "Conversation closed", "Hidden from all active lists"],
        ],
        col_widths=[usable_w*0.22, usable_w*0.4, usable_w*0.38],
    ))

    story.append(sp(16))
    story += [
        HRFlowable(width="100%", thickness=1, color=INDIGO_LIGHT, spaceAfter=12),
        Paragraph("TeleDesk — Developer Documentation", style("Footer", fontSize=9, textColor=SLATE_LIGHT, alignment=TA_CENTER)),
        Paragraph("Open Source · MIT License · March 2026", style("Footer2", fontSize=8, textColor=SLATE_LIGHT, alignment=TA_CENTER)),
    ]

    return story


# ── Render ─────────────────────────────────────────────────────────────────────
def on_page(canvas, doc):
    """Add page number to every page except the cover."""
    if doc.page > 1:
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(SLATE_LIGHT)
        canvas.drawRightString(PAGE_W - MARGIN, 1.2 * cm, f"Page {doc.page}")
        canvas.drawString(MARGIN, 1.2 * cm, "TeleDesk Developer Documentation")
        canvas.setStrokeColor(INDIGO_LIGHT)
        canvas.setLineWidth(0.5)
        canvas.line(MARGIN, 1.5 * cm, PAGE_W - MARGIN, 1.5 * cm)
        canvas.restoreState()


doc = SimpleDocTemplate(
    OUTPUT,
    pagesize=A4,
    leftMargin=MARGIN,
    rightMargin=MARGIN,
    topMargin=MARGIN,
    bottomMargin=2 * cm,
    title="TeleDesk Developer Documentation",
    author="TeleDesk",
    subject="Complete architecture reference for TeleDesk Flutter application",
)

doc.build(build(), onFirstPage=on_page, onLaterPages=on_page)
print(f"✅  PDF generated: {OUTPUT}")
