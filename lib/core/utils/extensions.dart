extension BoolX on bool {
  T when<T>({required T Function() onTrue, required T Function() onFalse}) {
    return this ? onTrue() : onFalse();
  }
}
