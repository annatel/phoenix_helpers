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
  # import Plug.Conn

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
    %{false: flat_includes, true: nested_includes} =
      query_param_include
      |> List.wrap()
      |> Enum.uniq()
      |> Enum.filter(&(&1 in available_includes))
      # |> IO.inspect()
      |> deduplicate_nested_includes(@include_separator)
      |> Enum.map(&String.split(&1, @include_separator))
      |> Enum.reduce([], fn includes, acc ->
        acc ++ [includes |> Enum.map(&String.to_atom(&1))]
      end)
      |> Enum.group_by(&(length(&1) > 1))

    nested_includes
    |> IO.inspect()
    |> Enum.reduce([], fn includes, acc ->
      {value, path} = List.pop_at(includes, -1) |> IO.inspect()

      # IO.inspect(acc, label: "acc")
      # IO.inspect(path, label: "path")
      # IO.inspect(value, label: "value")

      acc |> put_or_add(path, value)
    end)
    |> IO.inspect()
  end

  defp put_or_add(_keyword, [key | []], value), do: {key, value}

  defp put_or_add(keyword, [h | t], value) do
    Keyword.put_new(keyword, h, put_or_add(keyword, t, value))
  end

  # defp build_includes(includes, [parent_key | child_keys] = _path, value) do
  # includes
  # |> Map.put(parent_key, build_includes(in))
  # child_value =
  #   includes
  #   |> Keyword.put_new(parent_key, [])

  # Map.put(includes, parent_key, build_includes(child_value, child_keys, value))
  # end

  # defp build_includes(includes, [], _value), do: includes

  defp deduplicate_nested_includes(includes, separator)
       when is_list(includes) and is_binary(separator) do
    includes
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.reduce([], fn include, acc ->
      if Enum.any?(acc, &String.starts_with?(&1, include <> separator)) do
        acc
      else
        acc ++ [include]
      end
    end)
  end
end
