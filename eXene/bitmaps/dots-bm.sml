(* dots-bm.sml
 * this file created by bm2mlx
 * from:  mit/dots1x1 mit/dots2x2
 * on: Wed Mar  6 15:22:38 EST 1991
 *)
structure DotsBM =
  struct
    val dots1x1 = EXeneBase.IMAGE{
            sz = Geometry.SIZE{wid=16, ht=16},
            data = [[
                "\255\255",
                "\170\170",
                "\255\255",
                "\170\170",
                "\255\255",
                "\170\170",
                "\255\255",
                "\170\170",
                "\255\255",
                "\170\170",
                "\255\255",
                "\170\170",
                "\255\255",
                "\170\170",
                "\255\255",
                "\170\170"
              ]]
          }
    val dots2x2 = EXeneBase.IMAGE{
            sz = Geometry.SIZE{wid=16, ht=16},
            data = [[
                "\255\255",
                "\255\255",
                "\204\204",
                "\204\204",
                "\255\255",
                "\255\255",
                "\204\204",
                "\204\204",
                "\255\255",
                "\255\255",
                "\204\204",
                "\204\204",
                "\255\255",
                "\255\255",
                "\204\204",
                "\204\204"
              ]]
          }
  end (* DotsBM *)