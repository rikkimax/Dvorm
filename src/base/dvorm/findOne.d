module dvorm.findOne;
import dvorm;
import std.conv : to;
import std.traits;

string findOne(C)() {
	string ret = "static C findOne(";
	string argArray = "string[] args = [";
	string argNames = "string[] argNames = [";
	
	C c = newValueOfType!(C)();
	
	uint indexCount;
	bool hasIndex;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)() && !shouldBeIgnored!(C, m)()) {
			static if (isAnId!(C, m)) {
				static if (isAnObjectType!(typeof(mixin("c." ~ m)))()) {
					// so we are an object.
					//assert(0, "Cannot use an object as an id");
					mixin("import " ~ moduleName!(mixin("c." ~ m)) ~ ";");
					mixin("auto d = newValueOfType!(" ~ typeof(mixin("c." ~ m)).stringof ~ ");");
					foreach(n; __traits(allMembers, typeof(mixin("c." ~ m)))) {
						static if (isUsable!(typeof(d), n)()) {
							foreach(UDA; __traits(getAttributes, mixin("d." ~ n))) {
								static if (is(UDA : dbId)) {
									argNames ~= "\"" ~ getNameValue!(C, m)() ~ "_" ~ getNameValue!(typeof(d), n)() ~ "\",";
									
									string argNum = to!string(indexCount);
									ret ~= typeof(mixin("d." ~ n)).stringof ~ " v" ~ argNum;
									
									if (hasDefaultValue!(typeof(d), n)()) {
										ret ~= " = " ~ getDefaultValue!(typeof(d), n) ~ ",";
									} else {
										ret ~= ",";
									}
									
									indexCount++;
									hasIndex = true;
									
									if (typeof(mixin("d." ~ n)).stringof != "string") {
										argArray ~= "to!string(v" ~ argNum ~ "),";
									} else {
										argArray ~= "v" ~ argNum ~ ",";
									}
								}
							}
						}
					}
				} else {
					argNames ~= "\"" ~ getNameValue!(C, m)() ~ "\",";
					
					string argNum = to!string(indexCount);
					ret ~= typeof(mixin("c." ~ m)).stringof ~ " v" ~ argNum;
					
					if (hasDefaultValue!(C, m)()) {
						ret ~= " = " ~ typeof(mixin("c." ~ m)).stringof ~ ".init,";
					} else {
						ret ~= ",";
					}
					
					indexCount++;
					hasIndex = true;
					
					if (typeof(mixin("c." ~ m)).stringof != "string") {
						argArray ~= "\"" ~ getDefaultValue!(C, m)() ~ "\",";
					} else {
						argArray ~= "v" ~ argNum ~ ",";
					}
				}
			}
		}
	}
	
	if (hasIndex) {
		ret = ret[0 .. $-1];
		if (argArray[$ - 1] == ',') {
			argArray = argArray[0 .. $-1];
			argNames = argNames[0 .. $-1];
		}
	} else {
		assert(0, "You derped. Type " ~ C.stringof ~ " does not have any id's, so cannot be an dvorm model.");
	}
	
	ret ~= ") {\nC ret;\n";
	
	argArray ~= "];\n";
	ret ~= argArray;
	
	argNames ~= "];\n";
	ret ~= argNames;
	
	// database dependent findOne part
	ret ~= objectBuilderCreator!C();
	ret ~= "ret = provider(getDbType!" ~ C.stringof ~ ").findOne!" ~ C.stringof ~ "(argNames, args, &objectBuilder);\n";	 
	ret ~= "return ret;}\n";
	return ret;
}
