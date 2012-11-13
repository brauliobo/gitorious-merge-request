require 'rubygems'

require 'mechanize'
require 'trollop'
require 'active_support/all'
require 'highline/import'
require 'i18n/core_ext/string/interpolate'

require File.expand_path('./gitorious_merge_request/version', File.dirname(__FILE__))
require File.expand_path('./git', File.dirname(__FILE__))
require File.expand_path('./gitorious', File.dirname(__FILE__))
require File.expand_path('./gitorious/merge_request', File.dirname(__FILE__))

class GitoriousMergeRequest

  def initialize
  end

  def login opts
    login_dies opts
    email = opts[:email]
    password = ask('Password: '){ |q| q.echo = false }

    puts 'Login...'
    Gitorious.new.login email, password
  end

  def cmd_new opts
    Trollop::die :summary, "must exist" unless opts[:summary]
    Trollop::die :forked, "must exist" unless opts[:forked_repo]
    Trollop::die :forked_branch, "must exist" unless opts[:forked_branch]
    Trollop::die :target, "must exist" unless opts[:target_repo]
    Trollop::die :target_branch, "must exist" unless opts[:target_branch]

    login opts
    puts "Opening merge request page"
    mr = Gitorious::MergeRequest.create opts
    puts "YOUR NEW MERGE REQUEST\n"
    show mr
  end

  def parse_code code
    id = Integer(code) rescue nil
    if id
      git = Git.new 'origin'
      pp git.url
    else
      if code =~ /(.+):(\d+)/
        repo, id = $1, $2.to_i
      else
        repo = code
      end
    end

    [repo, id]
  end

  def cmd_rm opts
    login_dies opts
    code_dies opts
    repo, id = parse_code opts[:code]

    login opts
    Gitorious::MergeRequest.delete repo, id
  end

  def cmd_show opts
    code_dies opts
    repo, id = parse_code opts[:code]

    mr = Gitorious::MergeRequest.new repo, id
    show mr
  end

  def cmd_list opts
    code_dies opts
    repo, id = parse_code opts[:code]
    status = opts[:status] || ''

    list = Gitorious::MergeRequest.list repo, status
    list.each do |mr|
      show mr
    end
  end

  def cmd_checkout opts
  end

  def cmd_diff opts
  end

  def show mr
#Requester: #{mr.requester}
    puts <<-EOS
ID: #{mr.id}
Summary: #{mr.summary}
Proposal:
#{mr.proposal}

Ending commit: #{mr.ending_commit}
Merge base SHA: #{mr.merge_base_sha}

EOS
  end

end

