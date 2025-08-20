defmodule Ims.Accounts.UserNotifier do
  import Swoosh.Email

  alias Ims.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    from_email =
      Application.fetch_env!(:ims, :mailer_from_email)

    from_name =
      Application.get_env(:ims, :mailer_from_name, "IMS")

    email =
      new()
      # "user@example.com" or {"Name", "user@example.com"}
      |> to(recipient)
      # guarantees non-empty address
      |> from({from_name, from_email})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _meta} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
