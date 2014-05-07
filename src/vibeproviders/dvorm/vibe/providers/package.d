module dvorm.vibe.providers;
import dvorm.provider;
import dvorm.connection;
public import dvorm.vibe.providers.mongo;

shared static this() {
	registerProvider(DbType.Mongo, new MongoProvider);
}