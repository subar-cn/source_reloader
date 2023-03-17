require 'sketchup.rb'
require 'extensions.rb'

module SourceReloader
  unless file_loaded?(__FILE__)
    file_loaded(__FILE__)

    loader = File.join('source_reloader', 'reloader')
    ex = SketchupExtension.new("source_reloader", loader)
    ex.description = '源码自动重载工具'
    ex.version = "1.0"
    ex.copyright = 'SUAPP © 2023'
    ex.creator = 'SUAPP'

    Sketchup.register_extension(ex, true)
  end
end
