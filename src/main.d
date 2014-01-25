module main;
import dvorm;
import dvorm.unittests;
import std.stdio : writeln;

void main() {
	version(unittest) {
		//unittest1(DbConnection(DbType.Mongo, "192.168.100.10", ushort.init, null, null, "aa_test"));
		unittest1(DbConnection(DbType.Memory));
		
		writeln(getOrmLog());
	}
}