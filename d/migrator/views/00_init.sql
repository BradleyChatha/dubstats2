BEGIN TRANSACTION;

-- Tables

CREATE TABLE IF NOT EXISTS migrations(
    name TEXT NOT NULL PRIMARY KEY
);

DROP TABLE IF EXISTS package CASCADE;
CREATE TABLE package(
    name            VARCHAR(50) NOT NULL PRIMARY KEY,
    update_interval INTERVAL NOT NULL DEFAULT INTERVAL '1 week',
    last_update     TIMESTAMP WITHOUT TIME ZONE DEFAULT TIMESTAMP '1970-01-01 00:00:00',
    next_update     TIMESTAMP WITHOUT TIME ZONE GENERATED ALWAYS AS (last_update + update_interval) STORED
);

DROP TABLE IF EXISTS package_version CASCADE;
CREATE TABLE package_version(
    id              INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    semver          VARCHAR(20) NOT NULL,
    package_name    VARCHAR(50) NOT NULL,

    CONSTRAINT fk_package_version_package FOREIGN KEY(package_name) REFERENCES package(name) ON DELETE CASCADE,
    CONSTRAINT cs_semver_package_name UNIQUE(semver, package_name) -- Doesn't make sense for there to be multiple entries for the same version per package.
);
CREATE INDEX idx_package_version_package_name ON package_version(package_name);

DROP TABLE IF EXISTS package_update CASCADE;
CREATE TABLE package_update(
    id                  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    package_version_id  INTEGER NOT NULL,
    downloads_total     INTEGER NOT NULL,
    stars               INTEGER NOT NULL,
    watchers            INTEGER NOT NULL,
    forks               INTEGER NOT NULL,
    issues              INTEGER NOT NULL,
    score               FLOAT8 NOT NULL,
    start_date          TIMESTAMP WITHOUT TIME ZONE NOT NULL,

    CONSTRAINT fk_package_update_package_version FOREIGN KEY(package_version_id) REFERENCES package_version(id) ON DELETE CASCADE,
    CONSTRAINT cs_package_version_id_start_date UNIQUE(package_version_id, start_date) -- Doesn't make sense for there to be entries with the same start date.
);
CREATE INDEX idx_package_update_package_version_id ON package_update(package_version_id);

DROP TABLE IF EXISTS package_dependency_map CASCADE;
CREATE TABLE package_dependency_map(
    id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    package_version_id INTEGER NOT NULL,
    package_name VARCHAR(50) NOT NULL, -- NOTE: This is not set up as a foreign key as dub packages can depend on local & sub packages e.g. `dep "" path="../lib"`
                                       -- Apps can easily perform a lookup for cases where this relationship needs to be enforced.
    
    CONSTRAINT fk_package_dependency_map_package_version FOREIGN KEY(package_version_id) REFERENCES package_version(id) ON DELETE CASCADE,
    CONSTRAINT cs_package_dependency_map_version_id_name UNIQUE(package_version_id, package_name)
);
CREATE INDEX idx_package_dependency_map_package_version_id ON package_dependency_map(package_version_id);
CREATE INDEX idx_package_dependency_map_package_name ON package_dependency_map(package_name);

-- Functions

-- Get all versions for a package.
CREATE OR REPLACE FUNCTION get_package_versions(pname TEXT)
RETURNS SETOF package_version
AS $$
    SELECT * FROM package_version
    WHERE package_name = pname;
$$ LANGUAGE sql;

-- Get all updates for a package.
CREATE OR REPLACE FUNCTION get_package_updates(pname TEXT)
RETURNS SETOF package_update
AS $$
    SELECT package_update.* FROM package_update
    RIGHT JOIN package_version ON package_version.id = package_update.package_version_id
    WHERE package_version.package_name = pname
    ORDER BY package_update.start_date DESC;
$$ LANGUAGE sql;

-- Get all dependencies for a package, across all versions.
CREATE OR REPLACE FUNCTION get_package_dependencies_all_versions(pname TEXT)
RETURNS SETOF package
AS $$
    SELECT package.*
    FROM package_dependency_map
    RIGHT JOIN package_version ON package_version.id = package_dependency_map.package_version_id
    RIGHT JOIN package ON package.name = package_version.package_name
    ORDER BY package_dependency_map.package_name DESC;
$$ LANGUAGE sql;

-- Adds all packages that don't already exist, and automatically determines their update interval
-- based on how recently they were updated.
DROP TYPE IF EXISTS add_packages_if_not_exists_param CASCADE;
CREATE TYPE add_packages_if_not_exists_param AS (pname TEXT, last_update TIMESTAMP WITHOUT TIME ZONE);
CREATE OR REPLACE FUNCTION add_packages_if_not_exists(packages add_packages_if_not_exists_param [])
RETURNS BOOLEAN
AS $$
DECLARE
    interval INTERVAL;
    was_insert BOOLEAN;
    package_info add_packages_if_not_exists_param;
BEGIN
    FOREACH package_info IN ARRAY packages
    LOOP
        IF (SELECT count(*) FROM package WHERE name = package_info.pname) = 1 THEN
            CONTINUE;
        END IF;

        IF package_info.last_update > now() - INTERVAL '6 months' THEN
            interval := INTERVAL '1 week';
        ELSIF package_info.last_update > now() - INTERVAL '1 year' THEN
            interval := INTERVAL '1 month';
        ELSIF package_info.last_update > now() - INTERVAL '2 years' THEN
            interval := INTERVAL '6 months';
        ELSE
            interval := INTERVAL '1 year';
        END IF;

        was_insert := TRUE;

        INSERT INTO package(name, update_interval) VALUES(package_info.pname, interval);
    END LOOP;

    RETURN was_insert;
END
$$ LANGUAGE PLPGSQL;

-- Views

-- Returns the next package which needs to be updated.
-- Since the updater is running at a very slow rate (I think it'll be ~1 min per check) I may as well just make a utility view here.
-- This is also why we're only returning one at a time, since we're only doing one at a time so we're not accidentally DDOSing code.dlang.org
CREATE OR REPLACE VIEW next_package_name_which_needs_updating AS
    SELECT package.name FROM package
    WHERE package.next_update <= (now() AT TIME ZONE 'utc')
    LIMIT 1;

-- Triggers

-- Anytime a new package_update is inserted, we'll also update the last_update column for the appropriate package.
CREATE OR REPLACE FUNCTION _update_package_next_update()
RETURNS TRIGGER
AS $$
DECLARE
    pname TEXT;
BEGIN
    SELECT name
    INTO pname
    FROM package_version
    RIGHT JOIN package ON package.name = package_version.package_name
    WHERE package_version.id = NEW.package_version_id;

    UPDATE package SET last_update = (now() AT TIME ZONE 'utc') WHERE package.name = pname;
    
    RETURN NEW;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER on_package_new_stats AFTER INSERT ON package_update
FOR EACH ROW EXECUTE PROCEDURE _update_package_next_update();

COMMIT;