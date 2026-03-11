# minitalk

A client-server communication program built on UNIX signals. The server prints its PID and waits. The client takes that PID and a string, encodes each character into binary, and transmits it bit by bit using only `SIGUSR1` and `SIGUSR2`. The server reconstructs and prints each character as it arrives.

> **Context.** A 42 School project. The idea of two programs with no shared memory and no direct connection somehow managing to talk to each other was too interesting to pass up. And i could not have chosen any better, Aded so much over the mandatory requirements, its a whole diferent project.

---

## How It Works

A signal carries no data, it is just a notification that something happened. With only two signals available, the question was how to send a string at all.

Two signals. That is binary, it was pretty on the nose. Every character is already a number, and every number is already binary. `SIGUSR1` and `SIGUSR2` mean 0 and 1. The client sends 8 signals per character. The server collects them and reconstructs the byte. I doubt anyone reached a different conclusion, but if Morse code had Unicode support I would have used it instead — writing this felt like building a virtual telegraph either way.

```
Sending 'H':

  'H'  =  72  =  01001000

  bit 1  →  0  →  SIGUSR1
  bit 2  →  1  →  SIGUSR2
  bit 3  →  0  →  SIGUSR1
  bit 4  →  0  →  SIGUSR1
  bit 5  →  1  →  SIGUSR2
  bit 6  →  0  →  SIGUSR1
  bit 7  →  0  →  SIGUSR1
  bit 8  →  0  →  SIGUSR1

  8 signals sent. One character transmitted.
```

On the server side, the logic runs in reverse: `SIGUSR1` leaves the accumulator untouched, `SIGUSR2` turns the corresponding bit on. Once all 8 bits arrive, the accumulator holds the original character and gets printed. Encoding and decoding are close enough to mirror images that once one was written, the other followed almost on its own.

---

## The Four Versions

On the surface this looks like a binary encoding problem. And it is. But underneath it is really a question about **protocol design under heavy constraints**, and that second question is the one most people might miss.

This repository does not just contain the final solution. It documents the entire journey across four versions, each one a response to the limitations of the last. Understanding why each one exists matters as much, or more, as understanding how it works.

---

### 1. Legacy Version
*First iteration. Minimal tools. Maximum humility.*

Built using the old `signal()` function and a `usleep()` timer to pace transmissions. Not meant to be a final answer, just meant to get in the shoes of a time where this was all we had. It shows the limits of working without all the information you wish you had — at some point signals were just bullets meant to `kill()` another process (please laugh, i am proud of that joke). You are essentially throwing signals into the void and hoping the server catches them in time.

It works. Mostly. Until it does not. And you never really know which one it will be.

`signal()` is the older, simpler interface, it registers a handler but tells you nothing about who sent the signal or why. This version was left deliberately rustic rather than upgraded, because the two versions exist to show the difference, not just claim it. Anyone reading the code can see exactly what changes between them and why it matters, history happening in front of your eyes all over again.

**Key constraint:** no acknowledgement from server to client. The client sends bits on a blind timer and hopes for the best, while the server has no way to differentiate between clients at all. Everyone is in the dark here.

---

### 2. Basic Handshake Version
*The immediate upgrade. Same problem, better tools.*

The introduction of `sigaction()` over `signal()` is what makes this possible. With `SA_SIGINFO` the server can now see **who** sent the signal, not just that a signal arrived. That single piece of information unlocks the handshake: after every bit received, the server signals back to the client, and the client waits before sending the next one.

The unreliable `usleep()` timer is gone (but not gone forever, as will become relevant). Synchronization is now enforced by the protocol itself rather than hoped for by a sleep call.

This version handles one client at a time cleanly and reliably. The weakness only shows when two clients try to transmit at the same time, their characters arrive interleaved, and the output becomes unintelligible. Not technically corrupted bit by bit, but functionally indistinguishable from it when you are reading the result.

**Key improvement:** `signal()` → `sigaction()`. Blind timer → handshake protocol.

**Key constraint:** just barely less fragile against two or more clients transmitting simultaneously.

---

### 3. Buffer Version
*AKA: The False Prophet.*

Inspired by the GNL (Get Next Line) project and an undying love for solving everything with strings — and if that does not work, using even more string magic.

This version stores each client's incoming characters in a per-client buffer and only prints the full message once the null byte arrives. Output is always clean, always complete (unless too long), never interleaved.

It handles up to 10 simultaneous clients, buffers their messages independently, and prints them in order of completion — not by who arrived first, it is a dog eats dog world out there.

It felt like the necessary trade-off for robustness. It felt inevitable. It was presented as a step forward, and in some ways it genuinely was, just misdirected as i would find out later.

Then its limitations became more visible the more i thought about them:
- Messages are capped at `MAX_MSG_LEN` characters
- `malloc()` is unsafe inside a signal handler, so dynamic allocation is off the table — no way around a fixed buffer
- Clients past the 10th are silently ignored, not queued, not told to wait, just dropped, and they do not even know it. Ghosted like that one date who said they would call you back
- The order of output depends on message length, not arrival — not a real guarantee

When you hold a hammer, everything looks like a nail. The buffer was the hammer. It had worked before so it had to work now, until the problem stopped looking like a nail.

**Key improvement:** clean output and concurrent handling up to a configurable limit.

**Key constraint:** message length limits, silent client loss past the maximum, and buffering the entire message before printing felt at odds with the spirit of the project.

---

### 4. Queue & Wait Version
*The last minute redemption.*

While testing the Buffer version and thinking about how to work around its limitations — dynamic allocation was explored and ruled out as unsafe in signal handler context — something clicked. The buffer was trying to handle concurrency. But concurrency was never actually required. It was assumed.

The real requirements were hiding something more: **how do you build a robust communication protocol with only two signals?**

The answer to the first part was always obvious: binary. One signal is 0, the other is 1. Eight signals make a character. There are only 10 kinds of people in this world: those who understand binary, and those who do not.

The answer to the second part was more subtle: **signals do not have to mean the same thing in every context.** With a simple state variable, the same signal can mean "I want to connect" before the handshake and "this bit is a 0" during transmission. Two signals, handled correctly across states, give you as many distinct messages as you need.

This version establishes a connection protocol before transmission begins. Clients register with the server and are placed in a queue, first in, first out. Those who do not get a spot keep trying periodically, like that one date who cannot take a hint, and eventually get in once a slot opens. Once logged, they stop sending connection requests entirely and simply wait. The server drives the transmission: after storing each bit it immediately requests the next one by signaling the client. The client only sends when asked. No message is lost. No message is capped. No client is silently dropped.

The server pulls, the client pushes only when pulled. This inversion of control is what makes the whole thing reliable, a waiting client generates no noise that could interfere with an active transmission.

One last addition: the client keeps a timeout while waiting for the server's next bit request. If 500ms pass with no signal, it assumes the last bit was lost in transit and resends it. Just as it insists on getting connected, it also insists on being heard. The `usleep()` timer from the legacy version came back, not as a crutch this time, but as a safety net.

The basic protocol is arguably simpler than the Buffer version. The edge case handling, however, was a different story. Fitting it all within the 42 norm, 5 functions per file, 25 lines per function, 4 arguments per function, while also making it robust was a real fight. Earlier iterations had functions carrying multiple responsibilities as a direct result, but that was cleaned up. Every function now does one thing, and the error handling reads as part of the normal flow rather than as bolted-on afterthoughts. In exchange, the server can recover from dead clients, the client can detect a dead server, and the handshake holds up well under concurrent load.

Once the architecture was settled, the work shifted to debugging the weak and inconsistent points, the kind of problems that only show up under specific timing or when a client dies at exactly the wrong moment. A test suite was written to cover every case the protocol claims to handle: correctness, concurrency, robustness, server death, and bad input. It made the difference between hoping something works and knowing it does. More importantly, it meant that fixing one edge case could not silently break another, every change was verified against the full suite before moving on. Without it, each iteration would have required manually testing every scenario by hand, and some of the subtler regressions would have gone unnoticed until much later.

The only real trade-offs are latency and ordering past the queue limit, both of which are so much more forgiving than the alternatives that calling them defects feels generous.

**Key improvement:** virtually unlimited message length, no silent drops, clients know exactly where they stand, transmission is driven by the server, both sides can detect and recover from the other going silent.

**Key constraint:** latency grows with queue depth, and ordering is only guaranteed up to the queue limit.

**Key insight:** do not solve the problem you assumed you had. Solve the problem you actually have.

---

#### Basic Protocol

| Signal | Direction | Context | Meaning |
|---|---|---|---|
| SIGUSR1 | client → server | connecting | connection request |
| SIGUSR1 | server → client | connecting | you are queued |
| SIGUSR2 | server → client | queued | send me a bit |
| SIGUSR1 | client → server | transmitting | bit 0 |
| SIGUSR2 | client → server | transmitting | bit 1 |
| SIGUSR2 | server → client | transmitting | bit received, send next |

---

#### Edge Cases & Safety Features

**Client cannot reach server.** On every connection attempt, `kill()` is checked for a `-1` return. If the server PID is invalid or the process is gone, the client exits immediately with an error rather than looping forever into the void.

**Server goes silent mid-transmission.** The client polls every 5ms waiting for the next bit request. After 500ms with no signal, it assumes the last bit was dropped and resends it. The retry uses the same `kill()` check — if that returns `-1`, the server is gone and the client exits cleanly.

**Client dies mid-transmission.** The server sends `SIGUSR2` to request the next bit. If `kill()` returns `-1`, the client is gone. The server prints a newline if any output was already on the current line, drops that slot, resets its accumulator to a clean state, and immediately moves to the next client in the queue. No freeze, no corruption carried forward, no mangled terminal.

**Client dies during connection phase.** If a client sends a connection request and then dies before the server responds, the server will detect the dead PID the next time it tries to send `SIGUSR2` to start transmission, and will skip to the next queued client.

**Queue full.** When all `MAX_Q` slots are occupied, connection requests from new clients are silently ignored. Those clients will keep retrying on their `usleep()` timer and will eventually get in once a slot opens. The queue limit is configurable.

**Accumulator reset on client drop.** When the server drops a dead client mid-character, `mask` and `letter` are explicitly reset before moving to the next client. Without this, the next client's first character would be assembled from whatever bits the dead client had already sent — a subtle corruption that would be very hard to trace. The reset ensures every new client starts from a known clean state.

---

#### Known Bugs & Weaknesses

**Signals are not queued by the OS.** `SIGUSR1` and `SIGUSR2` are standard signals, not realtime signals. The OS holds at most one pending signal of each type at a time. If two arrive while the handler is busy, only one survives. This is the root cause of all the reliability issues in this project, the retry logic reduces the damage, but cannot eliminate it entirely.

**Spurious bit retry can corrupt a character.** When the client's 500ms timeout fires and it resends the last bit, the server may have actually received the first send and is simply slow to respond. In that case the server receives the same bit twice, assembles the wrong character, and prints it. The message from that client is corrupted from that point on. This does not affect other clients in the queue — their state is separate and the corruption does not propagate, but the affected client's message will be wrong. Difficult to reproduce under normal conditions, but not impossible.

**Race on first connection.** If two clients send their very first `SIGUSR1` at the exact same millisecond, one signal may be dropped before either handshake is established. One client connects normally, the other loops on its retry timer and reconnects on the next attempt. Low probability, no data loss, but the second client's queue position is determined by when it successfully retries, not when it first tried.

**Ordering past `MAX_Q`.** Once the queue is full, new clients compete for the first available slot on a timing basis. Whoever happens to send their retry signal at the right moment wins. There is no fairness guarantee beyond the queue limit.

**Dead client mid-character leaves a partial print.** If a client is killed after the server has already printed some characters of its message but before the null byte, the server will print whatever arrived up to that point, append a newline, drop the dead client cleanly, and move on to the next one in the queue. The output is incomplete but never messy, the terminal stays sane and the next client's message starts on a fresh line.

---

#### What's Handled

Not everything listed here was required by the subject. Some of it was mandatory, some was bonus, and the rest was a personal decision to push the protocol further.

**Mandatory.** The server receives a string from the client and prints it. Multiple messages can be sent in succession without restarting the server. Unicode support.

**Bonus.** The client prints a confirmation once the server has received the full message.

**Everything else was self-imposed.** Connection handshake before transmission. Client queue with FIFO ordering. Server-driven bit requests (pull model). Client-side retry on dropped bits. Detection and clean recovery from dead clients — both mid-transmission and during connection. Detection and clean exit when the server dies. Newline on partial output when a client is killed mid-message. Accumulator reset on client drop to prevent state corruption. Timeout-based dequeue of unresponsive clients. Queue overflow handling with automatic retry. Argument validation on the client (non-numeric PID, wrong argument count). `kill()` return value checked on every signal sent.

None of these were asked for. All of them came from asking what would go wrong if they were not there.

---

## Constraints

**Only `SIGUSR1` and `SIGUSR2` allowed.** No other signals, no other communication channel. This is the constraint the entire project is built around, everything else is a consequence of it.

**Global variables.** The subject allows one global per program. The client uses a single `volatile sig_atomic_t` for its state machine; the server uses a single global struct for the queue and transmission state. The `volatile` qualifier matters more than it looks, it tells the compiler that the value can change between any two instructions, because a signal handler can fire at any point. Without it, the compiler is free to cache a variable in a register and never re-read it from memory, which means the main loop could spin forever waiting for a state change that already happened. `sig_atomic_t` adds the second guarantee: reads and writes to the variable are atomic, so the main loop will never see a half-written value left behind by a handler that was interrupted mid-store. Together they are what makes the handshake between handler and main code actually correct, not just correct-looking. The kind of distinction that does not matter until it does, and when it does it is almost impossible to debug. The similarity to multithreaded programming is not a coincidence — a signal handler interrupts the main flow at an unpredictable point and modifies shared state, which is exactly what a thread does. The same problems show up: visibility, atomicity, reordering. The same tools apply: `volatile` in signals mirrors memory barriers in threads, `sig_atomic_t` mirrors atomic types. The only real difference is that signals are cooperative (one handler runs at a time) while threads are truly concurrent. The mental model transfers almost directly, just at a smaller scale.

**25 lines per function.** Small enough to occasionally matter.

**No threads, no sockets, no other IPC.** The allowed function list is short and deliberate. There is no true concurrency, and no fallback if signals are not enough. The design has to work within what signals can actually do by themselves.

---

## Discarded Ideas

**Morse code as the encoding method.** Two signals, dots and dashes — it maps perfectly. Unfortunately Morse code does not cover most of Unicode, and the subject required Unicode support. Discarded before a single line was written. `... --- ...`

**A busy loop instead of `pause()`.** The server could spin in `while (1) {}` and handle signals as interrupts. It would work, but it would also burn CPU doing nothing at all. `pause()` suspends the process until a signal arrives and costs nothing between them. The loop is still there, `pause()` only handles one signal per call, but the difference between the two is night and day.

**Runtime delay calibration.** The idea was to have the client send a few test signals at startup, have the server time the round-trip, and use that to set `usleep()` — a fun idea, letting it self-tune to whatever machine it runs on. The problem: receiving signals back from the server requires the sender's PID, which requires `sigaction()`. At that point the bonus acknowledgment model was already half-implemented, and finishing it properly was less work than building calibration on top of the basic version. It just made no sense even as a joke.

**Timer-based acknowledgment.** Instead of the server sending a signal back after every bit, I considered having the server only respond after a period of silence — signaling to the client that the message was received in full. But that left all the reliability issues with signals untouched, so it was dropped immediately.

**`alarm()` for server-side timeouts.** The server has no way to detect a dead client on its own, it can only discover the problem when it tries to send the next signal. `alarm()` would have allowed a timeout-based wakeup on the server side too, creating redundant recovery from both ends. It is not on the allowed function list. The client-side retry and the `kill()` return check cover the gap adequately.

---

## What I Learned

The most important thing this project taught me was not about signals, binary encoding, or even protocol design, though it taught me all of those things.

It was this: **the version of you that was proud of the wrong solution was right to be proud.** You cannot get to the Queue version without going through the Buffer one first. The clarity came because it was built, not in spite of it.

The Buffer version was a reuse of a pattern that had worked somewhere else. Recognizing a pattern and applying it is a real skill — it is just that when the pattern stops fitting the problem, you have to be willing to put it down. When i stopped asking *"how do I fix this buffer"* and started asking *"why do I need a buffer at all"*, the answer got closer.

All roads lead to Rome, but some are better paved.

---

## Usage

Start the server:
```bash
./server
```

Send a message from another terminal:
```bash
./client [server_pid] "your message here"
```

The client will print:
```
Attempting connection...
Connection established.
Sending message...
Message received.
```

The server runs until you stop it with `Ctrl+C` (and now i even know why).

---

## Building

```bash
make        # server and client
make clean  # remove object files
make fclean # remove object files and binaries
make re     # clean rebuild
```

---

## Testing

```bash
bash test_minitalk.sh
```

The test suite compiles the project and runs 16 tests across five categories: correctness (basic messages, empty strings, special characters, numbers, long text, Unicode, sequential delivery), concurrency (simultaneous clients with no interleaving, repeated messages), robustness (dead client recovery, queue overflow with 12 clients against a `MAX_Q` of 10), server death (before connection, mid-transmission), and bad input (invalid PID, non-numeric PID, wrong argument count).

Every test starts a fresh server, runs a scenario, and checks the result against an expected outcome. The suite was not written after the fact to validate a finished project, it was written during development, while debugging the weak points of the final architecture. Being able to fix one problem and immediately know whether it broke something else was what made the edge case work manageable. Some of the subtler issues, like state corruption after a dead client, or a second client's message arriving garbled because the accumulator was not reset, would have survived much longer without automated verification on every iteration.

