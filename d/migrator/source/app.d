import std, database;

const CONNECTION_STRING_FILE = "connection_string.txt";

struct Migration
{
    string name;
    string sql;
}

const MIGRATIONS = 
[
    Migration("init", import("00_init.sql"))
];

void main()
{
    auto db = connectToDb();
    auto existing = getExistingMigrations(db);

    foreach(migration; MIGRATIONS.filter!(m => !existing.canFind(m.name)))
    {
        writeln("Executing migration: ", migration.name);
        db.execute(migration.sql);
        //db.execute("INSERT INTO migrations(name) VALUES ($1)", migration.name);
    }
}

Database connectToDb()
{
    enforce(CONNECTION_STRING_FILE.exists, "Please make a file called '"~CONNECTION_STRING_FILE~"' and put the connection string in there.");
    const connectionString = readText(CONNECTION_STRING_FILE);
    auto db = new Database(connectionString);
    return db;
}

string[] getExistingMigrations(Database db)
{
    auto result = db.execute("SELECT * FROM pg_tables WHERE tablename = 'migrations'");
    if(result.rows == 0)
        return null;

    result = db.execute("SELECT * FROM migrations");
    auto array = new string[result.rows];
    foreach(i; 0..result.rows)
        array[i] = result.get!string(i, 0);

    return array;
}