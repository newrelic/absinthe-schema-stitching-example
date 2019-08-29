# Copyright (c) New Relic Corporation. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaStitch.GraphQLClient do
  def request(
        url,
        query,
        variables
      ) do
    headers = ["Content-Type": "application/json"]

    body = %{
      query: query,
      variables: variables
    }

    HTTPoison.post(url, Jason.encode!(body), headers)
    |> parse
  end

  defp parse({:ok, %{status_code: 200, body: body}}) do
    Jason.decode!(body)
    |> case do
      %{"errors" => errors} -> {:error, "Response returned errors: #{inspect(errors)}"}
      %{"data" => data} -> {:ok, data}
    end
  end

  defp parse({:ok, %{status_code: status_code}}) do
    {:error, "Downstream server responsed with status #{status_code}"}
  end

  defp parse({:error, %{reason: reason}}) do
    {:error, "Error contacting downstream server: #{inspect(reason)}"}
  end
end
