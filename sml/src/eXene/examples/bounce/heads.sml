(* heads.sml
 *
 * COPYRIGHT (c) 1990,1991 by John H. Reppy.  See COPYRIGHT file for details.
 *)

structure Heads =
  struct

    val xlogo_data = EXeneBase.imageFromAscii (32, [[
            "0b11111111000000000000000000000011",
            "0b01111111100000000000000000000011",
            "0b00111111110000000000000000000110",
            "0b00011111111000000000000000001100",
            "0b00011111111000000000000000011000",
            "0b00001111111100000000000000110000",
            "0b00000111111110000000000001100000",
            "0b00000011111111000000000001100000",
            "0b00000011111111000000000011000000",
            "0b00000001111111100000000110000000",
            "0b00000000111111110000001100000000",
            "0b00000000011111111000011000000000",
            "0b00000000011111111000110000000000",
            "0b00000000001111111100110000000000",
            "0b00000000000111111101100000000000",
            "0b00000000000011111011000000000000",
            "0b00000000000011110111000000000000",
            "0b00000000000001101111100000000000",
            "0b00000000000011011111110000000000",
            "0b00000000000110011111111000000000",
            "0b00000000000110011111111000000000",
            "0b00000000001100001111111100000000",
            "0b00000000011000000111111110000000",
            "0b00000000110000000011111111000000",
            "0b00000001100000000011111111000000",
            "0b00000011000000000001111111100000",
            "0b00000011000000000000111111110000",
            "0b00000110000000000000011111111000",
            "0b00001100000000000000011111111000",
            "0b00011000000000000000001111111100",
            "0b00110000000000000000000111111110",
            "0b01100000000000000000000011111111"
          ]])

    val north_data = EXeneBase.imageFromAscii (48, [[
	    "0b000000000000000000000000000000000000000000000000",
	    "0b000000000000000000000101000000000000000000000000",
	    "0b000000000000000000111111111000000000000000000000",
	    "0b000000000000000101011111111111110000000000000000",
	    "0b000000000000001110111111111111111110000000000000",
	    "0b000000000000011101011111111111111111000000000000",
	    "0b000000000000111010111111111111111110100000000000",
	    "0b000000000001110101111111111111111111010000000000",
	    "0b000000000011111110111111111111111111100000000000",
	    "0b000000000111111101011111111111111111010000000000",
	    "0b000000000111111010101000001111101011101000000000",
	    "0b000000000111111101010000000111110101010100000000",
	    "0b000000001111111110100000001010101010101010000000",
	    "0b000000001111111101000000000101010101010100000000",
	    "0b000000001111111111100000000010101010101110000000",
	    "0b000000011111111111000000000001110111010111000000",
	    "0b000000111111111110000000000000111111111111000000",
	    "0b000000011111111100000000000000011111111111000000",
	    "0b000000111111111010000000000000001111111111100000",
	    "0b000000011111110100000000000000000111111111100000",
	    "0b000000111111101000000000000111101011111111100000",
	    "0b000000011111110111000000001100000101111111110000",
	    "0b000000111111100000111000001111101000111111111000",
	    "0b000000011111010111001000000111110000011111110000",
	    "0b000000111111101010001100000000000000111111111000",
	    "0b000000011111010000000100000000000000011111110000",
	    "0b000000111110000000001100000000000000111000100000",
	    "0b000000011111000000001100000000000000011101100000",
	    "0b000000001110100000001000000000000000111001000000",
	    "0b000000001111000000011000000000000000010001000000",
	    "0b000000001111100000011000000000000000100010000000",
	    "0b000000000111010000011100110000000001000100000000",
	    "0b000000000011100000001100000000000000111100000000",
	    "0b000000000001110000000000000000000001011100000000",
	    "0b000000000001111000000000000000000000111000000000",
	    "0b000000000000111100000000000000000001110000000000",
	    "0b000000000000111000111110011110000000100000000000",
	    "0b000000000000011100010000000000000001100000000000",
	    "0b000000000000011000000010000000000011100000000000",
	    "0b000000000000001101000000000000000101000000000000",
	    "0b000000000000001110100000000000001000000000000000",
	    "0b000000000000001101000000000000010001000000000000",
	    "0b000000000000001111100000000000111000000000000000",
	    "0b000000000000000111110000000001110001000000000000",
	    "0b000000000000001111111011111111100000000000000000",
	    "0b000000000000011111111111110000000001000000000000",
	    "0b000000000000011111111000000000000001100000000000",
	    "0b000000000000111100000100000000000001100000000000"
	  ]])
    val bala_data = EXeneBase.imageFromAscii (48, [[
	    "0x000000000000", "0x000000000000",
	    "0x00001ffe0000", "0x00007fff8000",
	    "0x0001ffffe000", "0x0003fffff000",
	    "0x0007fffff800", "0x001ffed5fc00",
	    "0x003ff5aa7e00", "0x001f8ab4bf00",
	    "0x001f554a7f00", "0x007f0a240f00",
	    "0x007e10c83f80", "0x007d02101f80",
	    "0x00fe04a02f80", "0x02fc10001fc0",
	    "0x00fd02a00fc0", "0x03fc097f0fe0",
	    "0x00fbffec47e0", "0x02fefffe07ff",
	    "0x01fa7f3e27fc", "0x03fdbabd07fc",
	    "0x0fff7c7807fa", "0x0efdf85602fc",
	    "0x0ffcac3403ba", "0x03fa7810432c",
	    "0x07fc909e0278", "0x03f97f4c0078",
	    "0x03fc77e40040", "0x00dd6ffc0060",
	    "0x00fafefc0040", "0x00faff9e03c0",
	    "0x01fdb80203c0", "0x004b76a207e0",
	    "0x005fe7e087c0", "0x003f6a0127c0",
	    "0x0017dad04fe0", "0x001ff7c297c0",
	    "0x00137ffd47c0", "0x0010ffeba600",
	    "0x0008affe0900", "0x0000dffda600",
	    "0x0001f7f22400", "0x0000aded8c00",
	    "0x0001dbba2800", "0x0000d7681020",
	    "0x000044d07000", "0x00073a908800"
	  ]])
    val rob_data = EXeneBase.imageFromAscii (48, [[
	    "0x000000000000", "0x00000FBE0000",
	    "0x00015E7FC000", "0x000505018000",
	    "0x00055300B800", "0x000407C0E400",
	    "0x000003808F00", "0x000002884D00",
	    "0x00000000EF00", "0x000000011D80",
	    "0x00000157F380", "0x00402005FF00",
	    "0x008300017F80", "0x001E02AFFF80",
	    "0x00B85554BE80", "0x00F508AAAF80",
	    "0x01D0A357FF00", "0x00A5A80B7F00",
	    "0x00DFC242FF80", "0x007FB00FFF80",
	    "0x006FFD1FFD80", "0x005FFE77FB80",
	    "0x006FFFBFFFC0", "0x007EFFFFFDC0",
	    "0x005EFEF7FF80", "0x001EF6B27CC0",
	    "0x00666EFFFF80", "0x0007FF3FFD00",
	    "0x0027FE6FF980", "0x0007FE9BFD00",
	    "0x0027FD3FF900", "0x0001F3E02800",
	    "0x0001409D5400", "0x0000913EAC00",
	    "0x0001425A9800", "0x000000056800",
	    "0x00008AFF1400", "0x000016AE7800",
	    "0x000000088000", "0x000080B37000",
	    "0x000020214000", "0x0000940BF000",
	    "0x000068134000", "0x00001247D000",
	    "0x00006D9D6000", "0x0000176B9000",
	    "0x00006CDEB000", "0x000013256000"
	  ]])
    val dbm_data = EXeneBase.imageFromAscii (48, [[
	    "0x000002800000", "0x00003EBC0000",
	    "0x0000EA850000", "0x0001B801C000",
	    "0x0007C0004000", "0x000500000000",
	    "0x000D00002000", "0x001C00001000",
	    "0x000800000800", "0x003A00000800",
	    "0x001000000400", "0x003C00000200",
	    "0x000A00000A00", "0x003800000A00",
	    "0x001C00000800", "0x0019FA050E00",
	    "0x001A4EF7F400", "0x0011FF9ED400",
	    "0x00437EFBEC00", "0x0058AB9FE000",
	    "0x00422C8D0500", "0x0001550BC000",
	    "0x002801080A00", "0x0000AC020000",
	    "0x001A0400A000", "0x0000B5FE0800",
	    "0x000F17F9D000", "0x0005F3FEDC00",
	    "0x00077EF5E800", "0x0005EBFF7800",
	    "0x0007FFFFEC00", "0x0007FFFFF800",
	    "0x0002FF0BF000", "0x0007E96AD000",
	    "0x0003FFEFF000", "0x0003E9797000",
	    "0x0003FBEFF000", "0x0001FABBE000",
	    "0x0001EAEAF000", "0x0003FFABD000",
	    "0x0000F9FFF000", "0x0003FF79B000",
	    "0x00027DFFD200", "0x00035FFF7100",
	    "0x00017FFFA000", "0x00214BF4A900",
	    "0x00017FFFA000", "0x00418554C010"
	  ]])
    val dgb_data = EXeneBase.imageFromAscii (48, [[
	    "0x000000000000", "0x000000040000",
	    "0x000003ff8000", "0x00001fffc000",
	    "0x00003fffe000", "0x00007ffff000",
	    "0x0000fffffa00", "0x0001ffffff00",
	    "0x0003ffffff80", "0x0007ffffffc0",
	    "0x000fffe82fe0", "0x001fff4017f0",
	    "0x003ffe000bf8", "0x001fd00007f0",
	    "0x003f800003f8", "0x007f000007f0",
	    "0x007e800003f8", "0x007d000007f8",
	    "0x007e000003f8", "0x007fd01507f8",
	    "0x003ffefe83f8", "0x007f541047f8",
	    "0x003eef2eaff8", "0x003f5c17f5f0",
	    "0x000b8c088380", "0x000d1c004100",
	    "0x000a08000200", "0x000e18100008",
	    "0x000eb8000208", "0x000c1c400600",
	    "0x000e0e000a00", "0x000c14000440",
	    "0x000e28000840", "0x000c54000400",
	    "0x000e38380f80", "0x000415000400",
	    "0x00060a000800", "0x000715001c00",
	    "0x00028a003800", "0x000150017000",
	    "0x0003e002e800", "0x005fd005c400",
	    "0x00ffea2a8800", "0x015fff450c00",
	    "0xc09bf80a0880", "0x005d7d540840",
	    "0x00b8ba800800", "0x001c15001000"
	  ]])
    val att_data = EXeneBase.imageFromAscii (38, [[
	    "0b00000000000000111111111000000000000000",
	    "0b00000000000111111111111111000000000000",
	    "0b00000000001111111111111111110000000000",
	    "0b00000000000000000000000000000000000000",
	    "0b00000001000000000011111111111110000000",
	    "0b00000011111111111111111111111111000000",
	    "0b00000000000000000000011111111111100000",
	    "0b00000000000000000000000000000000000000",
	    "0b00011111111111111111111111111111110000",
	    "0b00011111111111111111111111111111111000",
	    "0b00000000000000000000000001111111111000",
	    "0b00000000000000000000000000001111111100",
	    "0b01111111111111111111111111111111111100",
	    "0b01111111111111111111111111111111111100",
	    "0b00000000000000000000000000001111111110",
	    "0b00000000000000000000000000111111111110",
	    "0b11111111111111111111111111111111111110",
	    "0b11111111111111111111111111111111111110",
	    "0b00000000000000000000000000000000000000",
	    "0b11000000000000000000000111111111111110",
	    "0b11111111111111111111111111111111111110",
	    "0b01111111111111111111111111111111111110",
	    "0b00000000000000000000000000000000000000",
	    "0b01111110000000000111111111111111111110",
	    "0b01111111111111111111111111111111111110",
	    "0b01111111111111111111111111111111111100",
	    "0b00100000000000000000000000000000000000",
	    "0b00111111111111111111111111111111111000",
	    "0b00011111111111111111111111111111111000",
	    "0b00001111111111111111111111111111110000",
	    "0b00000000000000000000000000000000000000",
	    "0b00000111111111111111111111111111100000",
	    "0b00000011111111111111111111111111000000",
	    "0b00000001111111111111111111111100000000",
	    "0b00000000001111111111111111110000000000",
	    "0b00000000001111111111111111100000000000",
	    "0b00000000000001111111111110000000000000",
	    "0b00000000000000000000000000000000000000"
	  ]])

    val headDataList = [
	    xlogo_data,
	    north_data,
	    bala_data,
	    rob_data,
	    dbm_data,
	    dgb_data,
	    att_data
	  ]

  end (* Heads *)
