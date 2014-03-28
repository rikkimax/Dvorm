module dvorm.email.providers;
import dvorm.provider;
import dvorm.connection;
public import dvorm.email.providers.email;

shared static this() {
	registerProvider(DbType.Email, new EmailProvider);
}