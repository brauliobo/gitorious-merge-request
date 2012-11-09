require 'rubygems'

require 'mechanize'
require 'trollop'
require 'active_support/all'
require 'highline/import'

require File.expand_path('./gitorious-merge-request/version', File.dirname(__FILE__))

module GitoriousMergeRequest

  MRUrl = "https://gitorious.org/%{repo}/merge_requests/%{id}"
  NewMRUrl = "https://gitorious.org/%{forked_repo}/merge_requests/new"
  CommitListUrl = "https://gitorious.org/%{forked_repo}/merge_requests/commit_list"

  def login opts
    @email = opts[:email]

    password = ask('Password:'){ |q| q.echo = false }

    puts 'Login...'
    page = @mechanize.get 'https://gitorious.org/login'
    form = page.forms.first
    fields = form.fields
    fields.find{ |f| f.name == 'email' }.value = @email
    fields.find{ |f| f.name == 'password' }.value = password
    page = form.submit

    raise "Can't login" unless page.content.include?('Logged in successfully')
  end

  def cmd_new opts
    login_dies opts
    Trollop::die :summary, "must exist" unless opts[:summary]
    Trollop::die :forked, "must exist" unless opts[:forked_repo]
    Trollop::die :forked_branch, "must exist" unless opts[:forked_branch]
    Trollop::die :target, "must exist" unless opts[:target_repo]
    Trollop::die :target_branch, "must exist" unless opts[:target_branch]

    @summary = opts[:summary]
    @proposal = opts[:proposal]
    @forked_repo = opts[:forked_repo]
    @forked_branch = opts[:forked_branch]
    @target_repo = opts[:target_repo]
    @target_branch = opts[:target_branch]

    def ending_commit(target_id)
      forked_repo = @forked_repo.split('/')[1,2].join('/')

      puts "Selecting last commit"
      page = @mechanize.post CommitListUrl % {:forked_repo => forked_repo}, {
        'authenticity_token' => @authenticity_token,
        'merge_request[target_repository_id]' => target_id,
        'merge_request[target_branch]' => @target_branch,
        'merge_request[source_branch]' => @forked_branch}

        # TODO: give option to select
        first_commit = page.parser.css('#commit_0 input').first
        raise 'No commit to merge' unless first_commit
        first_commit.attr 'value'
    end

    def merge_request
      forked_repo = @forked_repo.split('/')[1,2].join('/')
      target_repo = @target_repo.split('/').last

      puts "Opening merge request page"
      page = @mechanize.get NewMRUrl % {:forked_repo => forked_repo}
      form = page.form_with :id => 'new_merge_request'

      form.set_fields 'merge_request[summary]' => @summary
      form.set_fields 'merge_request[proposal]' => @proposal

      @authenticity_token = form.fields.find{ |f| f.name == 'authenticity_token' }.value

      target_option = page.parser.css('#merge_request_target_repository_id option').find{ |o| o.text == target_repo }
      raise "Can't find target repository" unless target_option
      target_id = target_option.attr('value')
      form.set_fields 'merge_request[target_repository_id]' => target_id

      target_branch_option = page.parser.css("#merge_request_target_branch option[value=#{@target_branch}]").first
      raise "Can't find target branch" unless target_branch_option
      form.set_fields 'merge_request[target_branch]' => @target_branch

      forked_branch_option = page.parser.css("#merge_request_source_branch option[value=#{@forked_branch}]").first
      raise "Can't find forked branch" unless forked_branch_option
      form.set_fields 'merge_request[source_branch]' => @forked_branch

      commit = ending_commit target_id
      form.add_field! 'merge_request[ending_commit]', commit

      page = form.submit
      raise "Error while creating merge request" if page.parser.css('.errorExplanation').first

      puts "YOUR NEW MERGE REQUEST\n"
      cmd_show_for page
    end

    @mechanize = Mechanize.new
    login opts
    merge_request
  end

  def parse_code opts
    @code = opts[:code]

    raise "can't parse code" unless @code =~ /(.+):(\d+)/
    repo = $1
    id = $2.to_i

    [repo, id]
  end

  def cmd_rm opts
    login_dies opts
    code_dies opts

    repo, id = parse_code opts

    @mechanize = Mechanize.new
    login opts
    page = @mechanize.get MRUrl % {:repo => repo, :id => id}
    form = page.form_with :action => "/#{repo}/merge_requests/#{id}"
    page = form.submit
  end

  def cmd_show opts
    code_dies opts

    repo, id = parse_code opts

    @mechanize = Mechanize.new
    page = @mechanize.get MRUrl % {:repo => repo, :id => id}

    cmd_show_for page
  end

  def cmd_show_for page
    raise "can't grab summary" unless page.parser.css('#content h1').first.text.strip =~ /[^#]+ #(\d+): (.+)/
      id, summary = $1, $2
    proposal = page.parser.css('.proposal').first.text.strip

    lis = page.parser.css('ul.meta li')
    raise "can't get meta content" if lis.empty?

    a = lis[0].css('a').last
    requester = "#{a.text.strip} (http://gitorious.org#{a.attr('href')})"

    puts <<-EOS
Requester: #{requester}

ID: #{id}
Summary: #{summary}
Proposal:
#{proposal}

EOS
  end

end

