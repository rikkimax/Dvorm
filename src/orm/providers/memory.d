module dvorm.providers.memory;
import dvorm.provider;
import dvorm.unittests;
import std.string;
import std.conv;

private {
	shared TableData[string] tableData;

	struct TableData {
		string[string][] value;
	}
}

class MemoryProvider : Provider {
	override Object[] find(string table, string[] argNames, string[] args, ObjectBuilder builder, DbConnection[] connection) {
		if (tableData.get(table, TableData.init) is cast(shared)TableData.init)
			tableData[table] = TableData.init;
		
		size_t[] value = indexsOfIds(table, argNames, argNames, args);

		Object[] ret;
		foreach(v; value) {
			ret ~= builder(cast(string[string])tableData[table].value[v]);
		}
		return ret;
	}

	override Object[] findAll(string table, ObjectBuilder builder, DbConnection[] connection) {
		TableData datums = cast(TableData)tableData.get(table, cast(shared)TableData.init);
		if (datums.value == null) {
			return null;
		} else {
			Object[] ret;
			foreach(d; datums.value) {
				ret ~= builder(cast(string[string])d);
			}
			return ret;
		}
	}

	override Object findOne(string table, string[] argNames, string[] args, ObjectBuilder builder, DbConnection[] connection) {
		if (tableData.get(table, TableData.init) is cast(shared)TableData.init)
			tableData[table] = TableData.init;

		size_t value = indexOfIds(table, argNames, argNames, args);
		if (value >= 0 && value < tableData[table].value.length)
			return builder(cast(string[string])tableData[table].value[value]);
		return null;
	}

	override void remove(string table, string[] idNames, string[] valueNames, string[] valueArray, DbConnection[] connection) {
		if (tableData.get(table, TableData.init) is cast(shared)TableData.init)
			tableData[table] = TableData.init;

		size_t value = indexOfIds(table, idNames, valueNames, valueArray);
		if (tableData[table].value.length > value) {
			if (value > 0 && value < tableData[table].value.length)
				tableData[table].value = tableData[table].value[0 .. value] ~ tableData[table].value[value .. $];
			else if (value > 0)
				tableData[table].value = tableData[table].value[0 .. value];
			else if (tableData[table].value.length > 1)
				tableData[table].value = tableData[table].value[1 .. $];
			else
				tableData.remove(table);
		}
	}

	override void save(string table, string[] idNames, string[] valueNames, string[] valueArray, ObjectBuilder builder, DbConnection[] connection) {
		if (tableData.get(table, TableData.init) is cast(shared)TableData.init)
			tableData[table] = TableData.init;

		size_t value = indexOfIds(table, idNames, valueNames, valueArray);
		string[string] values;

		size_t vi;
		foreach(vn; valueNames) {
			values[vn] = valueArray[vi];
			vi++;
		}

		if (tableData[table].value.length < value)
			tableData[table].value[value] = cast(shared)values;
		else
			tableData[table].value ~= cast(shared)values;
	}

	override string[] handleQueryOp(string op, string prop, string value, string[] store) {
		return store ~ [op ~ ":" ~ prop ~ ":" ~ value];
	}

	override Object[] handleQuery(string[] store, string table, string[] idNames, string[] valueNames, ObjectBuilder builder, DbConnection[] connection) {
		TableData datums = cast(TableData)tableData.get(table, cast(shared)TableData.init);
		if (datums.value == null) {
			return null;
		} else {
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

			int num_skip = 0, num_docs_per_chunk = 0;
			size_t i;

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

			Object[] ret;
			foreach(d; datums.value) {
				bool stillOk = true;

				foreach(k, v; d) {
					bool isFloat = false;
					bool isLong = false;

					float f;
					long l;

					try {
						f = to!float(v);
						isFloat = true;
					} catch (Exception e) {}
					try {
						l = to!long(v);
						isLong = true;
					} catch (Exception e) {}

					foreach(op; ops) {
						if (op.prop == k) {
							switch(op.op) {

								case "eq":
									mixin(getQueryOp!("==")());
									break;
								case "neq":
									mixin(getQueryOp!("!=")());
									break;

								case "lt":
									mixin(getQueryOp!("<")());
									break;
								case "lte":
									mixin(getQueryOp!("<=")());
									break;

								case "mt":
									mixin(getQueryOp!(">")());
									break;
								case "mte":
									mixin(getQueryOp!(">=")());
									break;

								case "like":
									if (isFloat) {
										try {
											if (!(to!float(op.value) <> f)) stillOk = false;
									    } catch (Exception e) {stillOk = false;}
									} else if (isLong) {
									    try {
										if (!(to!long(op.value) <> l)) stillOk = false;
										} catch (Exception e) {stillOk = false;}
									} else {
										ptrdiff_t loc = v.indexOf(op.value, CaseSensitive.no);
										if (!(loc >= 0)) stillOk = false;
									}
									break;

								case "startAt":
									num_skip = to!int(v);
									break;
								case "maxAmount":
									num_docs_per_chunk = to!int(v);
									break;

								default:
									stillOk = false;
									break;
							}
						}
					}
				}

				if (stillOk) {
					if ((i > num_skip || num_skip == 0) && (i < num_skip + num_docs_per_chunk || num_docs_per_chunk == 0))
						ret ~= builder(cast(string[string])d);
					i++;
				}
			}
			return ret;
		}
	}
}

private {
	size_t indexOfIds(string table, string[] ids, string[] valueNames, string[] valueArray) {
		TableData td = cast(TableData)tableData.get(table, cast(shared)TableData.init);
		size_t i;
		foreach(tda; td.value) {
			bool matches = true;
			foreach(v; valueNames) {
				bool hasId = false;
				foreach(id; ids) {
					if (id == v)
						hasId = true;
				}
				if (hasId) {
					if (valueArray[i] != tda[v]) {
						matches = false;
					}
				}
			}
			if (matches) {
				return i;
			}
			i++;
		}
		return tableData.get(table, TableData.init).value.length;
	}

	size_t[] indexsOfIds(string table, string[] ids, string[] valueNames, string[] valueArray) {
		TableData td = cast(TableData)tableData.get(table, cast(shared)TableData.init);
		size_t[] ret;
		size_t i;
		foreach(tda; td.value) {
			bool matches = true;
			size_t j;
			foreach(v; valueNames) {
				bool hasId = false;
				foreach(id; ids) {
					if (id == v)
						hasId = true;
				}
				if (hasId) {
					if (valueArray[j] != tda[v]) {
						matches = false;
					}
				}
				j++;
			}
			if (matches) {
				ret ~= i;
			}
			i++;
		}
		return ret;
	}

	struct QOp {
		string op;
		string prop;
		string value;
	}

	pure string getQueryOp(string o)() {
		return 
"""
if (isFloat) {
    try {
    if (!(mixin(\"to!float(op.value) " ~ o ~ " f\"))) stillOk = false;
    } catch (Exception e) {stillOk = false;}
} else if (isLong) {
    try {
	if (!(mixin(\"to!long(op.value) " ~ o ~ " l\"))) stillOk = false;
	} catch (Exception e) {stillOk = false;}
} else {
	if (!(mixin(\"op.value " ~ o ~ " v\"))) stillOk = false;
}
""";
	}
}

unittest {
	unittest1(DbConnection(DbType.Memory));
}