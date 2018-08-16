def service_main
  begin
    @s.mount_proc("/yaml") { |req, res| res['content-type'] = 'text/plain'
      res.body << Gem::Cache.from_installed_gems(File.join(gem.dir, "specifications")).to_yaml
    }

  rescue Exception => e
    File.open(@logfile, 'w+'){ |f| f.puts "Start failed: #{e}"}
    service_stop
  end

  begin
    @s.mount_proc("/"){ |req, res|
      specs = []
      specifications_dir = File.join(Gem.dir, "specifications")
      Gem::Cache.from_installed_gems(specifications_dir).each do |path, spec|
        specs << {
          "name" => spec.name,
          "version" => spec.version,
          "full_name" => spec.full_name,
          "summary" => spec.summary,
          "rdoc_installed" => Gem::DocManager.new(spec).rdoc_installed?,
          "doc_path" => ('/doc_root' + spec.full_name + '/rdoc/index.html')
        }
      end
      specs = specs.sort_by{ |spec| [spec["name"].downcase, spec["version"]]}
      template = TemplatePage.new(DOC_TEMPLATE)
      res['content-type'] = 'text/html'
      template.write_html_on(res.body, {"specs" => specs})
  }

  rescue Exception => e
    File.open(@logfile, 'w+'){ |f| f.puts "Start failed: #{e}"}
    service_stop
  end

  begin
    {"/gems" => "/cache/", "/doc_root" => "/doc/"}.each do |mount_point, mount_dir|
      @s.mount(mount_point, WEBrick::HTTPServlet::FileHandler, File.join(Gem.dir, mount_dir), true)
    end

  rescue Exception => e
    File.open(@logfile, 'w+'){ |f| f.puts "Start failed: #{e}"}
    service_stop
  end

  begin
    @s.start
  rescue Exception => e
    File.open(@logfile, 'w+'){|f| f.puts "Start failed: #{e}"}
    service_stop
  end
end

puts <<-EOF

Refactoring1 : Merge Redundant EXception Handlers /YOu have a series of exception
handling blocks with identical handlers./
*Merge the code into a single exception handling block.*

Thus:
  begin
    foo
  rescue Exception => e
    barf e
  end
  begin
    bar
  rescue Exception => e
    barf e
  end

Becomes:
  begin
    foo
    bar
  rescue Exception => e
    barf e
  end

Refactoring 2: Remove Unused Scope
/You have a begin... end block that introduces a scope that is unused./
  *Remove the unused scope.*

  Thus:

    def foo
      begin
        bar
      rescue
        baz
      end
    end

  Becomes:
    def foo
      bar
    rescue
      baz
    end

  Here is the Refactored code:
EOF

def service_main
  @s.mount_proc("/yaml") { |req, res| res['content-type'] = 'text/plain'
    res.body << Gem::Cache.from_installed_gems(File.join(Gem.dir, "specifications")).to_yaml
  }

  @s.mount_proc("/") { |req, res|
    specs = []
    specifications_dir = File.join(Gem.dir, "specifications")
    Gem::Cache.from_installed_gems(specifications_dir).each do
      |path, spec|
      specs << {
        "name" => spec.name,
        "version" => spec.version,
        "full_name" => spec.full_name,
        "summary" => spec.summary,
        "rdoc_installed" => Gem::DocManager.new(spec).rdoc_installed?,
        "doc_path" => ('/doc_root/' + spec.full_name + '/rdoc/index.html')

      }
    end

    specs = specs.sort_by { |sepc| [spec["name"].downcase, spec["version"]] }
    template = TemplatePage.new(DOC_TEMPLATE)
    res['content-type'] = 'text/html'
    template.write_html_on(res.body, {"spec" => specs})
  }

  ("/gems" => "/cache/", "/doc_root" => "/doc/").each do |mount_point, mount_dir|
    @s.mount(mount_point, WEBrick::HTTPServlet::FileHandler, File.join(Gem.dir, mount_dir), true)
  end

  @s.start
rescue Exception => e
  File.open(@logfile, 'w+'){ |f| f.puts "Start failed: #{e}"}
  service_stop
end
