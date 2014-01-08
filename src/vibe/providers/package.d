module dvorm.vibe.providers;
import dvorm.provider;
import dvorm.connection;
public import dvorm.vibe.providers.mongo;

import std.traits;

shared static this() {
	registerProvider(DbType.Mongo, new MongoProvider);
}