module dvorm.removeall;
import dvorm;

string removeAll(C)() {
	string ret;
	
	ret ~= "void removeAll() {";
	
	// database dependent find part
	ret ~=  objectBuilderCreator!C();
	ret ~= "    provider(getDbType!" ~ C.stringof ~ ").removeAll!" ~ C.stringof ~ "(&objectBuilder);";
	
	ret ~= "}";
	
	return ret;
}