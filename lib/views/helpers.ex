defmodule PhoenixHelpers.Views.Helpers do
  @spec render_fields(list(), map) :: map
  @spec render_fields(list(), map, map) :: map
  def render_fields(fields, data, assigns \\ %{}) when is_map(data) do
    fields
    |> Enum.filter(&field_loaded?(&1, data))
    |> Enum.reduce(%{}, fn
      field, acc when is_atom(field) ->
        acc |> Map.put(field, render_field(field, data, assigns))

      {field_name, _} = field, acc when is_atom(field_name) ->
        acc |> Map.put(field_name, render_field(field, data, assigns))
    end)
  end

  defp field_loaded?(field, data) when is_atom(field), do: data |> Map.has_key?(field)

  defp field_loaded?({field, _}, data) when is_atom(field) do
    value = Map.get(data, field)

    Map.has_key?(data, field) && Ecto.assoc_loaded?(value)
  end

  defp render_field(field, data, _assigns) when is_atom(field), do: Map.get(data, field)

  defp render_field({field, {view, template}}, data, assigns) when is_atom(field) do
    data
    |> Map.get(field)
    |> case do
      field_value when is_list(field_value) ->
        Phoenix.View.render_many(field_value, view, template, assigns)

      field_value ->
        Phoenix.View.render_one(field_value, view, template, assigns)
    end
  end
end
