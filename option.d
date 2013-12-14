module option;

import std.stdio, std.conv;

abstract class Option(T) {
public:
	abstract @property pure bool isDefined();
	abstract @property pure T get();

	abstract int opApply(int delegate(ref T) dg);

	abstract Option!T filter(bool delegate(ref T) p);

	Option!U flatMap(U)(Option!U function(ref T) f) {
		if (isDefined) {
			return (cast(Some!T)this).flatMap(f);
		} else { 
			return none!U;
		}
	}	

	auto getOrElse(U)(lazy U def) {
		if (isDefined) {
			return get;
		} else {
			return def();
		}
	}	

	Option!U map(U)(U function(ref T) f) {
		if (isDefined) {
			return (cast(Some!T)this).map(f);
		} else {
			return none!U;
		}
	}
}

class Some(T) : Option!T {
public:
	override @property pure bool isDefined() { return true; }
	override @property pure T get() { return _value; }

	override int opApply(int delegate(ref T) dg) {
		return dg(_value);
	}

	override Option!T filter(bool delegate(ref T) p) {
		if (p(_value)) return this;
		else return none!T;
	}

	override string toString() { return "Some(" ~ to!string(_value) ~ ")"; }

	override bool opEquals(Object rhs) {
		auto that = cast(Some!T)rhs;

		if (that) return that._value == this._value;
		else return false;
	}

	this(T value) {
		_value = value;
	}

	private T _value;

	protected auto map(U)(U function(ref T) f) {
		return some(f(_value));
	}

	protected auto flatMap(U)(U function(ref T) f) {
		return f(_value);
	}
}

auto some(T)(T value) {
	return new Some!T(value);
}

class None(T) : Option!T {
public:
	override @property pure bool isDefined() { return false; }
	override @property pure T get() { throw new Exception("OH NOES"); }

	override int opApply(int delegate(ref T) dg) {
		return 0;
	}

	override Option!T filter(bool delegate(ref T) p) {
		return this;
	}	

	override string toString() { return "None"; }

	override bool opEquals(Object rhs) {
		auto that = cast(None!T)rhs;

		if (that) return true;
		else return false;
	}

	this() { }
}

auto none(T)() {
	return new None!T();
}

unittest {
	writeln("Test Option basic monad operations");

	auto mult_fun = (ref int x) { return some(x*2); };
	auto never_fun = (ref int x) { assert(false, "flatMap on None never calls the mapping function"); return none!int; };

	Option!int option = some(17);
	assert(option.isDefined == true, "an Option with a value is defined");
	assert(option.get == 17, "an Option returns its value with get");

	assert(option.flatMap(mult_fun).get == 34, "flatMap applies the function on a defined Option");

	assert(option.getOrElse(99) == 17, "getOrElse on Some should return the stored value");

	option = none!int;
	assert(option.isDefined == false, "an Option without a value is not defined");
	// TODO assert(option.get == 17, "an Option returns its value with get");
	
	assert(option.flatMap(never_fun).isDefined == false, "flatMap on None returns None");
	
	assert(none!(int).flatMap((ref int x) { return some("string"); }).isDefined == false,
		"type changes are propagated on flatMap on None");

	assert(option.getOrElse(99) == 99, "getOrElse on None should return the supplied argument");	
}

unittest {
	writeln("Test Option equality");

	Option!int option = some(17);

	assert(option == some(17), "Some should be equal to another Some if their values are equal");
	assert(option != some!long(17), "Some should not be equal to another Some if their types are different");
	assert(option != none!int, "Some should not be equal to a None");

	option = none!int;

	assert(option == none!int, "None should be equal to None");
	assert(option != none!long, "None should not be equal to None of another type");
}

unittest {
	writeln("Test Option foreach compability");

	Option!int option = some(17);
	
	auto timesRan = 0;
	foreach(t; option) {
		assert(t == 17, "foreach iterates on the value in a Some");
		timesRan += 1;
	}
	assert(timesRan == 1, "foreach iterates exactly once on a Some");

	option = none!int;

	foreach(t; option) {
		assert(false, "foreach should not iterate at all on a None");
	}
}

unittest {
	writeln("Test Option map operation");

	auto double_fun = (ref int v) { return v * 2; };
	auto never_fun = (ref int v) { assert(false, "map on None should not call mapping function"); return v; };

	Option!int option = some(17);

	assert(option.map(double_fun).get == 34, "map on Some should apply mapping function to value and wrap result in Some");

	option = none!int;

	assert(option.map(never_fun).isDefined == false, "map on None should be a None");
}

unittest {
	writeln("Test Option filter operation");

	Option!int option = some(42);

	assert(option.filter((ref v) { return v == 42; }) is option, "filter on Some should return itself if the predicate holds");

	assert(option.filter((ref v) { return v == 41; }) == none!int, "filter on Some should return None if the predicate does not hold");

	option = none!int;

	assert(option.filter((ref v) { assert(false, "Predicate function should never be called when filtering on None"); return v == 42; }) is option, "filter on None should return itself");
}


