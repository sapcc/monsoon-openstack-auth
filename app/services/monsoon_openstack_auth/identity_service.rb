module MonsoonOpenstackAuth
  class IdentityService < MonsoonOpenstackAuth::OpenstackServiceProvider::Fog
    
    def driver(auth_params)
      Fog::IdentityV3::OpenStack.new(auth_params)
    end
    
    # admin connection to identity
    def api_connection
      @api_connection ||= MonsoonOpenstackAuth.api_client(@region).connection_driver.connection
    end
    
    # TODO: implement pagination
    def user_domains(options={per_page: 30, page: 1})     
      user = api_connection.users.find_by_id(@current_user.id)
      projects = user.projects if user
      if projects
        projects.collect{|project| project["domain"] || { "name" => project["domain_id"], "id" => project["domain_id"] }  }.uniq
      else
        []
      end
    end

    def domain(domain_id)
      api_connection.domains.find_by_id(domain_id)
    end

    # TODO: implement pagination
    def domain_projects(domain_id)    
      user = api_connection.users.find_by_id(@current_user.id)
      projects = []
      user.projects.each {|project| projects<<OpenStruct.new(project) if project['domain_id']==domain_id}  
      return projects
    end

    def project(project_id)
      api_connection.projects.find_by_id(project_id) 
    end
    
  end
end