module dvorm.query;
import dvorm;
import std.traits;

class Query(string moduleName, string name) {
	mixin("import " ~ moduleName ~ ";");
	mixin("import std.conv : to;");
	private string[] store;
	
	mixin(queryInterface!(mixin(name))());
	
	mixin(name ~ "[] " ~ q{find() {
			mixin(objectBuilderCreator!(mixin(name))());
			mixin("return dePointerArrayValues!(" ~ name ~ ")(cast(" ~ name ~ "*[])" ~
			      q{
				provider(getDbType!(mixin(name))).handleQuery(
					store,
					getTableName!(mixin(name))(),
					getAllIdNames!(mixin(name))(),
					getAllValueNames!(mixin(name))(),
					&objectBuilder,
					getDbConnectionInfo!(mixin(name))));
			});
		}});
	
	mixin(q{
		size_t count() {
			mixin(objectBuilderCreator!(mixin(name))());
			return provider(getDbType!(mixin(name))).handleQueryCount(store, getTableName!(mixin(name))(), getAllIdNames!(mixin(name))(), getAllValueNames!(mixin(name))(), &objectBuilder, getDbConnectionInfo!(mixin(name)));
		}
	});
	
	mixin(q{
		void remove() {
			mixin(objectBuilderCreator!(mixin(name))());
			provider(getDbType!(mixin(name))).handleQueryRemove(store, getTableName!(mixin(name))(), getAllIdNames!(mixin(name))(), getAllValueNames!(mixin(name))(), &objectBuilder, getDbConnectionInfo!(mixin(name)));
		}
	});
	
	mixin("""
Query!(\"" ~ mixin("std.traits.moduleName!" ~ name) ~  "\", \"" ~ name ~ "\") maxAmount(ushort value) {
	mixin(\"store = provider(getDbType!(mixin(name))).handleQueryOp(\\\"maxAmount\\\", \\\"\\\", to!string(value), store);\");
    return this;
}

Query!(\"" ~ mixin("std.traits.moduleName!" ~ name) ~  "\", \"" ~ name ~ "\") startAt(ushort value) {
	mixin(\"store = provider(getDbType!(mixin(name))).handleQueryOp(\\\"startAt\\\", \\\"\\\", to!string(value), store);\");
    return this;
}
""");
}

pure string queryInterface(C)() {
	string ret;
	
	C c = newValueOfType!C;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m) && !shouldBeIgnored!(C, m)) {
			static if (!isAnObjectType!(typeof(mixin("c." ~ m))) && !is(typeof(mixin("c." ~ m)) == enum)) {
				ret ~= queryIGen!(C, m, "eq")();
				ret ~= queryIGen!(C, m, "neq")();
				ret ~= queryIGen!(C, m, "lt")();
				ret ~= queryIGen!(C, m, "lte")();
				ret ~= queryIGen!(C, m, "mt")();
				ret ~= queryIGen!(C, m, "mte")();
				ret ~= queryIGen!(C, m, "like")();
			} else static if (!is(typeof(mixin("c." ~ m)) == enum)) {
				foreach(n; __traits(allMembers, typeof(mixin("c." ~ m)))) {
					static if (isUsable!(typeof(mixin("c." ~ m)), n) && !shouldBeIgnored!(typeof(mixin("c." ~ m)), n)) {
						static if (!isAnObjectType!(typeof(mixin("c." ~ m ~ "." ~ n)))) {
							ret ~= queryIGen!(C, m, "eq", n)();
							ret ~= queryIGen!(C, m, "neq", n)();
							ret ~= queryIGen!(C, m, "lt", n)();
							ret ~= queryIGen!(C, m, "lte", n)();
							ret ~= queryIGen!(C, m, "mt", n)();
							ret ~= queryIGen!(C, m, "mte", n)();
							ret ~= queryIGen!(C, m, "like", n)();
						}
					}
				}
			}
		}
	}
	
	return ret;
}

pure string queryGenerator(C)() {
	string ret;
	C c = newValueOfType!C;
	
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

pure string queryIGen(C, string m, string op, string subm="",
                      C c = newValueOfType!C,
                      string nameOfFunc = m ~ (subm == "" ? "" : "_" ~ subm) ~ "_" ~ op,
                      string handleName = getNameOfHandle!(C, m, subm)(),
                      string typeValue = typeof(mixin("c." ~ m)).stringof == "string" ? "value" : "to!string(value)",
                      string valueType = getValueOfHandle!(C, m, subm)())() {
	return 
		"""
Query!(\"" ~ moduleName!C ~ "\", \"" ~ C.stringof ~ "\") " ~ nameOfFunc ~ "(" ~ valueType ~ " value) {
    store = provider(getDbType!" ~ C.stringof ~ ").handleQueryOp(\"" ~ op ~ "\", \"" ~ handleName ~ "\", " ~ typeValue ~ ", store); 
    return this;
}
""";
}

pure string getNameOfHandle(C, string m, string subm)() {
	C c = newValueOfType!C;
	static if (subm == "") {
		return getNameValue!(C, m)();
	} else {
		return getNameValue!(C, m)() ~ "_" ~ getNameValue!(typeof(mixin("c." ~ m)), subm)();
	}
}

pure string getValueOfHandle(C, string m, string subm)() {
	C c = newValueOfType!C;
	static if (subm == "") {
		return typeof(mixin("c." ~ m)).stringof;
	} else {
		return typeof(mixin("c." ~ m ~ "." ~ subm)).stringof;
	}
}
