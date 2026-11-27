import GRDB

enum PlannerDatabaseMigration {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createPlannerTables") { db in
            try createInitialSchema(in: db)
            try SettingsRecord(Settings()).insert(db)
        }
        migrator.registerMigration("createPlanAttachments") { db in
            try db.execute(sql: """
                CREATE TABLE plan_attachments (
                    id BLOB NOT NULL PRIMARY KEY,
                    planID BLOB NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
                    checklistItemID BLOB,
                    position INTEGER NOT NULL,
                    name TEXT NOT NULL CHECK (length(name) > 0),
                    contentType TEXT,
                    byteCount INTEGER,
                    linkURL TEXT,
                    FOREIGN KEY (planID, checklistItemID) REFERENCES checklist_items(planID, itemID)
                        ON DELETE CASCADE,
                    CHECK (
                        (linkURL IS NULL AND contentType IS NOT NULL AND byteCount IS NOT NULL AND byteCount > 0)
                        OR
                        (linkURL IS NOT NULL AND contentType IS NULL AND byteCount IS NULL)
                    )
                );
                CREATE INDEX plan_attachments_owner ON plan_attachments (planID, checklistItemID);
                """)
        }
        migrator.registerMigration("createSharedAttachmentDestination") { db in
            try db.execute(sql: """
                CREATE TABLE shared_attachment_destination (
                    id INTEGER PRIMARY KEY CHECK (id = 1),
                    planID BLOB NOT NULL REFERENCES plans(id) ON DELETE CASCADE
                );
                """)
        }
        migrator.registerMigration("addPausedFocusDuration") { db in
            try db.alter(table: "focus_session") { table in
                table.add(column: "pausedSeconds", .integer)
            }
        }
        return migrator
    }

    private static func createInitialSchema(in db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE plans (
                id BLOB NOT NULL PRIMARY KEY,
                position INTEGER NOT NULL,
                title TEXT NOT NULL,
                year INTEGER NOT NULL,
                month INTEGER NOT NULL,
                day INTEGER NOT NULL,
                note TEXT NOT NULL,
                isFavorite INTEGER NOT NULL,
                advanceNotice TEXT NOT NULL
            );

            CREATE TABLE checklist_items (
                planID BLOB NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
                itemID BLOB NOT NULL,
                position INTEGER NOT NULL,
                title TEXT NOT NULL,
                isDone INTEGER NOT NULL,
                PRIMARY KEY (planID, itemID)
            );

            CREATE TABLE reminders (
                id BLOB NOT NULL PRIMARY KEY,
                position INTEGER NOT NULL,
                title TEXT NOT NULL,
                notifies INTEGER NOT NULL,
                scheduledAt REAL,
                intervalMinutes INTEGER,
                weekdays INTEGER,
                startMinute INTEGER,
                endMinute INTEGER,
                handledThrough REAL,
                snoozedUntil REAL,
                CHECK (
                    (scheduledAt IS NOT NULL AND intervalMinutes IS NULL AND weekdays IS NULL
                     AND startMinute IS NULL AND endMinute IS NULL)
                    OR
                    (scheduledAt IS NULL AND intervalMinutes IS NOT NULL AND weekdays IS NOT NULL
                     AND startMinute IS NOT NULL AND endMinute IS NOT NULL)
                )
            );

            CREATE TABLE settings (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                appearance TEXT NOT NULL,
                showsWeather INTEGER NOT NULL,
                cityID INTEGER,
                cityName TEXT,
                cityLatitude REAL,
                cityLongitude REAL,
                cityAdmin1 TEXT,
                cityCountry TEXT,
                weatherLocationMode TEXT,
                notificationsEnabled INTEGER NOT NULL,
                notificationSound TEXT NOT NULL,
                focusMinutes INTEGER NOT NULL,
                CHECK (
                    (cityID IS NULL AND cityName IS NULL AND cityLatitude IS NULL AND cityLongitude IS NULL
                     AND cityAdmin1 IS NULL AND cityCountry IS NULL)
                    OR
                    (cityID IS NOT NULL AND cityName IS NOT NULL AND cityLatitude IS NOT NULL AND cityLongitude IS NOT NULL)
                )
            );

            CREATE TABLE focus_session (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                planID BLOB NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
                planTitle TEXT NOT NULL,
                minutes INTEGER NOT NULL,
                endsAt REAL NOT NULL
            );
            """)
    }
}
