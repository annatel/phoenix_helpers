defmodule PhoenixHelpers.Plug.Parsers.QueryParserTest do
  use ExUnit.Case, async: true
  doctest PhoenixHelpers.Plug.Parsers.QueryParser
  use Plug.Test

  alias PhoenixHelpers.Plug.Parsers.QueryParser, as: PlugQueryParser

  describe "parse include" do
    test "when the include query_param is part of the available_includes, assigns the include to the query_parser" do
      available_includes = ["include1", "include2"]

      conn =
        conn(:get, "/?include[]=include1&include[]=include2")
        |> PlugQueryParser.call(%PlugQueryParser{available_includes: available_includes})

      assert %PlugQueryParser{
               available_includes: ^available_includes,
               includes: [:include2, :include1]
             } = conn.assigns.query_parser
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
        |> PlugQueryParser.call(%PlugQueryParser{available_includes: available_includes})

      assert %PlugQueryParser{
               includes: [
                 :parent2,
                 {:parent1, [:child3, :child1, {:child2, [:grandchild2, :grandchild1]}]}
               ]
             } = conn.assigns.query_parser
    end

    test "when the include query_param is duplicated, assigns only one of them to the include in the query_parser" do
      available_includes = ["parent", "parent.child", "par"]

      conn =
        conn(
          :get,
          "/?include[]=parent&include[]=parent&include[]=parent.child&include[]=parent.child&include[]=par"
        )
        |> PlugQueryParser.call(%PlugQueryParser{available_includes: available_includes})

      assert %PlugQueryParser{includes: [:par, parent: [:child]]} = conn.assigns.query_parser
    end

    test "when available_includes is by key, returns the includes according to the same keys" do
      available_includes = %{show: ["include1", "include2"], index: ["include1"], update: []}

      conn =
        conn(:get, "/?include[]=include1&include[]=include2")
        |> PlugQueryParser.call(%PlugQueryParser{available_includes: available_includes})

      assert %PlugQueryParser{
               available_includes: ^available_includes,
               includes: %{show: [:include2, :include1], index: [:include1], update: []}
             } = conn.assigns.query_parser
    end

    test "when the include query_param is not in the request, set include as nil" do
      conn =
        conn(:get, "/")
        |> PlugQueryParser.call(%PlugQueryParser{available_includes: ["include1"]})

      assert %PlugQueryParser{includes: nil} = conn.assigns.query_parser
    end

    test "when the include query_param is empty, set includes as an empty list" do
      conn =
        conn(:get, "/?include=")
        |> PlugQueryParser.call(%PlugQueryParser{available_includes: ["include1"]})

      assert %PlugQueryParser{includes: []} = conn.assigns.query_parser
    end

    test "when include is not part of the available_includes, ignore it" do
      conn =
        conn(:get, "/?include=include2")
        |> PlugQueryParser.call(%PlugQueryParser{available_includes: ["include1"]})

      assert %PlugQueryParser{includes: []} = conn.assigns.query_parser
    end
  end

  describe "page" do
    test "when page[number] and page[size] are in the query params, set the page in the query_parser" do
      conn =
        conn(:get, "/?page[number]=10&page[size]=1") |> PlugQueryParser.call(%PlugQueryParser{})

      assert %PlugQueryParser{page: %{number: 10, size: 1}} = conn.assigns.query_parser
    end

    test "when only page[number] is in the query params, set default for page[size] and set the page in the query_parser" do
      conn =
        conn(:get, "/?page[number]=10")
        |> PlugQueryParser.call(%PlugQueryParser{default_page_size: 100})

      assert %PlugQueryParser{page: %{number: 10, size: 100}} = conn.assigns.query_parser
    end

    test "when only page[size] is in the query params, set default for page[number] and set the page in the query_parser" do
      conn = conn(:get, "/?page[size]=1") |> PlugQueryParser.call(%PlugQueryParser{})

      assert %PlugQueryParser{page: %{number: 1, size: 1}} = conn.assigns.query_parser
    end

    test "when neither page[size] or page[number] are in the query params, set default for both and set the page in the query_parser" do
      conn = conn(:get, "/") |> PlugQueryParser.call(%PlugQueryParser{})

      assert %PlugQueryParser{page: %{number: 1, size: 100}} = conn.assigns.query_parser
    end

    test "when page paramter is set with other value thant size and number, ignore them" do
      conn = conn(:get, "/?page[page_size]=10") |> PlugQueryParser.call(%PlugQueryParser{})

      assert %PlugQueryParser{page: %{number: 1, size: 100}} = conn.assigns.query_parser
    end

    test "can override the default_page_size" do
      conn = conn(:get, "/") |> PlugQueryParser.call(%PlugQueryParser{default_page_size: 10})

      assert %PlugQueryParser{page: %{size: 10}} = conn.assigns.query_parser
    end
  end

  describe "query" do
    test "when q is in the query_param, set the q in the query" do
      conn = conn(:get, "/?q=query") |> PlugQueryParser.call(%PlugQueryParser{})
      assert %PlugQueryParser{q: "query"} = conn.assigns.query_parser

      conn = conn(:get, "/?q=") |> PlugQueryParser.call(%PlugQueryParser{})
      assert %PlugQueryParser{q: ""} = conn.assigns.query_parser
    end

    test "when q not is in the query_param, set the q to nil the query" do
      conn = conn(:get, "/") |> PlugQueryParser.call(%PlugQueryParser{})
      assert %PlugQueryParser{q: nil} = conn.assigns.query_parser
    end
  end
end
