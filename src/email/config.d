module dvorm.email.config;

enum ReceiveClientType {
	Pop3
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

protected __gshared {
	ReceiveClientType receiveType;
	ReceiveClientConfig receiveConfig;
}

void setReceive(ReceiveClientType type, ReceiveClientConfig config) {
	receiveType = type;
	receiveConfig = config;
}