require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "normalizes name to stripped downcase" do
    assert_equal "my-new-tag", Tag.create!(name: "  My-New-Tag  ").name
  end

  test "validates name presence" do
    tag = Tag.new(name: "")
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "validates name uniqueness" do
    Tag.create!(name: "unique-tag")
    assert_not Tag.new(name: "unique-tag").valid?
  end

  test "uniqueness is case-insensitive due to normalization" do
    Tag.create!(name: "Capitalized")
    assert_not Tag.new(name: "capitalized").valid?
  end

  test "search matches partial name" do
    assert_includes Tag.search("log"), tags(:login)
    assert_not_includes Tag.search("log"), tags(:regressao)
  end

  test "search returns empty for no match" do
    assert_empty Tag.search("nonexistent")
  end
end
