{.experimental: "strictFuncs".}
import sequtils

# Basic Ticket //------------------------------------------------------------- #

type ExpiredDefect* = object of Defect

type Ticket*[T] = object
  action: proc(): T

proc use*[T](this: Ticket[T]): T {.discardable.} = this.action()

template issue*[T](_: typedesc[Ticket[T]]; effect: untyped): Ticket[T] =
  Ticket[T](
    action: proc(): T = effect
  )

type BandledTicket* = seq[Ticket[void]]
converter zip*(this: BandledTicket): Ticket[void] {.inline.} =
  Ticket[void].issue:
    for ticket in this:
      ticket.use

proc bandle*(tickets: varargs[Ticket[void]]): Ticket[void] =
  @tickets

# -------------------------------------------------------------// Basic Ticket #
# Disposable Ticket //-------------------------------------------------------- #

type DisposableTicket*[T] = object
  ticket: Ticket[T]
  isInvalid: bool

func isInvalid*[T](this: DisposableTicket[T]): lent bool = this.isInvalid
func isValid*[T](this: DisposableTicket[T]): bool = not this.isValid

proc use*[T](this: ptr DisposableTicket[T]): T {.discardable.} =
  if this.isInvalid:
    raise ExpiredDefect.newException("It's expired")

  when T is void: this.ticket.use()
  else: result = this.ticket.use()
  this.isInvalid = true

template use*[T](this: var DisposableTicket[T]): untyped = this.addr.use
template consume*[T](this: ptr DisposableTicket[T]): untyped = this.use
template consume*[T](this: var DisposableTicket[T]): untyped = this.use

template issue*[T](_: typedesc[DisposableTicket[T]];
    effect: untyped): DisposableTicket[T] =
  DisposableTicket[T]( ticket: Ticket[T].issue(effect))

type BandledDisposableTicket* = seq[ptr DisposableTicket[void]]
converter zip*(this: BandledDisposableTicket): DisposableTicket[void] {.inline.} =
  DisposableTicket[void].issue:
    for ticket in this:
      ticket.consume

proc bandle*(tickets: varargs[ptr DisposableTicket[void]]): DisposableTicket[void] =
  @tickets

# --------------------------------------------------------// Disposable Ticket #
# Book of Tickets //---------------------------------------------------------- #

type BookofTickets*[T] = object
  ticket: Ticket[T]
  available: Natural

func isInvalid*[T](this: BookofTickets[T]): bool = this.available == 0
func isValid*[T](this: BookofTickets[T]): bool = this.available != 0

proc use*[T](this: ptr BookofTickets[T]): T {.discardable.} =
  if this[].isInvalid:
    raise ExpiredDefect.newException("It's expired")
  when T is void: this.ticket.use()
  else: result = this.ticket.use()
  dec this.available

template use*[T](this: var BookofTickets[T]): T = this.addr.use
template consume*[T](this: ptr BookofTickets[T]): T = this.use
template consume*[T](this: var BookofTickets[T]): T  = this.use

template issue*[T](_: typedesc[BookofTickets[T]];
    numberof: Natural; effect: untyped): BookofTickets[T] =
  BookofTickets[T]( ticket: Ticket[T].issue(effect), available: numberof)

# ----------------------------------------------------------// Book of Tickets #
# Abstract Ticket //---------------------------------------------------------- #

type AbstractTicket*[T] = object
  ticket: Ticket[T]
  isInvalidProc: proc(): bool
  useProc: proc(): T

proc isInvalid*[T](this: AbstractTicket[T]): bool {.inline.} = this.isInvalidProc()
proc use*[T](this: AbstractTicket[T]): T {.inline.} = this.useProc()

proc abstract*[T](this: Ticket[T]): AbstractTicket[T] =
  AbstractTicket[T](
    ticket: this,
    isInvalidProc: proc(): bool = true,
    useProc: proc(): T = use(this),
  )
proc abstract*[T](this: ptr DisposableTicket[T]): AbstractTicket[T] =
  AbstractTicket[T](
    ticket: this.ticket,
    isInvalidProc: proc(): bool = isInvalid(this[]),
    useProc: proc(): T = use(this),
  )
proc abstract*[T](this: ptr BookofTickets[T]): AbstractTicket[T] =
  AbstractTicket[T](
    ticket: this.ticket,
    isInvalidProc: proc(): bool = isInvalid(this[]),
    useProc: proc(): T = use(this),
  )


# ----------------------------------------------------------// Abstract Ticket #
