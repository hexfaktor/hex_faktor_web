defmodule HexFaktor.Router do
  use HexFaktor.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug HexFaktor.Plugs.AssignCurrentUserInfo
  end

  pipeline :badge do
    plug :accepts, ["svg"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HexFaktor do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/about", PageController, :about

    get "/notifications", NotificationController, :index
    get "/notifications/:id", NotificationController, :mark_as_read_for_branch
    post "/notifications/mark_all_as_read", NotificationController, :mark_as_read_for_user

    get "/projects", ProjectController, :index
    get "/add_project", ProjectController, :add_project
    get "/github/:owner/:name", ProjectController, :show_github

    post "/projects/sync_github", ProjectController, :sync_github
    post "/projects/sync_github/:owner/:name", ProjectController, :sync_github
    post "/projects/:id/rebuild", ProjectController, :rebuild_via_web

    get "/projects/:id/settings", ProjectController, :edit
    post "/projects/:id/update_settings", ProjectController, :update_settings
    put "/projects/:id/update", ProjectController, :update

    post "/projects/:id/activate_webhook", ProjectHookController, :activate_webhook
    post "/projects/:id/deactivate_webhook", ProjectHookController, :deactivate_webhook

    get "/settings", UserController, :edit
    put "/settings", UserController, :update
    get "/verify_email", UserController, :verify_email
    post "/resend_verify_email", UserController, :resend_verify_email

    get "/component/dep/:id", ComponentController, :dep
    get "/component/project-list-item/:id", ComponentController, :project_list_item
    get "/component/notification-counter", ComponentController, :notification_counter
  end

  scope "/packages", HexFaktor do
    pipe_through :browser

    get "/", PackageController, :index
    get "/:name", PackageController, :show
  end

  scope "/help", HexFaktor do
    pipe_through :browser

    get "/", HelpController, :index
    get "/badge", HelpController, :badge
  end

  scope "/auth", HexFaktor do
    pipe_through :browser

    get "/", GitHubAuthController, :sign_in
    get "/sign_out", GitHubAuthController, :sign_out
    get "/callback", GitHubAuthController, :callback
    get "/github/callback", GitHubAuthController, :callback
  end

  scope "/api", HexFaktor do
    pipe_through :api
    post "/hex_package_update", PageController, :hex_package_update
    post "/rebuild_via_hook", ProjectController, :rebuild_via_hook, as: :rebuild_via_hook
  end

  scope "/rebuild", HexFaktor do
    pipe_through :api
    post "/", ProjectController, :rebuild_via_hook
  end

  scope "/badge", HexFaktor do
    pipe_through :badge
    get "/all/github/:owner/:name", BadgeController, :all_deps_github
    get "/prod/github/:owner/:name", BadgeController, :prod_deps_github
    get "/hex/github/:owner/:name", BadgeController, :hex_github
  end

  scope "/test", HexFaktor do
    pipe_through :browser
    get "/500", PageController, :status_500
    get "/404", PageController, :status_404
  end

  # only enable email preview in dev environment
  if Mix.env == :dev do
    scope "/email", HexFaktor do
      pipe_through :browser
      get "/notifications", EmailController, :notifications
      get "/status_report", EmailController, :status_report
      get "/validation", EmailController, :validation
    end
  end
end
