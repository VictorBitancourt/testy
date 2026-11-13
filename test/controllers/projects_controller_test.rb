require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    @other = Project.create!(name: "Mobile App", user: users(:regular_user))
    @other_plan = @other.test_plans.create!(name: "Mobile Login", qa_name: "QA", user: users(:regular_user))
    @other_bug = @other.bugs.create!(title: "App crashes", description: "D", user: users(:regular_user), cause_tag: "memory")
  end

  test "root lists the projects" do
    get root_path

    assert_response :success
    assert_select ".project-card__name", text: "Main App"
    assert_select ".project-card__name", text: "Mobile App"
  end

  test "with several projects and none chosen, plans ask for a project" do
    get test_plans_path

    assert_redirected_to projects_path
  end

  test "opening a project shows only its plans" do
    get project_path(@other)
    assert_redirected_to test_plans_path

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Mobile Login"
    assert_not_includes response.body, test_plans(:login_plan).name
    assert_select ".topbar__project", text: /Mobile App/
  end

  test "bugs, root causes and new plans belong to the current project" do
    get project_path(@other)

    get bugs_path
    assert_includes response.body, "App crashes"
    assert_not_includes response.body, bugs(:open_bug).title

    get bug_root_causes_path
    assert_includes response.body, "memory"
    assert_not_includes response.body, ">ui<"

    post test_plans_path, params: { test_plan: { name: "Push", qa_name: "QA" } }
    assert_equal @other, TestPlan.find_by!(name: "Push").project

    post bugs_path, params: { bug: { title: "Push fails", description: "D" } }
    assert_equal @other, Bug.find_by!(title: "Push fails").project
  end

  test "opening a plan of another project switches to it" do
    get project_path(@other)

    get test_plan_path(test_plans(:login_plan))
    assert_select ".topbar__project", text: /Main App/

    get test_plans_path
    assert_includes response.body, test_plans(:login_plan).name
  end

  test "create a project and start in it" do
    post projects_path, params: { project: { name: "  Portal   do Cliente ", description: "Web" } }

    project = Project.find_by!(name: "Portal do Cliente")
    assert_equal users(:admin), project.user
    assert_redirected_to test_plans_path
    follow_redirect!
    assert_select ".topbar__project", text: /Portal do Cliente/
  end

  test "names are unique" do
    post projects_path, params: { project: { name: "main app" } }

    assert_response :unprocessable_entity
  end

  test "edit and delete need the owner or an admin" do
    logout_and_sign_in_as users(:regular_user)

    patch project_path(projects(:main)), params: { project: { name: "Hijacked" } }
    assert_redirected_to root_path
    assert_equal "Main App", projects(:main).reload.name

    patch project_path(@other), params: { project: { name: "Mobile" } }
    assert_equal "Mobile", @other.reload.name
  end

  test "deleting a project deletes its plans and bugs" do
    assert_difference -> { TestPlan.count } => -1, -> { Bug.count } => -1 do
      delete project_path(@other)
    end
    assert_redirected_to projects_path
  end

  test "Bug Jar button is red" do
    get project_path(projects(:main))
    follow_redirect!

    assert_select "a.btn--danger[href=?]", bugs_path
  end

  test "W shortcut on the topbar opens the projects page" do
    get project_path(projects(:main))
    follow_redirect!

    assert_select "a.topbar__project[href=?][data-keyboard-shortcut-key-value=w]", projects_path do
      assert_select ".kbd", "W"
    end
  end
end
