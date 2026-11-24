defmodule Ims.UserDeactivationTest do
  use Ims.DataCase

  alias Ims.Accounts
  alias Ims.Accounts.User

  test "archiving revokes sign-in and reactivation does not restore old sessions" do
    admin = Repo.insert!(%User{first_name: "Administrator"})
    user = Repo.insert!(%User{email: "archivable@example.com", hashed_password: Bcrypt.hash_pwd_salt("valid-password")})
    token = Accounts.generate_user_session_token(user)

    assert {:error, :own_account} = Accounts.set_user_deactivation(admin, admin.id, true)
    assert {:ok, [^token]} = Accounts.set_user_deactivation(admin, user.id, true)
    assert Accounts.get_user!(user.id).deactivated_at
    refute Accounts.get_user_by_session_token(token)
    refute Accounts.get_user_by_email_and_password(user.email, "valid-password")

    assert {:ok, []} = Accounts.set_user_deactivation(admin, user.id, false)
    assert %User{id: id} = Accounts.get_user_by_email_and_password(user.email, "valid-password")
    assert id == user.id
    refute Accounts.get_user_by_session_token(token)
  end
end
