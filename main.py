
import sys
import sqlite3
import json
import shutil
import hashlib
import secrets
import subprocess
from pathlib import Path
from datetime import datetime, timedelta

from PySide6.QtQuickControls2 import QQuickStyle

from PySide6.QtCore import (
    QObject,
    Signal,
    Slot,
    Property,
    QUrl,
    QSize,
    Qt
)

from PySide6.QtGui import (
    QGuiApplication,
    QFont,
    QFontDatabase,
    QPalette
)

from PySide6.QtQuick import QQuickView


# ============================================================
# 01. PROJECT CONFIGURATION
# ============================================================

PROJECT_DIR = Path(__file__).resolve().parent

DATABASE_PATH = (
    PROJECT_DIR
    / "data"
    / "bubtops.db"
)

FONT_DIRECTORY = PROJECT_DIR / "assets" / "fonts"


# ============================================================
# 02. APPLICATION FONT
# ============================================================

def load_application_font(app):

    font_candidates = [
        FONT_DIRECTORY / "InterVariable.ttf",
        FONT_DIRECTORY / "Inter-Regular.ttf",
        FONT_DIRECTORY / "Inter.ttf"
    ]

    for font_path in font_candidates:

        if not font_path.exists():
            continue

        font_id = QFontDatabase.addApplicationFont(
            str(font_path)
        )

        if font_id == -1:
            print("Could not load font:", font_path)
            continue

        families = QFontDatabase.applicationFontFamilies(
            font_id
        )

        if not families:
            continue

        font_family = families[0]

        application_font = QFont(font_family)
        application_font.setPointSizeF(10.5)
        application_font.setStyleHint(
            QFont.StyleHint.SansSerif
        )

        app.setFont(application_font)

        print("Application font loaded:", font_family)

        return font_family

    # Fallback if Inter is unavailable.
    fallback_font = QFont("Segoe UI")
    fallback_font.setPointSizeF(10.5)
    fallback_font.setStyleHint(
        QFont.StyleHint.SansSerif
    )

    app.setFont(fallback_font)

    print("Inter not found. Using system fallback font.")

    return fallback_font.family()


# ============================================================
# 03. ASSET DATABASE BACKEND
# ============================================================

class AssetBackend(QObject):

    assetsChanged = Signal()
    maintenanceChanged = Signal()
    settingsChanged = Signal()
    databaseLocationChanged = Signal()
    adminProfileChanged = Signal()

    # --------------------------------------------------------
    # INITIALIZATION
    # --------------------------------------------------------

    def __init__(self):
        super().__init__()

        self._database_error = ""
        self._settings_cache = None
        self._app = QGuiApplication.instance()
        self._style_hints = self._app.styleHints() if self._app else None
        if self._style_hints is not None:
            try:
                self._style_hints.colorSchemeChanged.connect(self._on_system_color_scheme_changed)
            except (AttributeError, TypeError, RuntimeError):
                pass
        if self._app is not None:
            try:
                self._app.paletteChanged.connect(self._on_system_color_scheme_changed)
            except (AttributeError, TypeError, RuntimeError):
                pass
        self._location_config = PROJECT_DIR / "data" / "db_location.json"
        self.database_path = DATABASE_PATH
        try:
            if self._location_config.exists():
                saved = json.loads(self._location_config.read_text(encoding="utf-8"))
                candidate = Path(saved.get("database_path", "")).expanduser()
                if candidate.is_file():
                    self.database_path = candidate
        except Exception as error:
            print("Database location config could not be read:", error)

        print(f"Using SQLite database: {self.database_path}")

        if not self.database_path.exists():

            self._database_error = (
                f"Database not found:\n{self.database_path}"
            )

            print(self._database_error)
            return

        try:

            self.ensure_cost_columns()
            self.ensure_settings_tables()

            print("Database initialized successfully.")

        except Exception as error:

            self._database_error = str(error)

            print(
                "Database initialization error:",
                self._database_error
            )

    # --------------------------------------------------------
    # DATABASE STATUS
    # --------------------------------------------------------

    @Property(bool, constant=True)
    def databaseReady(self):
        return self.database_path.exists() and not self._database_error

    @Property(str, notify=settingsChanged)
    def applicationName(self):
        return str(self.getSettings().get("application_name", "BubtOps"))

    def _on_system_color_scheme_changed(self, *_args):
        # Re-apply the effective palette when the operating-system theme changes.
        if self.getSettings().get("theme", "Dark Mode") == "System Mode":
            self.settingsChanged.emit()

    def _system_prefers_light(self):
        """Detect the desktop colour scheme, with palette fallback for platforms
        where Qt reports ColorScheme.Unknown (common on some Linux setups)."""
        try:
            if self._style_hints is not None:
                scheme = self._style_hints.colorScheme
                if callable(scheme):
                    scheme = scheme()
                if scheme == Qt.ColorScheme.Light:
                    return True
                if scheme == Qt.ColorScheme.Dark:
                    return False
        except (AttributeError, TypeError, RuntimeError):
            pass
        try:
            if self._app is not None:
                window_color = self._app.palette().color(QPalette.ColorRole.Window)
                return window_color.lightness() >= 128
        except (AttributeError, TypeError, RuntimeError):
            pass
        # Qt cannot determine the system setting; use a predictable light default.
        return True

    @Property(str, notify=settingsChanged)
    def theme(self):
        selected = str(self.getSettings().get("theme", "Dark Mode"))
        if selected in ("Light", "Light Mode"):
            return "Light"
        if selected == "System Mode":
            return "Light" if self._system_prefers_light() else "Dark Glass"
        return "Dark Glass"

    @Property(float, notify=settingsChanged)
    def fontScale(self):
        """Keep typography changes modest so cards and controls stay balanced."""
        try:
            size = float(self.getSettings().get("font_size", "10"))
            # Available values are 9..16. Scale from 0.96 to a restrained 1.22.
            return max(0.96, min(1.22, 0.96 + (size - 9.0) * 0.043))
        except (TypeError, ValueError):
            return 1.0

    @Property(str, notify=settingsChanged)
    def language(self):
        return str(self.getSettings().get("language", "English"))

    @Property(str, notify=settingsChanged)
    def dateFormat(self):
        return str(self.getSettings().get("date_format", "YYYY-MM-DD"))

    @Property(str, notify=adminProfileChanged)
    def adminName(self):
        return str(self.getAdminProfile().get("admin_name", "Administrator"))

    @Property(str, constant=True)
    def databaseError(self):
        return self._database_error

    # --------------------------------------------------------
    # DATABASE CONNECTION
    # --------------------------------------------------------

    def connect_database(self):

        if not self.database_path.exists():
            raise FileNotFoundError(f"Database not found: {self.database_path}")

        connection = sqlite3.connect(
            str(self.database_path),
            timeout=5
        )

        connection.row_factory = sqlite3.Row

        connection.execute(
            "PRAGMA foreign_keys = ON"
        )

        return connection

    # --------------------------------------------------------
    # ENSURE REQUIRED COLUMNS EXIST
    # --------------------------------------------------------

    def ensure_cost_columns(self):

        with self.connect_database() as connection:

            columns = connection.execute(
                "PRAGMA table_info(assets)"
            ).fetchall()

            if not columns:

                raise RuntimeError(
                    "The assets table was not found."
                )

            column_names = [
                column["name"]
                for column in columns
            ]

            if "purchase_cost" not in column_names:

                connection.execute("""
                    ALTER TABLE assets
                    ADD COLUMN purchase_cost
                    REAL NOT NULL DEFAULT 0
                """)

            if "estimated_repair_cost" not in column_names:

                connection.execute("""
                    ALTER TABLE assets
                    ADD COLUMN estimated_repair_cost
                    REAL NOT NULL DEFAULT 0
                """)

    # --------------------------------------------------------
    # SETTINGS + ASSET CONFIGURATION HISTORY
    # --------------------------------------------------------

    def ensure_settings_tables(self):
        """Create settings/history tables in the existing BubtOps database."""
        with self.connect_database() as connection:
            connection.execute("""
                CREATE TABLE IF NOT EXISTS app_settings (
                    setting_key TEXT PRIMARY KEY,
                    setting_value TEXT NOT NULL DEFAULT ''
                )
            """)
            connection.execute("""
                CREATE TABLE IF NOT EXISTS admin_profile (
                    profile_id INTEGER PRIMARY KEY CHECK (profile_id = 1),
                    admin_name TEXT NOT NULL DEFAULT 'Administrator',
                    username TEXT NOT NULL DEFAULT 'admin',
                    password_hash TEXT NOT NULL DEFAULT '',
                    password_salt TEXT NOT NULL DEFAULT ''
                )
            """)
            connection.execute("""
                CREATE TABLE IF NOT EXISTS asset_history (
                    history_id INTEGER PRIMARY KEY AUTOINCREMENT,
                    asset_id INTEGER,
                    asset_code TEXT NOT NULL,
                    asset_name TEXT NOT NULL,
                    action_type TEXT NOT NULL,
                    previous_info TEXT NOT NULL DEFAULT '',
                    updated_info TEXT NOT NULL DEFAULT '',
                    performed_by TEXT NOT NULL DEFAULT 'Administrator',
                    action_time TEXT NOT NULL
                )
            """)
            connection.execute("""
                CREATE TABLE IF NOT EXISTS backup_history (
                    backup_id INTEGER PRIMARY KEY AUTOINCREMENT,
                    file_path TEXT NOT NULL,
                    backup_time TEXT NOT NULL
                )
            """)
            defaults = {
                'application_name': 'BubtOps', 'language': 'English',
                'date_format': 'YYYY-MM-DD', 'default_dashboard': 'Overview',
                'theme': 'Dark Glass', 'font_size': '10'
            }
            for key, value in defaults.items():
                connection.execute(
                    'INSERT OR IGNORE INTO app_settings(setting_key, setting_value) VALUES (?, ?)',
                    (key, value)
                )
            connection.execute("""
                INSERT OR IGNORE INTO admin_profile(profile_id, admin_name, username)
                VALUES (1, 'Administrator', 'admin')
            """)

    @Property(str, notify=databaseLocationChanged)
    def databasePath(self):
        return str(self.database_path)

    @Property(str, notify=databaseLocationChanged)
    def databaseStatus(self):
        return 'Connected' if self.database_path.exists() and not self._database_error else 'Not connected'

    @Slot(result='QVariantMap')
    def getSettings(self):
        defaults = {
            'application_name': 'BubtOps', 'language': 'English',
            'date_format': 'YYYY-MM-DD', 'default_dashboard': 'Overview',
            'theme': 'Dark Glass', 'font_size': '10'
        }
        if self._settings_cache is not None:
            return dict(self._settings_cache)
        try:
            with self.connect_database() as connection:
                for row in connection.execute('SELECT setting_key, setting_value FROM app_settings'):
                    defaults[row['setting_key']] = row['setting_value']
            self._settings_cache = dict(defaults)
            return dict(defaults)
        except Exception as error:
            return {'error': str(error)}

    @Slot(str, str, result='QVariantMap')
    def saveSetting(self, key, value):
        try:
            with self.connect_database() as connection:
                connection.execute("""
                    INSERT INTO app_settings(setting_key, setting_value) VALUES (?, ?)
                    ON CONFLICT(setting_key) DO UPDATE SET setting_value=excluded.setting_value
                """, (key, value))
            if self._settings_cache is None:
                self._settings_cache = self.getSettings()
            self._settings_cache[key] = value
            self.settingsChanged.emit()
            return {'success': True, 'message': 'Setting saved and applied.'}
        except Exception as error:
            return {'success': False, 'message': str(error)}

    @Slot(result='QVariantMap')
    def getAdminProfile(self):
        try:
            with self.connect_database() as connection:
                row = connection.execute(
                    'SELECT admin_name, username FROM admin_profile WHERE profile_id=1'
                ).fetchone()
            return {'admin_name': row['admin_name'], 'username': row['username']} if row else {
                'admin_name': 'Administrator', 'username': 'admin'
            }
        except Exception as error:
            return {'error': str(error)}

    @Slot('QVariantMap', result='QVariantMap')
    def saveAdminProfile(self, data):
        try:
            name = str(data.get('admin_name', '')).strip()
            username = str(data.get('username', '')).strip()
            password = str(data.get('password', '')).strip()
            if not name or not username:
                return {'success': False, 'message': 'Admin name and username are required.'}
            with self.connect_database() as connection:
                if password:
                    salt = secrets.token_hex(16)
                    digest = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 200_000).hex()
                    connection.execute("""
                        UPDATE admin_profile SET admin_name=?, username=?, password_hash=?, password_salt=?
                        WHERE profile_id=1
                    """, (name, username, digest, salt))
                else:
                    connection.execute(
                        'UPDATE admin_profile SET admin_name=?, username=? WHERE profile_id=1',
                        (name, username)
                    )
            self.adminProfileChanged.emit()
            return {'success': True, 'message': 'Admin profile saved.'}
        except Exception as error:
            return {'success': False, 'message': str(error)}

    @Slot(str, str, result='QVariantList')
    def getAssetHistory(self, search_text='', action_type='All'):
        try:
            sql = '''SELECT history_id, asset_code, asset_name, action_type,
                            previous_info, updated_info, performed_by, action_time
                     FROM asset_history WHERE 1=1'''
            params = []
            if search_text.strip():
                pattern = '%' + search_text.strip() + '%'
                sql += ' AND (asset_code LIKE ? OR asset_name LIKE ?)'
                params.extend([pattern, pattern])
            if action_type and action_type != 'All':
                sql += ' AND action_type=?'
                params.append(action_type)
            sql += ' ORDER BY history_id DESC LIMIT 500'
            with self.connect_database() as connection:
                rows = connection.execute(sql, params).fetchall()
            return [dict(row) for row in rows]
        except Exception as error:
            print('History load error:', error)
            return []

    @Slot(int, result='QVariantMap')
    def deleteAssetHistory(self, history_id):
        try:
            with self.connect_database() as connection:
                cursor = connection.execute('DELETE FROM asset_history WHERE history_id=?', (history_id,))
                if cursor.rowcount == 0:
                    return {'success': False, 'message': 'History record not found.'}
            return {'success': True, 'message': 'Selected history record deleted. Asset data was not changed.'}
        except Exception as error:
            return {'success': False, 'message': str(error)}

    @Slot(bool, result='QVariantList')
    def getBackupHistory(self, last_30_days=False):
        try:
            sql = 'SELECT backup_id, file_path, backup_time FROM backup_history'
            params = []
            if last_30_days:
                cutoff = (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')
                sql += ' WHERE backup_time >= ?'
                params.append(cutoff)
            sql += ' ORDER BY backup_id DESC LIMIT 500'
            with self.connect_database() as connection:
                rows = connection.execute(sql, params).fetchall()
            return [dict(row) for row in rows]
        except Exception as error:
            print('Backup history load error:', error)
            return []

    @Slot(str, result='QVariantMap')
    def backupDatabase(self, target_path=''):
        try:
            if not target_path.strip():
                backup_dir = PROJECT_DIR / 'backups'
                backup_dir.mkdir(exist_ok=True)
                target = backup_dir / ('bubtops_backup_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.db')
            else:
                target = Path(target_path).expanduser()
                if target.suffix == '' or target.is_dir():
                    target.mkdir(parents=True, exist_ok=True)
                    target = target / ('bubtops_backup_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.db')
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
            with self.connect_database() as connection:
                destination = sqlite3.connect(str(target))
                connection.backup(destination)
                destination.close()
            stamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            with self.connect_database() as connection:
                connection.execute('INSERT INTO backup_history(file_path, backup_time) VALUES (?, ?)', (str(target), stamp))
            return {'success': True, 'message': 'Database backup created.', 'path': str(target)}
        except Exception as error:
            return {'success': False, 'message': str(error)}

    @Slot(str, result='QVariantMap')
    def revealBackupFile(self, file_path):
        """Open the backup's containing folder and select the exact file."""
        try:
            backup = Path(file_path).expanduser().resolve()
            if not backup.is_file():
                return {'success': False, 'message': 'Backup file not found: ' + str(backup)}

            if sys.platform.startswith('win'):
                # Open Windows Explorer and highlight the selected backup file.
                subprocess.Popen(['explorer.exe', '/select,', str(backup)])
            elif sys.platform == 'darwin':
                subprocess.Popen(['open', '-R', str(backup)])
            else:
                subprocess.Popen(['xdg-open', str(backup.parent)])

            return {'success': True, 'message': 'Opened backup file location: ' + backup.name}
        except Exception as error:
            return {'success': False, 'message': str(error)}

    @Slot(str, result='QVariantMap')
    def restoreDatabase(self, source_path):
        try:
            source = Path(source_path).expanduser()
            if not source.is_file():
                return {'success': False, 'message': 'Backup file was not found.'}
            check = sqlite3.connect(str(source))
            tables = {row[0] for row in check.execute("SELECT name FROM sqlite_master WHERE type='table'")}
            check.close()
            if not {'assets', 'locations', 'maintenance_records'}.issubset(tables):
                return {'success': False, 'message': 'This file is not a compatible BubtOps database backup.'}
            shutil.copy2(source, self.database_path)
            self._settings_cache = None
            self.ensure_settings_tables()
            self.settingsChanged.emit()
            self.databaseLocationChanged.emit()
            return {'success': True, 'message': 'Database restored. Please restart BubtOps.'}
        except Exception as error:
            return {'success': False, 'message': str(error)}
    @Slot(str, str, result=str)
    def themeColor(self, original, selected_theme):
        """Convert the dark-glass palette into a genuinely light palette.

        Dark navy colours are treated as surfaces even when saturated; only
        sufficiently bright, vivid colours are retained as accents. Alpha is
        preserved so translucent glass layers remain translucent.
        """
        if selected_theme != "Light":
            return original
        value = str(original).strip().lstrip("#")
        if len(value) not in (6, 8):
            return original
        try:
            alpha = None
            if len(value) == 8:
                alpha = int(value[:2], 16)
                value = value[2:]
            r, g, b = (int(value[i:i+2], 16) for i in (0, 2, 4))
            maximum, minimum = max(r, g, b), min(r, g, b)
            saturation = 0 if maximum == 0 else (maximum - minimum) / maximum
            luminance = (0.2126*r + 0.7152*g + 0.0722*b) / 255.0

            # Preserve clear, mid-bright accent colours, not dark navy surfaces.
            if saturation > 0.34 and 0.34 < luminance < 0.78:
                nr, ng, nb = r, g, b
            elif luminance < 0.20:
                nr, ng, nb = (244, 247, 251)  # page / deep surface -> light
            elif luminance < 0.43:
                nr, ng, nb = (229, 235, 243)  # panel / input -> soft light
            elif luminance < 0.68:
                nr, ng, nb = (194, 205, 219)  # muted border / secondary
            elif luminance < 0.86:
                nr, ng, nb = (69, 86, 108)     # light text -> readable dark
            else:
                nr, ng, nb = (27, 42, 61)      # white text -> dark navy

            rgb = f"{nr:02X}{ng:02X}{nb:02X}"
            return f"#{alpha:02X}{rgb}" if alpha is not None else f"#{rgb}"
        except (ValueError, TypeError):
            return original

    @Slot(str, str, result=str)
    def translateText(self, value, selected_language):
        """Translate common fixed interface labels; unknown text remains unchanged."""
        if selected_language != "Bangla":
            return value
        translations = {
            "Overview": "সারসংক্ষেপ", "Asset Registry": "সম্পদের তালিকা",
            "Locations": "অবস্থানসমূহ", "Maintenance": "রক্ষণাবেক্ষণ",
            "Reports": "রিপোর্ট", "Glass Preview": "ডিজাইন প্রিভিউ",
            "Settings": "সেটিংস", "About Application": "অ্যাপ্লিকেশন পরিচিতি",
            "WORKSPACE": "কর্মক্ষেত্র", "OFFLINE MODE": "অফলাইন মোড",
            "Local database active": "স্থানীয় ডেটাবেস সক্রিয়",
            "General Settings": "সাধারণ সেটিংস", "Account Settings": "অ্যাকাউন্ট সেটিংস",
            "Asset Configuration History": "সম্পদ পরিবর্তনের ইতিহাস",
            "Appearance Settings": "ডিজাইন সেটিংস", "Database Settings": "ডেটাবেস সেটিংস",
            "Application Name": "অ্যাপ্লিকেশনের নাম", "Language": "ভাষা",
            "Date Format": "তারিখের ফরম্যাট", "Default Dashboard": "প্রাথমিক ড্যাশবোর্ড",
            "Admin Name": "অ্যাডমিনের নাম", "Username": "ইউজারনেম",
            "New Password (optional)": "নতুন পাসওয়ার্ড (ঐচ্ছিক)",
            "Theme": "থিম", "Font Size": "ফন্টের আকার",
            "Light": "লাইট", "Dark Glass": "ডার্ক গ্লাস",
            "Save Changes": "পরিবর্তন সংরক্ষণ", "Save Appearance": "ডিজাইন সংরক্ষণ",
            "Save Account": "অ্যাকাউন্ট সংরক্ষণ", "Backup Database": "ডেটাবেস ব্যাকআপ",
            "Restore Database": "ডেটাবেস পুনরুদ্ধার", "Backup History": "ব্যাকআপের ইতিহাস",
            "View History": "ইতিহাস দেখুন", "Search History": "ইতিহাস খুঁজুন",
            "Delete Selected": "নির্বাচিতটি মুছুন", "Refresh": "রিফ্রেশ",
            "Search": "খুঁজুন", "All": "সব", "Added": "যুক্ত করা হয়েছে",
            "Updated": "আপডেট করা হয়েছে", "Deleted": "মুছে ফেলা হয়েছে",
            "Connection Status": "সংযোগের অবস্থা", "Database Location": "ডেটাবেসের অবস্থান",
            "English": "ইংরেজি", "Bangla": "বাংলা", "Last 30 Days": "গত ৩০ দিন",
            "All History": "সব ইতিহাস", "All": "সব", "Save Changes": "পরিবর্তন সংরক্ষণ",
            "Save Account": "অ্যাকাউন্ট সংরক্ষণ", "Save Appearance": "ডিজাইন সংরক্ষণ",
            "Set Database Location": "ডেটাবেসের অবস্থান নির্ধারণ", "Search": "খুঁজুন",
            "Delete Selected": "নির্বাচিতটি মুছুন", "Move / Set Location": "অবস্থান পরিবর্তন",
            "Information about this software.": "এই সফটওয়্যার সম্পর্কে তথ্য।",
            "Manage your BubtOps application preferences.": "BubtOps অ্যাপ্লিকেশনের পছন্দসমূহ পরিচালনা করুন।"
        }
        return translations.get(value, value)

    @Slot(str, result=str)
    def formatDate(self, value):
        """Format ISO-like date/time strings according to General Settings."""
        raw = str(value or "")
        if not raw:
            return raw
        fmt = self.dateFormat
        try:
            parsed = None
            for pattern in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d", "%Y-%m-%dT%H:%M:%S"):
                try:
                    parsed = datetime.strptime(raw[:19], pattern)
                    break
                except ValueError:
                    pass
            if parsed is None:
                return raw
            date_pattern = {"DD-MM-YYYY": "%d-%m-%Y", "MM-DD-YYYY": "%m-%d-%Y"}.get(fmt, "%Y-%m-%d")
            result = parsed.strftime(date_pattern)
            if len(raw) > 10 and (":" in raw):
                result += parsed.strftime(" %H:%M:%S")
            return result
        except Exception:
            return raw

    @Slot(str, result='QVariantMap')
    def setDatabaseLocation(self, target_path):
        """Copy the active database to a new location and switch future connections."""
        try:
            raw_target = str(target_path or "").strip()
            if not raw_target:
                return {"success": False, "message": "Choose a database file path."}
            target = Path(raw_target).expanduser()
            if target.suffix.lower() not in (".db", ".sqlite", ".sqlite3"):
                target = target / "bubtops.db"
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.resolve() == self.database_path.resolve():
                return {"success": True, "message": "This is already the active database location.", "path": str(target)}
            shutil.copy2(self.database_path, target)
            self.database_path = target
            self._location_config.parent.mkdir(parents=True, exist_ok=True)
            self._location_config.write_text(json.dumps({"database_path": str(target)}, indent=2), encoding="utf-8")
            self.databaseLocationChanged.emit()
            self.settingsChanged.emit()
            return {"success": True, "message": "Database copied and active location changed.", "path": str(target)}
        except Exception as error:
            return {"success": False, "message": str(error)}

    # --------------------------------------------------------
    # 04. GET ASSETS
    # --------------------------------------------------------

    @Slot(
        str,
        str,
        str,
        str,
        result="QVariantList"
    )
    def getAssets(
        self,
        search_text="",
        condition="",
        status="",
        category=""
    ):

        try:

            query = """
                SELECT
                    a.asset_id,
                    a.asset_code,
                    a.asset_name,
                    a.category,
                    a.purchase_date,
                    a.purchase_cost,
                    a.estimated_repair_cost,
                    a.asset_condition,
                    a.status,
                    a.location_id,
                    l.building,
                    l.floor,
                    l.room

                FROM assets a

                LEFT JOIN locations l
                    ON a.location_id = l.location_id

                WHERE 1 = 1
            """

            parameters = []

            if search_text.strip():

                query += """
                    AND (
                        a.asset_code LIKE ?
                        OR a.asset_name LIKE ?
                        OR a.category LIKE ?
                        OR a.status LIKE ?
                        OR l.building LIKE ?
                    )
                """

                search_value = f"%{search_text.strip()}%"

                parameters.extend([
                    search_value,
                    search_value,
                    search_value,
                    search_value,
                    search_value
                ])

            if condition:

                query += """
                    AND a.asset_condition = ?
                """

                parameters.append(condition)

            if status:

                query += """
                    AND a.status = ?
                """

                parameters.append(status)

            if category:

                query += """
                    AND a.category = ?
                """

                parameters.append(category)

            query += """
                ORDER BY a.asset_id DESC
            """

            with self.connect_database() as connection:

                rows = connection.execute(
                    query,
                    parameters
                ).fetchall()

                return [
                    dict(row)
                    for row in rows
                ]

        except Exception as error:

            print("Asset loading error:", error)

            return []

    # --------------------------------------------------------
    # 05. GET LOCATIONS
    # --------------------------------------------------------

    @Slot(result="QVariantList")
    def getLocations(self):

        try:

            with self.connect_database() as connection:

                rows = connection.execute("""
                    SELECT
                        location_id,
                        building,
                        floor,
                        room

                    FROM locations

                    ORDER BY building, floor, room
                """).fetchall()

                return [
                    dict(row)
                    for row in rows
                ]

        except Exception as error:

            print("Location loading error:", error)

            return []

    # --------------------------------------------------------
    # 06. GET CATEGORIES
    # --------------------------------------------------------

    @Slot(result="QVariantList")
    def getCategories(self):

        try:

            with self.connect_database() as connection:

                rows = connection.execute("""
                    SELECT DISTINCT category
                    FROM assets
                    WHERE category IS NOT NULL
                    AND category != ''
                    ORDER BY category
                """).fetchall()

                return [
                    row["category"]
                    for row in rows
                ]

        except Exception as error:

            print("Category loading error:", error)

            return []

    # --------------------------------------------------------
    # 07. GET LIVE DASHBOARD DATA
    # --------------------------------------------------------

    @Slot(result="QVariantMap")
    def getDashboardData(self):
        """Return live dashboard totals, condition counts and queue rows."""
        try:
            with self.connect_database() as connection:
                asset_columns = {
                    row["name"]
                    for row in connection.execute(
                        "PRAGMA table_info(assets)"
                    ).fetchall()
                }

                required = {"asset_id", "status", "asset_condition"}
                missing = required - asset_columns
                if missing:
                    raise RuntimeError(
                        "The assets table is missing required columns: "
                        + ", ".join(sorted(missing))
                    )

                def pick(columns, candidates):
                    for candidate in candidates:
                        if candidate in columns:
                            return candidate
                    return None

                asset_code_col = pick(
                    asset_columns, ["asset_code", "asset_tag", "code"]
                )
                asset_name_col = pick(
                    asset_columns, ["asset_name", "name", "item_name"]
                )
                location_id_col = pick(
                    asset_columns, ["location_id"]
                )
                purchase_cost_col = pick(
                    asset_columns, ["purchase_cost", "purchase_value", "cost"]
                )

                status_expr = "LOWER(TRIM(COALESCE(status, '')))"
                condition_expr = "LOWER(TRIM(COALESCE(asset_condition, '')))"
                attention_statuses = (
                    "'needs maintenance', 'under maintenance', 'out of service'"
                )
                attention_conditions = (
                    "'poor', 'damaged', 'critical', 'needs repair'"
                )
                attention_predicate = f"""
                    ({status_expr} IN ({attention_statuses})
                     OR {condition_expr} IN ({attention_conditions}))
                """

                stats = connection.execute(f"""
                    SELECT
                        COUNT(*) AS total_assets,
                        COALESCE(SUM(CASE
                            WHEN {status_expr} = 'in service'
                            THEN 1 ELSE 0 END), 0) AS in_service,
                        COALESCE(SUM(CASE
                            WHEN {attention_predicate}
                            THEN 1 ELSE 0 END), 0) AS needs_attention,
                        COALESCE(SUM(CASE
                            WHEN {condition_expr} = 'good'
                            THEN 1 ELSE 0 END), 0) AS good_condition,
                        COALESCE(SUM(CASE
                            WHEN {condition_expr} = 'fair'
                            THEN 1 ELSE 0 END), 0) AS fair_condition,
                        COALESCE(SUM(CASE
                            WHEN {condition_expr} IN ({attention_conditions})
                            THEN 1 ELSE 0 END), 0) AS attention_condition
                    FROM assets
                """).fetchone()

                total_assets = int(stats["total_assets"] or 0)
                in_service = int(stats["in_service"] or 0)
                needs_attention = int(stats["needs_attention"] or 0)
                good_condition = int(stats["good_condition"] or 0)
                fair_condition = int(stats["fair_condition"] or 0)
                attention_condition = int(stats["attention_condition"] or 0)
                other_condition = max(
                    0,
                    total_assets - good_condition - fair_condition
                    - attention_condition
                )

                # ---------------------------------------------
                # Maintenance data (columns are detected instead
                # of assuming every database has identical labels).
                # ---------------------------------------------
                maintenance_cost = 0.0
                maintenance_record_count = 0
                recent_records = []
                queue_mode = "maintenance"
                maintenance_table = connection.execute("""
                    SELECT name FROM sqlite_master
                    WHERE type = 'table' AND name = 'maintenance_records'
                """).fetchone()

                maintenance_columns = set()
                if maintenance_table:
                    maintenance_columns = {
                        row["name"]
                        for row in connection.execute(
                            "PRAGMA table_info(maintenance_records)"
                        ).fetchall()
                    }

                cost_col = pick(
                    maintenance_columns,
                    ["cost", "maintenance_cost", "repair_cost", "actual_cost", "total_cost", "amount", "expense", "maintenance_expense"]
                )
                date_col = pick(
                    maintenance_columns,
                    ["maintenance_date", "service_date", "date", "created_at"]
                )
                description_col = pick(
                    maintenance_columns,
                    ["description", "maintenance_type", "issue", "work_description", "notes"]
                )
                record_status_col = pick(
                    maintenance_columns,
                    ["status", "maintenance_status"]
                )
                maintenance_id_col = pick(
                    maintenance_columns,
                    ["maintenance_id", "record_id", "id"]
                )

                if maintenance_table:
                    maintenance_record_count = int(connection.execute(
                        "SELECT COUNT(*) FROM maintenance_records"
                    ).fetchone()[0] or 0)

                    if cost_col:
                        maintenance_cost = float(connection.execute(
                            f"SELECT COALESCE(SUM(COALESCE(\"{cost_col}\", 0)), 0) "
                            "FROM maintenance_records"
                        ).fetchone()[0] or 0)

                    if "asset_id" in maintenance_columns:
                        asset_code_sql = (
                            f"COALESCE(a.\"{asset_code_col}\", '—')"
                            if asset_code_col else "'—'"
                        )
                        asset_name_sql = (
                            f"COALESCE(a.\"{asset_name_col}\", 'Unnamed asset')"
                            if asset_name_col else "'Unnamed asset'"
                        )
                        date_sql = (
                            f"COALESCE(m.\"{date_col}\", '')"
                            if date_col else "''"
                        )
                        description_sql = (
                            f"COALESCE(m.\"{description_col}\", '')"
                            if description_col else "''"
                        )
                        status_sql = (
                            f"COALESCE(m.\"{record_status_col}\", 'Unknown')"
                            if record_status_col else "'Unknown'"
                        )
                        cost_sql = (
                            f"COALESCE(m.\"{cost_col}\", 0)"
                            if cost_col else "0"
                        )
                        order_sql = (
                            f"m.\"{maintenance_id_col}\" DESC"
                            if maintenance_id_col else "m.rowid DESC"
                        )

                        location_join = ""
                        building_sql = "'Not assigned'"
                        if location_id_col:
                            location_table = connection.execute("""
                                SELECT name FROM sqlite_master
                                WHERE type = 'table' AND name = 'locations'
                            """).fetchone()
                            if location_table:
                                location_columns = {
                                    row["name"]
                                    for row in connection.execute(
                                        "PRAGMA table_info(locations)"
                                    ).fetchall()
                                }
                                building_col = pick(
                                    location_columns,
                                    ["building", "building_name", "name"]
                                )
                                location_pk = pick(
                                    location_columns,
                                    ["location_id", "id"]
                                )
                                if building_col and location_pk:
                                    location_join = (
                                        f"LEFT JOIN locations l ON l.\"{location_pk}\" "
                                        f"= a.\"{location_id_col}\""
                                    )
                                    building_sql = (
                                        f"COALESCE(l.\"{building_col}\", 'Not assigned')"
                                    )

                        query = f"""
                            SELECT
                                m.asset_id AS asset_id,
                                {date_sql} AS maintenance_date,
                                {asset_code_sql} AS asset_code,
                                {asset_name_sql} AS asset_name,
                                {building_sql} AS building,
                                {description_sql} AS description,
                                {status_sql} AS status,
                                {cost_sql} AS cost,
                                'maintenance' AS record_type
                            FROM maintenance_records m
                            LEFT JOIN assets a ON a.asset_id = m.asset_id
                            {location_join}
                            ORDER BY {order_sql}
                            LIMIT 5
                        """
                        recent_records = [
                            dict(row)
                            for row in connection.execute(query).fetchall()
                        ]

                # If there are no maintenance records yet, show assets
                # whose status/condition needs attention instead of a blank
                # queue. This does not create or modify maintenance records.
                if not recent_records:
                    queue_mode = "attention"
                    asset_code_sql = (
                        f"COALESCE(a.\"{asset_code_col}\", '—')"
                        if asset_code_col else "'—'"
                    )
                    asset_name_sql = (
                        f"COALESCE(a.\"{asset_name_col}\", 'Unnamed asset')"
                        if asset_name_col else "'Unnamed asset'"
                    )
                    condition_sql = "COALESCE(a.asset_condition, 'Unknown')"
                    status_sql = "COALESCE(a.status, 'Unknown')"
                    location_join = ""
                    building_sql = "'Not assigned'"

                    if location_id_col:
                        location_table = connection.execute("""
                            SELECT name FROM sqlite_master
                            WHERE type = 'table' AND name = 'locations'
                        """).fetchone()
                        if location_table:
                            location_columns = {
                                row["name"]
                                for row in connection.execute(
                                    "PRAGMA table_info(locations)"
                                ).fetchall()
                            }
                            building_col = pick(
                                location_columns,
                                ["building", "building_name", "name"]
                            )
                            location_pk = pick(
                                location_columns,
                                ["location_id", "id"]
                            )
                            if building_col and location_pk:
                                location_join = (
                                    f"LEFT JOIN locations l ON l.\"{location_pk}\" "
                                    f"= a.\"{location_id_col}\""
                                )
                                building_sql = (
                                    f"COALESCE(l.\"{building_col}\", 'Not assigned')"
                                )

                    purchase_value_sql = (
                        f"COALESCE(a.\"{purchase_cost_col}\", 0)"
                        if purchase_cost_col else "0"
                    )
                    attention_query = f"""
                        SELECT
                            a.asset_id AS asset_id,
                            '' AS maintenance_date,
                            {asset_code_sql} AS asset_code,
                            {asset_name_sql} AS asset_name,
                            {building_sql} AS building,
                            ('Status: ' || {status_sql} || ' · Condition: ' || {condition_sql}) AS description,
                            {status_sql} AS status,
                            {purchase_value_sql} AS cost,
                            'attention' AS record_type
                        FROM assets a
                        {location_join}
                        WHERE {attention_predicate.replace('status', 'a.status').replace('asset_condition', 'a.asset_condition')}
                        ORDER BY a.asset_id DESC
                        LIMIT 5
                    """
                    recent_records = [
                        dict(row)
                        for row in connection.execute(attention_query).fetchall()
                    ]

                operational_rate = (
                    (in_service / total_assets) * 100
                    if total_assets else 0.0
                )

                # Always return the complete attention list separately from
                # maintenance history. The dashboard can scroll this list
                # without limiting it to the five latest maintenance records.
                attention_assets = self.getAttentionAssets()

                return {
                    "success": True,
                    "totalAssets": total_assets,
                    "inService": in_service,
                    "needsAttention": needs_attention,
                    "maintenanceCost": maintenance_cost,
                    "operationalRate": operational_rate,
                    "goodCondition": good_condition,
                    "fairCondition": fair_condition,
                    "attentionCondition": attention_condition,
                    "otherCondition": other_condition,
                    "maintenanceRecordCount": maintenance_record_count,
                    "queueCount": len(recent_records),
                    "queueMode": queue_mode,
                    "recentRecords": recent_records,
                    "attentionAssets": attention_assets,
                    "error": ""
                }

        except Exception as error:
            print("Dashboard data error:", error)
            return {
                "success": False,
                "totalAssets": 0,
                "inService": 0,
                "needsAttention": 0,
                "maintenanceCost": 0.0,
                "operationalRate": 0.0,
                "goodCondition": 0,
                "fairCondition": 0,
                "attentionCondition": 0,
                "otherCondition": 0,
                "maintenanceRecordCount": 0,
                "queueCount": 0,
                "queueMode": "maintenance",
                "recentRecords": [],
                "attentionAssets": [],
                "error": str(error)
            }

    # --------------------------------------------------------
    # 07A. GET ALL ASSETS THAT NEED ATTENTION
    # --------------------------------------------------------

    @Slot(result="QVariantList")
    def getAttentionAssets(self):
        """Return every asset flagged for repair, service or inspection."""
        try:
            with self.connect_database() as connection:
                asset_columns = {
                    row["name"]
                    for row in connection.execute(
                        "PRAGMA table_info(assets)"
                    ).fetchall()
                }

                required = {
                    "asset_id", "asset_code", "asset_name", "category",
                    "asset_condition", "status"
                }
                missing = required - asset_columns
                if missing:
                    raise RuntimeError(
                        "The assets table is missing required columns: "
                        + ", ".join(sorted(missing))
                    )

                location_columns = set()
                location_exists = connection.execute("""
                    SELECT 1 FROM sqlite_master
                    WHERE type = 'table' AND name = 'locations'
                """).fetchone() is not None

                if location_exists:
                    location_columns = {
                        row["name"]
                        for row in connection.execute(
                            "PRAGMA table_info(locations)"
                        ).fetchall()
                    }

                def pick(columns, candidates):
                    for candidate in candidates:
                        if candidate in columns:
                            return candidate
                    return None

                def asset_expr(column, fallback="''"):
                    if column and column in asset_columns:
                        return f'a."{column}"'
                    return fallback

                purchase_date_col = pick(
                    asset_columns, ["purchase_date", "acquisition_date"]
                )
                purchase_cost_col = pick(
                    asset_columns, ["purchase_cost", "purchase_value", "cost"]
                )
                repair_cost_col = pick(
                    asset_columns, ["estimated_repair_cost", "repair_cost"]
                )
                location_id_col = pick(asset_columns, ["location_id"])
                location_pk = pick(location_columns, ["location_id", "id"])
                building_col = pick(
                    location_columns, ["building", "building_name", "name"]
                )
                floor_col = pick(location_columns, ["floor", "floor_name"])
                room_col = pick(location_columns, ["room", "room_name"])

                location_join = ""
                building_sql = "'Not assigned'"
                floor_sql = "''"
                room_sql = "''"

                if (
                    location_exists and location_id_col
                    and location_pk and building_col
                ):
                    location_join = (
                        f'LEFT JOIN locations l '
                        f'ON l."{location_pk}" = a."{location_id_col}"'
                    )
                    building_sql = f"COALESCE(l.\"{building_col}\", 'Not assigned')"
                    if floor_col:
                        floor_sql = f"COALESCE(l.\"{floor_col}\", '')"
                    if room_col:
                        room_sql = f"COALESCE(l.\"{room_col}\", '')"

                status_expr = "LOWER(TRIM(COALESCE(a.status, '')))"
                condition_expr = "LOWER(TRIM(COALESCE(a.asset_condition, '')))"

                # Keep these labels aligned with getDashboardData() so the
                # KPI count and the clickable attention list describe the same assets.
                attention_statuses = (
                    "'needs maintenance', 'under maintenance', 'out of service'"
                )
                attention_conditions = (
                    "'poor', 'damaged', 'critical', 'needs repair'"
                )

                query = f"""
                    SELECT
                        a.asset_id AS asset_id,
                        {asset_expr('asset_code', "'—'")} AS asset_code,
                        {asset_expr('asset_name', "'Unnamed asset'")} AS asset_name,
                        {asset_expr('category', "'Uncategorized'")} AS category,
                        {asset_expr(purchase_date_col)} AS purchase_date,
                        COALESCE({asset_expr(purchase_cost_col, '0')}, 0) AS purchase_cost,
                        COALESCE({asset_expr(repair_cost_col, '0')}, 0) AS estimated_repair_cost,
                        COALESCE(a.asset_condition, 'Unknown') AS asset_condition,
                        COALESCE(a.status, 'Unknown') AS status,
                        {asset_expr(location_id_col, 'NULL')} AS location_id,
                        {building_sql} AS building,
                        {floor_sql} AS floor,
                        {room_sql} AS room
                    FROM assets a
                    {location_join}
                    WHERE
                        {status_expr} IN ({attention_statuses})
                        OR {condition_expr} IN ({attention_conditions})
                    ORDER BY
                        CASE
                            WHEN {status_expr} = 'out of service' THEN 0
                            WHEN {condition_expr} = 'critical' THEN 1
                            WHEN {status_expr} = 'under maintenance' THEN 2
                            ELSE 3
                        END,
                        a.asset_id DESC
                """

                return [
                    dict(row)
                    for row in connection.execute(query).fetchall()
                ]

        except Exception as error:
            print("Attention asset loading error:", error)
            return []

    # --------------------------------------------------------
    # 07B. GET MAINTENANCE HISTORY FOR ONE ASSET
    # --------------------------------------------------------

    @Slot(int, result="QVariantList")
    def getAssetMaintenanceHistory(self, asset_id):
        """Return recent maintenance records for the selected asset."""
        try:
            with self.connect_database() as connection:
                table_exists = connection.execute("""
                    SELECT 1 FROM sqlite_master
                    WHERE type = 'table' AND name = 'maintenance_records'
                """).fetchone() is not None

                if not table_exists:
                    return []

                columns = {
                    row["name"]
                    for row in connection.execute(
                        "PRAGMA table_info(maintenance_records)"
                    ).fetchall()
                }

                if "asset_id" not in columns:
                    return []

                def pick(candidates):
                    for candidate in candidates:
                        if candidate in columns:
                            return candidate
                    return None

                date_col = pick([
                    "maintenance_date", "service_date", "date", "created_at"
                ])
                description_col = pick([
                    "description", "maintenance_type", "issue",
                    "work_description", "notes"
                ])
                status_col = pick(["status", "maintenance_status"])
                cost_col = pick(["cost", "maintenance_cost", "repair_cost", "actual_cost", "total_cost", "amount", "expense", "maintenance_expense"])
                id_col = pick(["maintenance_id", "record_id", "id"])

                date_sql = f'm."{date_col}"' if date_col else "''"
                description_sql = f'm."{description_col}"' if description_col else "''"
                status_sql = f'm."{status_col}"' if status_col else "'Unknown'"
                cost_sql = f'COALESCE(m."{cost_col}", 0)' if cost_col else "0"
                order_sql = f'm."{id_col}" DESC' if id_col else "m.rowid DESC"

                rows = connection.execute(f"""
                    SELECT
                        {date_sql} AS maintenance_date,
                        {description_sql} AS description,
                        {status_sql} AS status,
                        {cost_sql} AS cost
                    FROM maintenance_records m
                    WHERE m.asset_id = ?
                    ORDER BY {order_sql}
                    LIMIT 12
                """, (int(asset_id),)).fetchall()

                return [dict(row) for row in rows]

        except Exception as error:
            print("Asset maintenance history error:", error)
            return []

    # --------------------------------------------------------
    # 07C. MAINTENANCE RECORDS: READ AND REGISTER
    # --------------------------------------------------------

    @Slot(result="QVariantList")
    def getMaintenanceRecords(self):
        """Return maintenance records joined to their asset and location."""
        try:
            with self.connect_database() as connection:
                table_exists = connection.execute("""
                    SELECT 1 FROM sqlite_master
                    WHERE type = 'table' AND name = 'maintenance_records'
                """).fetchone() is not None

                if not table_exists:
                    return []

                maintenance_columns = {
                    row["name"] for row in connection.execute(
                        "PRAGMA table_info(maintenance_records)"
                    ).fetchall()
                }
                asset_columns = {
                    row["name"] for row in connection.execute(
                        "PRAGMA table_info(assets)"
                    ).fetchall()
                }

                def pick(columns, candidates):
                    for candidate in candidates:
                        if candidate in columns:
                            return candidate
                    return None

                def expr(alias, column, fallback):
                    return f'{alias}."{column}"' if column else fallback

                date_col = pick(maintenance_columns, [
                    "maintenance_date", "service_date", "date", "created_at"
                ])
                description_col = pick(maintenance_columns, [
                    "description", "work_description", "issue", "notes", "maintenance_type"
                ])
                status_col = pick(maintenance_columns, ["status", "maintenance_status"])
                cost_col = pick(maintenance_columns, [
                    "cost", "maintenance_cost", "repair_cost", "actual_cost",
                    "total_cost", "amount", "expense", "maintenance_expense"
                ])
                id_col = pick(maintenance_columns, ["maintenance_id", "record_id", "id"])
                asset_name_col = pick(asset_columns, ["asset_name", "name", "item_name"])
                asset_code_col = pick(asset_columns, ["asset_code", "asset_tag", "code"])
                asset_category_col = pick(asset_columns, ["category", "asset_category"])

                location_join = ""
                building_sql = "'Not assigned'"
                if "location_id" in asset_columns:
                    location_table = connection.execute("""
                        SELECT 1 FROM sqlite_master
                        WHERE type = 'table' AND name = 'locations'
                    """).fetchone() is not None
                    if location_table:
                        location_columns = {
                            row["name"] for row in connection.execute(
                                "PRAGMA table_info(locations)"
                            ).fetchall()
                        }
                        location_pk = pick(location_columns, ["location_id", "id"])
                        building_col = pick(location_columns, ["building", "building_name", "name"])
                        if location_pk and building_col:
                            location_join = (
                                f'LEFT JOIN locations l ON l."{location_pk}" = a.location_id'
                            )
                            building_sql = f'COALESCE(l."{building_col}", \'Not assigned\')'

                date_sql = expr("m", date_col, "''")
                description_sql = expr("m", description_col, "''")
                status_sql = expr("m", status_col, "'Unknown'")
                cost_sql = f'COALESCE({expr("m", cost_col, "0")}, 0)'
                id_order = f'm."{id_col}" DESC' if id_col else "m.rowid DESC"
                name_sql = expr("a", asset_name_col, "'Unnamed asset'")
                code_sql = expr("a", asset_code_col, "'—'")
                category_sql = expr("a", asset_category_col, "''")

                if "asset_id" not in maintenance_columns:
                    return []

                rows = connection.execute(f"""
                    SELECT
                        m.asset_id AS asset_id,
                        {date_sql} AS maintenance_date,
                        {description_sql} AS description,
                        {status_sql} AS status,
                        {cost_sql} AS cost,
                        {name_sql} AS asset_name,
                        {code_sql} AS asset_code,
                        {category_sql} AS category,
                        {building_sql} AS building
                    FROM maintenance_records m
                    LEFT JOIN assets a ON a.asset_id = m.asset_id
                    {location_join}
                    ORDER BY {id_order}
                """).fetchall()

                return [dict(row) for row in rows]

        except Exception as error:
            print("Maintenance records loading error:", error)
            return []

    @Slot("QVariantMap", result="QVariantMap")
    def saveMaintenanceRecord(self, data):
        """Insert one maintenance expense using the existing table schema."""
        try:
            asset_id = int(data.get("asset_id") or 0)
            maintenance_date = str(data.get("maintenance_date", "")).strip()
            description = str(data.get("description", "")).strip()
            status = str(data.get("status", "Completed")).strip()

            try:
                cost = float(str(data.get("cost", "0")).replace(",", "").strip() or 0)
            except (TypeError, ValueError):
                return {"success": False, "message": "Enter a valid maintenance cost."}

            if asset_id <= 0:
                return {"success": False, "message": "Select an asset first."}
            if not description:
                return {"success": False, "message": "Enter a description of the maintenance work."}
            if cost < 0:
                return {"success": False, "message": "Maintenance cost cannot be negative."}
            try:
                datetime.strptime(maintenance_date, "%Y-%m-%d")
            except ValueError:
                return {"success": False, "message": "Use YYYY-MM-DD for the maintenance date."}

            now_text = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            allowed_statuses = {"Pending", "In Progress", "Completed"}
            if status not in allowed_statuses:
                return {"success": False, "message": "Choose a valid maintenance status."}

            with self.connect_database() as connection:
                asset_exists = connection.execute(
                    "SELECT 1 FROM assets WHERE asset_id = ?", (asset_id,)
                ).fetchone()
                if not asset_exists:
                    return {"success": False, "message": "The selected asset no longer exists."}

                table_exists = connection.execute("""
                    SELECT 1 FROM sqlite_master
                    WHERE type = 'table' AND name = 'maintenance_records'
                """).fetchone() is not None
                if not table_exists:
                    return {
                        "success": False,
                        "message": "The maintenance_records table does not exist in this database."
                    }

                columns = connection.execute(
                    "PRAGMA table_info(maintenance_records)"
                ).fetchall()
                column_names = {row["name"] for row in columns}

                cost_candidates = [
                    "cost", "maintenance_cost", "repair_cost", "actual_cost",
                    "total_cost", "amount", "expense", "maintenance_expense"
                ]
                date_candidates = ["maintenance_date", "service_date", "date", "created_at"]
                description_candidates = [
                    "description", "work_description", "issue", "notes", "maintenance_type"
                ]
                status_candidates = ["status", "maintenance_status"]

                values = {}
                for column in columns:
                    name = column["name"]
                    key = name.lower()

                    if key == "asset_id":
                        values[name] = asset_id
                    elif key in date_candidates:
                        values[name] = maintenance_date
                    elif key in description_candidates:
                        values[name] = description
                    elif key in cost_candidates:
                        values[name] = cost
                    elif key in status_candidates:
                        values[name] = status
                    elif key in ("work_type", "type"):
                        values[name] = "Repair / Service"
                    elif key in ("technician", "technician_name", "assigned_to", "performed_by", "handled_by"):
                        values[name] = "Not specified"
                    elif key in ("created_at", "updated_at", "recorded_at"):
                        values[name] = now_text
                    elif key in ("created_by", "recorded_by"):
                        values[name] = "Local user"

                required_missing = []
                for column in columns:
                    name = column["name"]
                    is_primary_key = int(column["pk"] or 0) > 0
                    requires_value = (
                        int(column["notnull"] or 0) == 1
                        and column["dflt_value"] is None
                        and not is_primary_key
                        and name not in values
                    )
                    if requires_value:
                        required_missing.append(name)

                if required_missing:
                    return {
                        "success": False,
                        "message": (
                            "Your maintenance table requires additional fields: "
                            + ", ".join(required_missing)
                            + ". Send me the table structure so I can add them to the form."
                        )
                    }

                if "asset_id" not in values:
                    return {"success": False, "message": "The maintenance table has no asset_id column."}
                if not any(name in values for name in date_candidates):
                    return {"success": False, "message": "The maintenance table has no supported date column."}
                if not any(name in values for name in description_candidates):
                    return {"success": False, "message": "The maintenance table has no supported description column."}
                if not any(name in values for name in cost_candidates):
                    return {"success": False, "message": "The maintenance table has no supported cost column."}

                quoted_columns = [f'"{name.replace(chr(34), chr(34) * 2)}"' for name in values]
                placeholders = ", ".join("?" for _ in values)
                sql = (
                    "INSERT INTO maintenance_records ("
                    + ", ".join(quoted_columns)
                    + ") VALUES ("
                    + placeholders
                    + ")"
                )
                cursor = connection.execute(sql, list(values.values()))
                new_id = int(cursor.lastrowid or 0)

            self.maintenanceChanged.emit()

            return {
                "success": True,
                "message": "Maintenance record saved successfully.",
                "record_id": new_id
            }

        except sqlite3.IntegrityError as error:
            return {
                "success": False,
                "message": "Database constraint error: " + str(error)
            }
        except Exception as error:
            print("Maintenance record save error:", error)
            return {"success": False, "message": str(error)}

    # --------------------------------------------------------
    # 08. SAVE / UPDATE ASSET
    # --------------------------------------------------------

    @Slot("QVariantMap", result="QVariantMap")
    def saveAsset(self, data):

        try:

            asset_id = int(
                data.get("asset_id") or 0
            )

            asset_code = str(
                data.get("asset_code", "")
            ).strip()

            asset_name = str(
                data.get("asset_name", "")
            ).strip()

            category = str(
                data.get("category", "")
            ).strip()

            asset_condition = str(
                data.get("asset_condition", "Good")
            ).strip()

            status = str(
                data.get("status", "In Service")
            ).strip()

            purchase_date = str(
                data.get("purchase_date", "")
            ).strip()

            if not asset_code or not asset_name or not category:

                return {
                    "success": False,
                    "message": (
                        "Asset code, name and category "
                        "are required."
                    )
                }

            if purchase_date:

                try:

                    datetime.strptime(
                        purchase_date,
                        "%Y-%m-%d"
                    )

                except ValueError:

                    return {
                        "success": False,
                        "message": (
                            "Purchase date must use "
                            "YYYY-MM-DD format."
                        )
                    }

            try:

                purchase_cost = float(
                    str(
                        data.get("purchase_cost", 0)
                    ).replace(",", "").strip() or 0
                )

                estimated_repair_cost = float(
                    str(
                        data.get("estimated_repair_cost", 0)
                    ).replace(",", "").strip() or 0
                )

                if (
                    purchase_cost < 0
                    or estimated_repair_cost < 0
                ):
                    raise ValueError

            except ValueError:

                return {
                    "success": False,
                    "message": (
                        "Enter valid non-negative "
                        "cost values."
                    )
                }

            location_value = data.get("location_id")

            location_id = (
                int(location_value)
                if location_value not in (None, "")
                else None
            )

            allowed_conditions = [
                "Good",
                "Fair",
                "Poor",
                "Damaged",
                "Critical"
            ]

            allowed_statuses = [
                "In Service",
                "Needs Maintenance",
                "Under Maintenance",
                "Out of Service"
            ]

            if asset_condition not in allowed_conditions:

                return {
                    "success": False,
                    "message": "Invalid asset condition."
                }

            if status not in allowed_statuses:

                return {
                    "success": False,
                    "message": "Invalid asset status."
                }

            with self.connect_database() as connection:

                values = (
                    asset_code, asset_name, category, location_id,
                    asset_condition, status, purchase_date or None,
                    purchase_cost, estimated_repair_cost
                )
                updated_snapshot = {
                    'Asset Code': asset_code, 'Asset Name': asset_name,
                    'Category': category, 'Location ID': location_id,
                    'Condition': asset_condition, 'Status': status,
                    'Purchase Date': purchase_date, 'Purchase Cost': purchase_cost,
                    'Estimated Repair Cost': estimated_repair_cost
                }

                if asset_id > 0:
                    old_row = connection.execute("""
                        SELECT asset_code, asset_name, category, location_id,
                               asset_condition, status, purchase_date,
                               purchase_cost, estimated_repair_cost
                        FROM assets WHERE asset_id=?
                    """, (asset_id,)).fetchone()
                    if not old_row:
                        return {'success': False, 'message': 'Asset not found.'}
                    previous_snapshot = dict(old_row)
                    connection.execute("""
                        UPDATE assets SET asset_code=?, asset_name=?, category=?,
                            location_id=?, asset_condition=?, status=?, purchase_date=?,
                            purchase_cost=?, estimated_repair_cost=?
                        WHERE asset_id=?
                    """, values + (asset_id,))
                    action = 'Updated'
                    history_asset_id = asset_id
                    message = 'Asset updated successfully. History record created.'
                else:
                    cursor = connection.execute("""
                        INSERT INTO assets (
                            asset_code, asset_name, category, location_id,
                            asset_condition, status, purchase_date,
                            purchase_cost, estimated_repair_cost
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, values)
                    history_asset_id = cursor.lastrowid
                    previous_snapshot = {}
                    action = 'Added'
                    message = 'Asset added successfully. History record created.'

                connection.execute("""
                    INSERT INTO asset_history (
                        asset_id, asset_code, asset_name, action_type,
                        previous_info, updated_info, performed_by, action_time
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    history_asset_id, asset_code, asset_name, action,
                    json.dumps(previous_snapshot, ensure_ascii=False, default=str),
                    json.dumps(updated_snapshot, ensure_ascii=False, default=str),
                    'Administrator', datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                ))

            self.assetsChanged.emit()

            return {
                "success": True,
                "message": message
            }

        except sqlite3.IntegrityError:

            return {
                "success": False,
                "message": (
                    "Database constraint error. "
                    "Check whether the asset code "
                    "already exists or the location is valid."
                )
            }

        except Exception as error:

            return {
                "success": False,
                "message": str(error)
            }

    # --------------------------------------------------------
    # 09. DELETE ASSET
    # --------------------------------------------------------

    @Slot(int, result="QVariantMap")
    def deleteAsset(self, asset_id):

        try:

            with self.connect_database() as connection:

                linked_records = connection.execute("""
                    SELECT COUNT(*)
                    FROM maintenance_records
                    WHERE asset_id = ?
                """, (asset_id,)).fetchone()[0]

                if linked_records > 0:

                    return {
                        "success": False,
                        "message": (
                            "This asset has maintenance records. "
                            "It cannot be deleted."
                        )
                    }

                asset_row = connection.execute("""
                    SELECT asset_code, asset_name, category, location_id,
                           asset_condition, status, purchase_date,
                           purchase_cost, estimated_repair_cost
                    FROM assets WHERE asset_id=?
                """, (asset_id,)).fetchone()

                cursor = connection.execute("""
                    DELETE FROM assets
                    WHERE asset_id = ?
                """, (asset_id,))

                if cursor.rowcount == 0:

                    return {
                        "success": False,
                        "message": "Asset not found."
                    }

                connection.execute("""
                    INSERT INTO asset_history (
                        asset_id, asset_code, asset_name, action_type,
                        previous_info, updated_info, performed_by, action_time
                    ) VALUES (?, ?, ?, 'Deleted', ?, '', 'Administrator', ?)
                """, (
                    asset_id, asset_row['asset_code'], asset_row['asset_name'],
                    json.dumps(dict(asset_row), ensure_ascii=False, default=str),
                    datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                ))

            self.assetsChanged.emit()

            return {
                "success": True,
                "message": "Asset deleted successfully."
            }

        except Exception as error:

            return {
                "success": False,
                "message": str(error)
            }


# ============================================================
# 09. APPLICATION ENTRY POINT
# ============================================================

def main():

    QQuickStyle.setStyle("Basic")

    app = QGuiApplication(sys.argv)

    # Load the application-wide font.
    load_application_font(app)

    view = QQuickView()

    # Create the Python database backend.
    backend = AssetBackend()

    # Make Python functions available to QML.
    view.rootContext().setContextProperty(
        "assetBackend",
        backend
    )

    # Window configuration
    view.setTitle(backend.applicationName + " | Campus Asset Management")
    backend.settingsChanged.connect(
        lambda: view.setTitle(backend.applicationName + " | Campus Asset Management")
    )

    view.setResizeMode(
        QQuickView.ResizeMode.SizeRootObjectToView
    )

    # Keep a sensible minimum size so the dashboard layouts do not
    # collapse into one another when the user restores the window.
    view.setMinimumSize(
        QSize(950, 600)
    )

    # Give Windows a sensible restore size. The app still starts maximized,
    # but restoring it will return to a window that fits the current screen.
    screen = app.primaryScreen()
    if screen is not None:
        available = screen.availableGeometry()
        initial_width = min(1200, max(950, available.width() - 80))
        initial_height = min(680, max(600, available.height() - 80))
        initial_x = available.x() + (available.width() - initial_width) // 2
        initial_y = available.y() + (available.height() - initial_height) // 2
        view.setGeometry(
            initial_x,
            initial_y,
            initial_width,
            initial_height
        )

    # Load main QML file
    qml_file = PROJECT_DIR / "main.qml"

    view.setSource(
        QUrl.fromLocalFile(str(qml_file))
    )

    # Check QML errors
    if view.status() == QQuickView.Status.Error:

        for error in view.errors():
            print(error.toString())

        return 1

    # Start maximized so the dashboard has the full usable desktop area
    # immediately instead of opening at the QML design size (1200 x 760).
    view.showMaximized()

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
