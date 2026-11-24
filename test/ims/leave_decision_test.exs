defmodule Ims.LeaveDecisionTest do
  use Ims.DataCase

  alias Ims.Accounts.User
  alias Ims.Leave.{LeaveApplication, LeaveBalance, LeaveType}

  test "annual leave approval and rejection persist second-precision decision timestamps" do
    employee = Repo.insert!(%User{first_name: "Leave", last_name: "Applicant"})
    reviewer = Repo.insert!(%User{first_name: "Leave", last_name: "Reviewer"})
    type = Repo.insert!(%LeaveType{name: "Annual Leave", default_days: 30, max_days: 30})
    start_date = Date.add(Ims.Leave.AnnualLeave.today(), 1)

    application = %LeaveApplication{
      user_id: employee.id,
      leave_type_id: type.id,
      start_date: start_date,
      end_date: start_date,
      days_requested: 1,
      status: "pending"
    }

    approved = Repo.insert!(application)
    rejected = Repo.insert!(application)

    assert {:ok, %{status: "approved", decided_at: %DateTime{microsecond: {0, 0}}}} =
             LeaveApplication.approve_leave_application(approved.id, reviewer)

    assert {:ok, %{status: "rejected", decided_at: %DateTime{microsecond: {0, 0}}}} =
             LeaveApplication.reject_leave_application(rejected.id, reviewer)

    balance = Repo.get_by(LeaveBalance, user_id: employee.id, leave_type_id: type.id)
    assert Decimal.eq?(balance.remaining_days, 29)
  end
end
