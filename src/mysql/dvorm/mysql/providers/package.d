module dvorm.mysql.providers;
import dvorm.provider;
import dvorm.connection;
public import dvorm.mysql.providers.mysql_native;

shared static this() {
	registerProvider(DbType.Mysql, new MysqlNativeProvider);
}