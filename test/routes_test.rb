require "test_helper"

class RouteTest < ActionDispatch::IntegrationTest
  test "root" do
    assert_recognizes({ controller: "test_plans", action: "index" }, "/")
  end

  test "test_plans resources" do
    assert_routing "/test_plans/new", { controller: "test_plans", action: "new" }
    assert_routing "/test_plans/1", { controller: "test_plans", action: "show", id: "1" }
    assert_routing "/test_plans/1/edit", { controller: "test_plans", action: "edit", id: "1" }
  end

  test "test_scenarios nested" do
    assert_recognizes({ controller: "test_scenarios", action: "create", test_plan_id: "1" }, { method: :post, path: "/test_plans/1/test_scenarios" })
  end

  test "ai_generation nested" do
    assert_recognizes({ controller: "test_plans/ai_generations", action: "create", test_plan_id: "1" }, { method: :post, path: "/test_plans/1/ai_generation" })
  end

  test "users resources" do
    assert_routing "/users", { controller: "users", action: "index" }
    assert_routing "/users/new", { controller: "users", action: "new" }
    assert_routing "/users/1/edit", { controller: "users", action: "edit", id: "1" }
  end

  test "session resource" do
    assert_routing "/session/new", { controller: "sessions", action: "new" }
    assert_routing({ method: :post, path: "/session" }, { controller: "sessions", action: "create" })
  end

  test "registration resource" do
    assert_routing "/registration/new", { controller: "registrations", action: "new" }
    assert_routing({ method: :post, path: "/registration" }, { controller: "registrations", action: "create" })
  end

  test "tags autocomplete" do
    assert_routing "/tags/autocomplete", { controller: "tags", action: "autocomplete" }
  end
end
