import std.stdio, std.conv;

abstract class Try(T) {
public:
	abstract @property bool isFailure();	
	abstract @property bool isSuccess();
	abstract @property T get();
	abstract @property Throwable error();

	// foreach compability
	abstract int opApply(int delegate(ref T) dg);	

	Try!U flatMap(U)(Try!U function(T t) f) {
		if (this.isSuccess) {
			try {
				return f(this.get);
			}
			catch (Exception t) {
				return new Failure!U(t);
			}			
		} else { 
			return new Failure!U(this.error);
		}
	}

	auto getOrElse(U)(lazy U def) {
		if (this.isSuccess) {
			return this.get;
		} else {
			return def();
		}
	}

	Try!U map(U)(U function(T t) f) {
		if (isSuccess) {
			try {
				return new Success!U(f(get));
			} catch (Exception e) {
				return new Failure!U(e);
			}					
		} else {
			return new Failure!U(error);
		}
	}
}

class Failure(T) : Try!T {
public:
	override @property bool isFailure() { return true; }
	override @property bool isSuccess() { return false; }
	override @property T get() { throw _exception; }
	override @property Throwable error() { return _exception; }

	override int opApply(int delegate(ref T) dg) {
		return 0;
	}

	this(Throwable exception) {
		this._exception = exception;
	}

	override string toString() { return "Failure(" ~ _exception.classinfo.name ~ "(" ~ _exception.msg ~ "))"; }

	private Throwable _exception;
}

class Success(T) : Try!(T) {	
public:
	override @property bool isFailure() { return false; }
	override @property bool isSuccess() { return true; }
	override @property T get() { return _value; }
	override @property Throwable error() { throw new Exception("Not a Failure"); }

	override int opApply(int delegate(ref T) dg) {
		return dg(_value);
	}

	this(T val) {
		this._value = val;
	}

	override string toString() { return "Success(" ~ to!string(_value) ~ ")"; }

	private T _value;
}

Try!T attempt(T)(T function() expression) {
	try {
		return new Success!T(expression());
	} catch (Exception e) {
		return new Failure!T(e);
	}
}

Try!T success(T)(T val) {
	return new Success!T(val);
}

Try!T failure(T = Throwable)(Throwable t) {
	return new Failure!T(t);
}

unittest { 
	writeln("Test basic and monadic Try operations");
	auto ok = new Success!int(1);

	assert(ok.isSuccess, "isSuccess for a Success should be true");
	assert(!ok.isFailure, "isFailure for a Success should be false");
	assert(ok.get == 1, "get for a Success is the stored thing");
	try {
		ok.error;
		assert(false, "error for a Success should throw an exception");
	} catch (Exception e) {}

	assert(ok.flatMap((x) { return new Success!int(2+x); }).get == 3,
		"flatMap on Success maps the stored value");
	assert(ok.getOrElse(3) == 1, "getOrElse on Success gets stored thing");


	auto fail = new Failure!int(new Exception("FAIL"));

	assert(!fail.isSuccess, "isSuccess for a Failure should be false");
	assert(fail.isFailure, "isFailure for a Failure should be true");
	try {
		fail.get;
		assert(false, "get for a Failure should throw an exception");
	} catch (Exception e) {
		assert(e.msg == "FAIL", "get for a Failure should throw the stored exception");
	}
	assert(fail.error.msg == "FAIL", "error for a Failure should return the stored exception");

	assert(
		fail.flatMap(
			function Try!int(int x) { assert(false, "flatMap on a Failure should not call the mapping function"); throw new Exception("WRONG_FAIL"); }
			).error.msg == "FAIL",
		"flatMap on a Failure should propagate original error"
		);
	assert(fail.getOrElse(3.2) == 3.2, "getOrElse on Failure gets else argument");
}

unittest {
	writeln("Test attempt() creation of Try");

	auto ok = attempt({ return 17; });

	assert(ok.isSuccess == true, "attempt() that doesn't throw is a Success");
	assert(ok.get == 17);

	auto fail = attempt({ throw new Exception("FAIL"); return 17; });

	assert(fail.isSuccess == false, "attempt() that throws is a Failure");
	assert(fail.error.msg == "FAIL");
}

unittest {
	writeln("Test success() and failure() creation of Try");

	auto ok = success(17);

	assert(ok.isSuccess == true, "success() gives a Success");
	assert(ok.get == 17);

	auto fail = failure(new Exception("FAIL"));

	assert(fail.isSuccess == false, "failure() gives a Failure");
	assert(fail.error.msg == "FAIL");
}

unittest {
	writeln("Test foreach compability");

	auto ok = success(42);

	auto timesRan = 0;
	foreach(t; ok) {
		assert(t == 42, "foreach iterates on the value in a Success");
		timesRan += 1;
	}
	assert(timesRan == 1, "foreach iterates exactly once on a Success");

	auto fail = failure(new Exception("FAIL"));

	foreach(t; fail) {
		assert(false, "foreach should not iterate at all on a Failure");
	}
}

unittest {
	writeln("Test type retained in flatMap on Failure");

	Try!int successOfInt = success(17);

	Try!int failureOfInt = successOfInt.flatMap(function Try!int(int x) { throw new Exception("FAIL"); });

	Try!string failureOfString = failureOfInt.flatMap((x) { return success("seventeen"); });

	string defaulted = failureOfString.getOrElse("sixteen");

	assert(defaulted == "sixteen");
}

unittest {
	writeln("Test map operation");

	auto double_fun = (int v) { return v * 2; };
	auto error_fun = (int v) { throw new Exception("FAIL"); return 0; };
	auto never_fun = (int v) { assert(false, "map on Failure should not call mapping function"); return v; };

	auto ok = success(17);

	assert(ok.map(double_fun).get == 34, "map on Success should apply mapping function to value and wrap result in Success if function succeeds");
	assert(ok.map(error_fun).error.msg == "FAIL", "map on Success should apply mapping function to value and wrap result in Failure of function throws");

	auto fail = failure!int(new Exception("SUPERFAIL"));

	assert(fail.map(never_fun).error.msg == "SUPERFAIL", "map on Failure should retain original failure");	

}

