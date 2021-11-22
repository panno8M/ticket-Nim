# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import sequtils

import tickets

test "Ticket with Result":
  var ticket = Ticket[string].issue:
    "ticket used"

  check ticket.use == "ticket used"

  ticket.use

test "Ticket for Action":
  var results: seq[int]
  var ticket = Ticket[void].issue:
    results.add results.len

  use ticket
  use ticket
  use ticket

  check results == [0, 1, 2]

test "Bandle Ticket":
  var results: seq[int]

  var ticket1 = Ticket[void].issue:
    results.add results.len
  var ticket2 = Ticket[void].issue:
    results.add results.len

  var bandled = bandle(ticket1, ticket2)

  use bandled
  check results == [0, 1]
  use bandled
  check results == [0, 1, 2, 3]

test "Disposable":
  var ticket = DisposableTicket[string].issue:
    "ticket consumed"

  check ticket.consume == "ticket consumed"

  check:
    try:
      consume ticket
      false
    except ExpiredDefect: true

test "Bandle Disposable":
  var results: seq[int]

  var ticket1 = DisposableTicket[void].issue:
    results.add results.len
  var ticket2 = DisposableTicket[void].issue:
    results.add results.len

  var bandled = bandle(ticket1.addr, ticket2.addr)

  consume bandled

  check results == [0, 1]

  check:
    try:
      consume bandled
      false
    except ExpiredDefect: true

test "Book of Tickets":
  var results: seq[int]
  var ticket = BookofTickets[int].issue(3):
    results.add results.len

  for i in 0..<3:
    consume ticket

  check results == [0, 1, 2]

  check:
    try:
      consume ticket
      false
    except ExpiredDefect: true

test "Abstract":
  var results: seq[string]
  var ticket = Ticket[void].issue:
    results.add "Ticket"
  var disp = DisposableTicket[void].issue:
    results.add "Disposable"
  var book = BookofTickets[void].issue(1):
    results.add "Book of"

  var abstracts = [
    abstract ticket,
    abstract disp.addr,
    abstract book.addr ]

  for abstract in abstracts.mitems:
    use abstract

  check results == ["Ticket", "Disposable", "Book of"]