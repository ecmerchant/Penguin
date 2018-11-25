require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get setup" do
    get accounts_setup_url
    assert_response :success
  end

end
