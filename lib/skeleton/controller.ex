defmodule Skeleton.Phoenix.Controller do
  import Plug.Conn
  alias Skeleton.Phoenix.Config, as: CtrlConfig
  alias Skeleton.Permission.Config, as: Config

  # Callbacks

  @callback is_authenticated(Plug.Conn.t()) :: Boolean.t()
  @callback fallback(Plug.Conn.t()) :: Plug.Conn.t()

  defmacro __using__(_) do
    alias Skeleton.Phoenix.Controller

    quote do
      import unquote(CtrlConfig.controller())

      # Ensure authenticated

      def ensure_authenticated(%{halted: true} = conn), do: conn
      def ensure_authenticated(conn), do: Controller.do_ensure_authenticated(conn)

      # Ensure not authenticated

      def ensure_not_authenticated(%{halted: true} = conn), do: conn
      def ensure_not_authenticated(conn), do: Controller.do_ensure_not_authenticated(conn)

      # Check permission

      def check_permission(%{halted: true} = conn, _, _, _), do: conn

      def check_permission(conn, permission_module, permission_name, ctx_fun) do
        Controller.do_check_permission(conn, permission_module, permission_name, ctx_fun)
      end

      def check_permission(%{halted: true} = conn, _, _), do: conn

      def check_permission(conn, permission_module, permission_name) do
        Controller.do_check_permission(conn, permission_module, permission_name, fn _, ctx ->
          ctx
        end)
      end

      # Permit params

      def permit_params(%{halted: true} = conn, _, _), do: conn

      def permit_params(conn, permission_module, permission_name) do
        Controller.do_permit_params(conn, permission_module, permission_name)
      end

      # Resolve

      def resolve(%{halted: true} = conn, _), do: CtrlConfig.controller().fallback(conn)
      def resolve(conn, callback), do: callback.(conn)
    end
  end

  # Do ensure authenticated

  def do_ensure_authenticated(conn) do
    if CtrlConfig.controller().is_authenticated(conn) do
      conn
    else
      unauthorized(conn)
    end
  end

  # Do ensure not authenticated

  def do_ensure_not_authenticated(conn) do
    if CtrlConfig.controller().is_authenticated(conn) do
      unauthorized(conn)
    else
      conn
    end
  end

  # Do check permission

  def do_check_permission(conn, permission_module, permission_name, ctx_fun) do
    context =
      conn
      |> build_permission_context(permission_module, ctx_fun)
      |> permission_module.preload_data([permission_name])

    if permission_module.check(permission_name, context) do
      conn
    else
      forbidden(conn)
    end
  end

  # Do permit params

  def do_permit_params(conn, permission_module, permission_name) do
    context = build_permission_context(conn, permission_module, fn _, ctx -> ctx end)
    permitted_params = permission_module.permit(permission_name, context)
    Map.put(conn, :params, permitted_params)
  end

  # Do build context

  def build_permission_context(conn, permission_module, ctx_fun) do
    default_context = Config.permission().context(conn)
    permission_context = permission_module.context(conn, default_context)

    ctx_fun.(conn, Map.merge(default_context, permission_context))
  end

  # Return unauthorized

  def unauthorized(conn) do
    conn |> put_status(:unauthorized) |> halt()
  end

  def forbidden(conn) do
    conn |> put_status(:forbidden) |> halt()
  end
end
