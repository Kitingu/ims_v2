defmodule ImsWeb.Select2 do
  use Phoenix.LiveComponent

  def render(assigns) do
    # Derive the name and value from the form and field
    name = Phoenix.HTML.Form.input_name(assigns.form, assigns.field)
    value = Phoenix.HTML.Form.input_value(assigns.form, assigns.field)

    assigns = assign(assigns, name: name, value: value)

    ~H"""
    <select id={@id} name={@name} class="form-select">
      <%= for {label, option_value} <- @options do %>
        <option value={option_value} selected={@value == option_value}><%= label %></option>
      <% end %>
    </select>
    """
  end
end
