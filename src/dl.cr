require "c/dlfcn"

module DL
<<<<<<< HEAD
  def self.dlopen(path, mode = LibC::RTLD_LAZY | LibC::RTLD_GLOBAL) : Void*
    LibC.dlopen(path, mode)
=======
  def self.dlopen(path, mode = LibDL::LAZY | LibDL::GLOBAL)
    ifdef darwin || linux
      LibDL.dlopen(path, mode)
    elsif windows
      puts "#-- dlopen(#{path})"
    end
>>>>>>> refs/remotes/origin/windows
  end
end
