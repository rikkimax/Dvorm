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
	
	override void remove(string table, string[] idNames, string[] valueNames, string[] valueArray, ObjectBuilder builder, DbConnection[] connection) {
		assert(table == getTableName!EmailMessage, "Email provider only uses the email data model.");
		
		bool handler(EmailMessage message) {
			foreach(i, a; valueNames) {
				string value = valueArray[i];
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
		
		getData(builder, null, &handler);
	}
	
	override void removeAll(string table, ObjectBuilder builder, DbConnection[] connection) {
		assert(table == getTableName!EmailMessage, "Email provider only uses the email data model.");
		
		bool handler(EmailMessage message) {
			return true;
		}
		
		getData(builder, null, &handler);
	}
	
	override void save(string table, string[] idNames, string[] valueNames, string[] valueArray, ObjectBuilder builder, DbConnection[] connection) {
		assert(table == getTableName!EmailMessage, "Email provider only uses the email data model.");
		switch(sendType) {
			case SendClientType.SMTP:
				string[string] values;
				foreach(i, v; valueNames) {
					values[v] = valueArray[i];
				}
				
				EmailMessage email = *cast(EmailMessage*)builder(values);
				if (email.from.user == "" || email.from.domain == "") {
					email.from = sendConfig.defaultEmailTo;
				}
				assert(email.from.user != "" && email.from.domain != "", "Must specify who you're sending from (account)");
				
				auto settings = new SMTPClientSettings(sendConfig.host, sendConfig.port);
				
				if ((receiveConfig.security & ClientSecurity.StartTLS) == ClientSecurity.StartTLS ||
				    (receiveConfig.security & ClientSecurity.SSL) == ClientSecurity.SSL) {
					settings.connectionType = SMTPConnectionType.startTLS;
				} else {
					settings.connectionType = SMTPConnectionType.plain;
				}
				
				settings.authType = SMTPAuthType.plain;
				settings.username = sendConfig.user;
				settings.password = sendConfig.password;
				
				auto mail = new Mail;
				mail.headers["From"] = email.from.toString();
				mail.headers["To"] = email.target.toString();
				mail.headers["Content-Type"] = email.contentType;
				mail.headers["Subject"] = email.subject;
				mail.bodyText = email.message;
				
				sendMail(settings, mail);
				break;
			default:
				break;
		}
	}
	
	override string[] handleQueryOp(string op, string prop, string value, string[] store) {
		return store ~ [op ~ ":" ~ prop ~ ":" ~ value];
	}
	
	override void*[] handleQuery(string[] store, string table, string[] idNames, string[] valueNames, ObjectBuilder builder, DbConnection[] connection) {
		assert(table == getTableName!EmailMessage, "Email provider only uses the email data model.");
		
		return handleQueryHelper(store, builder);
	}
	
	override size_t handleQueryCount(string[] store, string table, string[] idNames, string[] valueNames, ObjectBuilder builder, DbConnection[] connection) {
		return *cast(size_t*)handleQueryHelper!(false, true)(store, builder)[0];
	}
	
	override void handleQueryRemove(string[] store, string table, string[] idNames, string[] valueNames, ObjectBuilder builder, DbConnection[] connection) {
		assert(table == getTableName!EmailMessage, "Email provider only uses the email data model.");
		
		handleQueryHelper!(true)(store, builder);
	}
	
	override void*[] queryJoin(string[] store, string baseTable, string endTable, string[] baseIdNames, string[] endIdNames, Provider provider, ObjectBuilder builder, DbConnection[] baseConnection, DbConnection[] endConnection) {
		assert(table == getTableName!EmailMessage, "Email provider only uses the email data model.");
		static assert(0, baseTable ~ " does not have a relationship property for " ~ endTable);
	}
}

void*[] getData(ObjectBuilder builder, bool delegate(EmailMessage message) handler = null, bool delegate(EmailMessage message) removeHandler = null) {
	switch(receiveType) {
		case ReceiveClientType.Pop3:
			TCPConnection raw_conn;
			try {
			} catch(Exception e){
				throw new Exception("Failed to connect to POP3 server at "~receiveConfig.host~" port "
				                    ~to!string(receiveConfig.port), e);
			}
			scope(exit) raw_conn.close();
			
			string got;
			Stream conn = raw_conn;
			
			if ((receiveConfig.security & ClientSecurity.StartTLS) == ClientSecurity.StartTLS ||
			    (receiveConfig.security & ClientSecurity.SSL) == ClientSecurity.SSL) {
				auto ctx = new SSLContext(SSLContextKind.client);
				conn = new SSLStream(raw_conn, ctx, SSLStreamState.connecting);
				
				got = cast(string)conn.readLine();
			}
			
			void*[] ret;
			
			conn.write("USER " ~ receiveConfig.user ~ "\r\n");
			got = cast(string)conn.readLine();
			
			conn.write("PASS " ~ receiveConfig.password ~ "\r\n");
			got = cast(string)conn.readLine();
			if (got.length > 3) {
				if (got[0 .. 3] == "+OK") {
					// continue
				} else {
					assert(0, "Could not login to pop3 server");
				}
			} else {
				assert(0, "Could not login to pop3 server");
			}
			
			conn.write("LIST \r\n");
			got = cast(string)conn.readLine();
			
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
				
				if (removeHandler !is null) {
					if (removeHandler(*tempObj)) {
						conn.write("DELE " ~ id ~ "\r\n");
						got = cast(string)conn.readLine();
					}
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

struct QOp {
	string op;
	string prop;
	string value;
}

pure string getQueryOp(string o, string name, bool isLong = false)() {
	static if (isLong) {
		return "    try {
	if ((mixin(\"to!long(op.value) " ~ o ~ " to!long(message." ~ name ~ ")\"))) stillOk = false;
	} catch (Exception e) {stillOk = false;}\n";
	} else {
		return 
			"	if (!(mixin(\"op.value " ~ o ~ " message." ~ name ~ "\"))) stillOk = false;";
	}
}

void*[] handleQueryHelper(bool remove = false, bool count = false)(string[] store, ObjectBuilder builder) {
	int num_skip = 0, num_docs_per_chunk = 0;
	QOp[] ops;
	
	foreach(s; store) {
		size_t i = s.indexOf(":");
		if (i >= 0 && i + 1 < s.length) {
			string op = s[0 .. i];
			string prop = s[i + 1.. $];
			i = prop.indexOf(":");
			if (i >= 0 && i + 1 < prop.length) {
				string value = prop[i + 1.. $];
				prop = prop[0 .. i];
				
				ops ~= QOp(op, prop, value);
			}
		}
	}
	
	foreach(op; ops) {
		if (op.prop == "") {
			switch(op.op) {
				case "startAt":
					num_skip = to!int(op.value);
					break;
				case "maxAmount":
					num_docs_per_chunk = to!int(op.value);
					break;
					
				default:
					break;
			}
		}
	}
	
	size_t i;
	
	bool handler(EmailMessage message) {
		bool stillOk = true;
		
		foreach(op; ops) {
			switch(op.prop) {
				case "from_user":
					switch(op.op) {
						case "eq":
							mixin(getQueryOp!("==", "from.user")());
							break;
						case "neq":
							mixin(getQueryOp!("!=", "from.user")());
							break;
							
						case "lt":
							mixin(getQueryOp!("<", "from.user")());
							break;
						case "lte":
							mixin(getQueryOp!("<=", "from.user")());
							break;
							
						case "mt":
							mixin(getQueryOp!(">", "from.user")());
							break;
						case "mte":
							mixin(getQueryOp!(">=", "from.user")());
							break;
							
						case "like":
							ptrdiff_t loc = message.from.user.indexOf(op.value, CaseSensitive.no);
							if (!(loc >= 0)) stillOk = false;
							break;
							
						case "startAt":
						case "maxAmount":
						default:
							stillOk = false;
							break;
					}
					break;
				case "from_domain":
					switch(op.op) {
						case "eq":
							mixin(getQueryOp!("==", "from.domain")());
							break;
						case "neq":
							mixin(getQueryOp!("!=", "from.domain")());
							break;
							
						case "lt":
							mixin(getQueryOp!("<", "from.domain")());
							break;
						case "lte":
							mixin(getQueryOp!("<=", "from.domain")());
							break;
							
						case "mt":
							mixin(getQueryOp!(">", "from.domain")());
							break;
						case "mte":
							mixin(getQueryOp!(">=", "from.domain")());
							break;
							
						case "like":
							ptrdiff_t loc = message.from.domain.indexOf(op.value, CaseSensitive.no);
							if (!(loc >= 0)) stillOk = false;
							break;
							
						case "startAt":
						case "maxAmount":
						default:
							stillOk = false;
							break;
					}
					break;
				case "from_name":
					switch(op.op) {
						case "eq":
							mixin(getQueryOp!("==", "from.name")());
							break;
						case "neq":
							mixin(getQueryOp!("!=", "from.name")());
							break;
							
						case "lt":
							mixin(getQueryOp!("<", "from.name")());
							break;
						case "lte":
							mixin(getQueryOp!("<=", "from.name")());
							break;
							
						case "mt":
							mixin(getQueryOp!(">", "from.name")());
							break;
						case "mte":
							mixin(getQueryOp!(">=", "from.name")());
							break;
							
						case "like":
							ptrdiff_t loc = message.from.name.indexOf(op.value, CaseSensitive.no);
							if (!(loc >= 0)) stillOk = false;
							break;
							
						case "startAt":
						case "maxAmount":
						default:
							stillOk = false;
							break;
					}
					break;
					
				case "target_user":
					switch(op.op) {
						case "eq":
							mixin(getQueryOp!("==", "target.user")());
							break;
						case "neq":
							mixin(getQueryOp!("!=", "target.user")());
							break;
							
						case "lt":
							mixin(getQueryOp!("<", "target.user")());
							break;
						case "lte":
							mixin(getQueryOp!("<=", "target.user")());
							break;
							
						case "mt":
							mixin(getQueryOp!(">", "target.user")());
							break;
						case "mte":
							mixin(getQueryOp!(">=", "target.user")());
							break;
							
						case "like":
							ptrdiff_t loc = message.from.user.indexOf(op.value, CaseSensitive.no);
							if (!(loc >= 0)) stillOk = false;
							break;
							
						case "startAt":
						case "maxAmount":
						default:
							stillOk = false;
							break;
					}
					break;
				case "target_domain":
					switch(op.op) {
						case "eq":
							mixin(getQueryOp!("==", "target.domain")());
							break;
						case "neq":
							mixin(getQueryOp!("!=", "target.domain")());
							break;
							
						case "lt":
							mixin(getQueryOp!("<", "target.domain")());
							break;
						case "lte":
							mixin(getQueryOp!("<=", "target.domain")());
							break;
							
						case "mt":
							mixin(getQueryOp!(">", "target.domain")());
							break;
						case "mte":
							mixin(getQueryOp!(">=", "target.domain")());
							break;
							
						case "like":
							ptrdiff_t loc = message.from.domain.indexOf(op.value, CaseSensitive.no);
							if (!(loc >= 0)) stillOk = false;
							break;
							
						case "startAt":
						case "maxAmount":
						default:
							stillOk = false;
							break;
					}
					break;
				case "target_name":
					switch(op.op) {
						case "eq":
							mixin(getQueryOp!("==", "target.name")());
							break;
						case "neq":
							mixin(getQueryOp!("!=", "target.name")());
							break;
							
						case "lt":
							mixin(getQueryOp!("<", "target.name")());
							break;
						case "lte":
							mixin(getQueryOp!("<=", "target.name")());
							break;
							
						case "mt":
							mixin(getQueryOp!(">", "target.name")());
							break;
						case "mte":
							mixin(getQueryOp!(">=", "target.name")());
							break;
							
						case "like":
							ptrdiff_t loc = message.from.name.indexOf(op.value, CaseSensitive.no);
							if (!(loc >= 0)) stillOk = false;
							break;
							
						case "startAt":
						case "maxAmount":
						default:
							stillOk = false;
							break;
					}
					break;
					
				case "transversed":
					switch(op.op) {
						case "eq":
							mixin(getQueryOp!("==", "transversed", true)());
							break;
						case "neq":
							mixin(getQueryOp!("!=", "transversed", true)());
							break;
							
						case "lt":
							mixin(getQueryOp!("<", "transversed", true)());
							break;
						case "lte":
							mixin(getQueryOp!("<=", "transversed", true)());
							break;
							
						case "mt":
							mixin(getQueryOp!(">", "transversed", true)());
							break;
						case "mte":
							mixin(getQueryOp!(">=", "transversed", true)());
							break;
							
						case "like":
							if (!(to!long(op.value) != message.transversed)) stillOk = false;
							break;
							
						case "startAt":
						case "maxAmount":
						default:
							stillOk = false;
							break;
					}
					break;
					
				default:
					break;
			}
		}
		
		if (stillOk) {
			i++;
			if ((i > num_skip || num_skip == 0) && (i < num_skip + num_docs_per_chunk || num_docs_per_chunk == 0))
				return true;
		}
		
		return false;
	}
	
	static if (remove) {
		getData(builder, null, &handler);
		return null;
	} else static if (count) {
		getData(builder, &handler);
		return [[i].ptr];
	} else {
		return getData(builder, &handler);
	}
}