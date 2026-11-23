BubtOps Settings Integration Update
===================================

This update adds a Settings page and a separate About Application page to the
existing BubtOps PySide6 / Qt Quick project. The visual style follows the
current dark glass / aurora interface and uses the existing SQLite database:

  data/bubtops.db

New files:
  components/SettingsPage.qml
  components/AboutPage.qml

Updated files:
  main.py
  main.qml

Settings navigation:
  General Settings
  Account Settings
  Asset Configuration History
  Appearance Settings
  Database Settings

Only the selected Settings section is displayed in the content area. The
Settings navigation stays visible on the left. About Application is a separate
main navigation page, not one of the five Settings sections.

Asset history integration:
  - Adding an asset writes an Added record.
  - Updating an asset writes an Updated record with previous and new snapshots.
  - Deleting an asset writes a Deleted record before the asset is removed.
  - The history rows are stored in the same data/bubtops.db file as the main
    assets table. Deleting a history row does not delete the asset.

Database settings:
  - Database location and connection status are displayed.
  - Backup uses SQLite's backup API and records each backup in backup_history.
  - Restore validates the main BubtOps tables and then replaces the active DB.
    Restart the application after restoring.

Important implementation notes:
  - Account profile data is stored locally in a separate admin_profile table.
    The existing app build has no login/authentication screen, so changing this
    profile does not change a login account. A password hash is stored if a new
    password is entered, but no login flow currently checks it.
  - Language, default dashboard, theme, and font-size preferences are saved.
    Full application-wide language switching, startup-page switching, and
    theme/font restyling are not wired into the existing interface yet. The
    current dark-glass design remains active.
  - Restore should only be used with a BubtOps database backup. Make a backup
    first. Close other BubtOps instances before restoring.
  - The project was Python syntax-checked. PySide6 is not installed in this
    build environment, so a live GUI/QML runtime test could not be performed.

Run:
  pip install PySide6
  python main.py

Keep the existing project structure. Do not copy the older Tkinter settings
module's database.py into this PySide6 project; it uses a different database
schema and would not match the main application.
