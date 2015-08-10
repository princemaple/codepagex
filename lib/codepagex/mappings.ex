defmodule Codepagex.Mappings.Helpers do
  @moduledoc false

  def name_for_file(filename) do
    Regex.run(~r|unicode/(.*)[.]txt|i, filename)
    |> Enum.at(1)
  end

  def function_name_for_mapping_name(prefix, mapping_name) do
    mapping_part =
      mapping_name
      |> String.replace(~r|[-/]|, "_")
      |> String.downcase
    :"#{prefix}_#{mapping_part}"
  end

  defmacro def_to_string(name, mapping) do
    quote(bind_quoted: [n: name, m: mapping], unquote: false) do
      alias Codepagex.Mappings.Helpers
      fn_name = Helpers.function_name_for_mapping_name("to_string", n)

      for {from, to} <- m do
        def unquote(fn_name)(unquote(from) <> rest, acc) do
          unquote(fn_name)(rest, [unquote(to) | acc])
        end
      end

      def unquote(fn_name)("", acc) do
        rev = acc |> :lists.reverse
        result = for code_point <- rev, into: "", do: <<code_point :: utf8>>
        {:ok, result}
      end

      def unquote(fn_name)(_, _) do
        {:error, "Missing code point"}
      end

      # TODO: Have a way to deal with missing code points
    end
  end

  defmacro def_from_string(name, mapping) do
    quote(bind_quoted: [n: name, m: mapping], unquote: false) do
      alias Codepagex.Mappings.Helpers
      fn_name = Helpers.function_name_for_mapping_name("from_string", n)

      for {to, from} <- m do
        def unquote(fn_name)(<<unquote(from) :: utf8>> <> rest, acc) do
          unquote(fn_name)(rest, [unquote(to) | acc])
        end
      end

      def unquote(fn_name)("", acc) do
        rev = acc |> :lists.reverse
        result = for chars <- rev, into: "", do: chars
        {:ok, result}
      end

      def unquote(fn_name)(_, _) do
        {:error, "Missing code point"}
      end

      # TODO: Have a way to deal with missing code points
    end
  end
end

defmodule Codepagex.Mappings do
  @moduledoc false

  require Codepagex.Mappings.Helpers
  alias Codepagex.Mappings.Helpers

  # A lot of encoding are left out as they have unsupported codepoints
  # dealing with left-right and double utf codepoints
  #
  # IBMGRAPH: This has a different file format
  # WINDOWS/CP9__: These are large
  # VENDORS/MISC/KPS9566: Large
  #
  @mapping_folder Path.join([__DIR__] ++ ~w(.. .. unicode))
  @mapping_files (
    @mapping_folder
    |> Path.join(Path.join(~w(** *.TXT)))
    |> Path.wildcard
    |> Enum.reject(&(String.match?(&1, ~r[README]i)))
    |> Enum.reject(&(String.match?(&1, ~r[VENDORS/APPLE]i)))
    |> Enum.reject(&(String.match?(&1, ~r[MISC/IBMGRAPH]i)))
    |> Enum.reject(&(String.match?(&1, ~r[VENDORS/MICSFT/WINDOWS/CP9]i)))
    |> Enum.reject(&(String.match?(&1, ~r[VENDORS/MISC/KPS9566]i)))
    )
  @names_files for n <- @mapping_files, do: {Helpers.name_for_file(n), n}, into: %{}
  @names @names_files |> Dict.keys |> Enum.sort

  # load mapping files
  @mappings (for {name, file} <- @names_files, 
              do: {name, Codepagex.MappingFile.load(file)})

  def list_mappings, do: @names

  # define the to_string_xxx for each mapping
  for {n, m} <- @mappings, do: Helpers.def_to_string(n, m)

  # define methods to forward to_string(mapping, binary) to a specific implementation
  for name <- @names do
    def to_string(unquote(name |> String.to_atom), binary) do
      unquote(Helpers.function_name_for_mapping_name("to_string", name))(binary, [])
    end
  end

  def to_string(mapping, _), do: {:error, "Unknown mapping #{inspect mapping}"}

  # define the from_string_xxx for each mapping
  for {n, m} <- @mappings, do: Helpers.def_from_string(n, m)

  # define methods to forward from_string(mapping, binary) to a specific implementation
  for name <- @names do
    def from_string(unquote(name |> String.to_atom), binary) do
      unquote(Helpers.function_name_for_mapping_name("from_string", name))(binary, [])
    end
  end

  def from_string(mapping, _), do: {:error, "Unknown mapping #{inspect mapping}"}
end

