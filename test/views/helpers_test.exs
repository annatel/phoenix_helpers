Code.require_file("../fixtures/views.exs", __DIR__)

defmodule PhoenixHelpers.Views.HelpersTest do
  use ExUnit.Case, async: true

  alias PhoenixHelpers.Views.Helpers, as: PhoenixViewHelpers

  test "render non-nested fields" do
    assert PhoenixViewHelpers.render_fields([:a, :b], %{a: 1, b: 2}) == %{a: 1, b: 2}
    assert PhoenixViewHelpers.render_fields([:a, :b], %{a: 1, b: %{a: 1}}) == %{a: 1, b: %{a: 1}}
    assert PhoenixViewHelpers.render_fields([:a, :b], %{a: 1, b: nil}) == %{a: 1, b: nil}

    assert PhoenixViewHelpers.render_fields([:id, :email], %MyApp.User{id: 1, email: "email"}) ==
             %{id: 1, email: "email"}
  end

  test "render nested field when its value is a list" do
    user = %MyApp.User{id: 1, posts: [%MyApp.Post{title: "title"}]}

    fields = [
      :id,
      posts: {MyApp.PostView, "post.json"}
    ]

    assert PhoenixViewHelpers.render_fields(fields, user) == %{id: 1, posts: [%{title: "title"}]}
    assert PhoenixViewHelpers.render_fields(fields, %{posts: []}) == %{posts: []}
  end

  test "render nested field when its value is a struct" do
    user = %MyApp.User{id: 1, last_login: %MyApp.Login{ip: "10.90.90.1"}}

    fields = [
      :id,
      last_login: {MyApp.LoginView, "login.json"}
    ]

    assert PhoenixViewHelpers.render_fields(fields, user) == %{
             id: 1,
             last_login: %{ip: "10.90.90.1"}
           }

    assert PhoenixViewHelpers.render_fields(fields, %{last_login: %MyApp.Login{}}) == %{
             last_login: %{ip: nil}
           }
  end

  test "render nested field when its value is nil" do
    assert PhoenixViewHelpers.render_fields(
             [{:last_login, {MyApp.LoginView, "login.json"}}],
             %{last_login: nil}
           ) == %{last_login: nil}
  end

  test "render nested field when its value is %Ecto.Association.NotLoaded{}" do
    assert PhoenixViewHelpers.render_fields([{:last_login, {MyApp.LoginView, "login.json"}}], %{
             last_login: %Ecto.Association.NotLoaded{}
           }) == %{}
  end

  test "when one of the fields does not exist, returns the data without the not loaded fields" do
    assert PhoenixViewHelpers.render_fields([:a, :b], %{b: 2}) == %{b: 2}

    assert PhoenixViewHelpers.render_fields(
             [:id, {:last_login, {MyApp.LoginView, "login.json"}}],
             %{id: 2}
           ) == %{id: 2}
  end
end
