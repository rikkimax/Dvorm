module dvorm.email.providers.email;
import dvorm.email.message;
import dvorm.email.config;
import dvorm;
import vibe.d;
import std.conv : to;
import std.string : split, toLower, join;
import std.datetime :  DateTime, dur, SysTime;

class EmailProvider : Provider {
	override void*[] find(string table, string[] argNames, string[] args, ObjectBuilder builder, DbConnection[] connection){
		assert(table == getTableName!EmailMessage, "Email provider only uses the email data model.");
		
		bool handler(EmailMessage message) {
			foreach(i, a; argNames) {
				string value = args[i];
				if (value == "") continue;
				
				switch(a) {
					case "from_user":
						if (message.from.user != value) return false;
						break;
					case "from_domain":
						if (message.from.domain != value) return false;
						break;
					case "from_name":
						if (message.from.name != value) return false;
						break;
						
					case "target_user":
						if (message.target.user != value) return false;
						break;
					case "target_domain":
						if (message.target.domain != value) return false;
						break;
					case "target_name":
						if (message.target.name != value) return false;
						break;
						
					case "transversed":
						if (value == "0") continue;
						
						if (message.transversed != to!ulong(value)) return false;
						break;
						
					default:
						break;
				}
			}
			
			return true;
		}
		
		return getData(builder, &handler);
	}
	
	override void*[] findAll(string table, ObjectBuilder builder, DbConnection[] connection) {
		assert(table == getTableName!EmailMessage, "Email provider only uses the email data model.");
		
		return getData(builder);
	}
	
	override void* findOne(string table, string[] argNames, string[] args, ObjectBuilder builder, DbConnection[] connection){
		assert(table == getTableName!EmailMessage, "Email provider only uses the email data model.");
		
		void*[] data = getData(builder);
		if (data.length >= 1) {
			return data[0];
		} else {
			return null;
		}
	}
	
	
	override void remove(string table, string[] idNames, string[] valueNames, string[] valueArray, DbConnection[] connection){}
	override void removeAll(string table, DbConnection[] connection){}
	override void save(string table, string[] idNames, string[] valueNames, string[] valueArray, ObjectBuilder builder, DbConnection[] connection){}
	
	override string[] handleQueryOp(string op, string prop, string value, string[] store){return null;}
	override void*[] handleQuery(string[] store, string table, string[] idNames, string[] valueNames, ObjectBuilder builder, DbConnection[] connection){return null;}
	override size_t handleQueryCount(string[] store, string table, string[] idNames, string[] valueNames, DbConnection[] connection){return 0;}
	override void handleQueryRemove(string[] store, string table, string[] idNames, string[] valueNames, DbConnection[] connection){}
}

void*[] getData(ObjectBuilder builder, bool delegate(EmailMessage message) handler = null) {
	switch(receiveType) {
		case ReceiveClientType.Pop3:
			TCPConnection raw_conn;
			try {
				raw_conn = connectTCP(receiveConfig.host, receiveConfig.port);
			} catch(Exception e){
				throw new Exception("Failed to connect to POP3 server at "~receiveConfig.host~" port "
				                    ~to!string(receiveConfig.port), e);
			}
			scope(exit) raw_conn.close();
			
			string got;
			Stream conn = raw_conn;
			
			debug {
				import std.file;
			}
			
			if ((receiveConfig.security & ClientSecurity.StartTLS) == ClientSecurity.StartTLS ||
			    (receiveConfig.security & ClientSecurity.SSL) == ClientSecurity.SSL) {
				auto ctx = new SSLContext(SSLContextKind.client);
				conn = new SSLStream(raw_conn, ctx, SSLStreamState.connecting);
				
				got = cast(string)conn.readLine();
				debug {
					append("out.txt", "ssl: " ~ got ~ "\n");
				}
			}
			
			void*[] ret;
			
			conn.write("USER " ~ receiveConfig.user ~ "\r\n");
			
			got = cast(string)conn.readLine();
			debug {
				append("out.txt", "user: " ~ got ~ "\n");
			}
			
			conn.write("PASS " ~ receiveConfig.password ~ "\r\n");
			
			got = cast(string)conn.readLine();
			debug {
				append("out.txt", "pass: " ~ got ~ "\n");
			}
			
			conn.write("LIST \r\n");
			
			got = cast(string)conn.readLine();
			debug {
				append("out.txt", "list: " ~ got ~ "\n");
			}
			
			string[] ids;
			while((got = cast(string)conn.readLine()) != ".") {
				string[] splitted = got.split(" ");
				if (splitted.length == 2) {
					ids ~= splitted[0];
				}
			}
			
			foreach(id; ids) {					
				string from;
				string target;
				string date;
				string contentType;
				string subject;
				string message;
				
				string boundry;
				bool hitEndOfHeaders = false;
				bool useBoundry = false;
				bool hitBoundry = false;
				
				string[] splitted;
				
				conn.write("RETR " ~ id ~ "\r\n");
				while((got = cast(string)conn.readLine()) != ".") {
					
					if (got.length > "\r\n.".length) {
						if (got[0 .. "\r\n.".length] == "\r\n.") {
							got = got["\r\n.".length - 1 .. $];
						}
					}
					
					append("out.txt", "retr " ~ id ~ ": " ~ got ~ "\n");
					
					splitted = got.split(" ");
					if (splitted.length >= 2) {
						switch(splitted[0].toLower()) {
							case "from:":
								from = got["from: ".length .. $];
								break;
							case "to:":
								target = splitted[1];
								break;
							case "subject:":
								subject = got["subject: ".length .. $];
								break;
							case "date:":
								date = got["date: ".length .. $];
								break;
							case "content-type:":
								contentType = splitted[1];
								break;
							default:
								break;
						}
					}
					
					if (contentType.length > "multipart/mixed; boundary=".length) {
						if (contentType[0 .. "multipart/mixed; boundary=".length] == "multipart/mixed; boundary=\"") {
							boundry = contentType["multipart/mixed; boundary=".length + 1 .. $-1];
						} else if (contentType[0 .. "multipart/mixed; boundary=".length] == "multipart/mixed; boundary=") {
							boundry = contentType["multipart/mixed; boundary=".length .. $];
						}
					}
					
					if (hitBoundry) {
						message ~= got ~ "\n";
					}
					
					if (hitEndOfHeaders) {
						if (useBoundry) {
							if (!hitBoundry && got == "--" ~ boundry) {
								hitBoundry = true;
							} else if (hitBoundry && got == "--" ~ boundry ~ "--") {
								hitBoundry = false;
							}
						} else {
							hitBoundry = true;
						}
						
						if (boundry != "") {
							useBoundry = true;
						}
					}
					
					if (got == "")
						hitEndOfHeaders = true;
				}
				
				string[string] build = ["target" : target, "contentType": contentType, "subject": subject, "message": message];
				splitted = from.split(" ");
				if (splitted.length == 1) {
					string[] splitted2 = from.split("@");
					if (splitted2.length == 2) {
						build["from_user"] = splitted2[0];
						build["from_domain"] = splitted2[1];
					}
				} else if (splitted[$-1][0] == '<' && splitted[$-1][$-1] == '>') {
					string text = splitted[$-1][1 .. $-1];
					string[] splitted2 = splitted[$-1].split("@");
					build["from_user"] = splitted2[0][1 .. $];
					build["from_domain"] = splitted2[1][0 .. $-1];
					build["from_name"] = splitted[0 .. $-1].join(" ");
				}
				
				build["transversed"] = to!string(smtpUTC0Time(date));
				
				EmailMessage* tempObj = cast(EmailMessage*)builder(build);
				
				if (handler !is null) {
					if (handler(*tempObj))
						ret ~= tempObj;
				} else
					ret ~= tempObj;
				
				debug {
					append("out.txt", "parsed " ~ id ~ ": " ~ from ~ "\n");
					append("out.txt", "parsed " ~ id ~ ": " ~ target ~ "\n");
					append("out.txt", "parsed " ~ id ~ ": " ~ date ~ "\n");
					append("out.txt", "parsed " ~ id ~ ": " ~ contentType ~ "\n");
					append("out.txt", "parsed " ~ id ~ ": " ~ subject ~ "\n");
					append("out.txt", "parsed " ~ id ~ ": " ~ message ~ "\n");
				}
			}
			
			return ret;
		default:
			return null;
	}
}

ulong smtpUTC0Time(string text) {
	string[] values = text.split(" ");
	
	if (values.length >= 6) {
		int day = to!int(values[1]);
		int month;
		int year = to!int(values[3]);
		int hour;
		int minute;
		int second;
		int hourOffset = to!int(values[5][0 .. 3]);
		int minuteOffset = to!int(values[5][0] ~ values[5][3 .. $]);
		
		string t;
		string[] t2;
		
		t = values[2].toLower();
		foreach(m; __traits(allMembers, Month)) {
			if (t == m) {
				month = cast(int)mixin("Month." ~ m);	
			}
		}
		
		t2 = values[4].split(":");
		if (t2.length == 3) {
			hour = to!int(t2[0]);
			minute = to!int(t2[1]);
			second = to!int(t2[2]);
		}
		
		DateTime dt = DateTime(year, month, day, hour, minute, second);
		dt -= dur!"hours"(hourOffset);
		dt -= dur!"minutes"(minuteOffset);
		
		return new SysTime(dt).toUnixTime();
	}
	
	return 0;
}