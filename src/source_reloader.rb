require 'sketchup.rb'
require 'extensions.rb'

module SourceReloader
  unless file_loaded?(__FILE__)
    file_loaded(__FILE__)

    loader = File.join('source_reloader', 'reloader')
    ex = SketchupExtension.new("源码自动重载", loader)
    ex.description = '用于本机插件开发过程中，自动重新加载有过修改的文件。'
    ex.version = "1.0"
    ex.copyright = 'SUAPP © 2023'
    ex.creator = 'SUAPP'

    Sketchup.register_extension(ex, true)
  end
end
