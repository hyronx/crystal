require "c/signal"
require "c/stdio"
require "c/unistd"

ifdef linux
  enum Signal
    HUP    = LibC::SIGHUP
    INT    = LibC::SIGINT
    QUIT   = LibC::SIGQUIT
    ILL    = LibC::SIGILL
    TRAP   = LibC::SIGTRAP
    IOT    = LibC::SIGIOT
    ABRT   = LibC::SIGABRT
    FPE    = LibC::SIGFPE
    KILL   = LibC::SIGKILL
    BUS    = LibC::SIGBUS
    SEGV   = LibC::SIGSEGV
    SYS    = LibC::SIGSYS
    PIPE   = LibC::SIGPIPE
    ALRM   = LibC::SIGALRM
    TERM   = LibC::SIGTERM
    URG    = LibC::SIGURG
    STOP   = LibC::SIGSTOP
    TSTP   = LibC::SIGTSTP
    CONT   = LibC::SIGCONT
    CHLD   = LibC::SIGCHLD
    TTIN   = LibC::SIGTTIN
    TTOU   = LibC::SIGTTOU
    IO     = LibC::SIGIO
    XCPU   = LibC::SIGXCPU
    XFSZ   = LibC::SIGXFSZ
    VTALRM = LibC::SIGVTALRM
    USR1   = LibC::SIGUSR1
    USR2   = LibC::SIGUSR2
    WINCH  = LibC::SIGWINCH

    PWR    = LibC::SIGPWR
    STKFLT = LibC::SIGSTKFLT
    UNUSED = LibC::SIGUNUSED
  end
else
  enum Signal
    HUP    = LibC::SIGHUP
    INT    = LibC::SIGINT
    QUIT   = LibC::SIGQUIT
    ILL    = LibC::SIGILL
    TRAP   = LibC::SIGTRAP
    IOT    = LibC::SIGIOT
    ABRT   = LibC::SIGABRT
    FPE    = LibC::SIGFPE
    KILL   = LibC::SIGKILL
    BUS    = LibC::SIGBUS
    SEGV   = LibC::SIGSEGV
    SYS    = LibC::SIGSYS
    PIPE   = LibC::SIGPIPE
    ALRM   = LibC::SIGALRM
    TERM   = LibC::SIGTERM
    URG    = LibC::SIGURG
    STOP   = LibC::SIGSTOP
    TSTP   = LibC::SIGTSTP
    CONT   = LibC::SIGCONT
    CHLD   = LibC::SIGCHLD
    TTIN   = LibC::SIGTTIN
    TTOU   = LibC::SIGTTOU
    IO     = LibC::SIGIO
    XCPU   = LibC::SIGXCPU
    XFSZ   = LibC::SIGXFSZ
    VTALRM = LibC::SIGVTALRM
    USR1   = LibC::SIGUSR1
    USR2   = LibC::SIGUSR2
    WINCH  = LibC::SIGWINCH
  end
end

<<<<<<< HEAD
# Signals are processed through the event loop and run in their own Fiber.
# Signals may be lost if the event loop doesn't run before exit.
# An uncaught exceptions in a signal handler is a fatal error.
enum Signal
  def trap(block : Signal ->)
    trap &block
  end

  def trap(&block : Signal ->)
    Event::SignalHandler.add_handler self, block
  end

  def reset
    case self
    when CHLD
      # don't ignore by default.  send events to a waitpid service
      trap do
        Event::SignalChildHandler.instance.trigger
        nil
      end
    else
      del_handler Proc(Int32, Void).new(Pointer(Void).new(0_u64), Pointer(Void).null)
=======
module Signal
  extend self

  EXIT   =  0
  HUP    =  1
  INT    =  2
  QUIT   =  3
  ILL    =  4
  TRAP   =  5
  IOT    =  6
  ABRT   =  6
  EMT    =  7
  FPE    =  8
  KILL   =  9
  BUS    = 10
  SEGV   = 11
  SYS    = 12
  PIPE   = 13
  ALRM   = 15
  TERM   = 15
  URG    = 16
  STOP   = 17
  TSTP   = 18
  CONT   = 19
  CHLD   = 20
  CLD    = 20
  TTIN   = 21
  TTOU   = 22
  IO     = 23
  XCPU   = 24
  XFSZ   = 25
  VTLARM = 26
  PROF   = 27
  WINCH  = 28
  INFO   = 29
  USR1   = 30
  USR2   = 31

  DEFAULT = Proc(Int32, Void).new(Pointer(Void).new(0_u64), Pointer(Void).null)
  IGNORE  = Proc(Int32, Void).new(Pointer(Void).new(1_u64), Pointer(Void).null)

  def trap(signal, block : Int32 ->)
    trap signal, &block
  end

  def trap(signal, &block : Int32 ->)
    if block.closure?
      handlers = @@handlers ||= {} of Int32 => Int32 ->
      handlers[signal] = block
      LibC.signal(signal, ->handler(Int32))
    else
      LibC.signal(signal, block)
>>>>>>> refs/remotes/origin/windows
    end
  end

  def ignore
    del_handler Proc(Int32, Void).new(Pointer(Void).new(1_u64), Pointer(Void).null)
  end

  private def del_handler(block)
    Event::SignalHandler.del_handler self
    LibC.signal value, block
  end

  @@default_handlers_setup = false

  # :nodoc:
  def self.setup_default_handlers
    return if @@default_handlers_setup
    @@default_handlers_setup = true

    Signal::PIPE.ignore
    Signal::CHLD.reset
  end
end

# :nodoc:
fun __crystal_sigfault_handler(sig : LibC::Int, addr : Void*)
  # Capture fault signals (SEGV, BUS) and finish the process printing a backtrace first
  LibC.printf "Invalid memory access (signal %d) at address 0x%lx\n", sig, addr
  CallStack.print_backtrace
  LibC._exit sig
end

LibExt.setup_sigfault_handler
