defmodule PhoenixHelpers.Plug.QueryParser do
  @moduledoc """

  """
  @behaviour Plug

  import Plug.Conn
  alias PhoenixHelpers.Query

  @include_separator "."

  @spec init(keyword) :: PhoenixHelpers.Query.t()
  def init(opts) do
    %Query{
      available_includes: Keyword.get(opts, :include)
    }
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, %Query{} = query) do
    params =
      conn
      |> fetch_query_params()
      |> Map.get(:query_params)

    phoenix_helper_query =
      query
      |> put_includes(params)
      |> put_filters(params)

    conn
    |> assign(:phoenix_helper_query, phoenix_helper_query)
  end

  defp put_includes(%Query{} = query, %{} = params) do
    includes = parse_include(query, Map.get(params, "include"))

    Map.put(query, :includes, includes)
  end

  defp put_filters(%Query{} = query, %{} = params) do
    filters = parse_filter(query, Map.get(params, "filter"))

    Map.put(query, :filters, filters)
  end

  defp parse_include(%Query{}, nil), do: nil
  defp parse_include(%Query{available_includes: []}, _query_param_include), do: []

  defp parse_include(%Query{available_includes: available_includes}, query_param_include) do
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

  defp parse_filter(%Query{}, ""), do: []
  defp parse_filter(%Query{}, nil), do: []

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

  defp parse_filter(%Query{}, _), do: []

  defp parse_filter(available_filters, filter) do
    filter
    |> Enum.filter(fn {key, _} -> key in available_filters end)
    |> Enum.uniq_by(fn {key, _} -> key end)
    |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
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

      iex> PhoenixHelpers.Plug.QueryParser.dedup_includes(["a.b", "a", "a.c"], ".")
      ["a.b", "a.c"]

  """
  @spec dedup_includes([binary], binary) :: [binary]
  def dedup_includes(includes, separator)
      when is_list(includes) and is_binary(separator) do
    includes
    |> Enum.sort(:desc)
    |> Enum.reduce([], fn include, acc ->
      if Enum.any?(acc, &String.starts_with?(&1, include <> separator)) do
        acc
      else
        [include | acc]
      end
    end)
  end
end
