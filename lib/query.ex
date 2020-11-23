defmodule PhoenixHelpers.Query do
  @moduledoc """

  """

  @default_page_size 100

  defstruct available_includes: [],
            includes: nil,
            available_filters: [],
            filters: [],
            default_page_size: @default_page_size,
            page: nil,
            q: nil

  @type t :: %__MODULE__{
          available_includes: [binary] | nil,
          includes: [atom] | nil,
          available_filters: [binary] | nil,
          filters: keyword,
          default_page_size: integer,
          page: %{number: integer, size: integer} | nil,
          q: nil
        }
end
