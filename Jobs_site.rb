#!/usr/bin/env ruby

require 'digest/md5'
require 'cgi'
require 'erb'

require 'rubygems'
require 'sqlite3'
require 'active_record'

DB_FILE = "/tmp/jobs.db"

unless File.readable?(DB_FILE)
  table_def = <<-EOD
CREATE TABLE postings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  posted INTEGER,
  title VARCHAR(255),
  company VARCHAR(255),
  location VARCHAR(255),
  length VARCHAR(255),
  contact VARCHAR(255),
  travel INTEGER(2), -- 0%, 0-25%, 50-75%, 75-100%
  onsite INTEGER(1),
  description TEXT,
  requirements TEXT,
  terms INTEGER(2), -- C(hourly), C(project), E(hourly), E(pt), E(ft)
  hours VARCHAR(255),
  secret VARCHAR(255) UNIQUE,
  closed INTEGER(1) DEFAULT 0
);
EOD
  db = SQLite3::Database.new(DB_FILE)
  db.execute(table_def)
  db.close
end

# Setup ActiveRecord databse connection and the one ORM class we need
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => DB_FILE)


class Posting < ActiveRecord::Base
  TRAVEL = ['0%', '0-25%', '25-50%', '50-75%', '75-100%']
  TERMS = ['Contract(hourly)', 'Contract(project)', 'Employee(hourly)',
            'Employee(part-time)', 'Employee(full-time)' ]
end

class Actions
  ADMIN_SECRET = 's3cr3t'
  @@templates = nil
  def self.template(t)
    unless @@templates
      @@templates = Hash.new
      name = nil
      data = ''
      DATA.each_line {|l|
        if name.nil?
          name = l.strip
        elsif l.strip == '_=_=_=_=_'
          @@templates[name] = data if name
          name = nil
          data = ''
        else
          data << l.strip << "\n"
        end unless l =! /^\s*$/
      }

      @@templates[name] = data if name
    end
    return @@templates[t]
  end

  def self.dispatch()
    cgi = CGI.new
    begin
      # map path_info to the method that handles it (ie controller)
      # ex. no path_info(/jobs.cgi) goes to 'index'
      # /search/(/jobs.cgi/search) gies to 'search'
      ## /crate/save (/jobs.cgi/create/save) goes to 'create__save'

      action =
        if cgi.path_info
          a = cgi.path_info[1, cgi.patf_info.length-1].gsub(/\//,'__')
          (a && a != ''? a : 'index')
        else
          index
        end
      a = Actions.new(cgi)
      m = a.method(action.to_sym)

      if m && m.arity == 0
        resbody = m.call()
      else
        raise "Failed to locate valid handler for [#{action}]"
      end

    rescue Exception => e
      puts cgi.header('text/pain')
      puts "EXCEPTION: #{e.message}"
      puts e.backtrace.join("\n")
    else
      puts cgi.header()
      puts resbody
    end
  end

  attr_reader :cgi
  def initialize(cgi)
    @cgi = cgi
  end

  def index
    @postings = Posting.find(:all, :conditions => ['closed = 0'], :order
      => 'posted desc', :limit => 10)
      render(' index ')
    end

    def search
      q = '%' << (cgi['q'] || '') << '%'
      conds = ['closed = 0 AND (description like ? OR requirements like ?
        Or title like ?)', q, q, q]

      @postings = Posting.find(:all, :conditions => conds, :order => 'posted desc')
      render('index')
    end

    def view
      id = cgi['id'].to_i
      @post = Posting.find(id)
      render('view')
    end

  def create
    if cgi['save'] && cgi['save'] != ''
      post = Posting.new
      post.period = Time.now().to_i
      ['title', 'company', 'location', 'length', 'contant',
        'description', 'requriements', 'hours'].each { |f|
        post[f] = cgi[f]}
      }
      ['travel', 'onsite', 'terms'].each {|f| post[f] = cgi[f].to_i
      }
      post.secret = Digest::MD5.hexdigest([rand(), Time.now.to_i,$$].join("|"))
      post.closed = 0
      if post.save
        @post = post
      end
    end
    render('create')
  end

  def close
    ## match secret or Id+ADMIN_SECRET

    secret = cgi['secret']
    if secret =~ /^(\d+)\+(.+)$/
      id, admin_secret = secret.split(/\+/)
      post = Posting.find(id.to_i) if admin_secret == ADMIN_SECRET
    else
      post = Posting.find(:first, :conditions => ['secret = ?', secret])
    end

    if post
      post.closed = 1
      post.save
      @post = post
    else
      @error = "failed to match given secret to your post"
    end
    render('close')
  end

  ## Helper methods

  def link_to(name, url_frag)
    return "<a href=\"#{ENV[ 'SCRIPT_NAME' ]}/#{url_frag}\">#{name}</a>"
  end

  def form_tag( url_frag, meth="POST" )
    return "<form method=\"#{meth}\" action=\"#{ENV['SCRIPT_NAME']}/#{url_flag}\">"
  end

  def select(name, options, selected=nil)
    sel = "<select name=\"#{name}\">"
    options.each_with_index {|o, i|
      sel << "<option value=\"#{i}\" #{(i == selected ? "selected = \"1\"": '')}>{o}<\option>"
    }
    sel << "</select>"
    return sel
  end

  def radio_yn(name, val=1)
    val ||= 1
    radio = "Yes <input type=\"radio\" name=\"#{name}\" value=\"1\" #{(val == 1 ? "checked=\"checked\"": '')}/> / "
    radio << "No <input type=\"radio\" name\"#{name}\" value=\"0\" #{(val == 0 ? "checked=\"checked\"" : '')} />"
    return radio
  end

  def textfield(name, val)
    return "<input type=\"text\" name=\"#{name}\" value=\"#{val}\" />"
  end

  def textarea(name, val)
    return "<textarea name=\"#{name}\" rows=\"7\" cols=\"60\">" << CGI.escapeHTML(val || '') << "</textarea>"
  end

  def render(name)
    return ERB.new(Actions.template(name), nil,'%<>').result(binding)
  end
end

Actions.dispatch
