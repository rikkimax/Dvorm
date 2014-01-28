Dvorm
========
An orm for D with Vibe support.

**Database providers supported:**

Default:

- Memory

With Vibe:
- Mongo

Usage
--------
Data types in terms of classes and structs should be interchable. The struct side of things has not really been tested yet however.

Utilising UDA's meta information can be applied to models in the form of classes and properties.
Methods are ignored all together.
Default values can be given for a property to allow find* methods not require all values.

```D
	@dbName("Books")
	class Book {
		@dbId
		@dbName("_id")
		string isbn;
		
		@dbDefaultValue("0")
		ubyte edition;
		
		void t() {}

		@dbIgnore
		string something;
		
		mixin OrmModel!Book;
	}
```

You can utilise objects as properties. But note that you cannot have an object have an object as an id as well it being an id. However a work around is making for each class an id class.
Name mangling will occur in the form prop_(prop.prop'sprop). In other words page_chapter.

For properties that are objects have a default value. Currently it does not build one if required.

To be able to operate any operation upon a model you require a database to operate with. To do so you utilise the database providers. You can set a database connection information at a global level or upon a model.

**Global**
```D
import dvorm.connection; // or import dvorm;
...
databaseConnection(DbConnection(DbType.Memory));
```
**On a model**
```D
M.databaseConnection(DbConnection(DbType.Memory));
```

If a database provider only needs one e.g. login it will only take it from the first DbConnection in the array.
In the above examples an array was not used however it can be.
For e.g. MongoDb multiple DbConnection's can be used for sharding.

**Upon a model these methods are available and should be light weight:**
- static M findOne(...)
- static M[] find(...)
- static M[] findAll()
- save()
- remove()
- static databaseConnection(DbConnection[])
- static DbConnection[] databaseConnection()
- static Query query()

**A Query supports operations based upon a type.**
- Query prop_eq(typeof(prop) v)

  Equal comparison.
- Query prop_neq(typeof(prop) v)

  Not equal comparison.
- Query prop_lt(typeof(prop) v)

  Less then comparison.
- Query prop_lte(typeof(prop) v)

  Less then or equal to comparrison.
- Query prop_mt(typeof(prop) v)

  More than comparison.
- Query prop_mte(typeof(prop) v)

  More than or equal to comparison.
- Query prop_like(typeof(prop) v)

  Is like comparison. Essentially .\*v.\* in regex.
- M[] find()

  Gets all models given the query.
  
- size_t count()

  The amount of models that would be returned if executed.
- void remove()
  Removes any models matching the criteria in query.

