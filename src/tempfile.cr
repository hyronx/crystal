<<<<<<< HEAD
require "c/stdlib"
=======
lib LibC
  fun tmpfile : File

  ifdef darwin || linux
    fun mkstemp(result : UInt8*) : Int32
  end
end
>>>>>>> refs/remotes/origin/windows

# The `Tempfile` class is for managing temporary files.
# Every tempfile is operated as a `File`, including
# initializing, reading and writing.
#
# ```
# tempfile = Tempfile.new("foo")
# # or
# tempfile = Tempfile.open("foo") { |file|
#   file.print("foobar")
# }
#
# File.size(tempfile.path)       # => 6
# File.stat(tempfile.path).mtime # => 2015-10-20 13:11:12 UTC
# File.exists?(tempfile.path)    # => true
# File.read_lines(tempfile.path) # => ["foobar"]
# ```
#
# Files created from this class are stored in a directory that handles
# temporary files.
#
# ```
# Tempfile.new("foo").path # => "/tmp/foo.ulBCPS"
# ```
#
# Also, it is encouraged to delete a tempfile after using it, which
# ensures they are not left behind in your filesystem until garbage collected.
#
# ```
# tempfile = Tempfile.new("foo")
# tempfile.unlink
# ```
class Tempfile < IO::FileDescriptor
  # Creates a `Tempfile` with the given filename.
  def initialize(name)
<<<<<<< HEAD
    tmpdir = self.class.dirname + File::SEPARATOR
    @path = "#{tmpdir}#{name}.XXXXXX"
    fileno = LibC.mkstemp(@path)
    if fileno == -1
      raise Errno.new("mkstemp")
    end
    super(fileno, blocking: true)
=======
    ifdef darwin || linux
      if tmpdir = ENV["TMPDIR"]?
        tmpdir = tmpdir + '/' unless tmpdir.ends_with? '/'
      else
        tmpdir = "/tmp/"
      end
      @path = "#{tmpdir}#{name}.XXXXXX"
      super(LibC.mkstemp(@path))
    elsif windows
      @path = ""
      super(LibC.fileno(LibC.tmpfile))
    end
>>>>>>> refs/remotes/origin/windows
  end

  # Retrieves the full path of a this tempfile.
  # ```
  # Tempfile.new("foo").path # => "/tmp/foo.ulBCPS"
  # ```
  getter path : String

  # Creates a file with *filename*, and yields it to the given block.
  # It is closed and returned at the end of this method call.
  #
  # ```
  # tempfile = Tempfile.open("foo") { |file|
  #   file.print("bar")
  # }
  # File.read(tempfile.path) # => "bar"
  # ```
  def self.open(filename)
    tempfile = Tempfile.new(filename)
    begin
      yield tempfile
    ensure
      tempfile.close
    end
    tempfile
  end

  # Returns the tmp dir used for tempfile
  # ```
  # Tempfile.dirname # => "/tmp"
  # ```
  def self.dirname : String
    unless tmpdir = ENV["TMPDIR"]?
      tmpdir = "/tmp"
    end
    tmpdir = tmpdir + File::SEPARATOR unless tmpdir.ends_with? File::SEPARATOR
    File.dirname(tmpdir)
  end

  # Deletes this tempfile.
  def delete
    ifdef darwin || linux
      File.delete(@path)
    elsif windows
      0
    end
  end

  # ditto
  def unlink
    delete
  end
end
