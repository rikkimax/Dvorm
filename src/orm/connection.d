module dvorm.connection;

static if (__traits(compiles, {import vibe.data.serialization;})) {
	import vibe.data.serialization;
}

string connection() {
	string ret;
	ret ~=
"""
static {
    @ignore
	private DbConnection[] databaseConnection_;

	@property {
	    void databaseConnection(DbConnection connection) {
	        databaseConnection([connection]);
	    }

	    void databaseConnection(DbConnection[] connection) {
	        databaseConnection_ = connection;
	    }

        @ignore
	    DbConnection[] databaseConnection() {
	        return databaseConnection_;
	    }
	}

    void opAssign(DbConnection connection) {
        databaseConnection(connection);
    }

    void opAssign(DbConnection[] connection) {
        databaseConnection(connection);
    }

    @ignore
    DbConnection[] opCast(T : DbConnection[])() {
        return databaseConnection();
    }
}
""";
	return ret;
}

struct DbConnection {
	DbType type;

	static if (__traits(compiles, {import vibe.data.serialization;})) {
		// just so we can use this for configuration :3
	@optional:
	}

	string host;
	ushort port;

	string user;
	string pass;

	string database;
}

enum DbType : string {
	Memory = "Memory",
	Mongo = "Mongo"/*,
	Redis = "Redis",
	Mysql = "Mysql",
	Postgresql = "Postgresql",
	Sqlite = "Sqlite"*/
}