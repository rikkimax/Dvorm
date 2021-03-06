module dvorm.relationship;
import dvorm;

string relationshipGenerator(C)() {
	string ret;
	C c = newValueOfType!C;
	
	foreach(m; __traits(allMembers, C)) {
		static if (isUsable!(C, m)() && !shouldBeIgnored!(C, m)()) {
			static if (isActualRelationship!(C, m)()) {
				static assert(m.length >= 2, "Property name must be more then 1 charactor long");
				ret ~= "import " ~ getRelationshipClassModuleName!(C, m)() ~ ";\n";
				
				// getter
				
				ret ~= getRelationshipClassName!(C, m)() ~ " " ~ getterName!(m)() ~ "() {\n";
				ret ~= "    return " ~ getRelationshipClassName!(C, m)() ~ ".findOne(";
				
				static if (isAnObjectType!(typeof(mixin("c." ~ m)))) {
					typeof(mixin("c." ~ m)) d = newValueOfType!(typeof(mixin("c." ~ m)));
					foreach(n; __traits(allMembers, typeof(d))) {
						static if (isUsable!(typeof(d), n)() && !shouldBeIgnored!(typeof(d), n)()) {
							static assert(!isAnObjectType!(typeof(mixin("d." ~ n))), "Recursive id objects not allowed.");
							ret ~= m ~ "." ~ n ~ ",";
						}
					}
				} else {
					ret ~= m ~ ",";
				}
				
				ret = ret[0 .. $-1];
				
				ret ~= ");\n";
				ret ~= "}\n";
				
				
				// setter
				
				ret ~= "void " ~ setterName!(m)() ~ "(" ~ getRelationshipClassName!(C, m)() ~ " value) {\n";
				ret ~= "    this." ~ m ~ " = ";
				
				static if (isAnObjectType!(typeof(mixin("c." ~ m)))) {					
					ret ~= "newValueOfType!(" ~ typeof(mixin("c." ~ m)).stringof ~ ");\n";
					foreach(n; __traits(allMembers, typeof(d))) {
						static if (isUsable!(typeof(d), n)() && !shouldBeIgnored!(typeof(d), n)()) {
							static assert(!is(typeof(mixin("d." ~ n)) : Object), "Recursive id objects not allowed.");
							ret ~= "    this." ~ m ~ "." ~ n ~ " = " ~ "value." ~ getRelationshipPropertyName!(C, m)() ~ "." ~ n ~ ";\n";
						}
					}
				} else {
					ret ~= "value." ~ getRelationshipPropertyName!(C, m)() ~ ";\n";
				}
				
				ret ~= "}\n";
			}
		}
	}
	
	return ret;
}