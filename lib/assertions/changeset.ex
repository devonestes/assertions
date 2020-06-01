defmodule Assertions.Changeset do
  @doc """
  Asserts that the given changeset is invalid.
  """
  #@spec assert_changeset_invalid(map(), atom(), fun()) :: true | no_return()
  defmacro assert_changeset_invalid(changeset, field, comparison) do
    quote do
      case Assertions.Changeset.do_assert_changeset_invalid(unquote(changeset), unquote(field)) do
        :valid_changeset -> raise "valid_changeset"
        :valid_key -> raise "valid_key"
        :not_found -> raise "not_found"
        :error -> raise "error"
        error -> unquote(comparison).(error)
      end
    end
  end

  defmacro assert_changeset_invalid(changeset, field) do
    assert_changeset_invalid(changeset, field, fn _ -> :ok end)
  end

  @doc false
  def do_assert_changeset_invalid(%{valid?: false} = changeset, field) do
    if changeset.data |> Map.keys() |> Enum.member?(field) do
      check_error(changeset.errors, field)
    else
      :not_found
    end
  end

  def do_assert_changeset_invalid(%{valid?: _}, _) do
    :valid_changeset
  end

  def do_assert_changeset_invalid(changeset, _) do
    IO.inspect(changeset)
    :error
  end

  defp check_error(errors, field) do
    case Keyword.get(errors, field) do
      {_, _} = error -> error
      _ -> :valid_key
    end
  end
end
