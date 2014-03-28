module dvorm.email.message;
import dvorm;
import std.regex;
import std.string : split;

class EmailMessage {
	@dbId {
		EmailAddress from;
		EmailAddress target;
		
		@dbDefaultValue("0")
		ulong transversed;
	}
	
	string contentType;
	string subject;
	string message;
	
	mixin OrmModel!EmailMessage;
}

shared static this() {
	EmailMessage.databaseConnection = DbConnection(DbType.Email);
}

struct EmailAddress {
	@dbId @dbDefaultValue("\"\"") {
		string user;
		string domain;
		string name;
	}
	
	void opAssign(string text) {
		string[] val = text.split("@");
		assert(val.length == 2, "Too many or too few @'s in email address");
		user = val[0];
		domain = val[1];
	}
	
	bool isValid() {
		// do validation checking
		auto exp = regex("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?");
		return !match(user ~ "@" ~ domain, exp).empty;
	}
	
	string toString() {
		if (name != "")
			return "<" ~ name ~ "> " ~ user ~ "@" ~ domain;
		else
			return user ~ "@" ~ domain;
	}
}