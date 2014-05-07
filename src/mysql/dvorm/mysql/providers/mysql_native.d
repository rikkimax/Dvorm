module dvorm.mysql.providers.mysql_native;
import dvorm.provider;
import mysql.db;
import vibe.core.connectionpool;
import std.conv : to;
import std.variant;
import std.string : indexOf;

private {
	shared Connection[string] tableCollections;
}

class MysqlNativeProvider : Provider {
	override void*[] find(string table, string[] argNames, string[] args, ObjectBuilder builder, DbConnection[] connection) {
		checkConnection(table, connection);
		assert(argNames.length > 0, "There must be atleast one property in table " ~ table ~ ".");
		Connection db = cast(Connection)tableCollections[connection[0].database ~ "." ~ table];
		Command cmd = Command(db);
		
		// TODO cache this state. Will help with not having to do the above ever again.
		
		string sql;
		sql ~= "SELECT * FROM " ~ table ~ " WHERE ";
		
		foreach(name; argNames) {
			sql ~= name ~ " = ? AND ";
		}
		sql.length -= 4;
		
		sql ~= ";";
		
		cmd.sql(sql);
		// TODO cache this state. Will help with not having to do the above ever again.
		cmd.prepare();
		
		string[] values = args;
		foreach(i, v; args) {
			if (v.length > 2 && v[0] == '"' && v[$-1] == '"')
				values[i] = v[1 .. $-1];
			
			cmd.bindParameter(values[i], i);
		}
		
		void*[] ret;
		
		ulong rows;
		if (cmd.execPrepared(rows)) {
			Row row;
			
			while((row = cmd.getNextRow()) != Row.init) {
				string[string] rValues;
				
				foreach(i, collumn; cmd.resultFieldDescriptions) {
					rValues[collumn.name] = row[i].toString();
				}
				ret ~= builder(rValues);
			}
		}
		
		// if cached don't do this
		cmd.releaseStatement();
		return ret;
	}
	
	override void*[] findAll(string table, ObjectBuilder builder, DbConnection[] connection) {
		checkConnection(table, connection);
		Connection db = cast(Connection)tableCollections[connection[0].database ~ "." ~ table];
		Command cmd = Command(db);
		
		// TODO cache this state. Will help with not having to do the above ever again.
		
		cmd.sql("SELECT * FROM " ~ table ~ ";");
		// TODO cache this state. Will help with not having to do the above ever again.
		cmd.prepare();
		
		void*[] ret;
		
		ulong rows;
		if (cmd.execPrepared(rows)) {
			Row row;
			
			while((row = cmd.getNextRow()) != Row.init) {
				string[string] rValues;
				
				foreach(i, collumn; cmd.resultFieldDescriptions) {
					rValues[collumn.name] = row[i].toString();
				}
				ret ~= builder(rValues);
			}
		}
		
		// if cached don't do this
		cmd.releaseStatement();
		return ret;
	}
	
	override void* findOne(string table, string[] argNames, string[] args, ObjectBuilder builder, DbConnection[] connection) {
		checkConnection(table, connection);
		assert(argNames.length > 0, "There must be atleast one property in table " ~ table ~ ".");
		Connection db = cast(Connection)tableCollections[connection[0].database ~ "." ~ table];
		Command cmd = Command(db);
		
		// TODO cache this state. Will help with not having to do the above ever again.
		
		string sql;
		sql ~= "SELECT * FROM " ~ table ~ " WHERE ";
		
		foreach(name; argNames) {
			sql ~= "`" ~ name ~ "` = ? AND ";
		}
		sql.length -= 4;
		
		sql ~= "LIMIT 1;";
		
		cmd.sql(sql);
		// TODO cache this state. Will help with not having to do the above ever again.
		cmd.prepare();
		
		string[] values = args;
		foreach(i, v; args) {
			if (v.length > 2 && v[0] == '"' && v[$-1] == '"')
				values[i] = v[1 .. $-1];
			
			cmd.bindParameter(values[i], i);
		}
		
		void* ret;
		
		ulong rows;
		if (cmd.execPrepared(rows)) {
			Row row = cmd.getNextRow();
			string[string] rValues;
			
			foreach(i, collumn; cmd.resultFieldDescriptions) {
				rValues[collumn.name] = row[i].toString();
			}
			
			ret = builder(rValues);
		}
		
		// if cached don't do this
		cmd.purgeResult();
		cmd.releaseStatement();
		return ret;
	}
	
	override void remove(string table, string[] idNames, string[] valueNames, string[] valueArray, ObjectBuilder builder, DbConnection[] connection) {
		checkConnection(table, connection);
		assert(valueNames.length > 0, "There must be atleast one property in table " ~ table ~ ".");
		Connection db = cast(Connection)tableCollections[connection[0].database ~ "." ~ table];
		Command cmd = Command(db);
		
		string sql;
		sql ~= "DELETE FROM " ~ table ~ " WHERE ";
		string[] values;
		
		foreach(i, name; valueNames) {
			bool isId;
			foreach(name2; idNames) {
				if (name2 == name) {
					isId = true;
					break;
				}
			}
			
			if (isId) {
				sql ~= "`" ~ name ~ "` = ? AND ";
				values ~= valueArray[i];
			}
		}
		
		sql.length -= 4;
		
		cmd.sql(sql);
		cmd.prepare();
		
		foreach(i, value; values) {
			cmd.bindParameter(value, i);
		}
		
		ulong rows;
		cmd.execPrepared(rows);
		
		// if cached don't do this
		cmd.releaseStatement();
	}
	
	override void removeAll(string table, ObjectBuilder builder, DbConnection[] connection) {
		checkConnection(table, connection);
		Connection db = cast(Connection)tableCollections[connection[0].database ~ "." ~ table];
		
		ulong rows;
		Command cmd = Command(db);
		
		cmd.sql("DELETE FROM " ~ table);
		cmd.execSQL(rows);
		
		// if cached don't do this
		cmd.purgeResult();
		cmd.releaseStatement();
	}
	
	override void save(string table, string[] idNames, string[] valueNames, string[] valueArray, ObjectBuilder builder, DbConnection[] connection) {
		checkConnection(table, connection);
		assert(valueNames.length > 0, "There must be atleast one property in table " ~ table ~ ".");
		Connection db = cast(Connection)tableCollections[connection[0].database ~ "." ~ table];
		Command cmd = Command(db);
		
		// ok so is this a new (insert) rather then update entry?
		string sql;
		sql ~= "INSERT INTO `" ~ table ~ "`(";
		
		foreach(name; valueNames) {
			sql ~= "`" ~ name ~ "`, ";
		}
		sql.length -= 2;
		
		sql ~= ") VALUES(";
		
		foreach(value; valueArray) {
			sql ~= "?, ";
		}
		sql.length -= 2;
		
		sql ~= ") ON DUPLICATE KEY UPDATE ";
		
		foreach(name; valueNames) {
			sql ~= "`" ~ name ~ "`=VALUES(`" ~ name ~ "`), ";
		}
		sql.length -= 2;
		
		sql ~= ";";
		
		cmd.sql(sql);
		// TODO cache this state. Will help with not having to do the above ever again.
		cmd.prepare();
		
		string[] values = valueArray;
		foreach(i, v; valueArray) {
			if (v.length > 2 && v[0] == '"' && v[$-1] == '"')
				valueArray[i] = v[1 .. $-1];
			
			cmd.bindParameter(valueArray[i], i);
		}
		
		ulong rows;
		cmd.execPrepared(rows);
		
		// if cached don't do this
		cmd.releaseStatement();
	}
	
	override string[] handleQueryOp(string op, string prop, string value, string[] store) {
		switch(op) {
			case "eq":
				return store ~ (to!string(value.length) ~ ":" ~ value ~ "`" ~ prop ~ "` = ?");
			case "neq":
				return store ~ (to!string(value.length) ~ ":" ~ value ~ "`" ~ prop ~ "` != ?");
			case "mt":
				return store ~ (to!string(value.length) ~ ":" ~ value ~ "`" ~ prop ~ "` > ?");
			case "mte":
				return store ~ (to!string(value.length) ~ ":" ~ value ~ "`" ~ prop ~ "` >= ?");
			case "lt":
				return store ~ (to!string(value.length) ~ ":" ~ value ~ "`" ~ prop ~ "` < ?");
			case "lte":
				return store ~ (to!string(value.length) ~ ":" ~ value ~ "`" ~ prop ~ "` <= ?");
			case "like":
				return store ~ (to!string(value.length + 2) ~ ":%" ~ value ~ "%`" ~ prop ~ "` LIKE ?");
			case "maxAmount":
				return store ~ ("maxAmount:" ~ value);
			case "startAt":
				return store ~ ("startAt:" ~ value);
			default:
				assert(0, "Unsupported query operation " ~ op);
		}
	}
	
	override void*[] handleQuery(string[] store, string table, string[] idNames, string[] valueNames, ObjectBuilder builder, DbConnection[] connection) {
		checkConnection(table, connection);
		assert(valueNames.length > 0, "There must be atleast one property in table " ~ table ~ ".");
		Connection db = cast(Connection)tableCollections[connection[0].database ~ "." ~ table];
		Command cmd = Command(db);
		
		string sql;
		sql ~= "SELECT * from " ~ table ~ " WHERE ";
		
		string[] values;
		
		string offset;
		string maxAmount;
		
		foreach(s; store) {
			if (s.length > "startAt".length && s[0 .. "startAt".length] == "startAt") {
				// last operation ignore
				offset = s["startAt:".length .. $];
			} else if (s.length > "maxAmount".length && s[0 .. "maxAmount".length] == "maxAmount") {
				// last operation ignore
				maxAmount = s["maxAmount:".length .. $];
			} else {
				size_t index = s.indexOf(":");
				size_t length = to!size_t(s[0 .. index]);
				sql ~= s[length + index + 1 .. $] ~ " AND ";
				values ~= s[index + 1 .. length + index + 1];
			}
		}
		sql.length -= 4;
		
		if (maxAmount != "" || offset != "") {
			sql ~= "LIMIT ";
			if (offset != "")
				sql ~= offset ~ ", ";
			if (maxAmount != "")
				sql ~= maxAmount;
			else if (offset != "")
				sql ~= to!string(size_t.max);
			
		}
		
		sql ~= ";";
		
		cmd.sql(sql);
		// TODO cache this state. Will help with not having to do the above ever again.
		cmd.prepare();
		
		foreach(i, value; values) {
			cmd.bindParameter(value, i);
		}
		
		void*[] ret;
		
		ulong rows;
		if (cmd.execPrepared(rows)) {
			Row row;
			
			while((row = cmd.getNextRow()) != Row.init) {
				string[string] rValues;
				
				foreach(i, collumn; cmd.resultFieldDescriptions) {
					rValues[collumn.name] = row[i].toString();
				}
				ret ~= builder(rValues);
			}
		}
		
		// if cached don't do this
		cmd.releaseStatement();
		return ret;
	}
	
	override size_t handleQueryCount(string[] store, string table, string[] idNames, string[] valueNames, ObjectBuilder builder, DbConnection[] connection) {
		checkConnection(table, connection);
		assert(valueNames.length > 0, "There must be atleast one property in table " ~ table ~ ".");
		Connection db = cast(Connection)tableCollections[connection[0].database ~ "." ~ table];
		Command cmd = Command(db);
		
		string sql;
		sql ~= "SELECT COUNT(*) from " ~ table ~ " WHERE ";
		
		string[] values;
		
		string offset;
		string maxAmount;
		
		foreach(s; store) {
			if (s.length > "startAt".length && s[0 .. "startAt".length] == "startAt") {
				// last operation ignore
				offset = s["startAt:".length .. $];
			} else if (s.length > "maxAmount".length && s[0 .. "maxAmount".length] == "maxAmount") {
				// last operation ignore
				maxAmount = s["maxAmount:".length .. $];
			} else {
				size_t index = s.indexOf(":");
				size_t length = to!size_t(s[0 .. index]);
				sql ~= s[length + index + 1 .. $] ~ " AND ";
				values ~= s[index + 1 .. length + index + 1];
			}
		}
		sql.length -= 4;
		
		if (maxAmount != "" || offset != "") {
			sql ~= "LIMIT ";
			if (offset != "")
				sql ~= offset ~ ", ";
			if (maxAmount != "")
				sql ~= maxAmount;
			else if (offset != "")
				sql ~= to!string(size_t.max);
			
		}
		
		sql ~= ";";
		
		cmd.sql(sql);
		// TODO cache this state. Will help with not having to do the above ever again.
		cmd.prepare();
		
		foreach(i, value; values) {
			cmd.bindParameter(value, i);
		}
		
		size_t ret;
		ulong rows;
		
		if (cmd.execPrepared(rows)) {
			Row row = cmd.getNextRow();
			ret = cast(size_t)row[0].get!long;
		}
		
		// if cached don't do this
		cmd.purgeResult();
		cmd.releaseStatement();
		return ret;
	}
	
	override void handleQueryRemove(string[] store, string table, string[] idNames, string[] valueNames, ObjectBuilder builder, DbConnection[] connection) {
		checkConnection(table, connection);
		assert(valueNames.length > 0, "There must be atleast one property in table " ~ table ~ ".");
		Connection db = cast(Connection)tableCollections[connection[0].database ~ "." ~ table];
		Command cmd = Command(db);
		
		string sql;
		sql ~= "DELETE from " ~ table ~ " WHERE ";
		
		string[] values;
		
		string offset;
		string maxAmount;
		
		foreach(s; store) {
			if (s.length > "startAt".length && s[0 .. "startAt".length] == "startAt") {
				// last operation ignore
				offset = s["startAt:".length .. $];
			} else if (s.length > "maxAmount".length && s[0 .. "maxAmount".length] == "maxAmount") {
				// last operation ignore
				maxAmount = s["maxAmount:".length .. $];
			} else {
				size_t index = s.indexOf(":");
				size_t length = to!size_t(s[0 .. index]);
				sql ~= s[length + index + 1 .. $] ~ " AND ";
				values ~= s[index + 1 .. length + index + 1];
			}
		}
		sql.length -= 4;
		
		if (maxAmount != "" || offset != "") {
			sql ~= "LIMIT ";
			if (offset != "")
				sql ~= offset ~ ", ";
			if (maxAmount != "")
				sql ~= maxAmount;
			else if (offset != "")
				sql ~= to!string(size_t.max);
			
		}
		
		sql ~= ";";
		
		cmd.sql(sql);
		// TODO cache this state. Will help with not having to do the above ever again.
		cmd.prepare();
		
		foreach(i, value; values) {
			cmd.bindParameter(value, i);
		}
		
		ulong rows;
		
		cmd.execPrepared(rows);
		
		// if cached don't do this
		cmd.purgeResult();
		cmd.releaseStatement();
	}
	
	override void*[] queryJoin(string[] store, string baseTable, string endTable, string[] baseIdNames, string[] endIdNames, Provider provider, ObjectBuilder builder, DbConnection[] baseConnection, DbConnection[] endConnection) {
		checkConnection(baseTable, baseConnection);
		checkConnection(endTable, endConnection);
		
		Connection db1 = cast(Connection)tableCollections[baseConnection[0].database ~ "." ~ baseTable];
		Connection db2 = cast(Connection)tableCollections[endConnection[0].database ~ "." ~ endTable];
		
		/**
		 * select T2.* from Books AS T1
		 * INNER JOIN Page AS T2 ON T1._id = T2.book_id
		 * WHERE T1.edition = 5
		 */
		
		string sql;
		Command cmd;
		string[] values;
		
		if (baseConnection == endConnection) {
			Command cmd1 = Command(db1);
			cmd = cmd1;
			
			sql ~= "SELECT T1.* FROM " ~ endTable ~ " AS T1 ";
			sql ~= "INNER JOIN " ~ baseTable ~ " AS T2 ON ";
			
			foreach(i, sname; baseIdNames) {
				string ename = endIdNames[i];
				
				sql ~= "T1." ~ ename ~ " = T2." ~ sname ~ " AND ";
			}
			sql.length -= 4;
			
			sql ~= "WHERE ";
			
			string offset;
			string maxAmount;
			
			foreach(s; store) {
				if (s.length > "startAt".length && s[0 .. "startAt".length] == "startAt") {
					// last operation ignore
					offset = s["startAt:".length .. $];
				} else if (s.length > "maxAmount".length && s[0 .. "maxAmount".length] == "maxAmount") {
					// last operation ignore
					maxAmount = s["maxAmount:".length .. $];
				} else {
					size_t index = s.indexOf(":");
					size_t length = to!size_t(s[0 .. index]);
					sql ~= "T2." ~ s[length + index + 1 .. $] ~ " AND ";
					values ~= s[index + 1 .. length + index + 1];
				}
			}
			sql.length -= 4;
			
			if (maxAmount != "" || offset != "") {
				sql ~= "LIMIT ";
				if (offset != "")
					sql ~= offset ~ ", ";
				if (maxAmount != "")
					sql ~= maxAmount;
				else if (offset != "")
					sql ~= to!string(size_t.max);
				
			}
			
			sql ~= ";";
		} else {
			assert(0, "Currently querying can only occur upon the same database.");
		}
		
		cmd.sql(sql);
		// TODO cache this state. Will help with not having to do the above ever again.
		cmd.prepare();
		
		foreach(i, value; values) {
			cmd.bindParameter(value, i);
		}
		
		void*[] ret;
		
		ulong rows;
		if (cmd.execPrepared(rows)) {
			Row row;
			
			while((row = cmd.getNextRow()) != Row.init) {
				string[string] rValues;
				
				foreach(i, collumn; cmd.resultFieldDescriptions) {
					rValues[collumn.name] = row[i].toString();
				}
				ret ~= builder(rValues);
			}
		}
		
		// if cached don't do this
		cmd.releaseStatement();
		return ret;
	}
}

private {
	void checkConnection(string table, DbConnection[] connections) {
		if (connections.length >= 1) {
			DbConnection con = connections[0];
			if (con.database ~ "." ~ table !in tableCollections) {
				if (con.port == ushort.init) {
					con.port = 3306;
				}
				
				LockedConnection!Connection cnx = new MysqlDB(con.host, con.user, con.pass, con.database, con.port).lockConnection();
				tableCollections[con.database ~ "." ~ table] = cast(shared)cnx.__conn;
			} else {
				// already created
			}
		} else {
			assert(0, "No database could be connected to. For table " ~ table ~ ".");
		}
	}
}