--- migration:up
CREATE TABLE users(
    id UUID PRIMARY KEY
);

--- migration:down
DROP TABLE users;

--- migration:end