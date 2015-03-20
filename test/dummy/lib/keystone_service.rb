class KeystoneService  
  def initialize(keystoneclient)
    @client = keystoneclient
  end
  
  def user_domains(username,options={per_page: 30, page: 1})
    users = @client.users.find_by_name(username)
    projects = users.first.projects if users and users.length>0
    if projects
      projects.collect{|project| project["domain"]}.uniq
    else
      []
    end
  end
  
  def domain(domain_id)
    @client.domains.find_by_id(domain_id)
  end
  
  def domain_projects(domain_id)
    @client.projects.all(domain_id:domain_id) 
  end
  
  def project(project_id)
    @client.projects.find_by_id(project_id) 
  end
end