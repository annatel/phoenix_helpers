defmodule PhoenixHelpers.Plug.QueryParserTest do
  use ExUnit.Case, async: true
  doctest PhoenixHelpers.Plug.QueryParser
  use Plug.Test

  alias PhoenixHelpers.Query
  alias PhoenixHelpers.Plug.QueryParser

  describe "parse include" do
    test "when the include query_param is part of the available_includes, assigns the include to the query_parser" do
      available_includes = ["include1", "include2"]

      conn =
        conn(:get, "/?include[]=include1&include[]=include2")
        |> QueryParser.call(%Query{available_includes: available_includes})

      assert %Query{
               available_includes: ^available_includes,
               includes: [:include2, :include1]
             } = conn.assigns.phoenix_helper_query
    end

    test "when the include query_param contains nested includes, assigns the include to the query_parser according to the preload format" do
      available_includes = [
        "parent1",
        "parent1.child1",
        "parent1.child2",
        "parent1.child2.grandchild1",
        "parent1.child2.grandchild2",
        "parent1.child3",
        "parent2"
      ]

      conn =
        conn(
          :get,
          "/?include[]=parent1&include[]=parent1.child1&include[]=parent1.child2&include[]=parent1.child2.grandchild1&include[]=parent1.child2.grandchild2&include[]=parent1.child3&include[]=parent2"
        )
        |> QueryParser.call(%Query{available_includes: available_includes})

      assert %Query{
               includes: [
                 :parent2,
                 {:parent1, [:child3, :child1, {:child2, [:grandchild2, :grandchild1]}]}
               ]
             } = conn.assigns.phoenix_helper_query
    end

    test "when the include query_param is duplicated, assigns only one of them to the include to the query_parser" do
      available_includes = ["parent", "parent.child", "par"]

      conn =
        conn(
          :get,
          "/?include[]=parent&include[]=parent&include[]=parent.child&include[]=parent.child&include[]=par"
        )
        |> QueryParser.call(%Query{available_includes: available_includes})

      assert conn.assigns.phoenix_helper_query == %Query{
               available_includes: available_includes,
               includes: [:par, parent: [:child]]
             }
    end

    test "when the include query_param is not in the request, set include as nil" do
      conn =
        conn(:get, "/")
        |> QueryParser.call(%Query{available_includes: ["include1"]})

      assert %Query{includes: nil} = conn.assigns.phoenix_helper_query
    end

    test "when the include query_param is empty, set includes as an empty list" do
      conn =
        conn(:get, "/?include=")
        |> QueryParser.call(%Query{available_includes: ["include1"]})

      assert %Query{includes: []} = conn.assigns.phoenix_helper_query
    end

    test "when include is not part of the available_includes, ignore it" do
      conn =
        conn(:get, "/?include=include2")
        |> QueryParser.call(%Query{available_includes: ["include1"]})

      assert %Query{
               available_includes: ["include1"],
               includes: []
             } = conn.assigns.phoenix_helper_query
    end
  end

  describe "parse_filter" do
    test "set filter" do
      available_filters = ["key1", "key2"]

      conn =
        conn(:get, "/?filter[key1]=value1&filter[key2]=value2")
        |> QueryParser.call(%Query{available_filters: available_filters})

      assert %Query{
               available_filters: ^available_filters,
               filters: [{:key1, "value1"}, {:key2, "value2"}]
             } = conn.assigns.phoenix_helper_query
    end

    test "ignore not available filters" do
      available_filters = ["key1"]

      conn =
        conn(:get, "/?filter[key1]=value1&filter[key2]=value2")
        |> QueryParser.call(%Query{available_filters: available_filters})

      assert %Query{
               available_filters: ^available_filters,
               filters: [{:key1, "value1"}]
             } = conn.assigns.phoenix_helper_query
    end

    test "ignore duplicate filters" do
      available_filters = ["key1"]

      conn =
        conn(:get, "/?filter[key1]=value1&filter[key1]=value2")
        |> QueryParser.call(%Query{available_filters: available_filters})

      assert %Query{
               available_filters: ^available_filters,
               filters: [{:key1, "value2"}]
             } = conn.assigns.phoenix_helper_query
    end

    test "when available_filters are defined by keys" do
      available_filters = %{index: ["key1"], show: ["key2"]}

      conn =
        conn(:get, "/?filter[key1]=value1&filter[key2]=value2")
        |> QueryParser.call(%Query{available_filters: available_filters})

      assert %Query{
               available_filters: ^available_filters,
               filters: %{index: [{:key1, "value1"}], show: [{:key2, "value2"}]}
             } = conn.assigns.phoenix_helper_query
    end

    test "when filter is empty" do
      available_filters = ["key1"]

      conn =
        conn(:get, "/?filter=")
        |> QueryParser.call(%Query{available_filters: available_filters})

      assert %Query{
               available_filters: ^available_filters,
               filters: []
             } = conn.assigns.phoenix_helper_query
    end

    test "when filter is not an array" do
      available_filters = ["key1"]

      conn =
        conn(:get, "/?filter=value1")
        |> QueryParser.call(%Query{available_filters: available_filters})

      assert %Query{
               available_filters: ^available_filters,
               filters: []
             } = conn.assigns.phoenix_helper_query
    end
  end
end
