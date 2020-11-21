defmodule MyApp.User do
  defstruct [:id, :email, :posts, :last_login]
end

defmodule MyApp.Login do
  defstruct [:ip]
end

defmodule MyApp.Post do
  defstruct [:id, :title]
end

defmodule MyApp.UserView do
  use Phoenix.View, root: "test/fixtures/templates"

  def render("user.json", %{user: user} = _assigns) do
    %{id: user.id, email: user.email}
  end
end

defmodule MyApp.PostView do
  use Phoenix.View, root: "test/fixtures/templates"

  def render("post.json", %{post: post} = _assigns) do
    %{title: post.title}
  end
end

defmodule MyApp.LoginView do
  use Phoenix.View, root: "test/fixtures/templates"

  def render("login.json", %{login: login} = _assigns) do
    %{ip: login.ip}
  end
end
