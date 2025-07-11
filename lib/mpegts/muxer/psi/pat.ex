defmodule Membrane.MPEGTS.Muxer.PAT do
  @moduledoc false

  @doc """
  Returns serialized Program Association Table pointin to a single program number
  which description is provided in a Program Map Table with given PID.
  """
  @spec serialize(non_neg_integer(), non_neg_integer()) :: binary()
  def serialize(program_number, pmt_pid) do
    # CONTENT
    # we assume that we have only a single program
    program_description = generate_program_description(program_number, pmt_pid)

    # HEADER
    table_id = 0x00
    section_syntax_indicator = 1
    # There are 4 bytes in crc32 and 5 bytes in the
    # header behind this field
    section_length = byte_size(program_description) + 5 + 4
    # We are free to choose any value
    transport_stream_id = 0x0001
    version_number = 0
    current_next_indicator = 1
    # we only have one section
    section_number = 0
    last_section_number = 0

    header =
      <<table_id::8, section_syntax_indicator::1, 0::1, 0b11::2, section_length::12,
        transport_stream_id::16, 0b11::2, version_number::5, current_next_indicator::1,
        section_number::8, last_section_number::8>>

    # CRC32
    crc32_value = CRC.calculate(header <> program_description, :crc_32_mpeg_2)
    crc32 = <<crc32_value::32>>
    header <> program_description <> crc32
  end

  defp generate_program_description(program_number, pmt_pid) do
    <<program_number::16, 0b111::3, pmt_pid::13>>
  end
end
