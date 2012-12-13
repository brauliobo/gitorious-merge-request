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

  def login opts
    Trollop::die :email, "must exist" unless opts[:email]
    email = opts[:email]
    password = ask('Password: '){ |q| q.echo = false }

    puts 'Login...'
    Gitorious.login email, password
  end

  def cmd_new opts
    opts[:forked_branch] ||= Git.current_branch

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
    id = nil if id.zero?
    if id or code.blank?
      repo = $origin_repo
    else
      raise 'Invalid code format' unless code =~ /(.+):(\d+)/
      repo_or_remote, id = $1, $2.to_i
      repo = if (remote = Gitorious.remote_to_repo(repo_or_remote))
               then remote else repo_or_remote end
    end
    [repo, id]
  end

  def cmd_rm opts
    repo, id = parse_code opts[:code]
    login opts
    Gitorious::MergeRequest.delete repo, id
  end

  def cmd_show opts
    repo, id = parse_code opts[:code]
    mr = Gitorious::MergeRequest.new repo, id
    show mr
  end

  def cmd_list opts
    repo, id = parse_code opts[:code]
    status = opts[:status] || ''
    list = Gitorious::MergeRequest.list repo, status
    list.each do |mr|
      puts "#{mr.id} from #{mr.username}: #{mr.summary}"
    end
  end

  def cmd_checkout opts
    repo, id = parse_code opts[:code]
    mr = Gitorious::MergeRequest.new repo, id
    mr.checkout
  end

  def cmd_diff opts
    repo, id = parse_code opts[:code]
    mr = Gitorious::MergeRequest.new repo, id
    mr.diff
  end

  def show mr
#Requester: #{mr.requester}
    puts <<-EOS
ID: #{mr.id} (#{Gitorious::MRUrl % {:repo => mr.target_repo, :id => mr.id}})
User: #{mr.username} (#{Gitorious::Host}/#{mr.username})
Summary: #{mr.summary}
Proposal:
#{mr.proposal}

Fork: branch #{mr.forked_branch} of #{mr.forked_repo}  (#{Gitorious::Host}/#{mr.forked_repo})
Target: branch #{mr.target_branch} of #{mr.target_repo} (#{Gitorious::Host}/#{mr.target_repo})
Ending commit: #{mr.ending_commit}
Merge base SHA: #{mr.merge_base_sha}

EOS
  end

end

