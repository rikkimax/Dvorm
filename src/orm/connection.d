module dvorm.connection;

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