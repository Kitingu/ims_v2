defmodule ImsWeb.Router do
  use ImsWeb, :router

  import ImsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ImsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug ImsWeb.Plugs.AuditPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin_auth do
    plug :browser
    plug :require_authenticated_user
    plug ImsWeb.Plugs.EnsureAuthorizedPlug, actions: ["manage"]
  end

  scope "/", ImsWeb do
    pipe_through :browser

    # users, roles and permissions
    # setup
  end

  # Other scopes may use custom stacks.
  scope "/api", ImsWeb do
    pipe_through :api

    post("/payment/validate", PaymentsController, :api_payment_validate)
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ims, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ImsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ImsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ImsWeb.UserAuth, :redirect_if_user_is_authenticated},{ImsWeb.Hooks.AuditOnMount, :set_actor} ] do
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit

      # settings
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ImsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ImsWeb.UserAuth, :ensure_authenticated},{ImsWeb.Hooks.AuditOnMount, :set_actor} ] do
      # live "/", UserProfileLive, :index
      live "/", DashboardLive.Index, :index

      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/asset_names", AssetNameLive.Index, :index
      live "/asset_names/new", AssetNameLive.Index, :new
      live "/asset_names/:id/edit", AssetNameLive.Index, :edit
      live "/asset_names/:id", AssetNameLive.Show, :show
      live "/asset_names/:id/show/edit", AssetNameLive.Show, :edit

      live "/offices", OfficeLive.Index, :index
      live "/offices/new", OfficeLive.Index, :new
      live "/offices/:id/edit", OfficeLive.Index, :edit
      live "/offices/:id", OfficeLive.Show, :show
      live "/offices/:id/show/edit", OfficeLive.Show, :edit

      live "/asset_types", AssetTypeLive.Index, :index
      live "/asset_types/new", AssetTypeLive.Index, :new
      live "/asset_types/:id/edit", AssetTypeLive.Index, :edit
      live "/asset_types/:id", AssetTypeLive.Show, :show
      live "/asset_types/:id/show/edit", AssetTypeLive.Show, :edit

      live "/locations", LocationLive.Index, :index
      live "/locations/new", LocationLive.Index, :new
      live "/locations/:id/edit", LocationLive.Index, :edit
      live "/locations/:id", LocationLive.Show, :show
      live "/locations/:id/show/edit", LocationLive.Show, :edit

      live "/departments", DepartmentsLive.Index, :index
      live "/departments/new", DepartmentsLive.Index, :new
      live "/departments/:id/edit", DepartmentsLive.Index, :edit
      live "/departments/:id", DepartmentsLive.Show, :show
      live "/departments/:id/show/edit", DepartmentsLive.Show, :edit

      live "/categories", CategoryLive.Index, :index
      live "/categories/new", CategoryLive.Index, :new
      live "/categories/:id/edit", CategoryLive.Index, :edit
      live "/categories/:id", CategoryLive.Show, :show
      live "/categories/:id/show/edit", CategoryLive.Show, :edit

      live "/assets", AssetLive.Index, :index
      live "/assets/new", AssetLive.Index, :new
      live "/assets/:id/edit", AssetLive.Index, :edit
      live "/assets/:id", AssetLive.Show, :show
      live "/assets/:id/show/edit", AssetLive.Show, :edit
      live "/assets/:id/assign", AssetLive.Index, :assign

      live "/asset_logs", AssetLogLive.Index, :index
      live "/asset_logs/new", AssetLogLive.Index, :new
      live "/asset_logs/:id/edit", AssetLogLive.Index, :edit
      live "/asset_logs/:id", AssetLogLive.Show, :show
      live "/asset_logs/:id/show/edit", AssetLogLive.Show, :edit

      live "/payment_gateways", PaymentGatewayLive.Index, :index
      live "/payment_gateways/new", PaymentGatewayLive.Index, :new
      live "/payment_gateways/:id/edit", PaymentGatewayLive.Index, :edit
      live "/payment_gateways/:id", PaymentGatewayLive.Show, :show
      live "/payment_gateways/:id/show/edit", PaymentGatewayLive.Show, :edit

      # live "/devices", DeviceLive.Index, :index
      # live "/devices/new", DeviceLive.Index, :new
      # live "/devices/:id/edit", DeviceLive.Index, :edit

      # live "/devices/:id", DeviceLive.Show, :show
      # live "/devices/:id/show/edit", DeviceLive.Show, :edit
      get "/leave-balances/export", LeaveBalanceExportController, :export
      # users

      live "/requests", RequestLive.Index, :index
      live "/requests/new", RequestLive.Index, :new
      live "/requests/:id/edit", RequestLive.Index, :edit

      live "/requests/:id", RequestLive.Show, :show
      live "/requests/:id/show/edit", RequestLive.Show, :edit

      # live "/lost_devices", LostDeviceLive.Index, :index
      # live "/lost_devices/new", LostDeviceLive.Index, :new
      # live "/lost_devices/:id/edit", LostDeviceLive.Index, :edit
      # live "/lost_devices/:id", LostDeviceLive.Show, :show

      # live "/returned_devices", ReturnedDeviceLive.Index, :index
      # live "/returned_devices/new", ReturnedDeviceLive.Index, :new
      # live "/returned_devices/:id/edit", ReturnedDeviceLive.Index, :edit

      # live "/returned_devices/:id", ReturnedDeviceLive.Show, :show
      # live "/returned_devices/:id/show/edit", ReturnedDeviceLive.Show, :edit

      live "/leave_applications", LeaveApplicationLive.Index, :index
      live "/leave_applications/new", LeaveApplicationLive.Index, :new

      # live "/training_applications", TrainingApplicationLive.Index, :index
      # live "/training_applications/new", TrainingApplicationLive.Index, :new
      # live "/training_applications/:id/edit", TrainingApplicationLive.Index, :edit

      # live "/training_applications/:id", TrainingApplicationLive.Show, :show
      # live "/training_applications/:id/show/edit", TrainingApplicationLive.Show, :edit

      live "/files", FileLive.Index, :index
      live "/files/new", FileLive.Index, :new
      live "/files/:id/edit", FileLive.Index, :edit

      live "/files/:id", FileLive.Show, :show
      live "/files/:id/show/edit", FileLive.Show, :edit

      live "/file_movements", FileMovementLive.Index, :index
      live "/file_movements/new", FileMovementLive.Index, :new
      live "/file_movements/:id/edit", FileMovementLive.Index, :edit

      live "/file_movements/:id", FileMovementLive.Show, :show
      live "/file_movements/:id/show/edit", FileMovementLive.Show, :edit
    end
  end

  scope "/admin", ImsWeb do
    pipe_through [:admin_auth]

    live_session :admin,
      # ✅ Mounts `current_user`
      on_mount: [{ImsWeb.UserAuth, :mount_current_user},{ImsWeb.Hooks.AuditOnMount, :set_actor} ] do
      get "/users/download_template", UserController, :download_template

      live "/users", UserLive, :index
      live "/users/register", UserRegistrationLive, :new
      live "/users/:id/edit", UserLive, :edit
      live "/users/:id", UserLive, :show

      # settings
      live "/settings", SettingLive.Index, :index
      live "/settings/new", SettingLive.Index, :new
      live "/settings/:id/edit", SettingLive.Index, :edit
      live "/settings/:id", SettingLive.Show, :show
      live "/settings/:id/show/edit", SettingLive.Show, :edit

      # categories
      # # categories
      # live "/categories", CategoryLive.Index, :index
      # live "/categories/new", CategoryLive.Index, :new
      # live "/categories/:id/edit", CategoryLive.Index, :edit

      # live "/categories/:id", CategoryLive.Show, :show
      # live "/categories/:id/show/edit", CategoryLive.Show, :edit

      # live "/user_assignments", UserAssignmentLive.Index, :index
      # live "/user_assignments/new", UserAssignmentLive.Index, :new
      # live "/user_assignments/:id/edit", UserAssignmentLive.Index, :edit

      # live "/user_assignments/:id", UserAssignmentLive.Show, :show
      # live "/user_assignments/:id/show/edit", UserAssignmentLive.Show, :edit

      # permissions
      # roles
      live "/roles", RoleLive.Index, :index
      live "/roles/new", RoleLive.Index, :new
      live "/roles/:id/edit", RoleLive.Index, :edit

      live "/job_groups", JobGroupLive.Index, :index
      live "/job_groups/new", JobGroupLive.Index, :new
      live "/job_groups/:id/edit", JobGroupLive.Index, :edit
      live "/job_groups/:id", JobGroupLive.Show, :show
      live "/job_groups/:id/show/edit", JobGroupLive.Show, :edit

      # live "/device_names", DeviceNameLive.Index, :index
      # live "/device_names/new", DeviceNameLive.Index, :new
      # live "/device_names/:id/edit", DeviceNameLive.Index, :edit

      # live "/device_names/:id", DeviceNameLive.Show, :show
      # live "/device_names/:id/show/edit", DeviceNameLive.Show, :edit
    end
  end

  scope "/hr", ImsWeb do
    pipe_through [:admin_auth]

    live_session :hr,
      on_mount: [{ImsWeb.UserAuth, :mount_current_user},{ImsWeb.Hooks.AuditOnMount, :set_actor} ] do
      live "/leave_applications", LeaveApplicationLive.Index, :index

      live "/leave_applications/:id/edit", LeaveApplicationLive.Index, :edit

      live "/leave_applications/:id", LeaveApplicationLive.Show, :show
      live "/leave_applications/:id/show/edit", LeaveApplicationLive.Show, :edit

      live "/leave_types", LeaveTypeLive.Index, :index
      live "/leave_types/new", LeaveTypeLive.Index, :new
      live "/leave_types/:id/edit", LeaveTypeLive.Index, :edit

      live "/leave_types/:id", LeaveTypeLive.Show, :show
      live "/leave_types/:id/show/edit", LeaveTypeLive.Show, :edit

      live "/leave_balances", LeaveBalanceLive.Index, :index
      live "/leave_balances/new", LeaveBalanceLive.Index, :new
      live "/leave_balances/:id/edit", LeaveBalanceLive.Index, :edit

      live "/training_applications", TrainingApplicationLive.Index, :index
      live "/training_applications/new", TrainingApplicationLive.Index, :new
      live "/training_applications/:id/edit", TrainingApplicationLive.Index, :edit
      live "/training_applications/:id", TrainingApplicationLive.Show, :show
      live "/training_applications/:id/show/edit", TrainingApplicationLive.Show, :edit

      live "/away_requests", AwayRequestLive.Index, :index
      live "/away_requests/new", AwayRequestLive.Index, :new
      live "/away_requests/:id/edit", AwayRequestLive.Index, :edit

      live "/away_requests/:id", AwayRequestLive.Show, :show
      live "/away_requests/:id/show/edit", AwayRequestLive.Show, :edit

      live "/intern_attachees", InternAttacheeLive.Index, :index
      live "/intern_attachees/new", InternAttacheeLive.Index, :new
      live "/intern_attachees/:id/edit", InternAttacheeLive.Index, :edit
      live "/intern_attachees/:id", InternAttacheeLive.Show, :show
      live "/intern_attachees/:id/show/edit", InternAttacheeLive.Show, :edit

      live "/training_projections", TrainingProjectionsLive.Index, :index
      live "/training_projections/:id/edit", TrainingProjectionsLive.Index, :edit
      live "/training_projections/:id", TrainingProjectionsLive.Show, :show
      live "/training_projections/:id/show/edit", TrainingProjectionsLive.Show, :edit
    end
  end

  scope "/welfare", ImsWeb do
    pipe_through [:admin_auth]

    live_session :welfare,
      on_mount: [{ImsWeb.UserAuth, :mount_current_user},{ImsWeb.Hooks.AuditOnMount, :set_actor} ] do
      live "/event_types", EventTypeLive.Index, :index
      live "/event_types/new", EventTypeLive.Index, :new
      live "/event_types/:id/edit", EventTypeLive.Index, :edit
      live "/event_types/:id", EventTypeLive.Show, :show
      live "/event_types/:id/show/edit", EventTypeLive.Show, :edit

      live "/events", EventLive.Index, :index
      live "/events/new", EventLive.Index, :new
      live "/events/upload_contributions", EventLive.UploadContributionsComponent, :index
      live "/events/:id/edit", EventLive.Index, :edit
      live "/events/:id", EventLive.Show, :show
      live "/events/:id/show/edit", EventLive.Show, :edit

        live "/members", Welfare.MemberLive.Index, :index
    end
  end

  scope "/", ImsWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    post "/reports/download", ReportsController, :download_report
    get "/reports/training_applications", ReportsController, :export_training_applications
    get "/reports/training_projections", ReportsController, :export_training_projections
    get "/unauthorized", UnauthorizedController, :index
    # live "/training_projections/new", TrainingProjectionsLive.Index, :new
    # live "/training_projections/success", TrainingProjectionsSuccessLive

    live_session :current_user,
      on_mount: [{ImsWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
