# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaStitch.QueryGenerator do
  @moduledoc """
  Takes an Absinthe resolution struct and generates the relevant GraphQL query and variables.
  """
  alias Absinthe.Blueprint

  @typename_field %Blueprint.Document.Field{name: "__typename"}

  def render(%{definition: tree, path: path, fragments: fragments}) do
    root_operation_node = List.last(path)

    used_fragments = gather_fragments(tree, fragments)
    used_variables = gather_variables(tree, used_fragments)

    query = build_query(tree, root_operation_node, used_variables, used_fragments)

    {query, used_variables}
  end

  defp gather_fragments(tree, fragments) do
    used_fragments = gather_tree_fragments(tree) ++ gather_nested_fragments(fragments)

    Enum.filter(fragments, fn {name, _fragment} -> name in used_fragments end)
    |> Enum.into(%{})
  end

  defp gather_tree_fragments(%{selections: selections}) do
    Enum.flat_map(selections, &gather_tree_fragments(&1))
  end

  defp gather_tree_fragments(%Blueprint.Document.Fragment.Spread{name: name}) do
    [name]
  end

  defp gather_nested_fragments(fragments) do
    Enum.flat_map(fragments, fn {_name, fragment} -> gather_tree_fragments(fragment) end)
  end

  def gather_variables(tree, fragments) do
    (gather_tree_variables(tree) ++ gather_fragment_variables(fragments))
    |> Enum.into(%{})
  end

  defp gather_tree_variables(%Blueprint.Document.Field{arguments: arguments, selections: []}) do
    gather_arguments(arguments)
  end

  defp gather_tree_variables(%Blueprint.Document.Field{
         arguments: arguments,
         selections: selections
       }) do
    argument_names = gather_arguments(arguments)

    Enum.reduce(selections, argument_names, fn selection, acc ->
      acc ++ gather_tree_variables(selection)
    end)
  end

  defp gather_tree_variables(%{selections: selections}) do
    Enum.reduce(selections, [], fn selection, acc ->
      acc ++ gather_tree_variables(selection)
    end)
  end

  defp gather_tree_variables(_) do
    []
  end

  defp gather_fragment_variables(fragments) do
    Enum.reduce(fragments, [], fn {_name, fragment}, acc ->
      acc ++ gather_tree_variables(fragment)
    end)
  end

  def gather_arguments(arguments) do
    arguments
    |> Enum.map(&select_variable_arguments/1)
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp select_variable_arguments(%{
         input_value: %{
           raw: %Blueprint.Input.RawValue{content: %Blueprint.Input.Variable{name: name}},
           data: data
         }
       }) do
    {name, data}
  end

  defp select_variable_arguments(%{
         input_value: %{
           normalized: %Absinthe.Blueprint.Input.Object{fields: fields}
         }
       }) do
    Enum.map(fields, &select_variable_arguments(&1))
  end

  defp select_variable_arguments(_argument) do
    nil
  end

  @indent_increment 2
  defp build_query(tree, root_operation_node, used_variables, fragments) do
    root_operation_type = build_operation_type(root_operation_node)
    root_operation_name = build_operation_name(root_operation_node)

    root_operation_variables = build_operation_variables(root_operation_node, used_variables)

    field_selection = build_field_selection(tree, @indent_increment)
    spread_fragments = build_fragments(fragments)

    "#{root_operation_type}#{root_operation_name}#{root_operation_variables} " <>
      "{\n#{field_selection}\n}#{spread_fragments}"
  end

  defp build_operation_type(%Blueprint.Document.Operation{type: operation_type}) do
    "#{operation_type}"
  end

  defp build_operation_name(%Blueprint.Document.Operation{name: nil}) do
    ""
  end

  defp build_operation_name(%Blueprint.Document.Operation{name: operation_name}) do
    " #{operation_name}"
  end

  defp build_operation_variables(
         %Blueprint.Document.Operation{variable_definitions: variable_definitions},
         used_variables
       ) do
    used_variable_names = Map.keys(used_variables)

    variable_definitions
    |> Enum.filter(&(&1.name in used_variable_names))
    |> Enum.map(&build_operation_variable_definition/1)
    |> Enum.join(", ")
    |> case do
      "" -> ""
      variables -> "(#{variables})"
    end
  end

  defp build_operation_variable_definition(%Blueprint.Document.VariableDefinition{
         name: name,
         type: type
       }) do
    "$#{name}: #{build_variable_typename(type)}"
  end

  defp build_variable_typename(%Blueprint.TypeReference.NonNull{of_type: of_type}) do
    build_variable_typename(of_type) <> "!"
  end

  defp build_variable_typename(%Blueprint.TypeReference.List{of_type: of_type}) do
    "[" <> build_variable_typename(of_type) <> "]"
  end

  defp build_variable_typename(%Blueprint.TypeReference.Name{name: typename}) do
    typename
  end

  defp build_field_selection(
         %Blueprint.Document.Fragment.Inline{
           selections: children,
           schema_node: %{name: type_name}
         },
         indent_level
       ) do
    indent = String.duplicate(" ", indent_level)

    subtree =
      Enum.map(children, &build_field_selection(&1, indent_level + @indent_increment))
      |> Enum.join("\n")

    "#{indent}... on #{type_name} {\n#{subtree}\n#{indent}}"
  end

  defp build_field_selection(
         %Blueprint.Document.Field{selections: []} = blueprint_node,
         indent_level
       ) do
    String.duplicate(" ", indent_level) <> build_field_name(blueprint_node)
  end

  defp build_field_selection(
         %Blueprint.Document.Field{selections: children} = blueprint_node,
         indent_level
       ) do
    indent = String.duplicate(" ", indent_level)
    field_name = build_field_name(blueprint_node)

    subtree =
      [@typename_field | children]
      |> Enum.map(&build_field_selection(&1, indent_level + @indent_increment))
      |> Enum.join("\n")

    "#{indent}#{field_name} {\n#{subtree}\n#{indent}}"
  end

  defp build_field_selection(
         %Blueprint.Document.Fragment.Spread{name: fragment_name},
         indent_level
       ) do
    indent = String.duplicate(" ", indent_level)
    "#{indent}...#{fragment_name}"
  end

  defp build_field_name(%Blueprint.Document.Field{name: name, arguments: args}) do
    args
    |> exclude_args_with_default_values
    |> case do
      [] -> name
      used_input_args -> "#{name}(#{build_input_args(used_input_args)})"
    end
  end

  defp exclude_args_with_default_values(args) do
    Enum.reject(args, fn
      %{
        input_value: %Blueprint.Input.Value{
          normalized: %Absinthe.Blueprint.Input.Generated{}
        }
      } ->
        true

      _ ->
        false
    end)
  end

  defp build_input_args(args) do
    Enum.map(args, &build_input_arg(&1)) |> Enum.join(", ")
  end

  defp build_input_arg(%{
         name: arg_name,
         input_value: input_value
       }) do
    "#{arg_name}: #{build_input_value(input_value)}"
  end

  defp build_input_value(%Blueprint.Input.Value{
         raw: %Blueprint.Input.RawValue{content: %Blueprint.Input.Variable{name: var_name}}
       }) do
    "$#{var_name}"
  end

  defp build_input_value(%Blueprint.Input.Value{
         normalized: %Blueprint.Input.String{value: value}
       }) do
    "\"#{value}\""
  end

  defp build_input_value(%Blueprint.Input.Value{
         normalized: %Blueprint.Input.Object{fields: sub_fields}
       }) do
    "{ #{build_input_args(sub_fields)} }"
  end

  defp build_input_value(%Blueprint.Input.Value{
         normalized: %Blueprint.Input.List{items: items}
       }) do
    list_items = Enum.map(items, &build_input_value/1) |> Enum.join(", ")
    "[ #{list_items} ]"
  end

  defp build_input_value(%Blueprint.Input.Value{
         normalized: %Blueprint.Input.Null{}
       }) do
    "null"
  end

  defp build_input_value(%Blueprint.Input.Value{normalized: %{value: value}}) do
    value
  end

  defp build_fragments(fragments) do
    Enum.map(fragments, &build_fragment(&1))
    |> Enum.join("")
  end

  defp build_fragment(
         {fragment_name, %{type_condition: %{name: type_name}, selections: children}}
       ) do
    subtree = Enum.map(children, &build_field_selection(&1, @indent_increment)) |> Enum.join("\n")

    "\n\nfragment #{fragment_name} on #{type_name} {\n#{subtree}\n}"
  end
end
