BUBT-OPS SETTINGS INTEGRATION (NO LOGIN SYSTEM)

This build integrates the Settings module with the existing PySide6/QML application.

Implemented integrations:
- Application Name updates visible branding and the desktop window title.
- Language preference translates common fixed interface labels into Bangla; English remains default.
- Date Format is used for the dashboard date and dates shown in History, Backup History, Maintenance and Needs Attention views where formatted.
- Default Dashboard selects Overview or Asset Registry on next application launch.
- Admin Name and Username are stored in the local admin profile. Password can be stored as a salted PBKDF2 hash, but NO login/authentication system is included, as requested.
- Asset Add/Update/Delete records are written to asset_history.
- Light/Dark theme remaps neutral interface colors across QML components; vivid accent colors are retained.
- Font Size scales QML text sizes application-wide.
- Database Location copies the active database to a selected path entered in the field and saves that path in data/db_location.json. Future launches use that database path.
- Backup and Restore remain available. Restore replaces the active database; restart the app after restore.

Important notes:
1. Make a backup before changing database location or restoring a database.
2. Database Location expects a full file path ending in .db, .sqlite, or .sqlite3; if a folder path is entered, bubtops.db is created inside it.
3. Language translation covers common fixed UI labels; user-entered data and some dynamically composed text remain as entered/in English.
4. The Account Settings page stores Admin Name/Username and a password hash only; no login screen or authentication is present.
5. Keep the data folder and assets/components folders with main.py and main.qml.

Run:
  pip install PySide6
  python main.py
