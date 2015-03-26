require 'spec_helper'

describe MonsoonIdentity::User do
  shared_examples_for "an user" do
    describe "initialize" do
      it "should create a new user object from token" do
        user = MonsoonIdentity::User.new(token)
        expect(user).not_to be(nil)
      end
    end
    
    context "User initialized" do
      let(:user) {user = MonsoonIdentity::User.new(token)}

      describe "id" do
        it "should return id" do
          expect(user.id).to eq(token["user"]["id"])
        end
      end

      describe "token" do
        it "should return token" do
          expect(user.token).to eq(token["value"])
        end
      end

      describe "name" do
        it "should return name" do
          expect(user.name).to eq(token["user"]["name"])
        end
      end

      describe "user_domain_id" do
        it "should return user domain id" do
          user_domain_id = begin token["user"]["domain"]["id"]; rescue; nil; end
          
          if user_domain_id
            expect(user.user_domain_id).to eq(user_domain_id)
          else
            new_user = MonsoonIdentity::User.new(token.merge({"user"=>{"domain"=>{"id" => "test"} } }))
            expect(new_user.user_domain_id).to eq("test")
          end
        end       
      end
      
      describe "user_domain_name" do
        it "should return user domain name" do
          user_domain_name = begin token["user"]["domain"]["name"]; rescue; nil; end
          
          if user_domain_name
            expect(user.user_domain_name).to eq(user_domain_name)
          else
            new_user = MonsoonIdentity::User.new(token.merge({"user"=>{"domain"=>{"name" => "test"} } }))
            expect(new_user.user_domain_name).to eq("test")
          end
        end       
      end    

      describe "domain_id" do
        it "should return domain_id" do
          domain_id = begin token["domain"]["id"]; rescue; nil; end
          
          if domain_id
            expect(user.domain_id).to eq(domain_id)
          else
            new_user = MonsoonIdentity::User.new(token.merge({"domain"=>{"id" => "test"} } ))
            expect(new_user.domain_id).to eq("test")
          end
        end
      end

      describe "domain_name" do
        it "should return domain_name" do
          domain_name = begin token["domain"]["name"]; rescue; nil; end
          
          if domain_name
            expect(user.domain_name).to eq(domain_name)
          else
            new_user = MonsoonIdentity::User.new(token.merge({"domain"=>{"name" => "test"} } ))
            expect(new_user.domain_name).to eq("test")
          end
        end
      end

      describe "project_id" do
        it "should return project_id" do
          project_id = begin token["project"]["id"]; rescue; nil; end
          
          if project_id
            expect(user.project_id).to eq(project_id)
          else
            new_user = MonsoonIdentity::User.new(token.merge({"project"=>{"id" => "test"} } ))
            expect(new_user.project_id).to eq("test")
          end
        end
      end

      describe "project_name" do
        it "should return project_name" do
          project_name = begin token["project"]["name"]; rescue; nil; end
          
          if project_name
            expect(user.project_name).to eq(project_name)
          else
            new_user = MonsoonIdentity::User.new(token.merge({"project"=>{"name" => "test"} } ))
            expect(new_user.project_name).to eq("test")
          end
        end
      end
      
      describe "project_domain_id" do
        it "should return project_id" do
          project_domain_id = begin token["project"]["domain"]["id"]; rescue; nil; end
          
          if project_domain_id
            expect(user.project_domain_id).to eq(project_domain_id)
          else
            new_user = MonsoonIdentity::User.new(token.merge({"project"=>{"id" => "test", "domain"=> {"id"=>"test"} } } ))
            expect(new_user.project_domain_id).to eq("test")
          end
        end
      end

      describe "project_domain_name" do
        it "should return project_name" do
          project_domain_name = begin token["project"]["domain"]["name"]; rescue; nil; end
          
          if project_domain_name
            expect(user.project_domain_name).to eq(project_domain_name)
          else
            new_user = MonsoonIdentity::User.new(token.merge({"project"=>{"name" => "test", "domain"=> {"name"=>"test"} } } ))
            expect(new_user.project_domain_name).to eq("test")
          end
        end
      end
      
      describe "project_scoped" do
        it "should return project_scoped" do
          project_scoped = begin token["project"]; rescue; nil; end
          
          if project_scoped
            expect(user.project_scoped).to eq(project_scoped)
          else
            new_user = MonsoonIdentity::User.new(token.merge({"project"=>{"name" => "test", "domain"=> {"name"=>"test"} } } ))
            expect(new_user.project_scoped).to eq({"name" => "test", "domain"=> {"name"=>"test"} })
          end
        end
      end
      
      #
      # describe "service_catalog" do
      #   it "should return service_catalog" do
      #     expect(user.service_catalog).to eq(token["domain"]["id"])
      #   end
      # end
      #
      # describe "roles" do
      #   it "should return roles" do
      #     expect(user.roles).to eq(token["domain"]["id"])
      #   end
      # end
      #
      # describe "endpoint" do
      #   it "should return endpoint" do
      #     expect(user.endpoint).to eq(token["domain"]["id"])
      #   end
      # end
      #
      # describe "enabled?" do
      #   it "should return enabled?" do
      #     expect(user.enabled?).to eq(token["domain"]["id"])
      #   end
      # end
      #
      # describe "projects" do
      #   it "should return projects" do
      #     expect(user.projects).to eq(token["domain"]["id"])
      #   end
      # end
      #
      # describe "region" do
      #   it "should return region" do
      #     expect(user.region).to eq(token["domain"]["id"])
      #   end
      # end
    end
  end
  
  context "Keystone" do
    it_should_behave_like "an user" do
      let(:token) { ApiStub.keystone_token }
    end
    
    # it_should_behave_like "an user" do
    #   let(:token) {
    #     api_params = Constants.keystone_api_params
    #     user_params = {id: 'ac33746004f1470b904e364d408cf42e', password:'openstack' }
    #
    #     api_connection = Fog::IdentityV3::OpenStack.new({
    #       openstack_region:   'europe',
    #       openstack_auth_url: api_params[:openstack_auth_url],
    #       openstack_userid:   api_params[:openstack_userid],
    #       openstack_api_key:  api_params[:openstack_api_key]
    #     })
    #
    #     auth = {auth:{identity: {methods: ["password"],password:{user:{id: user_params[:id],password: user_params[:password]}}}}}
    #     HashWithIndifferentAccess.new(api_connection.tokens.authenticate(auth).attributes)
    #   }
    # end
  end
  
  context "Authority" do
    it_should_behave_like "an user" do
      let(:token) { ApiStub.authority_token }
    end
    
    # it_should_behave_like "an user" do
    #   let(:token) {
    #     api_params = Constants.authority_api_params
    #     user_params = {id: 'test-user', password:'test' }
    #
    #     api_connection = Fog::IdentityV3::OpenStack.new({
    #       openstack_region:   'europe',
    #       openstack_auth_url: api_params[:openstack_auth_url],
    #       openstack_userid:   api_params[:openstack_userid],
    #       openstack_api_key:  api_params[:openstack_api_key]
    #     })
    #
    #     auth = {auth:{identity: {methods: ["password"],password:{user:{id: user_params[:id],password: user_params[:password]}}}}}
    #     HashWithIndifferentAccess.new(api_connection.tokens.authenticate(auth).attributes)
    #   }
    # end
  end
end
