defmodule CodepagexTest do
  use ExUnit.Case

  @iso_hello "hello "<> <<230, 248, 229>>
  @missing "Missing code point"

  test "list_codepages should return some existing values" do
    assert "ETSI/GSM0338" in Codepagex.list_mappings
    assert "VENDORS/NEXT/NEXTSTEP" in Codepagex.list_mappings
  end

  test "aliases should contain come aliases" do
    assert Codepagex.aliases.iso_8859_1 == "ISO8859/8859-1"
    assert Codepagex.aliases.iso_8859_5 == "ISO8859/8859-5"
  end

  test "to_string should work for ISO8859/8859-1" do
    assert Codepagex.to_string("ISO8859/8859-1", @iso_hello) == {:ok, "hello æøå"}
  end

  test "to_string should work for alias :iso_8859_1" do
    assert Codepagex.to_string(:iso_8859_1, @iso_hello) == {:ok, "hello æøå"}
  end

  test "to_string should work for ETSI/GSM0338" do
    assert Codepagex.to_string("ETSI/GSM0338", <<96>>) == {:ok, "¿"}
  end

  test "to_string should fail for ETSI/GSM0338 undefined character" do
    assert Codepagex.to_string("ETSI/GSM0338", <<128>>) == {:error, @missing}
  end

  test "to_string should fail for ETSI/GSM0338 single escape character" do
    assert Codepagex.to_string("ETSI/GSM0338", <<27>>) == {:error, @missing}
  end

  test "to_string should succeed for ETSI/GSM0338 multibyte character" do
    assert Codepagex.to_string("ETSI/GSM0338", <<27, 101>>) == {:ok, "€"}
  end

  test "to_string! should work for ETSI/GSM0338" do
    assert Codepagex.to_string!("ETSI/GSM0338", <<96>>) == "¿"
  end

  test "to_string! should fail for ETSI/GSM0338 undefined character" do
    assert_raise RuntimeError, fn ->
      Codepagex.to_string!("ETSI/GSM0338", <<128>>)
    end
  end

  test "to_string returns error on unknown mapping" do
    assert Codepagex.to_string(:unknown, "test")
            == {:error, "Unknown mapping :unknown"}
    assert Codepagex.to_string("bogus", "test")
            == {:error, "Unknown mapping \"bogus\""}
  end

  test "from_string should work for ISO8859/8859-1" do
    assert Codepagex.from_string("ISO8859/8859-1", "hello æøå") == {:ok, @iso_hello}
  end

  test "from_string should work for alias :iso_8859_1" do
    assert Codepagex.from_string(:iso_8859_1, "hello æøå") == {:ok, @iso_hello}
  end

  test "from_string should work for ETSI/GSM0338" do
    assert Codepagex.from_string("ETSI/GSM0338", "¿") == {:ok, <<96>>}
  end

  test "from_string should fail for ETSI/GSM0338 undefined character" do
    assert Codepagex.from_string("ETSI/GSM0338", "൨") == {:error, @missing}
  end

  test "from_string should succeed for ETSI/GSM0338 multibyte character" do
    assert Codepagex.from_string("ETSI/GSM0338", "€") == {:ok, <<27, 101>>}
  end

  test "from_string! should work for ETSI/GSM0338" do
    assert Codepagex.from_string!("ETSI/GSM0338", "¿") == <<96>>
  end

  test "from_string! should raise exception for undefined character" do
    assert_raise RuntimeError, fn ->
      Codepagex.from_string!("ETSI/GSM0338", "൨")
    end
  end

  test "translate works between ISO8859/8859-1 and ETSI/GSM0338" do
    assert Codepagex.translate(:iso_8859_1, "ETSI/GSM0338", @iso_hello)
      == {:ok, "hello " <> <<29, 12, 15>>}
  end

  test "translate! works between ISO8859/8859-1 and ETSI/GSM0338" do
    assert Codepagex.translate!(:iso_8859_1, "ETSI/GSM0338", @iso_hello)
      == "hello " <> <<29, 12, 15>>
  end

  test "translate! raises exception on failure" do
    assert_raise RuntimeError, fn ->
      Codepagex.translate!(:iso_8859_1, "ETSI/GSM0338", "൨")
    end
  end
end
