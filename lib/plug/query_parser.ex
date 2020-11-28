defmodule PhoenixHelpers.Plug.QueryParser do
  @moduledoc """
  A Plug for parsing include, filter, page and q.

  To use it, add it to your controller.

      plug PhoenixHelpers.Plug.QueryParser,
        include: ~w(posts comments)
        filter: ~w(name)

  The plug will add a `PhoenixHelpers.Query` struct called `phoenix_helper_query` to your conn.assigns

  ## Options

  * `include` - list or map by action of a available includes. Default is `[]`.
  * `filter` - list a available filter. Default is `[]`.
  * `default_page_number`

  """
  @behaviour Plug

  import Plug.Conn
  alias PhoenixHelpers.Query

  @include_separator "."

  @spec init(keyword) :: PhoenixHelpers.Query.t()
  def init(opts) do
    Query.new(
      Keyword.get(opts, :include),
      Keyword.get(opts, :filter),
      Keyword.get(opts, :default_page_size),
      Keyword.get(opts, :max_page_size)
    )
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, %Query{} = query) do
    query_params =
      conn
      |> fetch_query_params()
      |> Map.get(:query_params)

    phoenix_helper_query =
      query
      |> Map.put(:includes, parse_include(query, Map.get(query_params, "include")))
      |> Map.put(:filters, parse_filter(query, Map.get(query_params, "filter")))
      |> Map.put(:page, parse_page(query, Map.get(query_params, "page")))
      |> Map.put(:q, Map.get(query_params, "q"))

    conn
    |> assign(:phoenix_helper_query, phoenix_helper_query)
  end

  defp parse_include(%Query{}, nil), do: nil

  defp parse_include(%Query{available_includes: available_includes}, include)
       when is_map(available_includes) do
    available_includes
    |> Enum.map(&{elem(&1, 0), parse_include(elem(&1, 1), include)})
    |> Enum.into(%{})
  end

  defp parse_include(%Query{available_includes: available_includes}, include)
       when is_list(available_includes) do
    parse_include(available_includes, include)
  end

  defp parse_include(available_includes, include) when is_list(available_includes) do
    include
    |> List.wrap()
    |> Enum.uniq()
    |> Enum.filter(&(&1 in available_includes))
    |> dedup_includes(@include_separator)
    |> split_string_to_atoms(@include_separator)
    |> most_nested_first()
    |> Enum.reduce([], fn includes, acc ->
      acc |> build_includes(includes)
    end)
    |> to_ecto_preload_format()
    |> List.wrap()
  end

  defp parse_filter(%Query{available_filters: available_filters}, filter)
       when is_map(available_filters) and is_map(filter) do
    available_filters
    |> Enum.map(&{elem(&1, 0), parse_filter(elem(&1, 1), filter)})
    |> Enum.into(%{})
  end

  defp parse_filter(%Query{available_filters: available_filters}, filter)
       when is_list(available_filters) and is_map(filter) do
    parse_filter(available_filters, filter)
  end

  defp parse_filter(%Query{} = query, _), do: parse_filter(query, %{})

  defp parse_filter(available_filters, filter) do
    filter
    |> Enum.filter(fn {key, _} -> key in available_filters end)
    |> Enum.uniq_by(fn {key, _} -> key end)
    |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
  end

  defp parse_page(%Query{} = query, nil), do: parse_page(query, %{})

  defp parse_page(
         %Query{default_page_size: default_page_size, max_page_size: max_page_size},
         page
       ) do
    number = page |> Map.get("number") |> to_integer(1)
    size = page |> Map.get("size") |> to_integer(default_page_size)
    size = if size > max_page_size, do: max_page_size, else: size

    %{number: number, size: size}
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

  defp most_nested_first(includes) do
    includes |> Enum.sort_by(&length/1, &(&1 >= &2))
  end

  _ = """
  Split string or list of string by a separator and convert the result to a list of atoms
  Returns a list.

  ## Examples

      iex> PhoenixHelpers.Plug.QueryParser.split_string_to_atoms(["b", "a.b"], ".")
      [[:b], [:a, :b]]

  """

  defp split_string_to_atoms(binaries, separator) when is_list(binaries) do
    binaries
    |> Enum.map(&split_string_to_atoms(&1, separator))
  end

  defp split_string_to_atoms(binary, separator) when is_binary(separator) do
    binary
    |> String.split(separator)
    |> Enum.map(&String.to_existing_atom(&1))
  end

  _ = """
  Remove parent of nested includes
  Returns a list without the parent includes.

  ## Examples


      iex> PhoenixHelpers.Plug.QueryParser.dedup_includes(["a.b", "a", "a.c"], ".")
      ["a.b", "a.c"]

  """

  defp dedup_includes(includes, separator)
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

  defp to_ecto_preload_format({key, []}), do: key

  defp to_ecto_preload_format({key, [value]}) when is_atom(value), do: {key, value}

  defp to_ecto_preload_format({key, value}), do: {key, to_ecto_preload_format(value)}

  defp to_ecto_preload_format([value]), do: to_ecto_preload_format(value)

  defp to_ecto_preload_format(list) when is_list(list),
    do: list |> Enum.map(&to_ecto_preload_format/1)

  defp to_ecto_preload_format(value), do: value
end
