defmodule Skeleton.Phoenix.Controller do
  defmacro __using__(_) do
    quote do
      use Skeleton.Controller
      import Ecto.Query
      alias Skeleton.Phoenix.Repo
    end
  end

  def is_authenticated(conn), do: conn.private[:current_user]
  def is_not_authenticated(conn), do: !conn.private[:current_user]
end