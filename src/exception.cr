<<<<<<< HEAD
require "c/stdio"
require "c/string"
require "c/dlfcn"
require "unwind"

def caller
  CallStack.new.printable_backtrace
end

# :nodoc:
struct CallStack
  @callstack : Array(Void*)
  @backtrace : Array(String)?

  def initialize
    @callstack = CallStack.unwind
  end

  def printable_backtrace
    @backtrace ||= decode_backtrace
  end

  ifdef i686
    # This is only used for the workaround described in `Exception.unwind`
    @@makecontext_range : Range(Void*, Void*)?

    def self.makecontext_range
      @@makecontext_range ||= begin
        makecontext_start = makecontext_end = LibC.dlsym(LibC::RTLD_DEFAULT, "makecontext")

        while true
          ret = LibC.dladdr(makecontext_end, out info)
          break if ret == 0 || info.dli_sname.null?
          break unless LibC.strcmp(info.dli_sname, "makecontext") == 0
          makecontext_end += 1
        end

        (makecontext_start...makecontext_end)
      end
    end
  end

  protected def self.unwind
    callstack = [] of Void*
    backtrace_fn = ->(context : LibUnwind::Context, data : Void*) do
      bt = data.as(typeof(callstack))
      ip = Pointer(Void).new(LibUnwind.get_ip(context))
      bt << ip

      ifdef i686
        # This is a workaround for glibc bug: https://sourceware.org/bugzilla/show_bug.cgi?id=18635
        # The unwind info is corrupted when `makecontext` is used.
        # Stop the backtrace here. There is nothing interest beyond this point anyway.
        if CallStack.makecontext_range.includes?(ip)
          return LibUnwind::ReasonCode::END_OF_STACK
        end
      end

      LibUnwind::ReasonCode::NO_REASON
=======
ifdef darwin || linux
  ifdef darwin
    lib Unwind
      CURSOR_SIZE = 140
      CONTEXT_SIZE = 128

      REG_IP = -1

      fun get_context = unw_getcontext(context : LibC::SizeT*) : Int32
      fun init_local = unw_init_local(cursor : LibC::SizeT*, context : LibC::SizeT*) : Int32
      fun step = unw_step(cursor : LibC::SizeT*) : Int32
      fun get_reg = unw_get_reg(cursor : LibC::SizeT*, regnum : Int32, reg : LibC::SizeT*) : Int32
      fun get_proc_name = unw_get_proc_name(cursor : LibC::SizeT*, name : UInt8*, size : Int32, offset : LibC::SizeT*) : Int32
    end
  elsif linux
    ifdef x86_64
      @[Link("unwind")]
      lib Unwind
        CURSOR_SIZE = 140
        CONTEXT_SIZE = 128

        REG_IP = -1

        fun get_context = _Ux86_64_getcontext(context : LibC::SizeT*) : Int32
        fun init_local = _ULx86_64_init_local(cursor : LibC::SizeT*, context : LibC::SizeT*) : Int32
        fun step = _ULx86_64_step(cursor : LibC::SizeT*) : Int32
        fun get_reg = _ULx86_64_get_reg(cursor : LibC::SizeT*, regnum : Int32, reg : LibC::SizeT*) : Int32
        fun get_proc_name = _ULx86_64_get_proc_name(cursor : LibC::SizeT*, name : UInt8*, size : Int32, offset : LibC::SizeT*) : Int32
      end
    else
      @[Link("unwind")]
      lib Unwind
        CURSOR_SIZE = 127
        CONTEXT_SIZE = 87

        REG_IP = -1

        fun get_context = getcontext(context : LibC::SizeT*) : Int32
        fun init_local = _ULx86_init_local(cursor : LibC::SizeT*, context : LibC::SizeT*) : Int32
        fun step = _ULx86_step(cursor : LibC::SizeT*) : Int32
        fun get_reg = _ULx86_get_reg(cursor : LibC::SizeT*, regnum : Int32, reg : LibC::SizeT*) : Int32
        fun get_proc_name = _ULx86_get_proc_name(cursor : LibC::SizeT*, name : UInt8*, size : Int32, offset : LibC::SizeT*) : Int32
      end
>>>>>>> refs/remotes/origin/windows
    end

    LibUnwind.backtrace(backtrace_fn, callstack.as(Void*))
    callstack
  end

<<<<<<< HEAD
  struct RepeatedFrame
    getter ip : Void*, count : Int32

    def initialize(@ip : Void*)
      @count = 0
    end

    def incr
      @count += 1
    end
  end

  def self.print_backtrace
    backtrace_fn = ->(context : LibUnwind::Context, data : Void*) do
      last_frame = data.as(RepeatedFrame*)
      ip = Pointer(Void).new(LibUnwind.get_ip(context))
      if last_frame.value.ip == ip
        last_frame.value.incr
      else
        print_frame(last_frame.value) unless last_frame.value.ip.address == 0
        last_frame.value = RepeatedFrame.new ip
      end
      LibUnwind::ReasonCode::NO_REASON
    end

    rf = RepeatedFrame.new(Pointer(Void).null)
    LibUnwind.backtrace(backtrace_fn, pointerof(rf).as(Void*))
    print_frame(rf)
  end

  private def self.print_frame(repeated_frame)
    frame = decode_frame(repeated_frame.ip)
    if frame
      offset, sname = frame
      if repeated_frame.count == 0
        LibC.printf "[%ld] %s +%ld\n", repeated_frame.ip, sname, offset
      else
        LibC.printf "[%ld] %s +%ld (%ld times)\n", repeated_frame.ip, sname, offset, repeated_frame.count + 1
      end
    else
      if repeated_frame.count == 0
        LibC.printf "[%ld] ???\n", repeated_frame.ip
      else
        LibC.printf "[%ld] ??? (%ld times)\n", repeated_frame.ip, repeated_frame.count + 1
=======
  def caller
    cursor = Pointer(LibC::SizeT).malloc(Unwind::CURSOR_SIZE)
    context = Pointer(LibC::SizeT).malloc(Unwind::CONTEXT_SIZE)

    Unwind.get_context(context)
    Unwind.init_local(cursor, context)
    fname_size = 64
    fname_buffer = Pointer(UInt8).malloc(fname_size)

    backtrace = [] of String
    while Unwind.step(cursor) > 0
      Unwind.get_reg(cursor, Unwind::REG_IP, out pc)
      while true
        Unwind.get_proc_name(cursor, fname_buffer, fname_size, out offset)
        fname = String.new(fname_buffer)
        break if fname.length < fname_size - 1

        fname_size += 64
        fname_buffer = fname_buffer.realloc(fname_size)
      end
      backtrace << "#{fname} +#{offset} [#{pc}]"
    end
    backtrace
  end

  class Exception
    getter message
    getter cause
    getter backtrace

    def initialize(message = nil : String?, cause = nil : Exception?)
      @message = message
      @cause = cause
      @backtrace = caller
    end

    def backtrace
      backtrace = @backtrace
      ifdef linux
        backtrace = backtrace.map do |frame|
          Exception.unescape_linux_backtrace_frame(frame)
        end
>>>>>>> refs/remotes/origin/windows
      end
      backtrace
    end
<<<<<<< HEAD
  end

  private def decode_backtrace
    backtrace = Array(String).new(@callstack.size)
    @callstack.each do |ip|
      frame = CallStack.decode_frame(ip)
      if frame
        offset, sname = frame
        backtrace << "[#{ip.address}] #{String.new(sname)} +#{offset}"
      else
        backtrace << "[#{ip.address}] ???"
      end
    end
    backtrace
  end

  protected def self.decode_frame(ip, original_ip = ip)
    if LibC.dladdr(ip, out info) != 0
      offset = original_ip - info.dli_saddr

      if offset == 0
        return decode_frame(ip - 1, original_ip)
      end

      unless info.dli_sname.null?
        {offset, info.dli_sname}
      end
=======

    def to_s(io : IO)
      if @message
        io << @message
      end
    end

    def self.unescape_linux_backtrace_frame(frame)
      frame.gsub(/_(\d|A|B|C|D|E|F)(\d|A|B|C|D|E|F)_/) do |match|
        first = match[1].to_i(16) * 16
        second = match[2].to_i(16)
        value = first + second
        value.chr
      end
    end
  end
elsif windows
  class Exception
    getter message
    getter cause
    getter backtrace

    def initialize(message = nil : String?, cause = nil : Exception?)
      @message = message
      @cause = cause
      backtrace = [] of String
      backtrace << "schwupp blubb"
      @backtrace = backtrace
>>>>>>> refs/remotes/origin/windows
    end
  end
end

class Exception
  getter message : String?
  getter cause : Exception?
  property callstack : CallStack?

  def initialize(@message : String? = nil, @cause : Exception? = nil)
  end

  def backtrace
    self.backtrace?.not_nil!
  end

  def backtrace?
    @callstack.try &.printable_backtrace
  end

  def to_s(io : IO)
    io << @message
  end

  def inspect_with_backtrace
    String.build do |io|
      inspect_with_backtrace io
    end
  end

  def inspect_with_backtrace(io : IO)
    io << @message << " (" << self.class << ")\n"
    backtrace.try &.each do |frame|
      io.puts frame
    end
    io.flush
  end
end

# Raised when the given index is invalid.
#
# ```
# a = [:foo, :bar]
# a[2] # => IndexError: index out of bounds
# ```
class IndexError < Exception
  def initialize(message = "Index out of bounds")
    super(message)
  end
end

# Raised when the arguments are wrong and there isn't a more specific `Exception` class.
#
# ```
# [1, 2, 3].first(-4) # => ArgumentError: attempt to take negative size
# ```
class ArgumentError < Exception
  def initialize(message = "Argument error")
    super(message)
  end
end

# Raised when the type cast failed.
#
# ```
# [1, "hi"][1].as(Int32) # => TypeCastError: cast to Int32 failed
# ```
class TypeCastError < Exception
  def initialize(message = "Type Cast error")
    super(message)
  end
end

class InvalidByteSequenceError < Exception
  def initialize(message = "Invalid byte sequence in UTF-8 string")
    super(message)
  end
end

# Raised when the specified key is not found.
#
# ```
# h = {"foo" => "bar"}
# h["baz"] # => KeyError: Missing hash key: "baz"
# ```
class KeyError < Exception
end

class DivisionByZero < Exception
  def initialize(message = "Division by zero")
    super(message)
  end
end
