--- migration:up
ALTER TABLE users ADD COLUMN name TEXT NOT NULL;

--- migration:down
ALTER TABLE users DROP COLUMN name;

--- migration:end