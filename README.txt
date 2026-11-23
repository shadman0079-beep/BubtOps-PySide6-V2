BubtOps - Maintenance Registration and Attention List Scroll Fix
===============================================================

Files in this update
--------------------
- main.py
  Adds safe, schema-aware maintenance record registration and complete
  maintenance history loading. The dashboard now returns the full attention
  asset list separately from maintenance history. Saving a maintenance record
  emits maintenanceChanged so the dashboard refreshes.

- main.qml
  The dashboard's Assets needing attention panel now uses its own ListView and
  vertical scrollbar. It displays every flagged asset and opens the selected
  asset details. The Total Maintenance Cost card opens Maintenance Management.

- components/MaintenancePage.qml
  New maintenance registration form and scrollable maintenance history.

- components/NeedsAttention.qml
  Refreshes the selected asset's history when a maintenance record is saved.

How to test the maintenance cost
--------------------------------
1. Open the Maintenance page from the left sidebar, or click Total Maintenance
   Cost on the dashboard.
2. Select an asset.
3. Enter date in YYYY-MM-DD format.
4. Enter a description, for example: Motherboard repair and testing.
5. Enter the actual amount paid, for example 1500.
6. Choose Completed, In Progress, or Pending and save.
7. Return to Overview. Total Maintenance Cost should increase by that amount,
   and the maintenance entry should appear in the history list.

Important cost distinction
--------------------------
The card adds actual costs stored in maintenance_records. Purchase cost and
estimated repair cost in Asset Registry are not actual expenses and are not
added to that card. It remains ৳0.00 until a maintenance record with a cost is
saved.

Attention list
--------------
The dashboard list contains all assets whose status is Needs Maintenance,
Under Maintenance, or Out of Service, or whose condition is Poor, Damaged,
Critical, or Needs Repair. The dashboard panel scrolls independently and every
row opens the Needs Attention details page.

Installation
------------
Close BubtOps. Back up main.py, main.qml, and components/NeedsAttention.qml.
Extract this ZIP into the project root (for example G:\BubtOps_PySide6), allowing
main.py and main.qml to be replaced. The ZIP adds components/MaintenancePage.qml
and updates components/NeedsAttention.qml. Keep data, bubtops.db, .venv, and all
other components unchanged.

Run:
  cd G:\BubtOps_PySide6
  python main.py

No new database table is created. The existing maintenance_records table is
used. If that table has an additional required column not supported by the form,
the save operation reports its name instead of silently losing the record.
