defmodule PhoenixHelpers.Query do
  @moduledoc """

  """
  defstruct available_includes: [],
            includes: nil,
            available_filters: [],
            filters: []

  @type t :: %__MODULE__{
          available_includes: [binary] | nil,
          includes: [atom] | nil,
          available_filters: [binary] | nil,
          filters: keyword
        }
end
