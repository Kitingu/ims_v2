  alias Ims.Repo
alias Ims.Leave.LeaveType

leave_types = [
  %LeaveType{name: "Annual Leave", max_days: 45, carry_forward: true, requires_approval: true},
  %LeaveType{name: "Sick Leave", max_days: 30, carry_forward: false, requires_approval: true},
  %LeaveType{name: "Maternity Leave", max_days: 90, carry_forward: false, requires_approval: true},
  %LeaveType{name: "Paternity Leave", max_days: 10, carry_forward: false, requires_approval: true},
  %LeaveType{name: "Terminal Leave", max_days: 30, carry_forward: false, requires_approval: true}
]

Enum.each(leave_types, fn lt -> Repo.insert(lt) end)

IO.puts("Seeded leave types.")
