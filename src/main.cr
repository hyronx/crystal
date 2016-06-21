lib LibCrystalMain
  @[Raises]
  fun __crystal_main(argc : Int32, argv : UInt8**)
end

<<<<<<< HEAD
macro redefine_main(name = main)
  # :nodoc:
  fun main = {{name}}(argc : Int32, argv : UInt8**) : Int32
    %ex = nil
    %status = begin
=======
module AtExitHandlers
  @@handlers = nil

  def self.add(handler)
    handlers = @@handlers ||= [] of ->
    handlers << handler
  end

  def self.run
    return if @@running
    @@running = true

    begin
      @@handlers.try &.each &.call
    rescue handler_ex
      puts "Error running at_exit handler: #{handler_ex}"
    end
  end
end

def at_exit(&handler)
  AtExitHandlers.add(handler)
end

def exit(status = 0)
  AtExitHandlers.run
  Process.exit(status)
end

def abort(message, status = 1)
  puts message
  exit status
end

ifdef darwin || linux
  macro redefine_main(name = main)
    fun main = {{name}}(argc : Int32, argv : UInt8**) : Int32
>>>>>>> refs/remotes/origin/windows
      GC.init
      {{yield LibCrystalMain.__crystal_main(argc, argv)}}
      0
    rescue ex
<<<<<<< HEAD
      %ex = ex
      1
    end

    AtExitHandlers.run %status
    %ex.inspect_with_backtrace STDERR if %ex
    STDOUT.flush
    STDERR.flush
    %status
=======
      puts ex
      ex.backtrace.each do |frame|
        puts frame
      end
      1
    ensure
      AtExitHandlers.run
    end
  end

  redefine_main do |main|
    {{main}}
  end
elsif windows
  macro redefine_main(name = main)
    fun main = {{name}}(argc : Int32, argv : UInt8**) : Int32
      {{yield LibCrystalMain.__crystal_main(argc, argv)}}
      0
    end
>>>>>>> refs/remotes/origin/windows
  end

  redefine_main do |main|
    {{main}}
  end
end
