<<<<<<< HEAD
require "c/sys/stat"
=======
require "time"

lib LibC
  ifdef darwin
    struct Stat
      st_dev : Int32
      st_ino : Int32
      st_mode : LibC::ModeT
      st_nlink : UInt16
      st_uid : UInt32
      st_gid : UInt32
      st_rdev : Int32
      st_atimespec : LibC::TimeSpec
      st_mtimespec : LibC::TimeSpec
      st_ctimespec : LibC::TimeSpec
      st_size : Int64
      st_blocks : Int64
      st_blksize : Int32
      st_flags : UInt32
      st_gen : UInt32
      st_lspare : Int32
      st_qspare1 : Int64
      st_qspare2 : Int64
    end
  elsif linux
    ifdef x86_64
      struct Stat
        st_dev : UInt64
        st_ino : UInt64
        st_nlink : UInt64
        st_mode : LibC::ModeT
        st_uid : UInt32
        st_gid : UInt32
        __pad0 : UInt32
        st_rdev : UInt32
        st_size : Int64
        st_blksize : Int64
        st_blocks : Int64
        st_atimespec : LibC::TimeSpec
        st_mtimespec : LibC::TimeSpec
        st_ctimespec : LibC::TimeSpec
        __unused0 : Int64
        __unused1 : Int64
        __unused2 : Int64
      end
    else
      struct Stat
        st_dev : UInt64
        __pad1 : UInt16
        st_ino : UInt32
        st_mode : LibC::ModeT
        st_nlink : UInt32
        st_uid : UInt32
        st_gid : UInt32
        st_rdev : UInt64
        __pad2 : Int16
        st_size : UInt32
        st_blksize : Int32
        st_blocks : Int32
        st_atimespec : LibC::TimeSpec
        st_mtimespec : LibC::TimeSpec
        st_ctimespec : LibC::TimeSpec
        __unused4 : UInt64
        __unused5 : UInt64
      end
    end
  elsif windows
    struct Stat
      st_dev : UInt32
      st_ino : UInt16
      st_mode : LibC::ModeT
      st_nlink : Int16
      st_uid : Int16
      st_gid : Int16
      st_rdev : UInt32
      st_size : Int64
      st_blksize : Int32
      st_blocks : Int32
      st_atimespec : LibC::TimeSpec
      st_mtimespec : LibC::TimeSpec
      st_ctimespec : LibC::TimeSpec
    end
  end

  ifdef darwin || linux
    S_ISVTX  = 0001000
    S_ISGID  = 0002000
    S_ISUID  = 0004000
    S_IFBLK  = 0060000
    S_IFLNK  = 0120000
    S_IFSOCK = 0140000
  end

  S_IFIFO  = 0010000
  S_IFCHR  = 0020000
  S_IFDIR  = 0040000
  S_IFREG  = 0100000
  S_IFMT   = 0170000

  ifdef darwin || linux
    fun stat(path : UInt8*, stat : Stat*) : Int32
    fun lstat(path : UInt8*, stat : Stat*) : Int32
    fun fstat(fileno : Int32, stat : Stat*) : Int32
  elsif windows
    fun wstat = _wstat64(path : UInt16*, stat : Stat*) : Int32
    fun fstat = _fstat64(fileno : Int32, stat : Stat*) : Int32
  end
end
>>>>>>> refs/remotes/origin/windows

class File
  struct Stat
    def initialize(filename : String)
      ifdef darwin || linux
        status = LibC.stat(filename, out @stat)
      elsif windows
        status = LibC.wstat(filename.to_utf16, out @stat)
      end
      if status != 0
        raise Errno.new("Unable to get stat for '#{filename}'")
      end
    end

    def initialize(@stat : LibC::Stat)
    end

    def atime
      ifdef darwin
        time @stat.st_atimespec
      else
        time @stat.st_atim
      end
    end

    def blksize
      @stat.st_blksize
    end

    def blocks
      @stat.st_blocks
    end

    def ctime
      ifdef darwin
        time @stat.st_ctimespec
      else
        time @stat.st_ctim
      end
    end

    def dev
      @stat.st_dev
    end

    def gid
      @stat.st_gid
    end

    def ino
      @stat.st_ino
    end

    def mode
      @stat.st_mode
    end

    # permission bits of mode
    def perm
      mode & 0o7777
    end

    def mtime
      ifdef darwin
        time @stat.st_mtimespec
      else
        time @stat.st_mtim
      end
    end

    def nlink
      @stat.st_nlink
    end

    def rdev
      @stat.st_rdev
    end

    def size
      @stat.st_size.to_u64
    end

    def uid
      @stat.st_uid
    end

    def inspect(io)
      io << "#<File::Stat"
      io << " dev=0x"
      dev.to_s(16, io)
      io << ", ino=" << ino
      io << ", mode=0"
      mode.to_s(8, io)
      io << ", nlink=" << nlink
      io << ", uid=" << uid
      io << ", gid=" << gid
      io << ", rdev=0x"
      rdev.to_s(16, io)
      io << ", size=" << size
      io << ", blksize=" << blksize
      io << ", blocks=" << blocks
      io << ", atime=" << atime
      io << ", mtime=" << mtime
      io << ", ctime=" << ctime
      io << ">"
    end

    def blockdev?
      ifdef darwin || linux
        (@stat.st_mode & LibC::S_IFMT) == LibC::S_IFBLK
      elsif windows
        false
      end
    end

    def chardev?
      (@stat.st_mode & LibC::S_IFMT) == LibC::S_IFCHR
    end

    def directory?
      (@stat.st_mode & LibC::S_IFMT) == LibC::S_IFDIR
    end

    def file?
      (@stat.st_mode & LibC::S_IFMT) == LibC::S_IFREG
    end

    def setuid?
      ifdef darwin || linux
        (@stat.st_mode & LibC::S_IFMT) == LibC::S_ISUID
      elsif windows
        false
      end
    end

    def setgid?
      ifdef darwin || linux
        (@stat.st_mode & LibC::S_IFMT) == LibC::S_ISGID
      elsif windows
        false
      end
    end

    def symlink?
      (@stat.st_mode & LibC::S_IFMT) == LibC::S_IFLNK
    end

    def socket?
      ifdef darwin || linux
        (@stat.st_mode & LibC::S_IFMT) == LibC::S_IFSOCK
      elsif windows
        false
      end
    end

    def sticky?
      ifdef darwin || linux
        (@stat.st_mode & LibC::S_IFMT) == LibC::S_ISVTX
      elsif windows
        false
      end
    end

    private def time(value)
      Time.new value, Time::Kind::Utc
    end
  end
end
