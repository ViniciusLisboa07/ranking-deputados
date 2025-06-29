require "test_helper"

class Api::DespesasControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_despesas_index_url
    assert_response :success
  end

  test "should get show" do
    get api_despesas_show_url
    assert_response :success
  end
end
