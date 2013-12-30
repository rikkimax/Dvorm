module dvorm.query;
import dvorm;
import std.traits;

interface IQuery {}

class Query(string moduleName, string name) : IQuery {
	mixin("import " ~ moduleName ~ ";");

	private string[] store;
	
	mixin(queryInterface!(mixin(name))());

	mixin(name ~ "[] " ~ q{find() {
		mixin(objectBuilderCreator!(mixin(name))());
		mixin(name ~ "[] ret = cast(" ~ name ~ "[])" ~ q{provider(getDbType!(mixin(name))).handleQuery(store, getTableName!(mixin(name))(), getAllIdNames!(mixin(name))(), getAllValueNames!(mixin(name))(), &objectBuilder, mixin(name).databaseConnection());});
		return ret;
	}});

	mixin("""
Query!(\"" ~ mixin("std.traits.moduleName!" ~ name) ~  "\", \"" ~ name ~ "\") maxAmount(ushort value) {
	mixin(objectBuilderCreator!(mixin(name))());
	mixin(\"store = provider(getDbType!(mixin(name))).handleQueryOp(\\\"maxAmount\\\", \\\"\\\", to!string(value), store);\");
    return this;
}

Query!(\"" ~ mixin("std.traits.moduleName!" ~ name) ~  "\", \"" ~ name ~ "\") startAt(ushort value) {
	mixin(objectBuilderCreator!(mixin(name))());
	mixin(\"store = provider(getDbType!(mixin(name))).handleQueryOp(\\\"startAt\\\", \\\"\\\", to!string(value), store);\");
    return this;
}
""");
}

pure string queryInterface(C)() {
	string ret;

	C c = new C;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m) && !shouldBeIgnored!(C, m)) {
			ret ~= queryIGen!(C, m, "eq")();
			ret ~= queryIGen!(C, m, "neq")();
			ret ~= queryIGen!(C, m, "lt")();
			ret ~= queryIGen!(C, m, "lte")();
			ret ~= queryIGen!(C, m, "mt")();
			ret ~= queryIGen!(C, m, "mte")();
			ret ~= queryIGen!(C, m, "like")();
		}
	}
	
	return ret;
}

pure string queryGenerator(C)() {
	string ret;
	C c = new C;

	ret ~= "@property static Query!(\"" ~ moduleName!C ~ "\", \"" ~ C.stringof ~ "\") query() {";
	ret ~= "return new Query!(\"" ~ moduleName!C ~ "\", \"" ~ C.stringof ~ "\");";
	ret ~= "}";

	return ret;
}

pure bool hasType(C, string name, string type)() {
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m) && !shouldBeIgnored!(C, m)) {
			static if (typeof("c." ~ m).stringof == type) {
				return name != m;
			}
		}
	}

	return false;
}

pure string queryIGen(C, string m, string op)() {
	C c = new C;
	string typeValue = typeof(mixin("c." ~ m)).stringof == "string" ? "value" : "to!string(value)";
	return 
"""
Query!(\"" ~ moduleName!C ~ "\", \"" ~ C.stringof ~ "\")" ~ m ~ "_" ~ op ~ "(" ~ typeof("c." ~ m).stringof ~ " value) {
    import std.conv;
    store = provider(getDbType!" ~ C.stringof ~ ").handleQueryOp(\"" ~ op ~ "\", \"" ~ getNameValue!(C, m)() ~ "\", " ~ typeValue ~ ", store); 
    return this;
}
""";
}