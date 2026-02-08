require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid tag" do
    tag = Tag.new(name: "performance")
    assert tag.valid?
  end

  test "invalid without name" do
    tag = Tag.new(name: "")
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "normalizes name to stripped downcase" do
    tag = Tag.create!(name: "  My-New-Tag  ")
    assert_equal "my-new-tag", tag.name
  end

  test "uniqueness of name" do
    Tag.create!(name: "unique-tag")
    duplicate = Tag.new(name: "unique-tag")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "uniqueness is case-insensitive due to normalization" do
    Tag.create!(name: "Capitalized")
    duplicate = Tag.new(name: "capitalized")
    assert_not duplicate.valid?
  end

  test "scope search matches partial name" do
    results = Tag.search("log")
    assert_includes results, tags(:login)
    assert_not_includes results, tags(:regressao)
  end

  test "scope search returns empty for no match" do
    results = Tag.search("nonexistent")
    assert_empty results
  end
end
