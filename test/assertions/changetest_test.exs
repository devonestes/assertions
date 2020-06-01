defmodule Assertions.ChangesetTest do
  use Assertions.Case, async: true

  import Assertions.Changeset

  alias Ecto.Changeset

  doctest Assertions.Changeset

  describe "assert_changeset_invalid/3" do
    test "does not fail for invalid changesets with an error on the right key" do
      changeset = %{valid?: false, errors: [name: "invalid"]}
      assert_changeset_invalid(changeset, :name)
    end
  end
end
