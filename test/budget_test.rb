# budget_test.rb

ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../budget"

class BudgetTest < Minitest::Test
  include Rack::Test::Methods

  ## Begin Helper methods ################
  def app
    Sinatra::Application
  end

  ## Begin Tests ########################
  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "At-a-glance"
  end

  def test_add_item
    get "/new"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "Enter the category"
  end

  def test_get_tools
    get "/tools"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "Tools"
  end

  def test_edit
    get "/edit/education"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "Edit 'education' category:"
  end

  def test_post_item_added
    
  end
end
