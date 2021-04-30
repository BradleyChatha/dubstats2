// As expected, all the existing DB libraries for D are either abandoned, dog-shit, or just don't work.
// As expected, I need to work with C libraries instead, because that's the only way I can get any work done.
// Thankfully the D applications are very small in scope in terms of their DB interface needs, so this can be very barebones, very poor on quality of life, etc.
module database;

import std.conv : to;
import std.traits : isSomeString, isNumeric, isBoolean;
import std.exception : enforce;
import std.string : fromStringz, toStringz;
import std.stdio : writeln, writefln;
import libpq_fe;

struct RowResult
{
    private PGresult* _handle;
    private uint _rowCount;
    private uint _colCount;

    @disable this(this){}

    ~this()
    {
        if(this._handle !is null)
            PQclear(this._handle);
    }

    private this(PGresult* handle)
    {
        this._handle = handle;
        this._rowCount = PQntuples(handle);
        this._colCount = PQnfields(handle);
    }

    T get(T)(uint row, uint column)
    {
        assert(row < this._rowCount, "Row out of bounds.");
        assert(column < this._colCount, "Column out of bounds.");
        assert(PQfformat(this._handle, column) == 0, "Can't handle binary data (yet!)");
        return PQgetvalue(this._handle, row, column).fromStringz.to!T;
    }

    @property
    uint rows()
    {
        return this._rowCount;
    }

    @property
    uint columns()
    {
        return this._colCount;
    }
}

final class Database
{
    private PGconn* _conn;

    this(string connectionString)
    {
        const keywords = ["dbname".ptr, null];
        const char* value = connectionString.toStringz;
        this._conn = PQconnectdbParams(keywords.ptr, &value, 1);

        const status = PQstatus(this._conn);
        enforce(status == ConnStatusType.CONNECTION_OK, "Could not connect to database:"~PQerrorMessage(this._conn).fromStringz);
    }

    ~this()
    {
        if(this._conn !is null)
            PQfinish(this._conn);
    }

    RowResult execute(string command)
    {
        //debug writeln("Executing command: "~command);

        auto result = PQexec(this._conn, command.toStringz);
        const status = PQresultStatus(result);
        enforce(status != ExecStatusType.PGRES_NONFATAL_ERROR && status != ExecStatusType.PGRES_FATAL_ERROR, "Error executing command: "~PQresultErrorMessage(result).fromStringz);
        return RowResult(result);
    }

    RowResult execute(string command, string[] args...)
    {
        //debug writefln("Executing:\n\t%s\nArgs: %s", command, args);

        const(char)*[] newArgs;
        newArgs.length = args.length;

        foreach(i, arg; args)
            newArgs[i] = arg.toStringz;

        auto result = PQexecParams(
            this._conn, 
            command.toStringz, 
            args.length.to!uint, 
            null, 
            newArgs.ptr, 
            null, 
            null, 
            0
        );
        const status = PQresultStatus(result);
        enforce(status != ExecStatusType.PGRES_NONFATAL_ERROR && status != ExecStatusType.PGRES_FATAL_ERROR, "Error executing command: "~PQresultErrorMessage(result).fromStringz);
        return RowResult(result);
    }

    @property
    PGconn* handle()
    {
        return this._conn;
    }
}