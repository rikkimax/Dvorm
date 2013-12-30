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

pure string logger(C, bool keysOnly = false, bool appendOnly = false, string prefix="")() {
	string ret;
	if (!appendOnly) {
		ret ~= "static this() {";
		ret ~= "string ormLogVal = \"" ~ getTableName!(C)() ~ ":\r\n\";";
	}

	C c = new C;

	void[][string] ids;
	
	foreach(m; __traits(allMembers, C)) {
		foreach(UDA; __traits(getAttributes, mixin("c." ~ m))) {
			static if (is(UDA : id)) {
				ids[m] = [];
			}
		}

		static if (isUsable!(C, m)()) {
			static if (is(typeof(mixin("c." ~ m)) : Object)) {
				// so we are an object.
				ret ~= logger!(typeof(mixin("c." ~ m)), true, true, getNameValue!(C, m)() ~ "_")();
			} else {
				// default action. Mostly for non object based i.e. primitives or strings.
				if (m in ids) {
					ret ~= "ormLogVal ~= \"PK: [";
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
			if (m !in ids) {
				static if(!keysOnly) {
					ret ~= "ormLogVal ~= \"[";
					ret ~= typeof(mixin("c." ~ m)).stringof ~ "] " ~ prefix ~ getNameValue!(C, m)() ~ "\";";
					if (hasDefaultValue!(C, m))
						ret ~= "ormLogVal ~= \" = " ~ getDefaultValue!(C, m)() ~ "\r\n\";";
					else
						ret ~= "ormLogVal ~= \"\r\n\";";
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