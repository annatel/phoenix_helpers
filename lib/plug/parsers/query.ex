defmodule PhoenixHelpers.Plug.Parsers.QueryParser do
  @moduledoc """

  """
  @behaviour Plug

  import Plug.Conn

  @include_separator "."
  @default_page_size 100

  defstruct available_includes: [],
            includes: nil,
            default_page_size: @default_page_size,
            page: nil,
            q: nil

  @type t :: %__MODULE__{
          available_includes: [binary] | nil,
          includes: [atom] | nil,
          default_page_size: integer,
          page: %{number: integer, size: integer} | nil
        }

  @spec init(keyword) :: PhoenixHelpers.Plug.Parsers.QueryParser.t()
  def init(opts) do
    %__MODULE__{
      available_includes: Keyword.get(opts, :include)
    }
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, %__MODULE__{} = query_parser) do
    query_params =
      conn
      |> fetch_query_params()
      |> Map.get(:query_params)

    query_param_include = Map.get(query_params, "include")
    includes = parse_include(query_parser, query_param_include)

    query_param_page = Map.get(query_params, "page")
    page = parse_page(query_parser, query_param_page)

    query_param_query = Map.get(query_params, "q")

    query_parser =
      query_parser
      |> Map.put(:includes, includes)
      |> Map.put(:page, page)
      |> Map.put(:q, query_param_query)

    conn
    |> assign(:query_parser, query_parser)
  end

  defp parse_page(%__MODULE__{} = query_parser, nil), do: parse_page(query_parser, %{})

  defp parse_page(%__MODULE__{default_page_size: default_page_size}, page) do
    number = page |> Map.get("number") |> to_integer(1)
    size = page |> Map.get("size") |> to_integer(default_page_size)

    %{number: number, size: size}
  end

  defp to_integer(nil, default_value) when is_integer(default_value),
    do: default_value

  defp to_integer(string, default_value) when is_integer(default_value) do
    string
    |> Integer.parse()
    |> case do
      :error -> default_value
      {integer, _} -> integer
    end
  end

  defp parse_include(%__MODULE__{}, nil), do: nil
  defp parse_include(%__MODULE__{available_includes: []}, _query_param_include), do: []

  defp parse_include(%__MODULE__{available_includes: available_includes}, query_param_include) do
    query_param_include
    |> List.wrap()
    |> Enum.uniq()
    |> Enum.filter(&(&1 in available_includes))
    |> dedup_includes(@include_separator)
    |> Enum.map(&String.split(&1, @include_separator))
    |> Enum.reduce([], fn includes, acc ->
      acc ++ [includes |> Enum.map(&String.to_existing_atom(&1))]
    end)
    |> Enum.sort_by(&length/1, :desc)
    |> Enum.reduce([], fn includes, acc ->
      acc |> build_includes(includes)
    end)
    |> Enum.map(fn
      {key, []} -> key
      value -> value
    end)
  end

  defp build_includes(keyword, []), do: keyword

  defp build_includes(keyword, [key | [value]]) do
    current_value = Keyword.get(keyword, key, [])
    Keyword.put(keyword, key, [value | current_value])
  end

  defp build_includes(keyword, [key | keys]) do
    value = Keyword.get(keyword, key, [])
    Keyword.put(keyword, key, build_includes(value, keys))
  end

  @doc """
  Remove parent of nested includes

  Returns a list without the parent includes.

  ## Examples

      iex> PhoenixHelpers.Plug.Parsers.QueryParser.dedup_includes(["a.b", "a", "a.c"], ".")
      ["a.b", "a.c"]

  """
  @spec dedup_includes([binary], binary) :: [binary]
  def dedup_includes(includes, separator)
      when is_list(includes) and is_binary(separator) do
    includes
    |> Enum.sort(&(&1 >= &2))
    |> Enum.reduce([], fn include, acc ->
      if Enum.any?(acc, &String.starts_with?(&1, include <> separator)) do
        acc
      else
        [include | acc]
      end
    end)
  end
end
