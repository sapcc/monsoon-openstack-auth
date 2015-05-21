require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should get terms" do
    get :terms
    assert_response :success
  end

  test "should get register" do
    get :register
    assert_response :success
  end

end
