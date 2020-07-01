defmodule Skeleton.Controller do
  import Plug.Conn
  alias Skeleton.Phoenix.Config, as: CtrlConfig
  alias Skeleton.Permission.Config, as: PermConfig

  defmacro __using__(_) do
    alias Skeleton.Controller, as: Ctrl

    quote do
      # Ensure authenticated

      def ensure_authenticated(%{halted: true} = conn), do: conn
      def ensure_authenticated(conn), do: Ctrl.do_ensure_authenticated(conn)

      # Ensure not authenticated

      def ensure_not_authenticated(%{halted: true} = conn), do: conn
      def ensure_not_authenticated(conn), do: Ctrl.do_ensure_not_authenticated(conn)

      # Check permission

      def check_permission(conn, permission_module, permission_name, _)
      def check_permission(%{halted: true} = conn, _, _, _), do: conn

      def check_permission(conn, permission_module, permission_name, ctx_fun) do
        Ctrl.do_check_permission(conn, permission_module, permission_name, ctx_fun)
      end

      def check_permission(conn, permission_module, permission_name) do
        Ctrl.do_check_permission(conn, permission_module, permission_name, fn _, ctx -> ctx end)
      end

      # Permit params

      def permit_params(%{halted: true} = conn, _, _), do: conn

      def permit_params(conn, permission_module, permission_name) do
        Ctrl.do_permit_params(conn, permission_module, permission_name)
      end

      # Resolve

      def resolve(%{halted: true} = conn, _), do: conn
      def resolve(conn, callback), do: callback.(put_status(conn, :ok))
    end
  end

  # Do ensure authenticated

  def do_ensure_authenticated(conn) do
    if CtrlConfig.controller().is_authenticated(conn) do
      success(conn)
    else
      unauthorized(conn)
    end
  end

  # Do ensure not authenticated

  def do_ensure_not_authenticated(conn) do
    if CtrlConfig.controller().is_authenticated(conn) do
      unauthorized(conn)
    else
      success(conn)
    end
  end

  # Do check permission

  def do_check_permission(conn, permission_module, permission_name, ctx_fun) do
    context = build_permission_context(conn, ctx_fun)

    if permission_module.check(permission_name, context) do
      success(conn)
    else
      unauthorized(conn)
    end
  end

  # Do permit params

  def do_permit_params(conn, permission_module, permission_name) do
    context = build_permission_context(conn, fn _, ctx -> ctx end)
    permitted_params = permission_module.permit(permission_name, context)
    Map.put(conn, :params, permitted_params)
  end

  # Do build context

  def build_permission_context(conn, ctx_fun) do
    ctx_fun.(conn, PermConfig.permission().context(conn))
  end

  # Return unauthorized

  def unauthorized(conn) do
    conn |> put_status(:unauthorized) |> halt()
  end

  # Retorn success

  def success(conn) do
    put_status(conn, :ok)
  end
end