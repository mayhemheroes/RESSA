class Foo extends Bar { constructor(x = 1, ...rest) { super(x); this.y = [...rest]; } get z() { return this.y.length; } }
