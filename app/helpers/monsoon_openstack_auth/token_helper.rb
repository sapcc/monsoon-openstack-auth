module MonsoonOpenstackAuth
  module TokenHelper

    def self.included(base)
      base.send :helper_method,:dump_openstack_token
    end

    def dump_openstack_token
      return unless session
      token = session[MonsoonOpenstackAuth::SessionStore::SESSION_NAME]
      if token && token.is_a?(Hash)
        content = render partial: "layouts/monsoon_openstack_auth/token_debug", locals:{token:token}

        content.is_a?(Array) ? content.first : content # Not quite sure why this is returning an array in some rails versions, but check just in case
      end
    end

  end
end