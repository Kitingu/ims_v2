alias Ims.Repo
alias Ims.Accounts.{Role, Departments, Permission, JobGroup}

admin_role = Repo.insert!(%Role{name: "Admin"})
user_role = Repo.insert!(%Role{name: "User"})
# Insert permissions
Permission.insert_permissions()
IO.puts("Permissions inserted.")

# Assign permissions to admin role
admin_role = Repo.get_by(Role, name: "Admin")
permissions = Repo.all(Permission)

Permission.assign_permissions_to_role(admin_role, permissions)

it_department = Repo.insert!(%Departments{name: "IT"})
hr_department = Repo.insert!(%Departments{name: "HR"})

job_group = Repo.insert!(%JobGroup{name: "k"})
job_group_1 = Repo.insert!(%JobGroup{name: "S"})

# Store in app env for access in later files
Application.put_env(:ims, :seed_data, %{
  admin_role: admin_role,
  user_role: user_role,
  it_department: it_department,
  hr_department: hr_department,
  job_group: job_group,
  job_group_1: job_group_1
})

IO.puts("Seeded roles, departments, and job groups.")
