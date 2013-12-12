import std.stdio, std.conv;

abstract class Try(T) {
public:
	abstract @property bool isFailure();	
	abstract @property bool isSuccess();
	abstract @property T get();
	abstract @property Throwable error();

	Try!U flatMap(U)(Try!U function(T t) f) {
		if (this.isSuccess) {
			try {
				return f(this.get);
			}
			catch (Exception t) {
				return new Failure!U(t);
			}			
		} else { // TODO cast
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
}

class Failure(T) : Try!T {
public:
	override @property bool isFailure() { return true; }
	override @property bool isSuccess() { return false; }
	override @property T get() { throw _exception; }
	override @property Throwable error() { return _exception; }

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

	this(T val) {
		this._value = val;
	}

	override string toString() { return "Success(" ~ to!string(_value) ~ ")"; }

	private T _value;
}

Try!T attempt(T)(lazy T expression) {
	try {
		return new Success!T(expression());
	} catch (Exception e) {
		return new Failure!T(e);
	}
}

class FakeException : Exception {
	this (string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line, null);
	}
}

unittest {	
	auto ok1 = new Success!int(1);

	assert(ok1.isSuccess, "isSuccess for a Success should be true");
	assert(!ok1.isFailure, "isFailure for a Success should be false");
	assert(ok1.get == 1, "get for a Success is the stored thing");
	try {
		ok1.error;
		assert(false, "error for a Success should throw an exception");
	} catch (Exception e) {}

	assert(ok1.flatMap((x) { return new Success!int(2+x); }).get == 3,
		"flatMap on Success maps the stored value");
	assert(ok1.getOrElse(3) == 1, "getOrElse on Success gets stored thing");


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

Try!int mult(int v) { return new Success!int(v*3); }
Try!int fail(int v) { throw new FakeException("SOMETHING WRONG"); }

int fail2(int v) { throw new FakeException("SOMETHING WRONG"); }

void main() {
	//auto succ = new Failure!int(new FakeException("hoho")); 
	auto succ = attempt(1);
	//auto issuc = succ.isSuccess();
	auto succ2 = succ;
		//flatMap!int(&fail).
		//.flatMap!int(&mult);

	writeln("Hello, world: " ~ to!string(succ2.getOrElse(17)));
}