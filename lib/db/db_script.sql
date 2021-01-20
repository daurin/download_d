CREATE TABLE IF NOT EXISTS "DOWNLOAD_TASK"(
    "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "id_custom" TEXT NOT NULL UNIQUE,
    "url" TEXT NOT NULL,
    "status" INTEGER NOT NULL,
    "progress" INTEGER NOT NULL,
    "headers" TEXT NOT NULL,
    "save_dir" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "size" INTEGER NOT NULL,
    "resumable" NUMERIC NULL,
    "display_name" TEXT NOT NULL,
    "show_notification" NUMERIC NOT NULL,
    "mime_type" TEXT NOT NULL,
    "index" INTEGER NULL,
    "created_at" NUMERIC NOT NULL,
    "completed_at" NUMERIC NULL,
    "limit_bandwidth" INTEGER NULL,
    "duration" INTEGER NULL,
    "thumbnail_url" TEXT NULL
);

CREATE TABLE IF NOT EXISTS "DOWNLOAD_GROUP_TASK"(
    "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "title" TEXT NOT NULL,
    "created_at" NUMERIC NOT NULL
);