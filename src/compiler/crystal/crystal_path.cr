require "./config"

module Crystal
  struct CrystalPath
    def self.default_path
      ENV["CRYSTAL_PATH"]? || Crystal::Config.path
    end

    def self.default_libs_path
      ENV["CRYSTAL_LIBS_PATH"]? || "/usr/local/lib/crystal"
    end

    @crystal_path : Array(String)
    @crystal_libs_path : Array(String)

    def initialize(path = CrystalPath.default_path, target_triple = LLVM.default_target_triple, libs_path = CrystalPath.default_libs_path)
      @crystal_path = path.split(':').reject &.empty?
      add_target_path(target_triple)

      @crystal_libs_path = libs_path.split(':').reject &.empty?
    end

    private def add_target_path(target_triple = LLVM.default_target_triple)
      triple = target_triple.split('-')
      triple.delete(triple[1]) if triple.size == 4 # skip vendor

      if %w(i386 i486 i586).includes?(triple[0])
        triple[0] = "i686"
      end

      target = if triple.any?(&.includes?("macosx"))
                 {triple[0], "macosx", "darwin"}.join('-')
               elsif triple.any?(&.includes?("freebsd"))
                 {triple[0], triple[1], "freebsd"}.join('-')
               else
                 triple.join('-')
               end

      @crystal_path.each do |path|
        _path = File.join(path, "lib_c", target)
        if Dir.exists?(_path)
          @crystal_path << _path unless @crystal_path.includes?(_path)
          return
        end
      end
    end

    def find(filename, relative_to = nil)
      relative_to = File.dirname(relative_to) if relative_to.is_a?(String)
      if filename.starts_with? '.'
        result = find_in_path_relative_to_dir(filename, relative_to)
      else
        result = find_in_crystal_path(filename, relative_to)
      end
      result = [result] if result.is_a?(String)
      result
    end

    def find_lib(filename, relative_to = nil)
      relative_to = File.dirname(relative_to) if relative_to.is_a?(String)
      if filename.starts_with? '.'
        result = find_lib_in_path_relative_to_dir(filename, relative_to)
      else
        result = find_lib_in_crystal_path(filename, relative_to)
      end
      result = [result] if result.is_a?(String)
      result
    end

    private def find_in_path_relative_to_dir(filename, relative_to, check_crystal_path = true)
      if relative_to.is_a?(String)
        # Check if it's a wildcard.
        if filename.ends_with?("/*") || (recursive = filename.ends_with?("/**"))
          filename_dir_index = filename.rindex('/').not_nil!
          filename_dir = filename[0..filename_dir_index]
          relative_dir = "#{relative_to}/#{filename_dir}"
          if File.exists?(relative_dir)
            files = [] of String
            gather_dir_files(relative_dir, files, recursive)
            return files
          end
        else
          relative_filename = "#{relative_to}/#{filename}"

          # Check if .cr file exists.
          relative_filename_cr = relative_filename.ends_with?(".cr") ? relative_filename : "#{relative_filename}.cr"
          if File.exists?(relative_filename_cr)
            return make_relative_unless_absolute relative_filename_cr
          end

          # If it's a directory, we check if a .cr file with a name the same as the
          # directory basename exists, and we require that one.
          if Dir.exists?(relative_filename)
            basename = File.basename(relative_filename)
            absolute_filename = make_relative_unless_absolute("#{relative_filename}/#{basename}.cr")
            if File.exists?(absolute_filename)
              return absolute_filename
            end
          end
        end
      end

      if check_crystal_path
        find_in_crystal_path filename, relative_to
      else
        nil
      end
    end

    private def find_lib_in_path_relative_to_dir(filename, relative_to, check_crystal_path = true)
      if relative_to.is_a?(String)
        # Check if it's a wildcard.
        if filename.ends_with?("/*") || (recursive = filename.ends_with?("/**"))
          filename_dir_index = filename.rindex('/').not_nil!
          filename_dir = filename[0..filename_dir_index]

          # Extracts the actual name of the directory 
          # which should be the same like the library searched for.
          filename_index = filename.rindex('/', filename_dir_index - 1).not_nil!
          filename = filename[filename_index..filename_dir_index]
          if filename.starts_with?("lib")
            filename = "lib" + filename
          end
          
          if filename.ends_with?(".so")
            filename += ".so"
          end

          relative_path = "#{relative_to}/#{filename_dir}/#{filename}"
          return relative_path if File.exists?(relative_path)
        else
          if filename.starts_with?("lib")
            filename = "lib" + filename
          end

          relative_filename = "#{relative_to}/#{filename}"

          # Check if .so file exists.
          relative_filename_so = relative_filename.ends_with?(".so") ? relative_filename : "#{relative_filename}.so"
          if File.exists?(relative_filename_so)
            return make_relative_unless_absolute relative_filename_so
          end
        end
      end

      if check_crystal_path
        find_lib_in_crystal_path filename, relative_to
      else
        nil
      end
    end

    private def gather_dir_files(dir, files_accumulator, recursive)
      files = [] of String
      dirs = [] of String

      Dir.foreach(dir) do |filename|
        full_name = "#{dir}/#{filename}"

        if File.directory?(full_name)
          if filename != "." && filename != ".." && recursive
            dirs << filename
          end
        else
          if filename.ends_with?(".cr")
            files << full_name
          end
        end
      end

      files.sort!
      dirs.sort!

      files.each do |file|
        files_accumulator << File.expand_path(file)
      end

      dirs.each do |subdir|
        gather_dir_files("#{dir}/#{subdir}", files_accumulator, recursive)
      end
    end

    private def make_relative_unless_absolute(filename)
      filename = "#{Dir.current}/#{filename}" unless filename.starts_with?('/')
      File.expand_path(filename)
    end

    private def find_in_crystal_path(filename, relative_to)
      @crystal_path.each do |path|
        required = find_in_path_relative_to_dir(filename, path, check_crystal_path: false)
        return required if required
      end

      if relative_to
        raise "can't find file '#{filename}' relative to '#{relative_to}'"
      else
        raise "can't find file '#{filename}'"
      end
    end

    private def find_lib_in_crystal_path(filename, relative_to)
      @crystal_libs_path.each do |path|
        library = find_lib_in_path_relative_to_dir(filename, path, check_crystal_path: false)
        return library if library
      end
    end
  end
end
