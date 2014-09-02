module dvorm;
public import dvorm.util;
public import dvorm.connection;
public import dvorm.provider;

// global connection information
// aka default storage of models
mixin(connection());

mixin template OrmModel(C) {
    import dvorm.findOne;
    import dvorm.find;
    import dvorm.findAll;
    import dvorm.util;
    import dvorm.save;
    import dvorm.remove;
    import dvorm.removeall;
    import dvorm.logging;
    import dvorm.connection;

    import dvorm.query;
    import dvorm.relationship;

    import std.traits : isBasicType, isArray;
	
    mixin(findOne!C());
    mixin(find!C());
    mixin(findAll!C());
    mixin(save!C());
    mixin(remove!C());
    mixin(removeAll!C());
    mixin(logger!C());
    mixin(connection());
    mixin(queryGenerator!C());
    mixin(relationshipGenerator!C());
}
