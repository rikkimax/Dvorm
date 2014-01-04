module dvorm.save;
import dvorm;
import std.conv : to;
import std.traits;

string save(C)() {
	string ret;
	ret ~= "void save() {";
	
	string valueArray;
	valueArray ~= "string[] valueArray = [";
	
	string valueNames;
	valueNames ~= "string[] valueNames = [";
	
	string idNames;
	idNames ~= "string[] idNames = [";
	
	C c = new C;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)() && !shouldBeIgnored!(C, m)()) {
			foreach(UDA; __traits(getAttributes, mixin("c." ~ m))) {
				static if (is(UDA : dbId)) {
					static if (!is(typeof(mixin("c." ~ m)) : Object))
						idNames ~= "\"" ~ getNameValue!(C, m)() ~ "\",";
				}
			}
			
			static if (is(typeof(mixin("c." ~ m)) : Object)) {
				//assert(0, "Have yet to enable saving of objects");
				mixin("import " ~ moduleName!(mixin("c." ~ m)) ~ ";");
				mixin("auto d = new typeof(c." ~ m ~ ");");
				foreach(n; __traits(allMembers, mixin("typeof(d)"))) {
					static if (isUsable!(typeof(d), n)() && !shouldBeIgnored!(typeof(d), n)()) {
						foreach(UDA; __traits(getAttributes, mixin("d." ~ n))) {
							static if (is(UDA : dbId)) {
								idNames ~= "\"" ~ getNameValue!(C, m)()  ~ "_" ~ getNameValue!(typeof(d), n)() ~ "\",";
								valueNames ~= "\"" ~ getNameValue!(C, m)()  ~ "_" ~ getNameValue!(typeof(d), n)() ~ "\",";
								static if (is(typeof(mixin("d." ~ n)) : Object)) {
									assert(0, "Cannot use an object as an id, when more then one recursion. " ~ C.stringof ~ "." ~ m ~ "." ~ n);
								} else static if (typeof(mixin("d." ~ n)).stringof != "string") {
									valueArray ~= "to!string(" ~ m ~ "." ~ n ~ "),";
								} else {
									valueArray ~= m ~ "." ~ n ~ ",";
								}
							}
						}
					}
				}
			} else static if (typeof(mixin("c." ~ m)).stringof != "string") {
				valueNames ~= "\"" ~ getNameValue!(C, m)() ~ "\",";
				valueArray ~= "to!string(" ~ m ~ "),";
			} else {
				valueNames ~= "\"" ~ getNameValue!(C, m)() ~ "\",";
				valueArray ~= m ~ ",";
			}
		}
	}
	
	if (idNames[$ - 1] == ',') {
		idNames = idNames[0 .. $-1];
	}
	
	if (valueNames[$ - 1] == ',') {
		valueNames = valueNames[0 .. $-1];
		valueArray = valueArray[0 .. $-1];
	}
	
	ret ~= idNames ~ "];";
	ret ~= valueNames ~ "];";
	ret ~= valueArray ~ "];";
	
	// database dependent find part
	ret ~=  objectBuilderCreator!C();
	ret ~= "provider(getDbType!" ~ C.stringof ~ ").save!" ~ C.stringof ~ "(idNames, valueNames, valueArray, &objectBuilder);";
	
	ret ~= "}";
	return ret;
}