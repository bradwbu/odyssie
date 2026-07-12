defmodule OdyssieWeb.Router do
  use OdyssieWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OdyssieWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # ── Auth Routes ───────────────────────────────────────────────────────

  scope "/", OdyssieWeb do
    pipe_through :browser

    get "/session/set/:token", SessionController, :set_token

    live_session :require_no_user,
      on_mount: [{OdyssieWeb.Hooks, :require_no_user}] do
      live "/login", AuthLive.LoginLive, :new
      live "/signup", AuthLive.RegisterLive, :new
    end
  end

  # ── Authenticated Routes ─────────────────────────────────────────────

  scope "/", OdyssieWeb do
    pipe_through :browser

    live_session :require_user,
      on_mount: [{OdyssieWeb.Hooks, :require_user}] do
        live "/", HomeLive.Index, :index
        live "/home", HomeLive.Index, :index

        live "/explore", SearchLive.Index, :index
        live "/notifications", NotificationLive.Index, :index

        live "/messages", ChatLive.Inbox, :index
        live "/messages/:user_id", ChatLive.Show, :show

        live "/compose", PostLive.Compose, :new
        live "/post/:id", PostLive.Show, :show

        live "/:username", ProfileLive.Index, :index
        live "/:username/with_replies", ProfileLive.Index, :replies
        live "/:username/likes", ProfileLive.Index, :likes
        live "/:username/media", ProfileLive.Index, :media
      end
  end

  # ── API Routes ────────────────────────────────────────────────────────

  scope "/api", OdyssieWeb do
    pipe_through :api

    post "/session", SessionController, :create
    delete "/session", SessionController, :delete
  end

  if Application.compile_env(:odyssie, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: OdyssieWeb.Telemetry
    end
  end
end
