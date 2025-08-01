// The amount is because FPC has issues resolving certian overloads
//--- language eval uses these


function Modulo(X,Y: Double): Double; inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X,Y: Single): Single; inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X,Y: Int8):  Int8;    inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X,Y: UInt8): UInt8;   inline; begin Result := X mod Y; end;
function Modulo(X,Y: Int16):  Int16;  inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X,Y: UInt16):UInt16;  inline; begin Result := X mod Y; end;
function Modulo(X,Y: Int32):  Int32;  inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X,Y: UInt32):UInt32;  inline; begin Result := X mod Y; end;
function Modulo(X,Y: Int64):  Int64;  inline;
begin
  Result := x mod y;
  if (Result <> 0) and ((result < 0) <> (Y < 0)) then begin
    if Y < 0 then Result -= Y else Result += Y;
  end;
end;
function Modulo(X,Y: UInt64):UInt64; inline; begin Result := x mod y; end;

function Modulo(X:Int8;   Y:UInt8):  Int32; inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X:UInt8;  Y:Int8):   Int32; inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X:Int16;  Y:UInt16): Int32; inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X:UInt16; Y:Int16):  Int32; inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X:Int32;  Y:UInt32): Int64; inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X:UInt32; Y:Int32):  Int64; inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X:Int64;  Y:UInt64): Int64; inline; begin Result := X - Floor(X / Y) * Y; end;
function Modulo(X:UInt64; Y:Int64):  Int64; inline; begin Result := X - Floor(X / Y) * Y; end;

function Divide(X,Y: Double): Double; inline; begin Result := X / Y; end;
function Divide(X,Y: Single): Single; inline; begin Result := X / Y; end;
function Divide(X,Y: Int8):  Int32;   inline; begin Result := X div Y; end;
function Divide(X,Y: UInt8):UInt32;   inline; begin Result := X div Y; end;
function Divide(X,Y: Int16):  Int32;  inline; begin Result := X div Y; end;
function Divide(X,Y: UInt16):UInt32;  inline; begin Result := X div Y; end;
function Divide(X,Y: Int32):  Int32;  inline; begin Result := X div Y; end;
function Divide(X,Y: UInt32):UInt32;  inline; begin Result := X div Y; end;
function Divide(X,Y: Int64):  Int64;  inline; begin Result := X div Y; end;
function Divide(X,Y: UInt64):UInt64;  inline; begin Result := X div Y; end;
function Divide(X:Int8;   Y:UInt8):  Int32; inline; begin Result := X div Y; end;
function Divide(X:UInt8;  Y:Int8):   Int32; inline; begin Result := X div Y; end;
function Divide(X:Int16;  Y:UInt16): Int32; inline; begin Result := X div Y; end;
function Divide(X:UInt16; Y:Int16):  Int32; inline; begin Result := X div Y; end;
function Divide(X:Int32;  Y:UInt32): Int64; inline; begin Result := X div Y; end;
function Divide(X:UInt32; Y:Int32):  Int64; inline; begin Result := X div Y; end;
function Divide(X:Int64;  Y:UInt64): Int64; inline; begin Result := X div Y; end;
function Divide(X:UInt64; Y:Int64):  Int64; inline; begin Result := X div Y; end;


// will not do shit with negative exponent, in that case you should cast your value to a float.
function ipow(base, exp: Int64): Int64; inline;
begin
  if exp < 0 then Exit(0);
  Result := 1;
  while (exp <> 0) do
  begin
    if (exp and 1) <> 0 then
      Result *= base;
    exp := exp shr 1;
    base := Sqr(base);
  end;
end;

function Power(X,Y: Double): Double; inline; begin Result := Math.Power(X, Y); end;
function Power(X,Y: Single): Single; inline; begin Result := Math.Power(X, Y); end;
function Power(X,Y: Int8):  Int64;   inline; begin Result := ipow(X, Y); end;
function Power(X,Y: UInt8): Int64;   inline; begin Result := ipow(X, Y); end;
function Power(X,Y: Int16):  Int64;  inline; begin Result := ipow(X, Y); end;
function Power(X,Y: UInt16): Int64;  inline; begin Result := ipow(X, Y); end;
function Power(X,Y: Int32):  Int64;  inline; begin Result := ipow(X, Y); end;
function Power(X,Y: UInt32): Int64;  inline; begin Result := ipow(X, Y); end;
function Power(X,Y: Int64):  Int64;  inline; begin Result := ipow(X, Y); end;
function Power(X,Y: UInt64): Int64;  inline; begin Result := ipow(X, Y); end;
function Power(X:Int8;   Y:UInt8):  Int64; inline; begin Result := ipow(X, Y); end;
function Power(X:UInt8;  Y:Int8):   Int64; inline; begin Result := ipow(X, Y); end;
function Power(X:Int16;  Y:UInt16): Int64; inline; begin Result := ipow(X, Y); end;
function Power(X:UInt16; Y:Int16):  Int64; inline; begin Result := ipow(X, Y); end;
function Power(X:Int32;  Y:UInt32): Int64; inline; begin Result := ipow(X, Y); end;
function Power(X:UInt32; Y:Int32):  Int64; inline; begin Result := ipow(X, Y); end;
function Power(X:Int64;  Y:UInt64): Int64; inline; begin Result := ipow(X, Y); end;
function Power(X:UInt64; Y:Int64):  Int64; inline; begin Result := ipow(X, Y); end;


function Sar(X,Y: Int8):  Int64;  inline; begin Result := SarSmallInt(X, Y); end;
function Sar(X,Y: UInt8): Int64;  inline; begin Result := SarSmallInt(X, Y); end;
function Sar(X,Y: Int16):  Int64; inline; begin Result := SarShortInt(X, Y); end;
function Sar(X,Y: UInt16): Int64; inline; begin Result := SarShortInt(X, Y); end;
function Sar(X,Y: Int32):  Int64; inline; begin Result := SarLongInt(X, Y); end;
function Sar(X,Y: UInt32): Int64; inline; begin Result := SarLongInt(X, Y); end;
function Sar(X,Y: Int64):  Int64; inline; begin Result := SarInt64(X, Y); end;
function Sar(X,Y: UInt64): Int64; inline; begin Result := SarInt64(X, Y); end;
function Sar(X:Int8;   Y:UInt8):  Int64; inline; begin Result := SarSmallInt(X, Y); end;
function Sar(X:UInt8;  Y:Int8):   Int64; inline; begin Result := SarSmallInt(X, Y); end;
function Sar(X:Int16;  Y:UInt16): Int64; inline; begin Result := SarShortInt(X, Y); end;
function Sar(X:UInt16; Y:Int16):  Int64; inline; begin Result := SarShortInt(X, Y); end;
function Sar(X:Int32;  Y:UInt32): Int64; inline; begin Result := SarLongInt(X, Y); end;
function Sar(X:UInt32; Y:Int32):  Int64; inline; begin Result := SarLongInt(X, Y); end;
function Sar(X:Int64;  Y:UInt64): Int64; inline; begin Result := SarInt64(X, Y); end;
function Sar(X:UInt64; Y:Int64):  Int64; inline; begin Result := SarInt64(X, Y); end;
