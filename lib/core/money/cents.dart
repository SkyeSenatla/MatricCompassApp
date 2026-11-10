/// Week 10 Day 1: money is a whole number of cents, never a double.
///
/// An extension type costs nothing at run time (it is an int underneath),
/// but the type checker treats it as its own type: you can't pass a mark or
/// a day count where an amount is expected, or add one to the other.
extension type const Cents(int value) {
  /// Adds two amounts, still in whole cents.
  Cents operator +(Cents other) => Cents(value + other.value);
}
