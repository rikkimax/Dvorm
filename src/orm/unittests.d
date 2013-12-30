module dvorm.unittests;
import dvorm;

version(unittest) {
	void unittest1(DbConnection[] cons...) {
		Book = cons;

		Book book = new Book;
		book.isbn = "978-0-300-14424-6";
		book.save();
		
		Book book2 = new Book;
		book2.isbn = "978-0-300-14424-7";
		book2.save();
		
		assert(Book.find(book.isbn).length == 1);
		assert(Book.find(book.isbn)[0].isbn == book.isbn);
		
		assert(Book.findOne(book.isbn) !is null);
		assert(Book.findOne(book.isbn).isbn == book.isbn);

		assert(Book.findAll().length == 2);
		
		bool hasFirst = false;
		bool hasSecond = false;
		foreach(b; Book.findAll()) {
			if (b.isbn == book.isbn) hasFirst = true;
			if (b.isbn == book2.isbn) hasSecond = true;
		}
		assert(hasFirst && hasSecond);
		
		assert(Book.query().isbn_eq(book.isbn).maxAmount(1).find().length == 1);
		assert(Book.query().isbn_eq(book.isbn).maxAmount(1).find()[0].isbn == book.isbn);
		
		assert(Book.query().isbn_neq(book.isbn).startAt(1).maxAmount(1).find().length == 0);
		assert(Book.query().isbn_neq(book.isbn).maxAmount(1).find()[0].isbn == book2.isbn);

		assert(Book.query().isbn_like(book.isbn[$-7 .. $]).find().length == 1);
		assert(Book.query().isbn_like(book.isbn[$-7 .. $]).find()[0].isbn == book.isbn);

		book.remove();
		assert(Book.findAll().length == 1);
		book2.remove();
		assert(Book.findAll().length == 0);
	}

	@tableName("Books")
	class Book {
		@id
		@name("_id")
		string isbn;
		
		@defaultValue("0")
		ubyte edition;
		
		void t() {}
		
		mixin OrmModel!Book;
	}
}