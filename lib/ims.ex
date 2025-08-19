defmodule Ims do
  def context do
    quote do
      alias Ims.Repo
      import Ecto.Query
    end
  end

  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
