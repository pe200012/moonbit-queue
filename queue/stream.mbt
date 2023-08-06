enum Thunk[T] {
  Force(T)
  Delay(() -> T)
}

struct Lazy[T] {
  mut thunk : Thunk[T]
}

func enforce[T](self : Lazy[T]) -> T {
  match self.thunk {
    Force(x) => x
    Delay(f) => {
      let y = f()
      self.thunk = Force(y)
      y
    }
  }
}

func lazy[T](f : () -> T) -> Lazy[T] {
  { thunk: Delay(f) }
}

func pure[T](x : T) -> Lazy[T] {
  { thunk: Force(x) }
}

func lazyFn[A, B](f : (A) -> B, x : A) -> Lazy[B] {
  { thunk: Delay(fn() { f(x) }) }
}

func lazyBind[A, B](self : Lazy[A], f : (A) -> Lazy[B]) -> Lazy[B] {
  { thunk: Delay(fn() { enforce(f(enforce(self))) }) }
}

func lazyMap[A, B](self : Lazy[A], f : (A) -> B) -> Lazy[B] {
  { thunk: Delay(fn() { f(enforce(self)) }) }
}

enum Stream[T] {
  Nil
  Cons(T, Lazy[Stream[T]])
}

func append[T](xs : Lazy[Stream[T]], ys : Lazy[Stream[T]]) -> Lazy[Stream[T]] {
  {
    thunk: Delay(fn() {
      match enforce(xs) {
        Nil => enforce(ys)
        Cons(x, xs) => Cons(x, append(xs, ys))
      }
    }),
  }
}

func take[T](n : Int, xs : Lazy[Stream[T]]) -> Lazy[Stream[T]] {
  lazy(
    fn() {
      match n {
        0 => Stream::Nil
        _ =>
          match enforce(xs) {
            Nil => Nil
            Cons(x, xs) => Cons(x, take(n - 1, xs))
          }
      }
    },
  )
}

func drop[T](n : Int, xs : Lazy[Stream[T]]) -> Lazy[Stream[T]] {
  fn aux(n : Int, c : Lazy[Stream[T]]) -> Stream[T] {
    match n {
      0 => enforce(c)
      _ =>
        match enforce(c) {
          Nil => Nil
          Cons(x, xs) => aux(n - 1, xs)
        }
    }
  }

  lazy(fn() { aux(n, xs) })
}

func rev[T](xs : Lazy[Stream[T]]) -> Lazy[Stream[T]] {
  fn aux(xs : Lazy[Stream[T]], acc : Stream[T]) -> Stream[T] {
    match enforce(xs) {
      Nil => acc
      Cons(x, xs) => aux(xs, Cons(x, lazy(fn() { acc })))
    }
  }

  lazy(fn() { aux(xs, Nil) })
}

