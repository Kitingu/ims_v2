defmodule Ims.RepoHelpers do
  import Ecto.Query, only: [from: 1, from: 2]

  defmacro __using__(opts) do
    quote do
      import Ecto.Query, only: [from: 1, from: 2]

      @repo Keyword.fetch!(unquote(opts), :repo)
      @filterable Keyword.get(unquote(opts), :filterable, [])

      def get!(queryable \\ __MODULE__, id)
      def get!(queryable, id), do: @repo.get!(queryable, id)
      def get(queryable \\ __MODULE__, id), do: @repo.get(queryable, id)

      def one!(queryable \\ __MODULE__), do: @repo.one!(queryable)
      def one(queryable \\ __MODULE__), do: @repo.one(queryable)

      def count(queryable \\ __MODULE__) do
        @repo.one(from(queryable, select: count("*")))
      end

      def all(queryable \\ __MODULE__, opts \\ []) do
        query = Ims.RepoHelpers.query_from_opts(queryable, opts)

        from(q in query)
        |> @repo.all(opts)
      end

      def newest(queryable \\ __MODULE__) do
        from(
          m in queryable,
          order_by: [
            desc: :id
          ],
          limit: 1
        )
        |> @repo.one
      end

      def delete(id) when is_binary(id) or is_integer(id) do
        # use delete_all so we dont to load the record first
        from(m in __MODULE__, where: m.id == ^id)
        |> @repo.delete_all()
      end

      def paginate(queryable, params, opts \\ []) do
        queryable
        |> Ims.RepoHelpers.query_from_opts(opts)
        |> @repo.paginate(params)
      end

      def filter_query(queryable \\ __MODULE__, filters) do
        @filterable
        |> Enum.reduce(queryable, fn
          {field, type}, query ->
            query_by_field_type(query, {field, type}, Map.get(filters, to_string(field)))

          field, query ->
            query_by_field_type(query, field, Map.get(filters, to_string(field)))
        end)
      end

      defmacro date_trunc(interval, right, _typed = true) do
        quote do
          type(
            fragment("date_trunc(?, ?)", ~s(#{unquote(interval)}), unquote(right)),
            :naive_datetime_usec
          )
        end
      end

      defmacro date_trunc(interval, right) do
        quote do
          fragment("date_trunc(?, ?)", ~s(#{unquote(interval)}), unquote(right))
        end
      end

      defp query_by_field_type(queryable, _field, nil), do: queryable
      defp query_by_field_type(queryable, _field, ""), do: queryable

      defp query_by_field_type(queryable, {field, type}, value) do
        case type do
          :text -> from(q in queryable, where: ilike(field(q, ^field), ^"%#{value}%"))
          _ -> from(q in queryable, where: field(q, ^field) == ^value)
        end
      end

      defp query_by_field_type(queryable, field, value) do
        from(q in queryable, where: field(q, ^field) == ^value)
      end

      defoverridable get: 2, get!: 2, filter_query: 1, filter_query: 2

      def query_from_opts(queryable, opts) do
        Ims.RepoHelpers.query_from_opts(queryable, opts)
      end
    end
  end

  @doc """
  Add selects, offsets, limits and order_by clauses from opts

  ## Options

    - :select - Columns to select
    - :offset - Number of rows to offset
    - :limit - Number of rows to return
    - :order_by - Columns to sort by
  """
  @spec query_from_opts(Ecto.Queryable.t(), Keyword.t()) :: Ecto.Query.t()
  def query_from_opts(queryable, opts) do
    {columns, opts} = Keyword.pop(opts, :select, [])
    {offset, opts} = Keyword.pop(opts, :offset)
    {limit, opts} = Keyword.pop(opts, :limit)
    {order_by, _opts} = Keyword.pop(opts, :order_by)

    select_for_opts(queryable, columns)
    |> order_by_for_opts(order_by)
    |> offset_for_opts(offset)
    |> limit_for_opts(limit)
  end

  # explicit call to from for when a bare schem is passed in without options as this would just return the module
  defp select_for_opts(queryable, []), do: from(queryable)

  defp select_for_opts(queryable, columns) when is_list(columns) do
    from(queryable, select: ^columns)
  end

  defp order_by_for_opts(queryable, nil), do: queryable

  defp order_by_for_opts(queryable, order_by) do
    from(queryable, order_by: ^order_by)
  end

  defp offset_for_opts(queryable, nil), do: queryable

  defp offset_for_opts(queryable, offset) when offset >= 0 do
    from(queryable, offset: ^offset)
  end

  defp limit_for_opts(queryable, nil), do: queryable

  defp limit_for_opts(queryable, limit) when limit >= 0 do
    from(queryable, limit: ^limit)
  end
end
