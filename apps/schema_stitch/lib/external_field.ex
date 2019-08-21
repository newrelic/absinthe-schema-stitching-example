defmodule SchemaStitch.ExternalField do
  @moduledoc """
  ExternalField will do things like intelligently convert ENUM_STRINGS to absinthe :enum_atoms, and
  respect camelCase data from the downstream server instead of requiring snake_case.
  """

  def tag_or_extract_resolution_field(
        %{
          source: {:external, source},
          schema: schema,
          definition: %{name: name, schema_node: %{type: type}}
        } = resolution
      ) do
    %{
      resolution
      | state: :resolved,
        value: tag_or_extract_value(schema, type, name, source)
    }
  end

  def tag_or_extract_value(schema, type, name, source) do
    get_type(schema, type)
    |> get_external_value(name, source)
  end

  defp get_external_value(%Absinthe.Type.Scalar{} = type, name, source) do
    with value <- Map.get(source, name) do
      transform_external_value(type, value)
    end
  end

  defp get_external_value({%Absinthe.Type.List{}, sub_type}, name, source) do
    with list when not is_nil(list) <- Map.get(source, name) do
      Enum.map(list, &transform_external_value(sub_type, &1))
    end
  end

  defp get_external_value(%Absinthe.Type.Enum{} = type, name, source) do
    with enum_name when not is_nil(enum_name) <- Map.get(source, name) do
      transform_external_value(type, enum_name)
    end
  end

  defp get_external_value(type, name, source) do
    with value when not is_nil(value) <- Map.get(source, name) do
      transform_external_value(type, value)
    end
  end

  defp get_type(schema, %Absinthe.Type.NonNull{of_type: type}) do
    get_type(schema, type)
  end

  defp get_type(schema, %Absinthe.Type.List{of_type: sub_type_id} = type_id) do
    {type_id, get_type(schema, sub_type_id)}
  end

  defp get_type(schema, type_id) do
    Absinthe.Schema.lookup_type(schema, type_id)
  end

  defp transform_external_value(%Absinthe.Type.Scalar{}, value) do
    value
  end

  defp transform_external_value(%Absinthe.Type.Enum{} = type, enum_name) do
    type.values_by_name()
    |> Map.get(enum_name)
    |> Map.get(:value)
  end

  defp transform_external_value(_type, value) do
    {:external, value}
  end
end
