import std, database, html, vibe.d;

const CONNECTION_STRING_FILE = "connection_string.txt";

struct InfoResult
{
    string semver;
    string[] depNames;
}

struct StatsResult
{
    double score;
    uint downloads_total;
    uint stars;
    uint watchers;
    uint forks;
    uint issues;
}

struct NextToUpdate
{
    string name;
}

void main()
{
    // This program will be running on a schedule, as there's no point keeping it in memory during its downtime.
    // So every run updates a single package.
    // Technically the discoverer should be doing the same buuuuuuuuuuut that's a tiny bit more complicated since it runs on two timers.
    auto db       = connectToDb();
    auto toUpdate = getNextPackageToUpdate(db);
    auto stats    = getStats(toUpdate).parseStats;
    auto info     = getInfo(toUpdate).parseInfo;

    writeln("Updating: ", toUpdate.name);

    db.execute(
        "INSERT INTO package_version(semver, package_name) VALUES ($1, $2) ON CONFLICT (semver, package_name) DO NOTHING;",
        info.semver, toUpdate.name
    );

    auto id = db.execute(
       "SELECT id FROM package_version WHERE package_name = $2 AND semver = $1;",
        info.semver, toUpdate.name
    ).get!uint(0, 0);

    foreach(dep; info.depNames)
    {
        db.execute(
            "INSERT INTO package_dependency_map(package_version_id, package_name) VALUES ($1, $2) ON CONFLICT (package_version_id, package_name) DO NOTHING;",
            id.to!string, dep
        );
    }

    db.execute(
        "INSERT INTO package_update(package_version_id, downloads_total, stars, watchers, forks, issues, score, start_date) "
       ~"VALUES ($1, $2, $3, $4, $5, $6, $7, now() AT TIME ZONE 'utc');",
        id.to!string, stats.downloads_total.to!string, stats.stars.to!string, stats.watchers.to!string, stats.forks.to!string, stats.issues.to!string,
        stats.score.to!string
    );
}

Database connectToDb()
{
    enforce(CONNECTION_STRING_FILE.exists, "Please make a file called '"~CONNECTION_STRING_FILE~"' and put the connection string in there.");
    const connectionString = readText(CONNECTION_STRING_FILE);
    auto db = new Database(connectionString);
    return db;
}

NextToUpdate getNextPackageToUpdate(Database db)
{
    auto result = db.execute("SELECT * FROM next_package_name_which_needs_updating;");
    if(result.rows == 0) // No packages to update.
        return NextToUpdate.init;
    return NextToUpdate(result.get!string(0, 0));
}

string getStats(NextToUpdate update)
{
    string result;
    requestHTTP("https://code.dlang.org/api/packages/%s/stats".format(update.name),
        (scope req) { req.method = HTTPMethod.GET; },
        (scope res) { result = res.bodyReader.readAllUTF8(); }
    );
    return result;
}

string getInfo(NextToUpdate update)
{
    string result;
    requestHTTP("https://code.dlang.org/api/packages/%s/%s/info".format(update.name, "latest"),
        (scope req) { req.method = HTTPMethod.GET; },
        (scope res) { result = res.bodyReader.readAllUTF8(); }
    );
    return result;
}

StatsResult parseStats(string stats)
{
    auto json = parseJsonString(stats);
    StatsResult result;
    result.score            = json["score"].to!double;
    result.downloads_total  = json["downloads"]["total"].get!uint;
    result.stars            = json["repo"]["stars"].get!uint;
    result.watchers         = json["repo"]["watchers"].get!uint;
    result.forks            = json["repo"]["forks"].get!uint;
    result.issues           = json["repo"]["issues"].get!uint;

    return result;
}

InfoResult parseInfo(string info)
{
    auto json = parseJsonString(info);
    InfoResult result;
    try result.depNames = json["info"]["dependencies"].byKeyValue.map!(kv => kv.key).array; catch(JSONException){}
    result.semver = json["version"].get!string;

    return result;
}