module dvorm.findAll;
import dvorm;
import std.conv : to;

string findAll(C)() {
	string ret;
	ret ~= "static C[] findAll(";
	
	ret ~= ") {C[] ret;";
	
	// database dependent findAll part
	ret ~=  objectBuilderCreator!C();
	ret ~= "ret = cast(" ~ C.stringof ~ "[])provider(getDbType!" ~ C.stringof ~ ").findAll!" ~ C.stringof ~ "(&objectBuilder);";
	
	ret ~= "return ret;}";
	return ret;
}