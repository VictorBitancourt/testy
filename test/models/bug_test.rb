require "test_helper"

class BugTest < ActiveSupport::TestCase
  test "create" do
    bug = Bug.new(title: "New Bug", description: "Something broke", user: users(:admin))
    assert bug.valid?
  end

  test "validates title presence" do
    bug = Bug.new(description: "Something broke", user: users(:admin))
    assert_not bug.valid?
    assert_includes bug.errors[:title], "can't be blank"
  end

  test "validates description presence" do
    bug = Bug.new(title: "New Bug", user: users(:admin))
    assert_not bug.valid?
    assert_includes bug.errors[:description], "can't be blank"
  end

  test "validates status inclusion" do
    bug = Bug.new(title: "Bug", description: "Desc", user: users(:admin), status: "invalid")
    assert_not bug.valid?
    assert_includes bug.errors[:status], "is not included in the list"
  end

  test "default status is open" do
    bug = Bug.new
    assert_equal "open", bug.status
  end

  test "display_name" do
    bug = bugs(:open_bug)
    assert_equal "##{bug.id} - #{bug.title}", bug.display_name
  end

  test "resolved?" do
    assert bugs(:resolved_bug).resolved?
    assert_not bugs(:open_bug).resolved?
  end

  test "open?" do
    assert bugs(:open_bug).open?
    assert_not bugs(:resolved_bug).open?
  end

  test "dependent nullify on test_scenarios" do
    bug = bugs(:open_bug)
    scenario = test_scenarios(:login_failure)
    scenario.update!(bug: bug)

    bug.destroy

    assert_nil scenario.reload.bug_id
  end

  test "scope open_bugs" do
    results = Bug.open_bugs
    assert_includes results, bugs(:open_bug)
    assert_not_includes results, bugs(:resolved_bug)
  end

  test "scope resolved" do
    results = Bug.resolved
    assert_includes results, bugs(:resolved_bug)
    assert_not_includes results, bugs(:open_bug)
  end

  test "scope by_feature" do
    results = Bug.by_feature("checkout")
    assert_includes results, bugs(:open_bug)
    assert_not_includes results, bugs(:resolved_bug)
  end

  test "scope by_feature returns all when nil" do
    assert_equal Bug.count, Bug.by_feature(nil).count
  end

  test "scope by_cause" do
    results = Bug.by_cause("ui")
    assert_includes results, bugs(:open_bug)
    assert_not_includes results, bugs(:resolved_bug)
  end

  test "scope search by title" do
    results = Bug.search("Button")
    assert_includes results, bugs(:open_bug)
    assert_not_includes results, bugs(:resolved_bug)
  end

  test "scope search by description" do
    results = Bug.search("500 error")
    assert_includes results, bugs(:resolved_bug)
    assert_not_includes results, bugs(:open_bug)
  end

  test "scope search by id with hash prefix" do
    bug = bugs(:open_bug)
    results = Bug.search("##{bug.id}")
    assert_includes results, bug
  end

  test "scope search returns none for blank" do
    assert_empty Bug.search("")
  end

  test "scope created_from" do
    assert_equal Bug.count, Bug.created_from(Time.zone.today).count
    assert_empty Bug.created_from(Time.zone.tomorrow)
  end

  test "scope created_until" do
    assert_equal Bug.count, Bug.created_until(Time.zone.today).count
    assert_empty Bug.created_until(Time.zone.yesterday)
  end
end
