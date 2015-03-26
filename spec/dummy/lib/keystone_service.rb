class KeystoneService  
  def initialize(keystoneclient)
    @client = keystoneclient
    @connection = @client.connection
  end
  
  def user_domains(username,options={per_page: 30, page: 1})    
    users = @connection.users.find_by_name(username)
    projects = users.first.projects if users and users.length>0
    if projects
      projects.collect{|project| project["domain"] || { "name" => project["domain_id"], "id" => project["domain_id"] }  }.uniq
    else
      []
    end
  end
  
  def domain(domain_id)
    @connection.domains.find_by_id(domain_id)
  end
  
  def domain_projects(domain_id)
    @connection.projects.all(domain_id:domain_id) 
  end
  
  def project(project_id)
    @connection.projects.find_by_id(project_id) 
  end
end