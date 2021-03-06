class Gitorious

  Host = "https://gitorious.org"
  MRListUrl = "#{Host}/%{repo}/merge_requests.xml?status=%{status}"
  MRUrl = "#{Host}/%{repo}/merge_requests/%{id}"
  MRUrlXml = "#{Host}/%{repo}/merge_requests/%{id}.xml"
  NewMRUrl = "#{Host}/%{forked_repo}/merge_requests/new"
  CommitListUrl = "#{Host}/%{forked_repo}/merge_requests/commit_list"

  def self.login email, password
    page = $mech.get 'https://gitorious.org/login'
    form = page.forms.first
    fields = form.fields
    fields.find{ |f| f.name == 'email' }.value = email
    fields.find{ |f| f.name == 'password' }.value = password
    page = form.submit

    raise "Can't login" unless page.content.include?('Logged in successfully')
    page
  end

  def self.remote_to_repo remote='origin'
    Git.remote_url(remote) =~ /gitorious\.org[\/:](.+).git/
    $1
  end

end
