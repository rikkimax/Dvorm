module dvorm.logging;
import dvorm;
import std.traits;

protected {
	shared string ormLog;
}

string getOrmLog() {
	return cast(string)ormLog;
}

void ormLogAppend(string val) {
	ormLog ~= val;
}

pure string logger(C, bool keysOnly = false, bool appendOnly = false, string prefix="", bool isFk=false, string fkPrefix="")() {
	string ret;
	if (!appendOnly) {
		ret ~= "static void logMe() {";
		ret ~= "string ormLogVal = \"" ~ getTableName!(C)() ~ ":\r\n\";";
	}
	
	C c = newValueOfType!C;
	
	void[][string] ids;
	
	foreach(m; __traits(allMembers, C)) {
		foreach(UDA; __traits(getAttributes, mixin("c." ~ m))) {
			static if (is(UDA : dbId)) {
				ids[m] = [];
			}
		}
		
		static if (isUsable!(C, m)()) {
			static if (isAnObjectType!(typeof(mixin("c." ~ m)))) {
				// so we are an object.
				static if (isActualRelationship!(C, m)() && !isFk) {
					mixin("import " ~ getRelationshipClassModuleName!(C, m)() ~ ";");
					ret ~= logger!(typeof(mixin("c." ~ m)), true, true, getNameValue!(C, m)() ~ "_", true, getTableName!(mixin(getRelationshipClassName!(C, m)()))())();
				} else {
					ret ~= logger!(typeof(mixin("c." ~ m)), true, true, getNameValue!(C, m)() ~ "_", true)();
				}
			} else {
				// default action. Mostly for non object based i.e. primitives or strings.
				if (m in ids) {
					static if (isActualRelationship!(C, m)() && !isFk) {
						mixin("import " ~ getRelationshipClassModuleName!(C, m)() ~ ";");
						ret ~= "ormLogVal ~= \"PK FK: [" ~ getTableName!(mixin(getRelationshipClassName!(C, m)())) ~ "][";
					} else {
						static if (isFk && fkPrefix != "") {
							ret ~= "ormLogVal ~= \"FK: [" ~ fkPrefix ~ "][";
						} else {
							ret ~= "ormLogVal ~= \"PK: [";
						}
					}
					ret ~= typeof(mixin("c." ~ m)).stringof ~ "] " ~ prefix ~ getNameValue!(C, m)() ~ "\";";
					if (hasDefaultValue!(C, m))
						ret ~= "ormLogVal ~= \" = " ~ getDefaultValue!(C, m)() ~ "\r\n\";";
					else
						ret ~= "ormLogVal ~= \"\r\n\";";
				}
			}
		}
	}
	
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)()) {
			static if (!isAnObjectType!(typeof(mixin("c." ~ m)))) {
				if (m !in ids) {
					static if(!keysOnly) {
						static if (isActualRelationship!(C, m)()) {
							mixin("import " ~ getRelationshipClassModuleName!(C, m)() ~ ";");
							ret ~= "ormLogVal ~= \"FK: [" ~ getTableName!(mixin(getRelationshipClassName!(C, m)())) ~ "][";
						} else {
							ret ~= "ormLogVal ~= \"[";
						}
						ret ~= typeof(mixin("c." ~ m)).stringof ~ "] " ~ prefix ~ getNameValue!(C, m)() ~ "\";";
						if (hasDefaultValue!(C, m))
							ret ~= "ormLogVal ~= \" = " ~ getDefaultValue!(C, m)() ~ "\r\n\";";
						else
							ret ~= "ormLogVal ~= \"\r\n\";";
					}
				}
			}
		}
	}
	
	if (!appendOnly) {
		ret ~= "ormLogVal ~= \"=======----=======\r\n\";";
		
		ret ~= "ormLogAppend(ormLogVal);";
		ret ~= "}";
	}
	return ret;
}