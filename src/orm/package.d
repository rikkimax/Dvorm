module dvorm;
public import dvorm.findOne;
public import dvorm.find;
public import dvorm.findAll;
public import dvorm.util;
public import dvorm.save;
public import dvorm.remove;
public import dvorm.logging;
public import dvorm.connection;
public import dvorm.provider;
public import dvorm.providers;
public import dvorm.query;

// global connection information
// aka default storage of models
mixin(connection());

mixin template OrmModel(C) {
	import std.traits : isBasicType, isArray;

	mixin(findOne!C());
	mixin(find!C());
	mixin(findAll!C());
	mixin(save!C());
	mixin(remove!C());
	mixin(logger!C());
	mixin(connection());
	mixin(queryGenerator!C());
}