module libpq_fe;

/*-------------------------------------------------------------------------
 *
 * libpq-fe.h
 *	  This file contains definitions for structures and
 *	  externs for functions used by frontend postgres applications.
 *
 * Portions Copyright (c) 1996-2019, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/interfaces/libpq/libpq-fe.h
 *
 *-------------------------------------------------------------------------
 */

import core.stdc.stdio;
import pg_config_ext, postgres_ext;

extern (C):

/*
 * postgres_ext.h defines the backend's externally visible types,
 * such as Oid.
 */

/*
 * Option flags for PQcopyResult
 */
enum PG_COPYRES_ATTRS = 0x01;
enum PG_COPYRES_TUPLES = 0x02; /* Implies PG_COPYRES_ATTRS */
enum PG_COPYRES_EVENTS = 0x04;
enum PG_COPYRES_NOTICEHOOKS = 0x08;

/* Application-visible enum types */

/*
 * Although it is okay to add to these lists, values which become unused
 * should never be removed, nor should constants be redefined - that would
 * break compatibility with existing code.
 */

enum ConnStatusType
{
    CONNECTION_OK = 0,
    CONNECTION_BAD = 1,
    /* Non-blocking mode only below here */

    /*
    	 * The existence of these should never be relied upon - they should only
    	 * be used for user feedback or similar purposes.
    	 */
    CONNECTION_STARTED = 2, /* Waiting for connection to be made.  */
    CONNECTION_MADE = 3, /* Connection OK; waiting to send.     */
    CONNECTION_AWAITING_RESPONSE = 4, /* Waiting for a response from the
    									 * postmaster.        */
    CONNECTION_AUTH_OK = 5, /* Received authentication; waiting for
    								 * backend startup. */
    CONNECTION_SETENV = 6, /* Negotiating environment. */
    CONNECTION_SSL_STARTUP = 7, /* Negotiating SSL. */
    CONNECTION_NEEDED = 8, /* Internal state: connect() needed */
    CONNECTION_CHECK_WRITABLE = 9, /* Check if we could make a writable
    								 * connection. */
    CONNECTION_CONSUME = 10, /* Wait for any pending message and consume
    								 * them. */
    CONNECTION_GSS_STARTUP = 11 /* Negotiating GSSAPI. */
}

enum PostgresPollingStatusType
{
    PGRES_POLLING_FAILED = 0,
    PGRES_POLLING_READING = 1, /* These two indicate that one may	  */
    PGRES_POLLING_WRITING = 2, /* use select before polling again.   */
    PGRES_POLLING_OK = 3,
    PGRES_POLLING_ACTIVE = 4 /* unused; keep for awhile for backwards
    								 * compatibility */
}

enum ExecStatusType
{
    PGRES_EMPTY_QUERY = 0, /* empty query string was executed */
    PGRES_COMMAND_OK = 1, /* a query command that doesn't return
    								 * anything was executed properly by the
    								 * backend */
    PGRES_TUPLES_OK = 2, /* a query command that returns tuples was
    								 * executed properly by the backend, PGresult
    								 * contains the result tuples */
    PGRES_COPY_OUT = 3, /* Copy Out data transfer in progress */
    PGRES_COPY_IN = 4, /* Copy In data transfer in progress */
    PGRES_BAD_RESPONSE = 5, /* an unexpected response was recv'd from the
    								 * backend */
    PGRES_NONFATAL_ERROR = 6, /* notice or warning message */
    PGRES_FATAL_ERROR = 7, /* query failed */
    PGRES_COPY_BOTH = 8, /* Copy In/Out data transfer in progress */
    PGRES_SINGLE_TUPLE = 9 /* single tuple from larger resultset */
}

enum PGTransactionStatusType
{
    PQTRANS_IDLE = 0, /* connection idle */
    PQTRANS_ACTIVE = 1, /* command in progress */
    PQTRANS_INTRANS = 2, /* idle, within transaction block */
    PQTRANS_INERROR = 3, /* idle, within failed transaction */
    PQTRANS_UNKNOWN = 4 /* cannot determine status */
}

enum PGVerbosity
{
    PQERRORS_TERSE = 0, /* single-line error messages */
    PQERRORS_DEFAULT = 1, /* recommended style */
    PQERRORS_VERBOSE = 2, /* all the facts, ma'am */
    PQERRORS_SQLSTATE = 3 /* only error severity and SQLSTATE code */
}

enum PGContextVisibility
{
    PQSHOW_CONTEXT_NEVER = 0, /* never show CONTEXT field */
    PQSHOW_CONTEXT_ERRORS = 1, /* show CONTEXT for errors only (default) */
    PQSHOW_CONTEXT_ALWAYS = 2 /* always show CONTEXT field */
}

/*
 * PGPing - The ordering of this enum should not be altered because the
 * values are exposed externally via pg_isready.
 */

enum PGPing
{
    PQPING_OK = 0, /* server is accepting connections */
    PQPING_REJECT = 1, /* server is alive but rejecting connections */
    PQPING_NO_RESPONSE = 2, /* could not establish connection */
    PQPING_NO_ATTEMPT = 3 /* connection not attempted (bad params) */
}

/* PGconn encapsulates a connection to the backend.
 * The contents of this struct are not supposed to be known to applications.
 */
struct pg_conn;
alias PGconn = pg_conn;

/* PGresult encapsulates the result of a query (or more precisely, of a single
 * SQL command --- a query string given to PQsendQuery can contain multiple
 * commands and thus return multiple PGresult objects).
 * The contents of this struct are not supposed to be known to applications.
 */
struct pg_result;
alias PGresult = pg_result;

/* PGcancel encapsulates the information needed to cancel a running
 * query on an existing connection.
 * The contents of this struct are not supposed to be known to applications.
 */
struct pg_cancel;
alias PGcancel = pg_cancel;

/* PGnotify represents the occurrence of a NOTIFY message.
 * Ideally this would be an opaque typedef, but it's so simple that it's
 * unlikely to change.
 * NOTE: in Postgres 6.4 and later, the be_pid is the notifying backend's,
 * whereas in earlier versions it was always your own backend's PID.
 */
struct pgNotify
{
    char* relname; /* notification condition name */
    int be_pid; /* process ID of notifying server process */
    char* extra; /* notification parameter */
    /* Fields below here are private to libpq; apps should not use 'em */
    pgNotify* next; /* list link */
}

alias PGnotify = pgNotify;

/* Function types for notice-handling callbacks */
alias PQnoticeReceiver = void function (void* arg, const(PGresult)* res);
alias PQnoticeProcessor = void function (void* arg, const(char)* message);

/* Print options for PQprint() */
alias pqbool = char;

struct _PQprintOpt
{
    pqbool header; /* print output field headings and row count */
    pqbool align_; /* fill align the fields */
    pqbool standard; /* old brain dead format */
    pqbool html3; /* output html tables */
    pqbool expanded; /* expand tables */
    pqbool pager; /* use pager for output if needed */
    char* fieldSep; /* field separator */
    char* tableOpt; /* insert to HTML <table ...> */
    char* caption; /* HTML <caption> */
    char** fieldName; /* null terminated array of replacement field
    								 * names */
}

alias PQprintOpt = _PQprintOpt;

/* ----------------
 * Structure for the conninfo parameter definitions returned by PQconndefaults
 * or PQconninfoParse.
 *
 * All fields except "val" point at static strings which must not be altered.
 * "val" is either NULL or a malloc'd current-value string.  PQconninfoFree()
 * will release both the val strings and the PQconninfoOption array itself.
 * ----------------
 */
struct _PQconninfoOption
{
    char* keyword; /* The keyword of the option			*/
    char* envvar; /* Fallback environment variable name	*/
    char* compiled; /* Fallback compiled in default value	*/
    char* val; /* Option's current value, or NULL		 */
    char* label; /* Label for field in connect dialog	*/
    char* dispchar; /* Indicates how to display this field in a
    								 * connect dialog. Values are: "" Display
    								 * entered value as is "*" Password field -
    								 * hide value "D"  Debug option - don't show
    								 * by default */
    int dispsize; /* Field size in characters for dialog	*/
}

alias PQconninfoOption = _PQconninfoOption;

/* ----------------
 * PQArgBlock -- structure for PQfn() arguments
 * ----------------
 */
struct PQArgBlock
{
    int len;
    int isint;

    /* can't use void (dec compiler barfs)	 */
    union _Anonymous_0
    {
        int* ptr;
        int integer;
    }

    _Anonymous_0 u;
}

/* ----------------
 * PGresAttDesc -- Data about a single attribute (column) of a query result
 * ----------------
 */
struct pgresAttDesc
{
    char* name; /* column name */
    Oid tableid; /* source table, if known */
    int columnid; /* source column, if known */
    int format; /* format code for value (text/binary) */
    Oid typid; /* type id */
    int typlen; /* type size */
    int atttypmod; /* type-specific modifier info */
}

alias PGresAttDesc = pgresAttDesc;

/* ----------------
 * Exported functions of libpq
 * ----------------
 */

/* ===	in fe-connect.c === */

/* make a new client connection to the backend */
/* Asynchronous (non-blocking) */
PGconn* PQconnectStart (const(char)* conninfo);
PGconn* PQconnectStartParams (
    const(char*)* keywords,
    const(char*)* values,
    int expand_dbname);
PostgresPollingStatusType PQconnectPoll (PGconn* conn);

/* Synchronous (blocking) */
PGconn* PQconnectdb (const(char)* conninfo);
PGconn* PQconnectdbParams (
    const(char*)* keywords,
    const(char*)* values,
    int expand_dbname);
PGconn* PQsetdbLogin (
    const(char)* pghost,
    const(char)* pgport,
    const(char)* pgoptions,
    const(char)* pgtty,
    const(char)* dbName,
    const(char)* login,
    const(char)* pwd);

extern (D) auto PQsetdb(T0, T1, T2, T3, T4)(auto ref T0 M_PGHOST, auto ref T1 M_PGPORT, auto ref T2 M_PGOPT, auto ref T3 M_PGTTY, auto ref T4 M_DBNAME)
{
    return PQsetdbLogin(M_PGHOST, M_PGPORT, M_PGOPT, M_PGTTY, M_DBNAME, NULL, NULL);
}

/* close the current connection and free the PGconn data structure */
void PQfinish (PGconn* conn);

/* get info about connection options known to PQconnectdb */
PQconninfoOption* PQconndefaults ();

/* parse connection options in same way as PQconnectdb */
PQconninfoOption* PQconninfoParse (const(char)* conninfo, char** errmsg);

/* return the connection options used by a live connection */
PQconninfoOption* PQconninfo (PGconn* conn);

/* free the data structure returned by PQconndefaults() or PQconninfoParse() */
void PQconninfoFree (PQconninfoOption* connOptions);

/*
 * close the current connection and restablish a new one with the same
 * parameters
 */
/* Asynchronous (non-blocking) */
int PQresetStart (PGconn* conn);
PostgresPollingStatusType PQresetPoll (PGconn* conn);

/* Synchronous (blocking) */
void PQreset (PGconn* conn);

/* request a cancel structure */
PGcancel* PQgetCancel (PGconn* conn);

/* free a cancel structure */
void PQfreeCancel (PGcancel* cancel);

/* issue a cancel request */
int PQcancel (PGcancel* cancel, char* errbuf, int errbufsize);

/* backwards compatible version of PQcancel; not thread-safe */
int PQrequestCancel (PGconn* conn);

/* Accessor functions for PGconn objects */
char* PQdb (const(PGconn)* conn);
char* PQuser (const(PGconn)* conn);
char* PQpass (const(PGconn)* conn);
char* PQhost (const(PGconn)* conn);
char* PQhostaddr (const(PGconn)* conn);
char* PQport (const(PGconn)* conn);
char* PQtty (const(PGconn)* conn);
char* PQoptions (const(PGconn)* conn);
ConnStatusType PQstatus (const(PGconn)* conn);
PGTransactionStatusType PQtransactionStatus (const(PGconn)* conn);
const(char)* PQparameterStatus (const(PGconn)* conn, const(char)* paramName);
int PQprotocolVersion (const(PGconn)* conn);
int PQserverVersion (const(PGconn)* conn);
char* PQerrorMessage (const(PGconn)* conn);
int PQsocket (const(PGconn)* conn);
int PQbackendPID (const(PGconn)* conn);
int PQconnectionNeedsPassword (const(PGconn)* conn);
int PQconnectionUsedPassword (const(PGconn)* conn);
int PQclientEncoding (const(PGconn)* conn);
int PQsetClientEncoding (PGconn* conn, const(char)* encoding);

/* SSL information functions */
int PQsslInUse (PGconn* conn);
void* PQsslStruct (PGconn* conn, const(char)* struct_name);
const(char)* PQsslAttribute (PGconn* conn, const(char)* attribute_name);
const(char*)* PQsslAttributeNames (PGconn* conn);

/* Get the OpenSSL structure associated with a connection. Returns NULL for
 * unencrypted connections or if any other TLS library is in use. */
void* PQgetssl (PGconn* conn);

/* Tell libpq whether it needs to initialize OpenSSL */
void PQinitSSL (int do_init);

/* More detailed way to tell libpq whether it needs to initialize OpenSSL */
void PQinitOpenSSL (int do_ssl, int do_crypto);

/* Return true if GSSAPI encryption is in use */
int PQgssEncInUse (PGconn* conn);

/* Returns GSSAPI context if GSSAPI is in use */
void* PQgetgssctx (PGconn* conn);

/* Set verbosity for PQerrorMessage and PQresultErrorMessage */
PGVerbosity PQsetErrorVerbosity (PGconn* conn, PGVerbosity verbosity);

/* Set CONTEXT visibility for PQerrorMessage and PQresultErrorMessage */
PGContextVisibility PQsetErrorContextVisibility (
    PGconn* conn,
    PGContextVisibility show_context);

/* Enable/disable tracing */
void PQtrace (PGconn* conn, FILE* debug_port);
void PQuntrace (PGconn* conn);

/* Override default notice handling routines */
PQnoticeReceiver PQsetNoticeReceiver (
    PGconn* conn,
    PQnoticeReceiver proc,
    void* arg);
PQnoticeProcessor PQsetNoticeProcessor (
    PGconn* conn,
    PQnoticeProcessor proc,
    void* arg);

/*
 *	   Used to set callback that prevents concurrent access to
 *	   non-thread safe functions that libpq needs.
 *	   The default implementation uses a libpq internal mutex.
 *	   Only required for multithreaded apps that use kerberos
 *	   both within their app and for postgresql connections.
 */
alias pgthreadlock_t = void function (int acquire);

pgthreadlock_t PQregisterThreadLock (pgthreadlock_t newhandler);

/* === in fe-exec.c === */

/* Simple synchronous query */
PGresult* PQexec (PGconn* conn, const(char)* query);
PGresult* PQexecParams (
    PGconn* conn,
    const(char)* command,
    int nParams,
    const(Oid)* paramTypes,
    const(char*)* paramValues,
    const(int)* paramLengths,
    const(int)* paramFormats,
    int resultFormat);
PGresult* PQprepare (
    PGconn* conn,
    const(char)* stmtName,
    const(char)* query,
    int nParams,
    const(Oid)* paramTypes);
PGresult* PQexecPrepared (
    PGconn* conn,
    const(char)* stmtName,
    int nParams,
    const(char*)* paramValues,
    const(int)* paramLengths,
    const(int)* paramFormats,
    int resultFormat);

/* Interface for multiple-result or asynchronous queries */
int PQsendQuery (PGconn* conn, const(char)* query);
int PQsendQueryParams (
    PGconn* conn,
    const(char)* command,
    int nParams,
    const(Oid)* paramTypes,
    const(char*)* paramValues,
    const(int)* paramLengths,
    const(int)* paramFormats,
    int resultFormat);
int PQsendPrepare (
    PGconn* conn,
    const(char)* stmtName,
    const(char)* query,
    int nParams,
    const(Oid)* paramTypes);
int PQsendQueryPrepared (
    PGconn* conn,
    const(char)* stmtName,
    int nParams,
    const(char*)* paramValues,
    const(int)* paramLengths,
    const(int)* paramFormats,
    int resultFormat);
int PQsetSingleRowMode (PGconn* conn);
PGresult* PQgetResult (PGconn* conn);

/* Routines for managing an asynchronous query */
int PQisBusy (PGconn* conn);
int PQconsumeInput (PGconn* conn);

/* LISTEN/NOTIFY support */
PGnotify* PQnotifies (PGconn* conn);

/* Routines for copy in/out */
int PQputCopyData (PGconn* conn, const(char)* buffer, int nbytes);
int PQputCopyEnd (PGconn* conn, const(char)* errormsg);
int PQgetCopyData (PGconn* conn, char** buffer, int async);

/* Deprecated routines for copy in/out */
int PQgetline (PGconn* conn, char* string, int length);
int PQputline (PGconn* conn, const(char)* string);
int PQgetlineAsync (PGconn* conn, char* buffer, int bufsize);
int PQputnbytes (PGconn* conn, const(char)* buffer, int nbytes);
int PQendcopy (PGconn* conn);

/* Set blocking/nonblocking connection to the backend */
int PQsetnonblocking (PGconn* conn, int arg);
int PQisnonblocking (const(PGconn)* conn);
int PQisthreadsafe ();
PGPing PQping (const(char)* conninfo);
PGPing PQpingParams (
    const(char*)* keywords,
    const(char*)* values,
    int expand_dbname);

/* Force the write buffer to be written (or at least try) */
int PQflush (PGconn* conn);

/*
 * "Fast path" interface --- not really recommended for application
 * use
 */
PGresult* PQfn (
    PGconn* conn,
    int fnid,
    int* result_buf,
    int* result_len,
    int result_is_int,
    const(PQArgBlock)* args,
    int nargs);

/* Accessor functions for PGresult objects */
ExecStatusType PQresultStatus (const(PGresult)* res);
char* PQresStatus (ExecStatusType status);
char* PQresultErrorMessage (const(PGresult)* res);
char* PQresultVerboseErrorMessage (
    const(PGresult)* res,
    PGVerbosity verbosity,
    PGContextVisibility show_context);
char* PQresultErrorField (const(PGresult)* res, int fieldcode);
int PQntuples (const(PGresult)* res);
int PQnfields (const(PGresult)* res);
int PQbinaryTuples (const(PGresult)* res);
char* PQfname (const(PGresult)* res, int field_num);
int PQfnumber (const(PGresult)* res, const(char)* field_name);
Oid PQftable (const(PGresult)* res, int field_num);
int PQftablecol (const(PGresult)* res, int field_num);
int PQfformat (const(PGresult)* res, int field_num);
Oid PQftype (const(PGresult)* res, int field_num);
int PQfsize (const(PGresult)* res, int field_num);
int PQfmod (const(PGresult)* res, int field_num);
char* PQcmdStatus (PGresult* res);
char* PQoidStatus (const(PGresult)* res); /* old and ugly */
Oid PQoidValue (const(PGresult)* res); /* new and improved */
char* PQcmdTuples (PGresult* res);
char* PQgetvalue (const(PGresult)* res, int tup_num, int field_num);
int PQgetlength (const(PGresult)* res, int tup_num, int field_num);
int PQgetisnull (const(PGresult)* res, int tup_num, int field_num);
int PQnparams (const(PGresult)* res);
Oid PQparamtype (const(PGresult)* res, int param_num);

/* Describe prepared statements and portals */
PGresult* PQdescribePrepared (PGconn* conn, const(char)* stmt);
PGresult* PQdescribePortal (PGconn* conn, const(char)* portal);
int PQsendDescribePrepared (PGconn* conn, const(char)* stmt);
int PQsendDescribePortal (PGconn* conn, const(char)* portal);

/* Delete a PGresult */
void PQclear (PGresult* res);

/* For freeing other alloc'd results, such as PGnotify structs */
void PQfreemem (void* ptr);

/* Exists for backward compatibility.  bjm 2003-03-24 */
alias PQfreeNotify = PQfreemem;

/* Error when no password was given. */
/* Note: depending on this is deprecated; use PQconnectionNeedsPassword(). */
enum PQnoPasswordSupplied = "fe_sendauth: no password supplied\n";

/* Create and manipulate PGresults */
PGresult* PQmakeEmptyPGresult (PGconn* conn, ExecStatusType status);
PGresult* PQcopyResult (const(PGresult)* src, int flags);
int PQsetResultAttrs (PGresult* res, int numAttributes, PGresAttDesc* attDescs);
void* PQresultAlloc (PGresult* res, size_t nBytes);
size_t PQresultMemorySize (const(PGresult)* res);
int PQsetvalue (PGresult* res, int tup_num, int field_num, char* value, int len);

/* Quoting strings before inclusion in queries. */
size_t PQescapeStringConn (
    PGconn* conn,
    char* to,
    const(char)* from,
    size_t length,
    int* error);
char* PQescapeLiteral (PGconn* conn, const(char)* str, size_t len);
char* PQescapeIdentifier (PGconn* conn, const(char)* str, size_t len);
ubyte* PQescapeByteaConn (
    PGconn* conn,
    const(ubyte)* from,
    size_t from_length,
    size_t* to_length);
ubyte* PQunescapeBytea (const(ubyte)* strtext, size_t* retbuflen);

/* These forms are deprecated! */
size_t PQescapeString (char* to, const(char)* from, size_t length);
ubyte* PQescapeBytea (
    const(ubyte)* from,
    size_t from_length,
    size_t* to_length);

/* === in fe-print.c === */

/* output stream */
void PQprint (FILE* fout, const(PGresult)* res, const(PQprintOpt)* ps); /* option structure */

/*
 * really old printing routines
 */

/* where to send the output */
/* pad the fields with spaces */
/* field separator */
/* display headers? */
void PQdisplayTuples (
    const(PGresult)* res,
    FILE* fp,
    int fillAlign,
    const(char)* fieldSep,
    int printHeader,
    int quiet);

/* output stream */
/* print attribute names */
/* delimiter bars */
void PQprintTuples (
    const(PGresult)* res,
    FILE* fout,
    int printAttName,
    int terseOutput,
    int width); /* width of column, if 0, use variable
										 * width */

/* === in fe-lobj.c === */

/* Large-object access routines */
int lo_open (PGconn* conn, Oid lobjId, int mode);
int lo_close (PGconn* conn, int fd);
int lo_read (PGconn* conn, int fd, char* buf, size_t len);
int lo_write (PGconn* conn, int fd, const(char)* buf, size_t len);
int lo_lseek (PGconn* conn, int fd, int offset, int whence);
pg_int64 lo_lseek64 (PGconn* conn, int fd, pg_int64 offset, int whence);
Oid lo_creat (PGconn* conn, int mode);
Oid lo_create (PGconn* conn, Oid lobjId);
int lo_tell (PGconn* conn, int fd);
pg_int64 lo_tell64 (PGconn* conn, int fd);
int lo_truncate (PGconn* conn, int fd, size_t len);
int lo_truncate64 (PGconn* conn, int fd, pg_int64 len);
int lo_unlink (PGconn* conn, Oid lobjId);
Oid lo_import (PGconn* conn, const(char)* filename);
Oid lo_import_with_oid (PGconn* conn, const(char)* filename, Oid lobjId);
int lo_export (PGconn* conn, Oid lobjId, const(char)* filename);

/* === in fe-misc.c === */

/* Get the version of the libpq library in use */
int PQlibVersion ();

/* Determine length of multibyte encoded char at *s */
int PQmblen (const(char)* s, int encoding);

/* Determine display length of multibyte encoded char at *s */
int PQdsplen (const(char)* s, int encoding);

/* Get encoding id from environment variable PGCLIENTENCODING */
int PQenv2encoding ();

/* === in fe-auth.c === */

char* PQencryptPassword (const(char)* passwd, const(char)* user);
char* PQencryptPasswordConn (PGconn* conn, const(char)* passwd, const(char)* user, const(char)* algorithm);

/* === in encnames.c === */

int pg_char_to_encoding (const(char)* name);
const(char)* pg_encoding_to_char (int encoding);
int pg_valid_server_encoding_id (int encoding);

/* LIBPQ_FE_H */
