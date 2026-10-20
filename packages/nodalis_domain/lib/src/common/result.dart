/// Functional Result type representing either a success with value [T] or a failure with error [E].
sealed class Result<T, E> {
  const Result();

  const factory Result.ok(T value) = Ok<T, E>;
  const factory Result.err(E error) = Err<T, E>;

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  E? get errorOrNull => switch (this) {
        Ok() => null,
        Err(:final error) => error,
      };

  Result<R, E> map<R>(R Function(T value) mapper) => switch (this) {
        Ok(:final value) => Result.ok(mapper(value)),
        Err(:final error) => Result.err(error),
      };

  Result<T, F> mapError<F>(F Function(E error) mapper) => switch (this) {
        Ok(:final value) => Result.ok(value),
        Err(:final error) => Result.err(mapper(error)),
      };
}

final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ok<T, E> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Result.ok($value)';
}

final class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Err<T, E> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Result.err($error)';
}
