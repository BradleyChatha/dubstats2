import std, database, html, vibe.d, libpq_fe, core.time;
import core.stdc.string : strlen;
import core.memory : GC;
import core.thread : Thread;

const CONNECTION_STRING_FILE = "connection_string.txt";
const SCRAPE_INTERVAL        = 1.minutes;
const LIMIT                  = 100;

struct IndexPageEntry
{
    string name;
    string updateTime;
}

void main()
{
    auto db = connectToDb();

    IndexPageEntry[] entries;
    uint skip;
    do
    {
        const url = makeUrl(skip, LIMIT);
        skip += LIMIT;
        writeln(url);

        requestHTTP(url,
            (scope req) { req.method = HTTPMethod.GET; },
            (scope res) { auto str = res.bodyReader.readAllUTF8(); entries = getEntries(str); }
        );
        pushPackages(db, entries);

        GC.collect();
        Thread.sleep(SCRAPE_INTERVAL);
    } while(entries.length > 0);
}

string makeUrl(uint skip, uint limit)
{
    return "https://code.dlang.org/?sort=updated&skip=%s&limit=%s".format(skip, limit);
}

Database connectToDb()
{
    enforce(CONNECTION_STRING_FILE.exists, "Please make a file called '"~CONNECTION_STRING_FILE~"' and put the connection string in there.");
    const connectionString = readText(CONNECTION_STRING_FILE);
    auto db = new Database(connectionString);
    return db;
}

IndexPageEntry[] getEntries(string entryPage)
{
    auto dom = createDocument(entryPage);
    IndexPageEntry[] entries;
    entries.reserve(100);

    auto rows = dom.root.find("body div#content table tr").drop(1);
    foreach(row; rows)
    {
        entries ~= IndexPageEntry(
            row.find("td a").front.text.assumeUnique,
            row.find("td.nobreak span.nobreak").front.attr("title").assumeUnique
        );
    }

    return entries;
}

bool pushPackages(Database db, IndexPageEntry[] entries)
{
    // SELECT * FROM add_packages_if_not_exists(ARRAY [('test2', '01/01/01')]::add_packages_if_not_exists_param[]);
    Appender!(char[]) output;

    writeln("Discovered: ", entries.map!(e => e.name));
    output.put("SELECT * FROM add_packages_if_not_exists(ARRAY [");
    foreach(i, entry; entries)
    {
        scope namePtr = PQescapeLiteral(db.handle, entry.name.ptr, entry.name.length);
        scope timePtr = PQescapeLiteral(db.handle, entry.updateTime.ptr, entry.updateTime.length);
        scope(exit)
        {
            PQfreemem(namePtr);
            PQfreemem(timePtr);
        }

        const nameExtraChars = strlen(&namePtr[entry.name.length]);
        const timeExtraChars = strlen(&timePtr[entry.updateTime.length]);

        output.put("(%s, %s)".format(namePtr[0..entry.name.length+nameExtraChars], timePtr[0..entry.updateTime.length+timeExtraChars]));

        if((i + 1) != entries.length)
            output.put(", ");
    }
    output.put("]::add_packages_if_not_exists_param[]);");

    return db.execute(output.data.idup).get!string(0, 0) == "t";
}