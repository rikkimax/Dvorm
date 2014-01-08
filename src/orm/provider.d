module dvorm.provider;
public import dvorm.connection;
import dvorm.util;
import std.traits;

private {
	__gshared Provider[DbType] providers;
}

Provider provider(DbType type) {
	assert(providers.get(type, null) !is null, "Database provider " ~ type ~ " has not been registered :(");
	return providers[type];
}

void registerProvider(DbType type, Provider p) {
	providers[type] = p;
}

abstract class Provider {
	Object[] find(C)(string[] argNames, string[] args, ObjectBuilder builder) {
		return find(getTableName!C(), argNames, args, builder, C.databaseConnection());
	}
	
	Object[] findAll(C)(ObjectBuilder builder) {
		return findAll(getTableName!C(), builder, C.databaseConnection());
	}
	
	Object findOne(C)(string[] argNames, string[] args, ObjectBuilder builder) {
		return findOne(getTableName!C(), argNames, args, builder, C.databaseConnection());
	}
	
	void remove(C)(string[] idNames, string[] valueNames, string[] valueArray) {
		remove(getTableName!C(), idNames, valueNames, valueArray, C.databaseConnection());
	}
	
	void save(C)(string[] idNames, string[] valueNames, string[] valueArray, ObjectBuilder builder) {
		save(getTableName!C(), idNames, valueNames, valueArray, builder, C.databaseConnection());
	}
	
	Object[] find(string table, string[] argNames, string[] args, ObjectBuilder builder, DbConnection[] connection);
	Object[] findAll(string table, ObjectBuilder builder, DbConnection[] connection);
	Object findOne(string table, string[] argNames, string[] args, ObjectBuilder builder, DbConnection[] connection);
	void remove(string table, string[] idNames, string[] valueNames, string[] valueArray, DbConnection[] connection);
	void save(string table, string[] idNames, string[] valueNames, string[] valueArray, ObjectBuilder builder, DbConnection[] connection);
	
	string[] handleQueryOp(string op, string prop, string value, string[] store);
	Object[] handleQuery(string[] store, string table, string[] idNames, string[] valueNames, ObjectBuilder builder, DbConnection[] connection);
	size_t handleQueryCount(string[] store, string table, string[] idNames, string[] valueNames, DbConnection[] connection);
	void handleQueryRemove(string[] store, string table, string[] idNames, string[] valueNames, DbConnection[] connection);
}

alias Object delegate(string[string] values) ObjectBuilder;

pure string objectBuilderCreator(C, string name = "objectBuilder")() {
	string ret;
	ret ~= "Object " ~ name ~ "(string[string] values) {\n";
	ret ~= "    import " ~ moduleName!C ~ ";\n";
	ret ~= "    import std.conv : to;\n";
	ret ~= "    " ~ C.stringof ~ " ret = new " ~ C.stringof ~ ";\n";
	ret ~= "    string keyValueOfName;";
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)) {
			static if (!shouldBeIgnored!(C, m)) {
				ret ~= 
					"""
    static if (!is(typeof(ret." ~ m ~ ") : Object)) {
        static if (isBasicType!(typeof(ret." ~ m ~ "))) {
            ret." ~ m ~ " = to!(typeof(ret." ~ m ~ "))(values[\"" ~ getNameValue!(C, m)() ~ "\"]);
        } else static if (isArray!(typeof(ret." ~ m ~ ")) && 
		    (typeof(ret." ~ m ~ ").stringof == \"string\" ||
			typeof(ret." ~ m ~ ").stringof == \"dstring\" ||
			typeof(ret." ~ m ~ ").stringof == \"wstring\")) {
            ret." ~ m ~ " = values[\"" ~ getNameValue!(C, m)() ~ "\"];
        }
    } else {
        auto " ~ m ~ " = new typeof(ret." ~ m  ~ ");
        foreach(n; __traits(allMembers, typeof(ret." ~ m ~ "))) {
            static if (isUsable!(typeof(ret." ~ m  ~ "), n)() && !shouldBeIgnored!(typeof(ret." ~ m  ~ "), n)()) {
                static if (!is(typeof(mixin(\"" ~ m ~ ".\" ~ n)) : Object)) {
                    keyValueOfName = \"" ~ getNameValue!(C, m)() ~ "_\" ~ getNameValue!(typeof(ret." ~ m  ~ "), n)();
                    static if (isBasicType!(typeof(mixin(\"" ~ m ~ ".\" ~ n)))) {
                       if (keyValueOfName in values) {
                           mixin(\"" ~ m ~ ".\" ~ n) = to!(typeof(mixin(\"" ~ m ~ ".\" ~ n)))(values[keyValueOfName]);
                       }
                    } else static if (isArray!(typeof(mixin(\"" ~ m ~ ".\" ~ n))) && 
			            (typeof(mixin(\"" ~ m ~ ".\" ~ n)).stringof == \"string\" ||
			 			typeof(mixin(\"" ~ m ~ ".\" ~ n)).stringof == \"dstring\" ||
			 			typeof(mixin(\"" ~ m ~ ".\" ~ n)).stringof == \"wstring\")) {
                       if (keyValueOfName in values) {
                           mixin(\"" ~ m ~ ".\" ~ n) = to!(typeof(mixin(\"" ~ m ~ ".\" ~ n)))(values[keyValueOfName]);
                       }
                    }
                } else {
                    assert(0, \"Cannot have ids within more then one recursion of an object\");
                }
            }
        }
        ret." ~ m ~ " = " ~ m ~ ";
    }
""";
			}
		}
	}
	
	ret ~= "    return ret;\n";
	ret ~= "}";
	return ret;
}