require 'pathname'
require 'singleton'

module SourceReloader
  class Reloader
    include Singleton

    attr_reader :cache, :mtimes

    def initialize
      @cache, @mtimes = {}, {}
    end

    def reload!(stderr = $stderr)
      rotation do |file, mtime|
        previous_mtime = mtimes[file] ||= mtime
        safe_load(file, mtime, stderr) if mtime > previous_mtime
      end
    end

    def mute_warnings
      old_verbose, $VERBOSE = $VERBOSE, nil
      yield if block_given?
    ensure
      $VERBOSE = old_verbose
    end

    # A safe Kernel::load, issuing the hooks depending on the results
    def safe_load(file, mtime, stderr = $stderr)
      mute_warnings { load(file) }
      stderr.send(:puts, "[#{Time.now.strftime('%F %T')}] 文件更新: #{file}")
    rescue TypeError => ex
      stderr.send(:puts, ex)
      if (class_name = ex.message[/superclass mismatch for class (\w+)/, 1])
        prefix = ex.backtrace.map { |s| s[/`<module:(\w+)>'$/, 1] }.compact.reverse.join('::')
        full_name = [prefix, class_name].join('::')
        if ::Object.const_defined?(full_name)
          ::Object.const_get(prefix).send(:remove_const, class_name)
          stderr.send(:puts, "[#{Time.now.strftime('%F %T')}] 强制更新: #{file}")
          retry
        end
      end
    rescue LoadError, SyntaxError => ex
      stderr.send(:puts, ex)
    ensure
      mtimes[file] = mtime
    end

    def rotation
      files = [$0, *$LOADED_FEATURES].uniq
      paths = ['./', *$LOAD_PATH].uniq

      files.map { |file|
        next if /\.(so|bundle)$/.match?(file) # cannot reload compiled files

        found, stat = figure_path(file, paths)
        next unless found && stat && mtime = stat.mtime

        cache[file] = found
        yield(found, mtime)
      }.compact
    end

    def figure_path(file, paths)
      if !(found = cache[file]) && Pathname.new(file).absolute?
        found = file
      end

      found, stat = safe_stat(found)
      return found, stat if found

      paths.find do |possible_path|
        path = ::File.join(possible_path, file)
        next unless File.exist?(path)

        found, stat = safe_stat(path)
        return ::File.expand_path(found), stat if found
      end

      [false, false]
    end

    def safe_stat(file)
      if file && (stat = ::File.stat(file)).file?
        [file, stat]
      end
    rescue Errno::ENOENT, Errno::ENOTDIR, Errno::ESRCH, Errno::EINVAL
      $LOADED_FEATURES.delete(file)
      cache.delete(file)
      false
    end
  end

  module_function

  def toggle!
    if $reloader_timer_id.nil?
      $reloader_timer_id = UI.start_timer(2, true) { Reloader.instance.reload! }
      puts "[#{Time.now.strftime('%F %T')}] 源码自动重载已开启！"
    else
      quit!
    end
  end

  def quit!
    unless $reloader_timer_id.nil?
      UI.stop_timer($reloader_timer_id)
      puts "[#{Time.now.strftime('%F %T')}] 源码自动重载已关闭！"
      $reloader_timer_id = nil
    end
  end
end

class ReloaderObserver < Sketchup::AppObserver
  def onExtensionsLoaded
    SourceReloader.toggle!
  end

  def onQuit()
    SourceReloader.quit!
  end

  def onUnloadExtension(extension_name)
    SourceReloader.quit! if extension_name == '源码自动重载'
  end
end

unless file_loaded?(__FILE__)
  Sketchup.add_observer(ReloaderObserver.new)

  toolbar = UI::Toolbar.new('源码自动重载')
  toolbar.add_item UI::Command.new('开启/关闭') { SourceReloader.toggle! }.tap { |cmd|
    cmd.tooltip = '开启/关闭源码自动重载'
    cmd.large_icon = cmd.small_icon = File.join(__dir__, "Resources/code.#{Sketchup.platform == :platform_osx ? 'pdf' : 'svg'}")
  }

  file_loaded(__FILE__)
end
