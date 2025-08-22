defmodule Ims.Repo.Migrations.CreateEmpowormentForm do
  use Ecto.Migration

  def change do
    create table(:survey_responses) do
      # Location / project meta
      add :project_name, :string, null: false
      add :location_text, :string
      add :county_id, references(:counties, on_delete: :restrict), null: false
      add :constituency_id, references(:constituencies, on_delete: :restrict), null: false
      add :ward_id, references(:wards, on_delete: :restrict), null: false
      add :date_of_data_collection, :date
      add :enumerator_name, :string

      # Section A — General
      add :respondent_name, :string
      # "male" | "female" | "other"
      add :gender, :string
      # "18_35" | "36_50" | "51_plus"
      add :age_bracket, :string
      # "youth" | "women" | "pwd" | "other"
      add :category, :string
      add :category_other, :string
      add :group_affiliation, :string
      add :contact_info, :string

      # Section B — Awareness & Participation
      add :aware_dp_visit, :boolean
      add :present_event, :boolean
      # "attendee" | "organizer" | "beneficiary" | "other"
      add :role_at_event, :string
      add :role_other, :string
      add :aware_funds, :boolean
      add :funds_declared_amount, :decimal, precision: 12, scale: 2

      # Section C — Fund Disbursement & Utilization
      add :received_funds, :boolean
      add :amount_received, :decimal, precision: 12, scale: 2
      add :date_received, :date
      add :activities_implemented, :text
      add :training_provided, :boolean
      add :training_desc, :text
      # "very_satisfied" | "satisfied" | "dissatisfied" | "very_dissatisfied"
      add :satisfaction, :string
      add :satisfaction_explain, :text
      # "very_high" | "high" | "moderate" | "low" | "no_impact"
      add :impact_rating, :string
      add :impact_explain, :text
      add :addressed_needs, :boolean
      add :addressed_explain, :text

      # Section D — Promises, Feedback & Follow-up
      add :promises_made, :boolean
      add :promises_desc, :text
      # "fully" | "partially" | "not_at_all"
      add :promises_fulfilled, :string
      add :promises_explain, :text
      add :consulted_after, :boolean
      add :followed_up, :boolean
      add :followup_frequency, :string

      # Section E — Recommendations
      add :challenges, :text
      add :improvements, :text
      add :other_comments, :text

      timestamps()
    end

    create index(:survey_responses, [:county_id])
    create index(:survey_responses, [:constituency_id])
    create index(:survey_responses, [:ward_id])
  end
end
