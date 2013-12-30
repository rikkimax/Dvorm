module dvorm.providers;
import dvorm.provider;
import dvorm.connection;
public import dvorm.providers.memory;

import std.traits;

static this() {
	registerProvider(DbType.Memory, new MemoryProvider);
}