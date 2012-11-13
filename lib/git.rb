# inspired from https://gitorious.org/gitorious/merge-request-cli
class Git

  attr_reader :remote

  def initialize remote = "origin"
    @remote = remote
  end

  def url
    output = `git remote -v`.scan(/^#{remote}\s+(.*).git(.*)/)
    output.first[0] if output
  end

end

