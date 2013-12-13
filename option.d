import std.stdio, std.conv;

abstract class Option(T) {
public:
	abstract @property bool isDefined();
	abstract @property T get();

	//abstract int opApply(int delegate(ref T) dg);

	Option!U flatMap(U)(Option!U function(T t) f) {
		if (this.isDefined) {
			return f(this.get);
		} else { 
			return none!U();
		}
	}	
}

class Some(T) : Option!T {
public:
	override @property bool isDefined() { return true; }
	override @property T get() { return _value; }

	this(T value) {
		_value = value;
	}

	private T _value;
}

auto some(T)(T value) {
	return new Some!T(value);
}

class None(T) : Option!T {
public:
	override @property bool isDefined() { return false; }
	override @property T get() { throw new Exception("OH NOES"); }

	this() { }
}

auto none(T)() {
	return new None!T();
}

unittest {
	writeln("Test basic monad operations");

	auto mult_fun = (int x) { return some(x*2); };
	auto never_fun = (int x) { assert(false, "flatMap on None never calls the mapping function"); return none!int; };

	Option!int option = some(17);
	assert(option.isDefined == true, "an Option with a value is defined");
	assert(option.get == 17, "an Option returns its value with get");

	assert(option.flatMap(mult_fun).get == 34, "flatMap applies the function on a defined Option");

	option = none!int;
	assert(option.isDefined == false, "an Option without a value is not defined");
	// TODO assert(option.get == 17, "an Option returns its value with get");
	
	assert(option.flatMap(never_fun).isDefined == false, "flatMap on None returns None");
	
	assert(none!(int).flatMap((int x) { return some("string"); }).isDefined == false,
		"type changes are propagated on flatMap on None");
	
}

