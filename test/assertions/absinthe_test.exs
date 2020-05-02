defmodule Nested.PetsSchema do
  use Absinthe.Schema

  interface :pet do
    field(:name, :string)
    resolve_type(fn _, _ -> :dog end)
  end

  object :person do
    field :name, :string do
      resolve(fn _, _, _ -> {:ok, "Name"} end)
    end

    field :pets, non_null(list_of(:pet)) do
      resolve(fn _, _, _ -> {:ok, [%{}, %{}]} end)
    end
  end

  object :cat do
    interface(:pet)
    field(:name, :string)
    field(:favorite_toy, :string)
    field(:weight, :integer)
  end

  object :dog do
    interface(:pet)
    field :name, :string do
      resolve(fn _, _, _ -> {:ok, "Miki"} end)
    end

    field :person, :person, name: "owner" do
      resolve(fn _, _, _ -> {:ok, %{}} end)
    end
  end

  input_object :add_person_input do
    field(:name, :string)
  end

  query do
    field :person, :person do
      arg(:name, :string)
      resolve(fn _, _, _ -> {:ok, %{}} end)
    end

    field :dog, :dog do
      arg(:name, :string)
      resolve(fn _, _, _ -> {:ok, %{}} end)
    end
  end

  mutation do
    field :add_person, :person do
      arg(:input, :add_person_input)
      resolve(fn _, _, _ -> {:ok, %{}} end)
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
        {:owner, [:name, {:pets, [:name, :__typename]}, :__typename]},
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
        {:pets,
         [
           :name,
           :__typename
         ]},
        :__typename
      ]

      assert_lists_equal(fields_for(:person, 2), expected)

      expected = [
        {:owner,
         [
           :name,
           {:pets,
            [
              {:owner,
               [
                 :name,
                 {:pets,
                  [
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
        weight
        name
        favoriteToy
        __typename
      """

      assert document_for(:cat) == expected
    end
  end

  describe "document_for/2" do
    test "allows the user to set the level of nesting" do
      expected = """
        owner {
          pets {
            ...on Dog {
              owner {
                name
                __typename
              }
            }
            ...on Cat {
              weight
              favoriteToy
            }
            name
            __typename
          }
          name
          __typename
        }
        name
        __typename
      """

      assert document_for(:dog, 4) == expected
    end
  end

  describe "assert_response_equals/3" do
    test "passes when it should" do
      expected_response = %{
        "dog" => %{
          "name" => "Miki",
          "__typename" => "Dog",
          "owner" => %{
            "name" => "Name",
            "__typename" => "Person",
            "pets" => [
              %{
                "__typename" => "Dog",
                "name" => "Miki",
                "owner" => %{
                  "__typename" => "Person",
                  "name" => "Name"
                }
              },
              %{
                "__typename" => "Dog",
                "name" => "Miki",
                "owner" => %{
                  "__typename" => "Person",
                  "name" => "Name"
                }
              }
            ]
          }
        }
      }

      query = """
      {
        dog {
          #{document_for(:dog, 4)}
        }
      }
      """

      assert_response_equals(query, expected_response)
    end

    test "works with mutations when we need to pass variables and context" do
      expected_response = %{
        "addPerson" => %{
          "name" => "Name",
          "__typename" => "Person",
          "pets" => [
            %{
              "__typename" => "Dog",
              "name" => "Miki"
            },
            %{
              "__typename" => "Dog",
              "name" => "Miki"
            }
          ]
        }
      }

      mutation = """
      mutation AddPerson($input: AddPersonInput!) {
        addPerson(input: $input) {
          #{document_for(:person, 2)}
        }
      }
      """

      variables = %{
        "input" => %{
          "name" => "Person"
        }
      }

      assert_response_equals(mutation, expected_response, variables: variables, context: %{})
    end

    test "fails when it should" do
      expected_response = %{
        "dog" => %{
          "name" => "Miki",
          "owner" => %{
            "name" => "Name",
            "__typename" => "Person",
            "pets" => [
              %{
                "__typename" => "Dog",
                "name" => "Miki",
                "owner" => %{
                  "__typename" => "Person",
                  "name" => "Name"
                }
              },
              %{
                "__typename" => "Dog",
                "name" => "Miki",
                "owner" => %{
                  "__typename" => "Person",
                  "name" => "Name"
                }
              }
            ]
          }
        }
      }

      query = """
      {
        dog {
          #{document_for(:dog, 4)}
        }
      }
      """

      assert_response_equals(query, expected_response)
    rescue
      error in [ExUnit.AssertionError] ->
        assert error.left == %{
                 "dog" => %{
                   "name" => "Miki",
                   "owner" => %{
                     "__typename" => "Person",
                     "pets" => [
                       %{
                         "__typename" => "Dog",
                         "name" => "Miki",
                         "owner" => %{"__typename" => "Person", "name" => "Name"}
                       },
                       %{
                         "__typename" => "Dog",
                         "name" => "Miki",
                         "owner" => %{"__typename" => "Person", "name" => "Name"}
                       }
                     ],
                     "name" => "Name"
                   },
                   "__typename" => "Dog"
                 }
               }

        assert error.right == %{
                 "dog" => %{
                   "name" => "Miki",
                   "owner" => %{
                     "name" => "Name",
                     "__typename" => "Person",
                     "pets" => [
                       %{
                         "__typename" => "Dog",
                         "name" => "Miki",
                         "owner" => %{
                           "__typename" => "Person",
                           "name" => "Name"
                         }
                       },
                       %{
                         "__typename" => "Dog",
                         "name" => "Miki",
                         "owner" => %{
                           "__typename" => "Person",
                           "name" => "Name"
                         }
                       }
                     ]
                   }
                 }
               }

        #assert error.message == "Response did not match the expected response"

        #assert ~S/assert_response_equals("{\n#{document_for(:dog, 4)}\n}", expected_response)/ ==
                 #Macro.to_string(error.expr)
    end
  end

  describe "assert_response_matches/3" do
    test "binds variables outside of the scope of the match" do
      query = """
      {
        dog {
          #{document_for(:dog, 4)}
        }
      }
      """

      assert_response_matches(query, do: %{"dog" => dog})

      assert %{
               "name" => _,
               "__typename" => "Do" <> _,
               "owner" => %{
                 "name" => "Na" <> "me",
                 "__typename" => "Person",
                 "pets" => pets
               }
             } = dog

      assert [
               %{
                 "name" => "Miki",
                 "owner" => %{
                   "__typename" => "Person",
                   "name" => "Name"
                 }
               },
               %{
                 "owner" => %{
                   "__typename" => "Person",
                   "name" => "Name"
                 }
               }
             ] = pets
    end

    test "fails when it should" do
      query = """
      {
        dog {
          #{document_for(:dog, 4)}
        }
      }
      """

      dog_type = "Dog"

      assert_response_matches(query) do
        %{
          "dog" => %{
            "name" => ^dog_type,
            "__typename" => "Do" <> _,
            "owner" => %{
              "name" => "Na" <> "me",
              "__typename" => "Person",
              "pets" => [
                %{
                  "__typename" => ^dog_type,
                  "name" => "Miki",
                  "owner" => %{
                    "__typename" => "Person",
                    "name" => "Name"
                  }
                },
                %{
                  "__typename" => ^dog_type,
                  "owner" => %{
                    "__typename" => "Person",
                    "name" => "Name"
                  }
                }
              ]
            }
          }
        }
      end
    rescue
      error in [ExUnit.AssertionError] ->
        assert Macro.to_string(error.left) ==
                 ~s/%{\"dog\" => %{\"name\" => ^dog_type, \"__typename\" => \"Do\" <> _, \"owner\" => %{\"name\" => \"Na\" <> \"me\", \"__typename\" => \"Person\", \"pets\" => [%{\"__typename\" => ^dog_type, \"name\" => \"Miki\", \"owner\" => %{\"__typename\" => \"Person\", \"name\" => \"Name\"}}, %{\"__typename\" => ^dog_type, \"owner\" => %{\"__typename\" => \"Person\", \"name\" => \"Name\"}}]}}}/

        assert error.right == %{
                 "dog" => %{
                   "name" => "Miki",
                   "owner" => %{
                     "__typename" => "Person",
                     "pets" => [
                       %{
                         "__typename" => "Dog",
                         "name" => "Miki",
                         "owner" => %{"__typename" => "Person", "name" => "Name"}
                       },
                       %{
                         "__typename" => "Dog",
                         "name" => "Miki",
                         "owner" => %{"__typename" => "Person", "name" => "Name"}
                       }
                     ],
                     "name" => "Name"
                   },
                   "__typename" => "Dog"
                 }
               }

        #assert error.message == "Response did not match the expected response"

        #assert ~S/assert_response_matches(query)/ == Macro.to_string(error.expr)
    end
  end
end
