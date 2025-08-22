defmodule Ims.Surveys.SurveyResponse do
  use Ecto.Schema
  import Ecto.Changeset

  schema "survey_responses" do
    field :project_name, :string
    field :location_text, :string
    field :date_of_data_collection, :date
    field :enumerator_name, :string

    belongs_to :county, Ims.Regions.County
    belongs_to :constituency, Ims.Regions.Constituency
    belongs_to :ward, Ims.Regions.Ward

    # Section A
    field :respondent_name, :string
    field :gender, :string
    field :age_bracket, :string
    field :category, :string
    field :category_other, :string
    field :group_affiliation, :string
    field :contact_info, :string

    # Section B
    field :aware_dp_visit, :boolean
    field :present_event, :boolean
    field :role_at_event, :string
    field :role_other, :string
    field :aware_funds, :boolean
    field :funds_declared_amount, :decimal

    # Section C
    field :received_funds, :boolean
    field :amount_received, :decimal
    field :date_received, :date
    field :activities_implemented, :string
    field :training_provided, :boolean
    field :training_desc, :string
    field :satisfaction, :string
    field :satisfaction_explain, :string
    field :impact_rating, :string
    field :impact_explain, :string
    field :addressed_needs, :boolean
    field :addressed_explain, :string

    # Section D
    field :promises_made, :boolean
    field :promises_desc, :string
    field :promises_fulfilled, :string
    field :promises_explain, :string
    field :consulted_after, :boolean
    field :followed_up, :boolean
    field :followup_frequency, :string

    # Section E
    field :challenges, :string
    field :improvements, :string
    field :other_comments, :string

    timestamps()
  end

  @gender ~w(male female other)
  @age ~w(18_35 36_50 51_plus)
  @category ~w(youth women pwd other)
  @role ~w(attendee organizer beneficiary other)
  @sat ~w(very_satisfied satisfied dissatisfied very_dissatisfied)
  @impact ~w(very_high high moderate low no_impact)
  @fulfilled ~w(fully partially not_at_all)

  def changeset(sr, attrs) do
    sr
    |> cast(attrs, __schema__(:fields))
    #
    # Always-required fields (including all Yes/No booleans themselves)
    #
    |> validate_required([
      :project_name,
      :location_text,
      :date_of_data_collection,
      :enumerator_name,
      :county_id,
      :constituency_id,
      :ward_id,
      :respondent_name,
      :gender,
      :age_bracket,
      :category,
      :group_affiliation,
      :contact_info,
      :aware_dp_visit,
      :present_event,
      :aware_funds,
      :activities_implemented,
      :received_funds,
      :training_provided,
      :satisfaction,
      :satisfaction_explain,
      :impact_rating,
      :impact_explain,
      :addressed_needs,
      :promises_made,
      :promises_fulfilled,
      :promises_explain,
      :consulted_after,
      :followed_up,
      :challenges,
      :improvements,
      :other_comments
    ])
    #
    # Conditional requireds
    #
    |> require_if(:category_other, fn cs -> get_field(cs, :category) == "other" end)
    |> require_if(:role_at_event, fn cs -> get_field(cs, :present_event) == true end)
    |> require_if(:role_other, fn cs -> get_field(cs, :role_at_event) == "other" end)
    |> require_if(:funds_declared_amount, fn cs -> get_field(cs, :aware_funds) == true end)
    |> require_if(:amount_received, fn cs -> get_field(cs, :received_funds) == true end)
    |> require_if(:date_received, fn cs -> get_field(cs, :received_funds) == true end)
    |> require_if(:training_desc, fn cs -> get_field(cs, :training_provided) == true end)
    |> require_if(:addressed_explain, fn cs -> get_field(cs, :addressed_needs) == true end)
    |> require_if(:promises_desc, fn cs -> get_field(cs, :promises_made) == true end)
    |> require_if(:followup_frequency, fn cs -> get_field(cs, :followed_up) == true end)
    #
    # Inclusions (only validate role_at_event when applicable)
    #
    |> validate_inclusion(:gender, @gender, message: "invalid gender")
    |> validate_inclusion(:age_bracket, @age, message: "invalid age bracket")
    |> validate_inclusion(:category, @category, message: "invalid category")
    |> maybe_validate_inclusion(:role_at_event, @role, fn cs ->
      get_field(cs, :present_event) == true
    end)
    |> validate_inclusion(:satisfaction, @sat, message: "invalid satisfaction")
    |> validate_inclusion(:impact_rating, @impact, message: "invalid impact rating")
    |> validate_inclusion(:promises_fulfilled, @fulfilled, message: "invalid value")
    #
    # Numbers must be non-negative when provided
    #
    |> validate_number(:funds_declared_amount, greater_than_or_equal_to: 0)
    |> validate_number(:amount_received, greater_than_or_equal_to: 0)
    #
    # Associations
    #
    |> assoc_constraint(:county)
    |> assoc_constraint(:constituency)
    |> assoc_constraint(:ward)
  end

  #
  # Helpers
  #
  defp require_if(changeset, field, predicate_fun) when is_function(predicate_fun, 1) do
    if predicate_fun.(changeset) do
      validate_required(changeset, [field])
    else
      changeset
    end
  end

  defp maybe_validate_inclusion(changeset, field, allowed, predicate_fun)
       when is_list(allowed) and is_function(predicate_fun, 1) do
    if predicate_fun.(changeset) do
      validate_inclusion(changeset, field, allowed)
    else
      changeset
    end
  end

  # Expose option lists for the form
  def gender_options, do: [{"Male", "male"}, {"Female", "female"}, {"Other", "other"}]
  def age_options, do: [{"18–35", "18_35"}, {"36–50", "36_50"}, {"51+", "51_plus"}]

  def category_options,
    do: [{"Youth", "youth"}, {"Women", "women"}, {"PWD", "pwd"}, {"Other", "other"}]

  def role_options,
    do: [
      {"Attendee", "attendee"},
      {"Organizer", "organizer"},
      {"Beneficiary", "beneficiary"},
      {"Other", "other"}
    ]

  def satisfaction_options,
    do: [
      {"Very satisfied", "very_satisfied"},
      {"Satisfied", "satisfied"},
      {"Dissatisfied", "dissatisfied"},
      {"Very dissatisfied", "very_dissatisfied"}
    ]

  def impact_options,
    do: [
      {"Very High", "very_high"},
      {"High", "high"},
      {"Moderate", "moderate"},
      {"Low", "low"},
      {"No Impact", "no_impact"}
    ]

  def fulfilled_options,
    do: [{"Fully", "fully"}, {"Partially", "partially"}, {"Not at all", "not_at_all"}]
end
