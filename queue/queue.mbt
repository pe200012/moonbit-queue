func never[T]() -> T {
  fn aux() {
    aux()
  }

  "ENCOUNTER: never()\n".print()
  aux()
}

struct Queue[T] {
  front : Lazy[Stream[T]]
  rear : List[T]
  schedule : Lazy[Stream[T]]
  length : Int
}

func empty[T]() -> Queue[T] {
  {
    front: pure(Stream::Nil),
    rear: Nil,
    schedule: pure(Stream::Nil),
    length: 0,
  }
}

func isEmpty[T](self : Queue[T]) -> Bool {
  match enforce(self.front) {
    Nil => true
    _ => false
  }
}

func rotate[T](f : Lazy[Stream[T]], r : List[T], a : Lazy[Stream[T]]) ->
     Lazy[Stream[T]] {
  lazy(
    fn() {
      match (enforce(f), r) {
        (Nil, Cons(x, _)) => Stream::Cons(x, a)
        (Cons(x, f), Cons(y, r)) =>
          Stream::Cons(x, rotate(f, r, lazy(fn() { Stream::Cons(y, a) })))
        _ => never()
      }
    },
  )
}

func queue[T](self : Queue[T]) -> Queue[T] {
  match enforce(self.schedule) {
    Cons(_, s) =>
      { front: self.front, rear: self.rear, schedule: s, length: self.length }
    Nil => {
      f := rotate(self.front, self.rear, pure(Stream::Nil))
      { front: f, rear: Nil, schedule: f, length: self.length }
    }
  }
}

func snoc[T](self : Queue[T], x : T) -> Queue[T] {
  queue(
    {
      front: self.front,
      rear: Cons(x, self.rear),
      schedule: self.schedule,
      length: self.length + 1,
    },
  )
}

func head[T](self : Queue[T]) -> Option[T] {
  match enforce(self.front) {
    Cons(x, _) => Some(x)
    Nil => None
  }
}

func tail[T](self : Queue[T]) -> Option[Queue[T]] {
  match enforce(self.front) {
    Cons(_, f) =>
      Some(queue(
        {
          front: f,
          rear: self.rear,
          schedule: self.schedule,
          length: self.length - 1,
        },
      ))
    Nil => None
  }
}

