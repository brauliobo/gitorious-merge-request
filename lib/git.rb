# inspired from https://gitorious.org/gitorious/merge-request-cli
class Git

  def self.remote_url remote='origin'
    output = `git remote -v`.scan(/^#{remote}\s+(.*.git)(.*)/)
    output.first[0] if output
  end

  def self.current_branch
    self.run('rev-parse', '--abbrev-ref HEAD', :quiet => true).squish
  end

  protected

  def self.method_missing method, *args, &block
    options = args.last
    a = args.first
    self.run method, a, options
  end

  def self.run cmd, args, options = {}
    cmdline = "git #{cmd} #{args}"
    if options[:quiet]
      `#{cmdline} 2>&1`
    else
      puts "$ #{cmdline}"
      system cmdline
    end
  end
end

