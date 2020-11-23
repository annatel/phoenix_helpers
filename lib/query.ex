defmodule PhoenixHelpers.Query do
  @moduledoc """

  """

  @max_page_size 1000
  @default_page_size 100

  defstruct available_includes: [],
            includes: nil,
            available_filters: [],
            filters: [],
            max_page_size: @max_page_size,
            default_page_size: @default_page_size,
            page: nil,
            q: nil

  @type t :: %__MODULE__{
          available_includes: [binary] | nil,
          includes: [atom] | nil,
          available_filters: [binary] | nil,
          filters: keyword,
          max_page_size: integer,
          default_page_size: integer,
          page: %{number: integer, size: integer} | nil,
          q: nil
        }
end
