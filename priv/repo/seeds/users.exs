  alias Ims.Repo
alias Ims.Accounts.User
alias Ims.Leave.{LeaveType, LeaveBalance}

# Get shared data from seed
seed_data = Application.get_env(:ims, :seed_data)

%{
  admin_role: admin_role,
  user_role: user_role,
  it_department: it_department,
  hr_department: hr_department,
  job_group: job_group,
  job_group_1: job_group_1
} = seed_data

# === Create users with gender ===
user_1 =
  %User{}
  |> User.registration_changeset(%{
    email: "admin@odp.com",
    password: "nqis2Xqe-",
    password_confirmation: "nqis2Xqe-",
    first_name: "Admin",
    last_name: "User",
    msisdn: "0715357867",
    designation: "ICT Director",
    personal_number: "123456",
    department_id: it_department.id,
    job_group_id: job_group_1.id,
    gender: "Male"
  })
  |> Ecto.Changeset.put_assoc(:roles, [admin_role])
  |> Repo.insert!()

user_2 =
  %User{}
  |> User.registration_changeset(%{
    email: "user@odp.com",
    password: "nqis2Xqe-",
    password_confirmation: "nqis2Xqe-",
    first_name: "Regular",
    last_name: "User",
    msisdn: "0715357868",
    designation: "Software Engineer",
    personal_number: "654321",
    department_id: hr_department.id,
    job_group_id: job_group.id,
    gender: "Female"
  })
  |> Ecto.Changeset.put_assoc(:roles, [user_role])
  |> Repo.insert!()

IO.puts("✅ Seeded users: #{user_1.email}, #{user_2.email}")

# === Fetch all leave types ===
leave_types = Repo.all(LeaveType)

# === Assign balances with 0 to each user, with gender-specific exclusions ===
assign_balances = fn user ->
  Enum.each(leave_types, fn leave_type ->
    skip =
      case {user.gender, leave_type.name} do
        {"Male", "Maternity Leave"} -> true
        {"Female", "Paternity Leave"} -> true
        _ -> false
      end

    unless skip do
      Repo.insert!(%LeaveBalance{
        user_id: user.id,
        leave_type_id: leave_type.id,
        remaining_days: 0
      })
    end
  end)
end

Enum.each([user_1, user_2], assign_balances)

IO.puts("✅ Assigned gender-aware leave balances to users.")
