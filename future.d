module future;

import std.stdio, std.conv, mtry;

abstract class Future(T) {
public:
	abstract @property bool isCompleted();
	abstract @property T get();
	abstract void onComplete(void function(Try!T) func);
}

class Promise(T) : Future!(T) {
public:
	@property bool isCompleted() {
		return _result !is null;
	}

	@property Future!T future() {
		return this;
	}

	auto complete(Try!T result) {
		_result = result;
	}

	@property T get() { return _result.get(); }

	void onComplete(void function(Try!T) func) {
		
	}

private:
	Try!T _result = null;
}

unittest {
	writeln("Test Promise");
	auto promise = new Promise!int();

	assert(promise.isCompleted == false, "a Promise should not be completed when created");

	promise.complete(success(11));

	assert(promise.isCompleted == true, "a Promise should be able to be completed if it is not completed");
}

unittest {
	writeln("Test Future of Promise");
	auto promise = new Promise!int();
	auto future = promise.future;

	assert(future.isCompleted == false, "a Future of a Promise should not be completed when the Promise isn't completed");

	promise.complete(success(11));

	assert(future.isCompleted == true, "a Future of a Promise should be completed when the Promise is completed");
}