defmodule PhoenixHelpers.Plug.Parsers.QueryParserTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias PhoenixHelpers.Plug.Parsers.QueryParser, as: PlugQueryParser

  describe "parse include" do
    test "when the include query_param is part of the available_includes, assigns the include to the query_parser" do
      available_includes = ["include1", "include2"]

      conn =
        conn(:get, "/?include[]=include1&include[]=include2")
        |> PlugQueryParser.call(%PlugQueryParser{available_includes: available_includes})

      assert conn.assigns.query_parser == %PlugQueryParser{
               available_includes: available_includes,
               includes: [:include1, :include2]
             }
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
               available_includes: available_includes,
               includes: [
                 :parent2,
                 parent1: [:child1, [child2: [:grandchild1, :grandchild2]], :child3]
               ]
             } = conn.assigns.query_parser
    end

    test "when the include query_param is duplicated, assigns only one of them to the include to the query_parser" do
      available_includes = ["parent", "parent.child"]

      conn =
        conn(
          :get,
          "/?include[]=parent&include[]=parent&include[]=parent.child&include[]=parent.child"
        )
        |> PlugQueryParser.call(%PlugQueryParser{available_includes: available_includes})

      assert conn.assigns.query_parser == %PlugQueryParser{
               available_includes: available_includes,
               includes: [:parent, [parent: :child]]
             }
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

      assert %PlugQueryParser{
               available_includes: ["include1"],
               includes: []
             } = conn.assigns.query_parser
    end
  end
end
