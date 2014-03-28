module dvorm.email.config;

enum ReceiveClientType {
	Pop3
}

enum SendClientType {
	SMTP
}

enum ClientSecurity : ushort {
	None = 0,
	StartTLS = 1 >> 1,
	SSL = 1 >> 2,
	SSL_StartTLS = StartTLS | SSL
}

struct ReceiveClientConfig {
	string host;
	ushort port;
	
	string user;
	string password;
	
	ushort security;
	
	static ReceiveClientConfig securePop3(string host, string user, string password) {
		ReceiveClientConfig ret;
		
		ret.host = host;
		ret.port = 995;
		ret.user = user;
		ret.password = password;
		ret.security = ClientSecurity.SSL_StartTLS;
		
		return ret;
	}
	
	static ReceiveClientConfig insecurePop3(string host, string user, string password) {
		ReceiveClientConfig ret;
		
		ret.host = host;
		ret.port = 110;
		ret.user = user;
		ret.password = password;
		ret.security = ClientSecurity.None;
		return ret;
	}
}

struct SendClientConfig {
	string host;
	ushort port;
	
	string user;
	string password;
	
	ushort security;
	string defaultEmailTo;
	
	static SendClientConfig secureSmtp(string host, string user, string password, string defaultEmailTo="") {
		SendClientConfig ret;
		
		ret.host = host;
		ret.port = 465;
		ret.user = user;
		ret.password = password;
		ret.security = ClientSecurity.SSL_StartTLS;
		ret.defaultEmailTo = defaultEmailTo;
		
		return ret;
	}
	
	static SendClientConfig insecureSmtp(string host, string user, string password, string defaultEmailTo="") {
		SendClientConfig ret;
		
		ret.host = host;
		ret.port = 25;
		ret.user = user;
		ret.password = password;
		ret.security = ClientSecurity.None;
		ret.defaultEmailTo = defaultEmailTo;
		return ret;
	}
}

protected __gshared {
	ReceiveClientType receiveType;
	ReceiveClientConfig receiveConfig;
	
	SendClientType sendType;
	SendClientConfig sendConfig;
}

void setEmailReceiveConfig(ReceiveClientType type, ReceiveClientConfig config) {
	receiveType = type;
	receiveConfig = config;
}

void setEmailSendConfig(SendClientType type, SendClientConfig config) {
	sendType = type;
	sendConfig = config;
}