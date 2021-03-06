module dvorm.remove;
import dvorm;
import std.conv : to;
import std.traits;

string remove(C)() {
	string ret;
	ret ~= "void remove() {";
	
	string valueArray;
	valueArray ~= "string[] valueArray = [";
	
	string valueNames;
	valueNames ~= "string[] valueNames = [";
	
	string idNames;
	idNames ~= "string[] idNames = [";
	
	C c = new C;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)() && !shouldBeIgnored!(C, m)()) {
			static if (isAnId!(C, m)) {
				static if (isAnObjectType!(typeof(mixin("c." ~ m)))) {
					//assert(0, "Have yet to enable saving of objects");
					mixin("import " ~ moduleName!(typeof(mixin("c." ~ m))) ~ ";");
					mixin(typeof(mixin("c." ~ m)).stringof ~ " d = newValueOfType!" ~ typeof(mixin("c." ~ m)).stringof ~ ";");
					foreach(n; __traits(allMembers, typeof(mixin("c." ~ m)))) {
						static if (isUsable!(typeof(d), n)()) {
							foreach(UDA; __traits(getAttributes, mixin("d." ~ n))) {
								static if (is(UDA : dbId)) {
									valueNames ~= "\"" ~ m  ~ "_" ~ getNameValue!(typeof(d), n)() ~ "\",";
									static if (isAnObjectType!(typeof(mixin("d." ~ n)))) {
										assert(0, "Cannot use an object as an id, when more then one recursion. " ~ C.stringof ~ "." ~ m ~ "." ~ n);
									} else static if (typeof(mixin("d." ~ n)).stringof != "string") {
										idNames ~= "\"" ~ getNameValue!(C, m)()  ~ "_" ~ getNameValue!(typeof(d), n)() ~ "\",";
										valueArray ~= "\"" ~ to!string(mixin("d." ~ n)) ~ "\",";
									} else {
										idNames ~= "\"" ~ getNameValue!(C, m)()  ~ "_" ~ getNameValue!(typeof(d), n)() ~ "\",";
										valueArray ~= "\"" ~ mixin("d." ~ n) ~ "\",";
									}
								}
							}
						}
					}
				} else static if (typeof(mixin("c." ~ m)).stringof != "string") {
					idNames ~= "\"" ~ getNameValue!(C, m)() ~ "\",";
					valueNames ~= "\"" ~ getNameValue!(C, m)() ~ "\",";
					valueArray ~= "to!string(" ~ m ~ "),";
				} else {
					idNames ~= "\"" ~ getNameValue!(C, m)() ~ "\",";
					valueNames ~= "\"" ~ getNameValue!(C, m)() ~ "\",";
					valueArray ~= m ~ ",";
				}
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
	ret ~= "provider(getDbType!" ~ C.stringof ~ ").remove!" ~ C.stringof ~ "(idNames, valueNames, valueArray, &objectBuilder);";
	
	ret ~= "}";
	return ret;
}