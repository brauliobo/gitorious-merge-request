class Gitorious::MergeRequest

  attr_accessor :repo, :id
  attr_accessor :proposal, :summary
  attr_accessor :merge_base_sha, :ending_commit

  def self.list repo, status="Open"
    page = $mech.get Gitorious::MRListUrl % {:repo => repo, :status => status}
    page.parser.xpath('//merge-request').map do |node|
      mr = self.new
      mr.id = node.at("id").content
      mr.summary = node.at("summary").content
      mr.proposal = node.at("proposal").content
      mr.merge_base_sha =  node.xpath('//versions/version').last.at('merge_base_sha').content
      mr
    end
  end

  def self.delete repo, id
    page = $mech.get Gitorious::MRUrl % {:repo => repo, :id => id}
    form = page.form_with :action => "/#{repo}/merge_requests/#{id}"
    page = form.submit
  end

  def self.create attrs = {}
    @summary = attrs[:summary]
    @proposal = attrs[:proposal]
    @forked_repo = attrs[:forked_repo]
    @forked_branch = attrs[:forked_branch]
    @target_repo = attrs[:target_repo]
    @target_branch = attrs[:target_branch]

    forked_repo = @forked_repo.split('/')[1,2].join('/')
    target_repo = @target_repo.split('/').last

    page = $mech.get Gitorious::NewMRUrl % {:forked_repo => forked_repo}
    form = page.form_with :id => 'new_merge_request'

    form.set_fields 'merge_request[summary]' => @summary
    form.set_fields 'merge_request[proposal]' => @proposal

    @authenticity_token = form.fields.find{ |f| f.name == 'authenticity_token' }.value

    target_option = page.parser.css('#merge_request_target_repository_id option').find{ |o| o.text == target_repo }
    raise "Can't find target repository" unless target_option
    target_id = target_option['value']
    form.set_fields 'merge_request[target_repository_id]' => target_id

    target_branch_option = page.parser.css("#merge_request_target_branch option[value=#{@target_branch}]").first
    raise "Can't find target branch" unless target_branch_option
    form.set_fields 'merge_request[target_branch]' => @target_branch

    forked_branch_option = page.parser.css("#merge_request_source_branch option[value=#{@forked_branch}]").first
    raise "Can't find forked branch" unless forked_branch_option
    form.set_fields 'merge_request[source_branch]' => @forked_branch

    commit = self.select_ending_commit target_id
    form.add_field! 'merge_request[ending_commit]', commit

    page = form.submit
    raise "Error while creating merge request" if page.parser.css('.errorExplanation').first

    repo = @target_repo
    id = page.uri.to_s.split('/').last
    mr = self.new repo, id
  end

  def initialize repo, id
    page = Nokogiri::HTML $mech.get(Gitorious::MRUrl % {:repo => repo, :id => id}).content
    self.repo = repo
    self.id = id
    self.summary = page.at("summary").content
    self.proposal = page.at("proposal").content
    username = page.at("username").content
    self.target_repo = page.at('target_repository/name').content
    self.target_branch = page.at('target_repository/branch').content
    self.ending_commit = page.at("ending-commit").content
    version = page.xpath('//versions/version').last
    self.merge_base_sha = version.at('merge_base_sha').content if version
  end

  def checkout
    `git checkout -b merge-requests/#{id} #{self.merge_base_sha}`
    `git pull #{git.remote} refs/merge-requests/#{self.id}`
  end

  def diff
    `git diff #{self.merge_base_sha}`
  end

  def to_s
    "#{id}: #{summary.lines.first}"
  end

  protected

  def self.select_ending_commit target_id
    forked_repo = @forked_repo.split('/')[1,2].join('/')

    puts "Selecting last commit"
    page = $mech.post Gitorious::CommitListUrl % {:forked_repo => forked_repo}, {
      'authenticity_token' => @authenticity_token,
      'merge_request[target_repository_id]' => target_id,
      'merge_request[target_branch]' => @target_branch,
      'merge_request[source_branch]' => @forked_branch}

      # TODO: give option to select
      first_commit = page.parser.css('#commit_0 input').first
      raise 'No commit to merge' unless first_commit
      first_commit['value']
  end

end
