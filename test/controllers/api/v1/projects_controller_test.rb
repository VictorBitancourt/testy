require "test_helper"

class Api::V1::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:main)
  end

  test "index without token returns 401" do
    api_get "/api/v1/projects", token: nil

    assert_response :unauthorized
  end

  test "index lists projects by name with counts" do
    Project.create!(name: "Aardvark")

    api_get "/api/v1/projects"

    assert_response :ok
    names = json_response["projects"].map { |p| p["name"] }
    assert_equal names.sort_by(&:downcase), names
    main = json_response["projects"].find { |p| p["id"] == @project.id }
    assert_equal @project.test_plans.count, main["test_plans_count"]
    assert_equal @project.bugs.open_bugs.count, main["open_bugs_count"]
  end

  test "show returns a project" do
    api_get "/api/v1/projects/#{@project.id}"

    assert_response :ok
    assert_equal "Main App", json_response["project"]["name"]
  end

  test "show unknown project returns 404" do
    api_get "/api/v1/projects/999999"

    assert_response :not_found
  end

  test "create makes a project owned by the token user" do
    assert_difference "Project.count", 1 do
      api_post "/api/v1/projects", params: { project: { name: "Mobile App", description: "iOS and Android" } }, token: USER_TOKEN
    end

    assert_response :created
    assert_equal "Mobile App", json_response["project"]["name"]
    assert_equal users(:regular_user).id, Project.find(json_response["project"]["id"]).user_id
  end

  test "create with a taken name returns 422" do
    api_post "/api/v1/projects", params: { project: { name: "main app" } }

    assert_response :unprocessable_entity
    assert json_response["errors"].any?
  end
end
