defmodule Nested.PetsSchema do
  use Absinthe.Schema

  object :person do
    field :name, :string do
      resolve(fn _, _, _ -> {:ok, "Name"} end)
    end

    field :dogs, non_null(list_of(:dog)) do
      fn _, _, _ -> {:ok, [%{name: "Miki"}, %{name: "Crusher"}]} end
    end
  end

  object :cat do
    field(:name, :string)
    field(:favorite_toy, :string)
    field(:weight, :integer)
  end

  object :dog do
    field :name, :string do
      resolve(fn _, _, _ -> {:ok, "Miki"} end)
    end

    field :person, :person, name: "owner" do
      resolve(fn _, _, _ ->
        {:ok, %{name: "Name"}}
      end)
    end
  end

  query do
    field :person, :person do
      arg(:name, :string)
    end

    field :dog, :dog do
      arg(:name, :string)
    end
  end
end

defmodule Assertions.AbsintheTest do
  alias Nested.PetsSchema

  use Assertions.AbsintheCase, async: true, schema: PetsSchema

  doctest Assertions.Absinthe

  describe "fields_for/1" do
    test "returns all fields for a single type" do
      assert_lists_equal(fields_for(:cat), [:__typename, :favorite_toy, :name, :weight])
    end

    test "returns a tuple for object child types, default nesting of 3" do
      expected = [
        {:owner, [:name, {:dogs, [:name, :__typename]}, :__typename]},
        :name,
        :__typename
      ]

      assert_lists_equal(fields_for(:dog), expected)
    end
  end

  describe "fields_for/2" do
    test "allows you to set the level of nesting of child types" do
      expected = [
        :name,
        {:dogs, [
          :name,
          :__typename
        ]},
        :__typename
      ]

      assert_lists_equal(fields_for(:person, 2), expected)

      expected = [
        {:owner, [
           :name,
           {:dogs, [
             {:owner, [
               :name,
               {:dogs, [
                 :name,
                 :__typename
               ]},
               :__typename
             ]},
             :name,
             :__typename
           ]},
           :__typename
         ]},
        :name,
        :__typename
      ]

      assert_lists_equal(fields_for(:dog, 5), expected)
    end
  end

  describe "document_for/1" do
    test "returns a properly formatted document that can be used as a query" do
      expected = """
      cat {
        weight
        name
        favoriteToy
        __typename
      }
      """

      assert document_for(:cat) == expected
    end
  end

  describe "document_for/2" do
    test "allows the user to set the level of nesting" do
      expected = """
      dog {
        owner {
          name
          dogs {
            owner {
              name
              __typename
            }
            name
            __typename
          }
          __typename
        }
        name
        __typename
      }
      """

      assert document_for(:dog, 4) == expected
    end
  end

  describe "assert_response_equals/3" do
    @describetag :skip
    test "passes when it should" do
      query = """
        {
          dog {
            name
            owner {
              name
              dogs {
                name
                owner {
                  name
                }
              }
            }
          }
        }
      """

      expected_response = %{
        "dog" => %{
          "name" => "Miki",
          "owner" => %{
            "name" => "Name",
            "dogs" => [
              %{
                "name" => "Miki",
                "owner" => %{
                  "name" => "Name"
                }
              },
              %{
                "name" => "Crusher",
                "owner" => %{
                  "name" => "Name"
                }
              }
            ]
          }
        }
      }

      assert query == expected_response

      # assert_response_equals(query, expected_response)
    end

    test "fails when it should"
  end

  describe "assert_response_matches/3" do
    @describetag :skip
    test "passes when it should"
    test "fails when it should"
  end
end
