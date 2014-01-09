module dvorm.util;
import dvorm.connection;
import std.conv : to;
import std.traits;

struct dbId {
}

struct dbDefaultValue {
	string value;
}

struct dbIgnore {
}

struct dbName {
	string value;
}

/**
 * Right now I have NO idea how to determine if this is dbActualModel or not.
 * So UDA it is
 */
@("dbIsModel")
struct dbActualModel(T, string prop) {
	T type;
	string name = prop;
}

pure string getDefaultValue(C, string m)() {
	C c = new C;
	
	foreach(UDA; __traits(getAttributes, mixin("c." ~ m))) {
		static if (__traits(compiles, {dbDefaultValue v = UDA;})) {
			return UDA.value;
		}
	}
	return "";
}

pure bool hasDefaultValue(C, string m)() {
	C c = new C;
	
	foreach(UDA; __traits(getAttributes, mixin("c." ~ m))) {
		static if (__traits(compiles, {dbDefaultValue v = UDA;})) {
			return true;
		}
	}
	return false;
}

pure string getNameValue(C, string m)() {
	C c = new C;
	
	foreach(UDA; __traits(getAttributes, mixin("c." ~ m))) {
		static if (__traits(compiles, {dbName v = UDA;})) {
			return UDA.value;
		}
	}
	return m;
}

pure string getTableName(C)() {
	foreach(UDA; __traits(getAttributes, C)) {
		static if (__traits(compiles, {dbName v = UDA;})) {
			return UDA.value;
		}
	}
	return C.stringof;
}

pure bool shouldBeIgnored(C, string m)() {
	C c = new C;
	
	static if (__traits(compiles, __traits(getProtection, mixin("c." ~ m))) &&
	           __traits(getProtection, mixin("c." ~ m)) == "public") {
		foreach(UDA; __traits(getAttributes, mixin("c." ~ m))) {
			static if (is(UDA : dbIgnore)) {
				return true;
			}
		}
		return false;
	} else {
		return true;
	}
}

pure bool isAnId(C, string m)() {
	C c = new C;
	
	foreach(UDA; __traits(getAttributes, mixin("c." ~ m))) {
		static if (is(UDA : dbId)) {
			return true;
		}
	}
	return false;
}

pure string[] getAllIds(C, bool first = true, string prefix="")() {
	string[] ret;
	C c = new C;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)()) {
			static if(is(typeof(mixin("c." ~ m)) : Object)) {
				static if (first)
					ret ~= getAllIds!(typeof(mixin("c." ~ m)), false, getNameValue!(C, m) ~ "_")();
			} else {
				static if (isAnId!(C, m)()) {
					ret ~= prefix ~ getNameValue!(C, m);
				}
			}
		}
	}
	return ret;
}

pure string[] getAllIdNames(C, bool first = true, string prefix="")() {
	string[] ret;
	C c = new C;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)()) {
			static if(is(typeof(mixin("c." ~ m)) : Object)) {
				static if (first)
					ret ~= getAllIdNames!(typeof(mixin("c." ~ m)), false, m ~ "_")();
			} else {
				static if (isAnId!(C, m)()) {
					ret ~= prefix ~ m;
				}
			}
		}
	}
	return ret;
}

pure string[] getAllValues(C, bool first = true, string prefix="")() {
	string[] ret;
	C c = new C;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)()) {
			static if(is(typeof(mixin("c." ~ m)) : Object)) {
				static if (first)
					ret ~= getAllValues!(typeof(mixin("c." ~ m)), false, m ~ "_")();
			} else {
				ret ~= prefix ~ getNameValue!(C, m);
			}
		}
	}
	return ret;
}

pure string[] getAllValueNames(C, bool first = true, string prefix="")() {
	string[] ret;
	C c = new C;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)()) {
			static if(is(typeof(mixin("c." ~ m)) : Object)) {
				static if (first)
					ret ~= getAllValueNames!(typeof(mixin("c." ~ m)), false, m ~ "_")();
			} else {
				ret ~= prefix ~ m;
			}
		}
	}
	return ret;
}

pure bool isUsable(C, string m)() {
	C c = C.init;

	static if (__traits(compiles, __traits(getProtection, mixin("c." ~ m))) &&
	           __traits(getProtection, mixin("c." ~ m)) == "public") {
		static if (!__traits(hasMember, Object, m) &&
		           !__traits(isAbstractFunction, Object, m) &&
		           !__traits(isStaticFunction, mixin("c." ~ m)) &&
		           !__traits(isOverrideFunction, mixin("c." ~ m)) &&
		           !__traits(isFinalFunction, mixin("c." ~ m)) &&
		           !(m.length >= 2 &&
		  m[0 .. 2] == "op") &&
		           !__traits(isVirtualMethod, mixin("c." ~ m))) {
			// first stage done.
		
			static if (isArray!(typeof(mixin("c." ~ m))) && 
			            (typeof(mixin("c." ~ m)).stringof == "string" ||
			 			typeof(mixin("c." ~ m)).stringof == "dstring" ||
			 			typeof(mixin("c." ~ m)).stringof == "wstring")) {
				// so we are an string (not allow any old array right now).
				return true;
			}
			
			static if (isBasicType!(typeof(mixin("c." ~ m))) ||
			           is(typeof(mixin("c." ~ m)) : Object) ||
			           is(typeof(mixin("c." ~ m)) == enum)) {
				// allow primitives and classes
				return true;
			}
			
			assert(0, "Type information for " ~ C.stringof ~ "." ~ m ~ " has not been implemented yet.");
	    } else {
			return false;
		}
	} else {
		return false;
	}
}

DbType getDbType(C)() {
	foreach(c; C.databaseConnection()) {
		return c.type;
	}
	return DbType.Memory;
}

/**
 * Does a variable have another model associated with it?
 */

pure bool isActualRelationship(T, string f)() {
	T t = new T;
	foreach(UDA; __traits(getAttributes, mixin("t." ~ f))) {
		foreach(UDA2; __traits(getAttributes, UDA)) {
			static if (UDA2 == "dbIsModel") {
				return true;	
			}
		}
	}
	
	return false;
}

/**
 * Get us the type name/module name of another model's based upon the variable.
 */

pure string getRelationshipClassName(T, string f)() {
	T t = new T;
	foreach(UDA; __traits(getAttributes, mixin("t." ~ f))) {
		return typeof(UDA.type).stringof;
	}
	
	return null;
}

pure string getRelationshipClassModuleName(T, string f)() {
	T t = new T;
	foreach(UDA; __traits(getAttributes, mixin("t." ~ f))) {
		return moduleName!(typeof(UDA.type));
	}
	
	return null;
}

/**
 * Get the name of property that the relationship's classes property is.
 */

pure string getRelationshipPropertyName(T, string f)() {
	T t = new T;
	foreach(UDA; __traits(getAttributes, mixin("t." ~ f))) {
		return UDA.name;
	}
	
	return null;
}