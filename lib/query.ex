defmodule PhoenixHelpers.Query do
  @moduledoc """

  """

  @max_page_size 1000
  @default_page_size 100

  defstruct available_includes: [],
            includes: nil,
            available_filters: [],
            filters: [],
            available_sort_fields: [],
            sort_fields: [],
            max_page_size: @max_page_size,
            default_page_size: @default_page_size,
            page: nil,
            q: nil

  @type t :: %__MODULE__{
          available_includes: [binary] | nil,
          includes: [atom] | nil,
          available_filters: [binary] | nil,
          filters: keyword,
          available_sort_fields: [binary] | nil,
          sort_fields: keyword,
          max_page_size: integer,
          default_page_size: integer,
          page: %{number: integer, size: integer} | nil,
          q: nil
        }

  @spec new(list, list, list, integer | nil, integer | nil) :: %__MODULE__{}
  def new(
        includes \\ [],
        filters \\ [],
        sort_fields \\ [],
        default_page_size \\ nil,
        max_page_size \\ nil
      ) do
    fields = [
      available_includes: includes,
      available_filters: filters,
      available_sort_fields: sort_fields,
      default_page_size: default_page_size || @default_page_size,
      max_page_size: max_page_size || @max_page_size
    ]

    struct!(__MODULE__, fields)
  end
end
