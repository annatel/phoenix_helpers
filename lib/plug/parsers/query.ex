defmodule PhoenixHelpers.Plug.Parsers.QueryParser do
  @moduledoc """

  """
  @behaviour Plug

  import Plug.Conn

  defstruct available_includes: [],
            includes: nil

  @type t :: %__MODULE__{
          available_includes: [binary] | nil,
          includes: [atom] | nil
        }

  @include_separator "."

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

    query_parser =
      query_parser
      |> Map.put(:includes, includes)

    conn
    |> assign(:query_parser, query_parser)
  end

  defp parse_include(%__MODULE__{}, nil), do: nil
  defp parse_include(%__MODULE__{available_includes: []}, _query_param_include), do: []

  defp parse_include(%__MODULE__{available_includes: available_includes}, query_param_include) do
    query_param_include
    |> List.wrap()
    |> Enum.uniq()
    |> Enum.filter(&(&1 in available_includes))
    |> dedup_nested_includes(@include_separator)
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

  defp dedup_nested_includes(includes, separator)
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
