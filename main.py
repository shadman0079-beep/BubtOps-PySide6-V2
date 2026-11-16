
import sys
import sqlite3
from pathlib import Path
from datetime import datetime

from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtQuickControls2 import QQuickStyle
QQuickStyle.setStyle("Basic")

from PySide6.QtCore import (
    QObject,
    Signal,
    Slot,
    Property,
    QUrl,
    QSize
)

from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView


# ============================================================
# 01. DATABASE CONFIGURATION
# ============================================================

# Existing database location.
# We are NOT creating a new database.

DATABASE_PATH = (
    Path(__file__).resolve().parent.parent
    / "BubtOps"
    / "bubtops.db"
)


# ============================================================
# 02. ASSET DATABASE BACKEND
# ============================================================

class AssetBackend(QObject):

    # Notifies QML when asset data changes.
    assetsChanged = Signal()

    # --------------------------------------------------------
    # INITIALIZATION
    # --------------------------------------------------------

    def __init__(self):
        super().__init__()

        self._database_error = ""

        if not DATABASE_PATH.exists():
            self._database_error = (
                f"Database not found:\n{DATABASE_PATH}"
            )
            return

        try:
            self.ensure_cost_columns()

        except Exception as error:
            self._database_error = str(error)

    # --------------------------------------------------------
    # DATABASE STATUS
    # --------------------------------------------------------

    @Property(bool, constant=True)
    def databaseReady(self):
        return (
            DATABASE_PATH.exists()
            and not self._database_error
        )

    @Property(str, constant=True)
    def databaseError(self):
        return self._database_error

    # --------------------------------------------------------
    # DATABASE CONNECTION
    # --------------------------------------------------------

    def connect_database(self):

        if not DATABASE_PATH.exists():
            raise FileNotFoundError(
                f"Database not found: {DATABASE_PATH}"
            )

        connection = sqlite3.connect(
            str(DATABASE_PATH),
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
    # 03. GET ASSETS
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

            # Search filter
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

            # Condition filter
            if condition:

                query += """
                    AND a.asset_condition = ?
                """

                parameters.append(condition)

            # Status filter
            if status:

                query += """
                    AND a.status = ?
                """

                parameters.append(status)

            # Category filter
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
    # 04. GET LOCATIONS
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
    # 05. GET CATEGORIES
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
    # 06. SAVE / UPDATE ASSET
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

            # Required fields
            if not asset_code or not asset_name or not category:

                return {
                    "success": False,
                    "message": (
                        "Asset code, name and category "
                        "are required."
                    )
                }

            # Date validation
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

            # Money validation
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

            # Location validation
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
                    asset_code,
                    asset_name,
                    category,
                    location_id,
                    asset_condition,
                    status,
                    purchase_date or None,
                    purchase_cost,
                    estimated_repair_cost
                )

                if asset_id > 0:

                    connection.execute("""
                        UPDATE assets

                        SET
                            asset_code = ?,
                            asset_name = ?,
                            category = ?,
                            location_id = ?,
                            asset_condition = ?,
                            status = ?,
                            purchase_date = ?,
                            purchase_cost = ?,
                            estimated_repair_cost = ?

                        WHERE asset_id = ?
                    """, values + (asset_id,))

                    message = "Asset updated successfully."

                else:

                    connection.execute("""
                        INSERT INTO assets (
                            asset_code,
                            asset_name,
                            category,
                            location_id,
                            asset_condition,
                            status,
                            purchase_date,
                            purchase_cost,
                            estimated_repair_cost
                        )

                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, values)

                    message = "Asset added successfully."

            self.assetsChanged.emit()

            return {
                "success": True,
                "message": message
            }

        except sqlite3.IntegrityError as error:

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
    # 07. DELETE ASSET
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

                cursor = connection.execute("""
                    DELETE FROM assets
                    WHERE asset_id = ?
                """, (asset_id,))

                if cursor.rowcount == 0:

                    return {
                        "success": False,
                        "message": "Asset not found."
                    }

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
# 08. APPLICATION ENTRY POINT
# ============================================================

def main():
    QQuickStyle.setStyle("Basic")

    app = QGuiApplication(sys.argv)

    view = QQuickView()

    # Create the Python database backend.
    backend = AssetBackend()

    # Make Python functions available to QML.
    view.rootContext().setContextProperty(
        "assetBackend",
        backend
    )

    # Window configuration
    view.setTitle(
        "BubtOps | Advanced Interface"
    )

    view.setResizeMode(
        QQuickView.ResizeMode.SizeRootObjectToView
    )

    view.setMinimumSize(
        QSize(950, 650)
    )

    # Load main QML file
    qml_file = Path(__file__).with_name("main.qml")

    view.setSource(
        QUrl.fromLocalFile(str(qml_file))
    )

    # Check QML errors
    if view.status() == QQuickView.Status.Error:

        for error in view.errors():
            print(error.toString())

        return 1

    view.show()

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
