# PhoenixHelpers

A Small collection of functions to make easier render fields of a schema with its associations.  
A Plug for parsing include, filter, page and q. 

## Installation

PhoenixHelpers is published on [Hex](https://hex.pm/packages/phoenix_helpers), the package can be installed
by adding `phoenix_helpers` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_helpers, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/phoenix_helpers](https://hexdocs.pm/phoenix_helpers).

# Usage

## Render fields

Instead of having to map each field, and to check if an association is loaded or not, just call the `render_fields` function.

```elixir
defmodule MyApp.UserView do
  
  def render("show.json", %{user: user}) do
    render_one(user, UserView, "user.json")
  end

  def render("user.json", %{user: user} = _assigns) do
    [
      :id,
      :name,
      :email,
      last_login: {MyApp.LoginView, "login.json"}
      posts: {MyApp.PostView, "post.json"}
    ]
    |> PhoenixHelpers.Views.Helpers.render_fields(user)
  end
end

iex> user = %User{
  id: 1,
  email: "email",
  last_login: %Ecto.Association.NotLoaded{}.
  posts: [%Post{title: "post 1"}]
}
iex> MyApp.UserView.render("user.json", %{user: user})
%{id: 1, email: "email", posts: %{title: "post 1}}
```

## Parsing the query params

```elixir
plug PhoenixHelpers.Plug.QueryParser,
  include: ~w(posts posts.user comments)
  filter: ~w(name)
```
The plug will add a `PhoenixHelpers.Query` struct called `phoenix_helper_query` to your conn.assigns.  
The `includes` will be parsed to the Ecto preload format.

### Filter
`/?filter[key1]=value1&filter[key2]=value2`
```elixir
%{filters: [key1: "value1", key2: "value2"]} = conn.assigns.phoenix_helper_query
```

### Page
`/?page[number]=2&page[size]=100`
```elixir
%{page: %{size: 2, number: 100}} = conn.assigns.phoenix_helper_query
```

### Include
`/?include[]=posts.user&include[]=comments`
```elixir
%{includes: [:comments, {posts: :user}]} = conn.assigns.phoenix_helper_query
```

### Query
`/?q=search_query`
```elixir
%{q: "search_query"} = conn.assigns.phoenix_helper_query
```