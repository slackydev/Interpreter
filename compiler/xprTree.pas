unit xprTree;
// Author: Jarl K. Holta
// License: GNU Lesser GPL (http://www.gnu.org/licenses/lgpl.html)
{$I header.inc}

interface

uses
  SysUtils, xprTypes, xprTokenizer, xprCompilerContext, xprIntermediate;

type
  ECompilerFlag = (cfLoopCond, cfIsAssigning);
  TCompilerFlags = set of ECompilerFlag;

  { XTree_Node }
  XTree_Node = class(TObject)
    FDocPos:  TDocPos;
    FContext: TCompilerContext;
    FResType: XType;

    constructor Create(ACTX: TCompilerContext; DocPos: TDocPos); virtual;
    function ToString(offset:string=''): string; virtual;

    function ResType(): XType; virtual;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; virtual;

    property ctx: TCompilerContext read FContext write FContext;
  end;
  XNodeArray = array of XTree_Node;
  
  (* 
    A list of statements or expressions
  *)
  XTree_ExprList = class(XTree_Node)
    List: XNodeArray;
    constructor Create(AList: XNodeArray; ACTX: TCompilerContext; DocPos: TDocPos); reintroduce;
    constructor Create(AStmt: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos); overload;
    function ToString(offset:string=''): string; override;

    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (*
    A stub for all constants
  *)
  XTree_Const = class(XTree_Node)
    StrValue: string;
    Expected: EExpressBaseType;

    function ToString(offset:string=''): string; override;

    function ResType(): XType; override;
    function SetExpectedType(ExpectedType: EExpressBaseType): Boolean; virtual;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  XTree_Bool  = class(XTree_Const)
    Value: Boolean;
    constructor Create(AValue: string; ACTX: TCompilerContext; DocPos: TDocPos); reintroduce;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  XTree_Char  = class(XTree_Const)
    Value: WideChar;
    constructor Create(AValue: string; ACTX: TCompilerContext; DocPos: TDocPos); reintroduce;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  XTree_Int  = class(XTree_Const)
    Value: Int64;
    constructor Create(AValue: string; ACTX: TCompilerContext; DocPos: TDocPos); reintroduce;
    function SetExpectedType(ExpectedType: EExpressBaseType): Boolean; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  XTree_Float = class(XTree_Const)
    Value: Double;
    constructor Create(AValue: string; ACTX: TCompilerContext; DocPos: TDocPos); reintroduce;
    function SetExpectedType(ExpectedType: EExpressBaseType): Boolean; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (* 
    A variable
  *)
  XTree_Identifier = class(XTree_Node)
    Name: string;
    constructor Create(AName:String; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(offset:string=''): string; override;

    function ResType(): XType; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;
  XIdentNodeList = specialize TArrayList<XTree_Identifier>;

  (*
    Declaring variables
  *)
  XTree_VarDecl = class(XTree_Node)
    Variables: XIdentNodeList;
    VarType: XType;
    Expr: XTree_Node;
    constructor Create(AVariables: XIdentNodeList; AExpr: XTree_Node; AType: XType; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(offset:string=''): string; override;

    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (* return from function *)
  XTree_Return = class(XTree_Node)
    Expr: XTree_Node;
    constructor Create(AExpr: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (* Declaring function *)
  XTree_Function = class(XTree_Node)
    Name:     string;
    ArgNames: TStringArray;
    ArgPass:  TPassArgsBy;
    ArgTypes: XTypeArray;
    RetType:  XType;
    PorgramBlock: XTree_ExprList;
    FrameSize: SizeInt;

    TypeName: String;

    //constructor Create(AName: string; AArgNames: TStringArray; AArgTypes: XTypeArray; AProg: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    constructor Create(AName: string; AArgNames: TStringArray; ByRef: TPassArgsBy; AArgTypes: XTypeArray; ARet:XType; AProg: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;

    function ToString(Offset:string=''): string; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (* A field lookup *)
  XTree_Field = class(XTree_Node)
    Left:  XTree_Node;
    Right: XTree_Node;

    constructor Create(ALeft, ARight: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(Offset:string=''): string; override;
    function ResType(): XType; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (* Call a function *)
  XTree_Invoke = class(XTree_Node)
    Method: XTree_Node;
    Args: XNodeArray;
    SelfExpr: XTree_Node;

    constructor Create(AFunc: XTree_Node; ArgList: XNodeArray; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(Offset:string=''): string; override;
    function ResolveMethod(out Func: TXprVar; out FuncType: XType): Boolean;
    function ResType(): XType; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (* An array lookup *)
  XTree_Index = class(XTree_Node)
    Expr, Index: XTree_Node;
    constructor Create(AExpr, AIndex: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(Offset:string=''): string; override;
    function ResType(): XType; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  
  (* if statement *)
  XTree_If = class(XTree_Node)
    Conditions: XNodeArray;
    Bodys: XNodeArray;
    ElseBody: XTree_ExprList;
    constructor Create(AConds, ABodys: XNodeArray; AElseBody: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(offset:string=''): string; override;
    
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (* while loop *)
  XTree_While = class(XTree_Node)
    Condition: XTree_Node;
    Body: XTree_ExprList;
    constructor Create(ACond: XTree_Node; ABody: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(offset:string=''): string; override;
    
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  XTree_Try = class(XTree_Node)
    TryBody, ExceptBody: XTree_ExprList;
    constructor Create(ATryBody, AExceptBody: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(offset:string=''): string; override;

    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (* for loop *)
  XTree_For = class(XTree_Node)
    EntryStmt, Condition, LoopStmt: XTree_Node;
    Body: XTree_ExprList;
    constructor Create(AEntryStmt, ACondition, ALoopStmt: XTree_Node; ABody: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(offset:string=''): string; override;

    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;
  
  (*  operator types *)
  XTree_UnaryOp = class(XTree_Node)
    Left: XTree_Node;
    OP: EOperator;

    constructor Create(Operation:EOperator; ALeft: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(offset:string=''): string; override;

    function ResType(): XType; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  XTree_BinaryOp = class(XTree_Node)
    Left, Right: XTree_Node;
    OP: EOperator;
    
    constructor Create(Operation:EOperator; ALeft, ARight: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(offset:string=''): string; override;

    function ResType(): XType; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  XTree_Assign = class(XTree_BinaryOp)
    function ResType(): XType; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

  (*  print 'print' *)
  XTree_Print = class(XTree_Node)
    Args: XNodeArray;
    constructor Create(ArgList: XNodeArray; ACTX: TCompilerContext; DocPos: TDocPos); virtual; reintroduce;
    function ToString(offset:string=''): string; override;
    function Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar; override;
  end;

function CompileAST(astnode:XTree_Node; doFree:Boolean = True): TIntermediateCode;

implementation

uses
  Math, xprUtils, xprVartypes, xprErrors, xprLangdef;


function CompileAST(astnode:XTree_Node; doFree:Boolean = True): TIntermediateCode;
begin
  astnode.Compile(NullResVar);
  astnode.ctx.Emit(GetInstr(icRET), NoDocPos);
  Result := astnode.ctx.Intermediate;
  //if doFree then
  //  astNode.Free;
end;


// ============================================================================
// Basenode
//
constructor XTree_Node.Create(ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FDocPos  := DocPos;
  Self.FContext := ACTX;
end;

function XTree_Node.ToString(offset:string=''): string;
begin
  Result := Offset + Copy(Self.ClassName(), 7, Length(Self.ClassName())-6)+'(...)';
end;

function XTree_Node.ResType(): XType;
begin
  Result := FResType;
end;

function XTree_Node.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
begin
  result := NullResVar;
end;


// ============================================================================
// List of expressions and statements
//
constructor XTree_ExprList.Create(AList: XNodeArray; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FDocPos  := DocPos;
  Self.FContext := ACTX;
  Self.List := AList;
end;

constructor XTree_ExprList.Create(AStmt: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FDocPos := DocPos;
  Self.FContext := ACTX;

  SetLength(Self.List, 1);
  Self.List[0] := AStmt;
end;

function XTree_ExprList.ToString(Offset:string=''): string;
var i:Int32;
begin
  Result := Offset + _AQUA_+'ExprList'+_WHITE_+'('+ LineEnding;
  for i:=0 to High(Self.List) do
  begin
    Result += Self.List[i].ToString(Offset + '  ');
    if i <> High(Self.List) then Result += ', ';
    Result += LineEnding;
  end;
  Result += Offset + ')';
end;

function XTree_ExprList.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var i:Int32;
begin
  for i:=0 to High(Self.List) do
    Self.List[i].Compile(NullResVar);

  Result := NullResVar;
end;


// ============================================================================
// Script constants
//
function XTree_Const.ToString(Offset:string=''): string;
begin
  Result := Offset + _PURPLE_+Self.StrValue+_WHITE_;
end;

function XTree_Const.ResType(): XType;
begin
  if (FResType = nil) then
    FResType := ctx.GetType(Self.Expected);
  Result := inherited;
end;

function XTree_Const.SetExpectedType(ExpectedType: EExpressBaseType): Boolean;
begin
  Result := False;
end;

function XTree_Const.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
begin
  Result := NullResVar;
  RaiseException(eUnexpected, FDocPos);
end;

constructor XTree_Bool.Create(AValue: string; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.StrValue := AValue;
  Self.Value    := AValue.ToBoolean();
  Self.Expected := xtBoolean;
end;

function XTree_Bool.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
begin
  Result := ctx.RegConst(Constant(Value, Expected));
end;


constructor XTree_Char.Create(AValue: string; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  if Length(AValue) <> 1 then RaiseException(eUnexpected, DocPos);
  Self.StrValue := AValue[1];
  Self.Value    := AValue[1];
  Self.Expected := xtAnsiChar;
end;

function XTree_Char.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
begin
  Result := ctx.RegConst(Constant(Value, Expected));
end;


constructor XTree_Int.Create(AValue: string; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.StrValue := AValue;
  Self.Value    := AValue.ToInt64();
  Self.Expected := SmallestIntSize(Value, xtInt);
end;

function XTree_Int.SetExpectedType(ExpectedType: EExpressBaseType): Boolean;
begin
  if not(ExpectedType in XprBoolTypes+XprIntTypes+XprFloatTypes) then
    Exit(False);
  if(Expected in XprIntTypes) and (SmallestIntSize(Value) > ExpectedType) then
    Exit(False);

  Expected := ExpectedType;
  FResType := ctx.GetType(Self.Expected);
  Result := True;
end;

function XTree_Int.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
begin
  Result := ctx.RegConst(Constant(Value, Expected));
end;


constructor XTree_Float.Create(AValue: string; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.StrValue := AValue;
  Self.Value    := AValue.ToExtended();
  Self.Expected := xtDouble;
end;

function XTree_Float.SetExpectedType(ExpectedType: EExpressBaseType): Boolean;
begin
  if not(ExpectedType in XprFloatTypes) then Exit(False);
  Expected := ExpectedType;
  FResType := ctx.GetType(Self.Expected);
  Result := True;
end;

function XTree_Float.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
begin
  Result := ctx.RegConst(Constant(Value, Expected));
end;


// ============================================================================
// Holding an identifier, it has no other purpose than to be used as a lookup
//
constructor XTree_Identifier.Create(AName:String; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.Name     := AName;
end;

function XTree_Identifier.ToString(Offset:string=''): string;
begin
  Result := Offset + _YELLOW_+Self.Name+_WHITE_;
end;

function XTree_Identifier.ResType(): XType;
begin
  Assert(Self.Name <> '');
  if (Self.FResType = nil) then
    Self.FResType := FContext.GetVar(Self.Name, FDocPos).VarType;
  Result := inherited;
end;

function XTree_Identifier.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  localVar: TXprVar;
begin
  Result := Self.FContext.GetVar(Self.Name, FDocPos);

  if Result.IsGlobal and (ctx.Scope <> GLOBAL_SCOPE) then
  begin
    localVar := TXprVar.Create(Result.VarType);
    localVar.Reference := True;//not(Result.VarType.BaseType in XprPointerTypes);
    ctx.RegVar(Self.Name, localVar, FDocPos);

    if localVar.Reference then
      ctx.Emit(GetInstr(icLOAD_GLOBAL, [localVar, Result]), FDocPos)
    else
      ctx.Emit(GetInstr(icCOPY_GLOBAL, [localVar, Result]), FDocPos);

    Result := localVar;
  end;
end;


// ============================================================================
// Variable declaration
//
constructor XTree_VarDecl.Create(AVariables: XIdentNodeList; AExpr: XTree_Node; AType: XType; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.Variables := AVariables;
  Self.VarType   := AType;
  Self.Expr      := AExpr;
end;

function XTree_VarDecl.ToString(Offset:string=''): string;
var i:Int32;
begin
  Result := Offset + _AQUA_+'VarDecl'+_WHITE_+'(';
  for i:=0 to Self.Variables.High do
  begin
    Result += Self.Variables.Data[i].ToString();
    if i <> Self.Variables.High then Result += ', ';
  end;
  if(Expr <> nil) then Result += _GRAY_ + ' <- '+ _WHITE_ + Self.Expr.ToString();
  Result += ')';
end;

function XTree_VarDecl.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  i:Int32;
begin
  if VarType = nil then
    Self.VarType := Self.Expr.ResType();

  for i:=0 to Self.Variables.High do
  begin
    Self.Variables.Data[i].FResType := self.VarType;

    ctx.RegVar(Self.Variables.Data[i].Name, self.VarType, Self.FDocPos);
  end;

  if Self.Expr <> nil then
  begin
    for i:=0 to Self.Variables.High do
      with XTree_Assign.Create(op_Asgn, Self.Variables.Data[i], Self.Expr, ctx, FDocPos) do
      try
        Compile(NullResVar, Flags);
      finally
        Free();
      end;
  end else
    {emit assign with default values};
  Result := NullResVar;
end;

// ============================================================================
// return statement
//
constructor XTree_Return.Create(AExpr: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.Expr     := AExpr;
end;

function XTree_Return.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  resVar: TXprVar;
begin
  resVar := Self.Expr.Compile(Dest, Flags);

  if resVar <> NullResVar then
    ctx.Emit(GetInstr(icRET, [resVar, Immediate(resVar.VarType.Size, ctx.GetType(xtInt32))]), FDocPos)
  else
    ctx.Emit(GetInstr(icRET, [resVar]), FDocPos);

  Result := NullResVar;
end;


// ============================================================================
// Function declaration
//
// Todo: Handle differnet types of passing parameters
//
constructor XTree_Function.Create(AName: string; AArgNames: TStringArray; ByRef: TPassArgsBy; AArgTypes: XTypeArray; ARet:XType; AProg: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  FContext := ACTX;
  FDocPos  := DocPos;

  Name     := AName;
  ArgNames := AArgNames;
  ArgPass  := ByRef;
  ArgTypes := AArgTypes;
  RetType  := ARet;
  PorgramBlock := AProg;

  SetLength(TypeName, 0);

  FrameSize := 0;
end;

function XTree_Function.ToString(offset:string=''): string;
var i: Int32;
begin
  Result := Offset + Copy(Self.ClassName(), 7, Length(Self.ClassName())-6)+'(';
  for i:=0 to High(Self.ArgNames) do
  begin
    Result += ArgNames[i];
    if i <> High(Self.ArgNames) then Result += ', '
  end;
  Result += LineEnding;
  Result += Self.PorgramBlock.ToString(Offset + '  ') + LineEnding;
  Result += Offset + ')';
end;

function XTree_Function.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  method: XType_Method;
  methodVar, arg, ptrVar: TXprVar;
  afterFunc: PtrInt;
  i,funcIdx,ptrIdx,allocFrame: Int32;

  procedure AddSelf();
  var
    SelfType: XType;
    i: Int32;
  begin
    SelfType := ctx.GetType(TypeName);

    SetLength(ArgTypes, Length(ArgTypes)+1);
    SetLength(ArgPass,  Length(ArgPass)+1);
    SetLength(ArgNames, Length(ArgPass)+1);

    for i:=High(ArgTypes)-1 downto 0 do
    begin
      ArgTypes[i+1] := ArgTypes[i];
      ArgPass[i+1]  := ArgPass[i];
      ArgNames[i+1] := ArgNames[i];
    end;

    ArgNames[0] := 'self';
    ArgPass[0]  := pbRef;
    ArgTypes[0] := SelfType;
  end;

begin
  if TypeName <> '' then AddSelf();
  method := XType_Method.Create(Name, ArgTypes, ArgPass, RetType, False);
  method.TypeMethod := TypeName <> '';

  methodVar := TXprVar.Create(method, ctx.CodeSize());
  funcIdx   := ctx.RegVar(Name, methodVar, FDocPos);

  // make a pointer to the function
  ctx.Emit(GetInstr(icMOV, [methodVar, Immediate(ctx.CodeSize()+1, ctx.GetType(xtInt32))]), Self.FDocPos);

  afterFunc := ctx.Emit(GetInstr(icJFUNC, [NullVar]), FDocPos);                // ►══JmpPastFunc══╗
  ctx.IncScope();

    allocFrame := ctx.Emit(GetInstr(icNEWFRAME, [NullVar]), FDocPos);
    for i:=High(ArgTypes) downto 0 do
    begin
      (*
        Approach to ref arg:
        Keeps "Reference" compile-time only

        We store a typed Pointer tagged with Reference for the codegen stage:
          At compile-time, if an argument is by-ref, allocate a local variable as usual,
          But instead of storing the value directly, store a pointer (address) into it,

        Then (when codegen sees Reference it will emit):
          On any use except ASGN: emit a DEREF to Temp, use the Temp for the operation
          On store: emit a specialized store operation that dereferences


        XXX: The conditional for XprPointerTypes might be wrong, but it works for simple cases.
        Reference flag might not really do justice, we need double deref, triple even possibly.
        Case where it can fail are change of basepointer, ie setlength
      *)
      if (ArgPass[i] = pbRef) {and (not(ArgTypes[i].BaseType in XprPointerTypes))} then
      begin
        // store as xtPointer to ensure enough stackspace
        ptrVar := ctx.RegVar(ArgNames[i], ctx.GetType(xtPointer), Self.FDocPos, ptrIdx);
        ctx.Variables.Data[ptrIdx].Reference := True;        // mark it for derefToTemp
        ctx.Variables.Data[ptrIdx].VarType   := ArgTypes[i]; // change type

        ptrVar := ctx.Variables.Data[ptrIdx];
        ctx.Emit(GetInstr(icPOPH, [ptrVar]), FDocPos);
      end else
      begin
        arg := ctx.RegVar(ArgNames[i], ArgTypes[i], Self.FDocPos);
        ctx.Emit(GetInstr(icPOP, [Immediate(arg.VarType.Size, ctx.GetType(xtInt32)), arg]), FDocPos);
      end;
    end;
    PorgramBlock.Compile(NullResVar, Flags);
    ctx.Emit(GetInstr(icRET), Self.FDocPos);

    // too late for recursive calls!!!
    ctx.PatchArg(allocFrame, ia1, ctx.FrameSize());

  ctx.DecScope();
  ctx.PatchJump(afterFunc);                                                    // ◄════GoHere═════╝

  Result := NullResVar;
end;


// ============================================================================
// Resolve (record) field-lookups
//
constructor XTree_Field.Create(ALeft, ARight: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;

  Self.Left  := ALeft;
  Self.Right := ARight;
end;

function XTree_Field.ToString(Offset:string=''): string;
begin
  Result := Offset + Self.Left.ToString() +'.'+ Right.ToString();
end;


function XTree_Field.ResType(): XType;
var
  recType: XType_Record;
  invoke: XTree_Invoke;
begin
  recType := XType_Record(Self.Left.ResType());

  if Self.Right is XTree_Identifier then
  begin
    if (Self.FResType = nil) then
      FResType := XType_Record(Self.Left.ResType()).FieldType(XTree_Identifier(Self.Right).Name);
  end
  else if Self.Right is XTree_Invoke then
  begin
    Invoke := XTree_Invoke(Self.Right);
    Invoke.SelfExpr := Left;
    FResType := XTree_Invoke(Self.Right).ResType();
  end
  else
    RaiseException('Unsupported right side in XTree_Field', FDocPos);

  Result := inherited;
end;


function XTree_Field.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  Offset: PtrInt;
  leftVar: TXprVar;
  Field: XTree_Identifier;
  invoke: XTree_Invoke;
begin
  if Self.Right is XTree_Identifier then
  begin
    leftVar := Self.Left.Compile(NullResVar);
    Field := Right as XTree_Identifier;
    Offset := XType_Record(Self.Left.ResType()).FieldOffset(Field.Name);
    if Offset = -1 then
      RaiseExceptionFmt(eSyntaxError, 'Unrecognized fieldname `%`', [Field.Name], Field.FDocPos);

    Result := leftVar;
    PtrUInt(Result.Addr) += Offset;
    Result.VarType := Self.ResType();
  end else if Right is XTree_Invoke then
  begin
    invoke := XTree_Invoke(Right);
    Invoke.SelfExpr := Self.Left;
    Result := Invoke.Compile(Dest, Flags);
  end else
    RaiseException('WTF IS THIS FIELD ACCESS?', FDocPos);
end;


// ============================================================================
// Invoke a method
//
constructor XTree_Invoke.Create(AFunc: XTree_Node; ArgList: XNodeArray; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  FContext := ACTX;
  FDocPos  := DocPos;
  Method := AFunc;
  Args   := ArgList;
  SelfExpr := nil;
end;

function XTree_Invoke.ResolveMethod(out Func: TXprVar; out FuncType: XType): Boolean;
  function MatchingParams(): Boolean;
  var
    i, impliedArgs:Int32;
    FType: XType_Method;
  begin
    impliedArgs := 0;
    FType := XType_Method(FuncType);

    if SelfExpr <> nil then
    begin
      impliedArgs := 1;
      if (not FType.TypeMethod) or (Length(FType.Params) = 0) then Exit(False);

      if(not(FType.Params[0].Equals(SelfExpr.ResType()))) or (not(FType.Params[0].CanAssign(SelfExpr.ResType()))) then
        Exit(False);
    end;

    if Length(FType.Params) <> Length(Args)+impliedArgs then
      Exit(False);

    for i:=impliedArgs to High(FType.Params) do
      if (not((FType.Passing[i] = pbRef)  and (FType.Params[i].Equals(Args[i-impliedArgs].ResType())))) and
         (not((FType.Passing[i] = pbCopy) and (FType.Params[i].CanAssign(Args[i-impliedArgs].ResType())))) then
        Exit(False);

    FuncType := FType;
    Result := True;
  end;
var
  i: Int32;
  list: TXprVarList;
begin
  Result := False;

  list := Self.FContext.GetVarList(XTree_Identifier(Method).Name, FDocPos);

  for i:=0 to list.High do
    if list.Data[i].VarType is XType_Method then
    begin
      Func := list.Data[i];
      FuncType := XType_Method(list.Data[i].VarType);
      if MatchingParams() then
      begin
        Exit(True);
      end else
        Func := NullVar;
    end;
end;

function XTree_Invoke.ToString(offset:string=''): string;
var i: Int32;
begin
  Result := Offset + Copy(Self.ClassName(), 7, Length(Self.ClassName())-6)+'(';
  for i:=0 to High(Args) do Result += Args[i].ToString() +', ';
  Result +=')';
end;

function XTree_Invoke.ResType(): XType;
var
  funcType: XType;
  func: TXprVar;
begin
  if FResType = nil then
  begin
    if Self.ResolveMethod(Func, funcType) then
      FResType := XType_Method(funcType).ReturnType
    else
      RaiseException('Cant resolve function', FDocPos);
  end;
  Result := inherited;
end;

function XTree_Invoke.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  Func: TXprVar;
  FuncType: XType_Method;

  (*
    Pass all arugments by reference at first, aka, we pass the address
    To the functionbody we should add handling for copying (when not passed by ref).
  *)
  procedure PushArgsToStack();
  var
    i:Int32;
    arg: TXprVar;
  begin
    if SelfExpr <> nil then
    begin
      arg := SelfExpr.Compile(NullVar);
      if arg.Reference then
        ctx.Emit(GetInstr(icPUSHREF, [arg]), FDocPos)
      else
        ctx.Emit(GetInstr(icPUSH, [arg]), FDocPos);
    end;

    i := 0;
    while i <= High(Args) do
    begin
      arg := Args[Asc(i)].Compile(NullVar);
      if arg.Reference then
        ctx.Emit(GetInstr(icPUSHREF, [arg]), FDocPos)
      else
        ctx.Emit(GetInstr(icPUSH, [arg]), FDocPos);
    end;
  end;

  procedure VerifyParams();
  var i, impliedArgs:Int32;
  begin
    impliedArgs := 0;
    if SelfExpr <> nil then
    begin
      impliedArgs := 1;
      if not FuncType.TypeMethod then RaiseException('Type method error thing', FDocPos);

      if(not(FuncType.Params[0].Equals(SelfExpr.ResType()))) or (not(FuncType.Params[0].CanAssign(SelfExpr.ResType()))) then
        RaiseException('Type method error thing 452696826021', FDocPos);
    end;

    if Length(FuncType.Params) <> Length(Args)+impliedArgs then
      RaiseExceptionFmt('Expected %d arguments, got %d', [Length(FuncType.Params), Length(Args)], FDocPos);

    for i:=impliedArgs to High(FuncType.Params) do
      if (not((FuncType.Passing[i] = pbRef)  and (FuncType.Params[i].Equals(Args[i-impliedArgs].ResType())))) and
         (not((FuncType.Passing[i] = pbCopy) and (FuncType.Params[i].CanAssign(Args[i-impliedArgs].ResType())))) then
        RaiseExceptionFmt('Incompatible argument [%d]', [i], Args[i].FDocPos);
  end;

var
  totalSlots: UInt16;
  i: Int32;
begin
  Result := NullResVar;
  Func   := NullResVar;

  if Method is XTree_Identifier then
  begin
    Self.ResolveMethod(Func, XType(FuncType));
  end else
  begin
    Func     := Method.Compile(NullVar);
    FuncType := XType_Method(func.VarType);
  end;

  if Func = NullResVar then
    RaiseException('Identifier not matched', FDocPos);

  if not(func.VarType is XType_Method) then
    RaiseException('Cannot invoke identifer', FDocPos);

  VerifyParams();

  if (FuncType.ReturnType <> nil) then
  begin
    if (Dest = NullResVar) then
      Dest := ctx.GetTempVar(FuncType.ReturnType);
    ctx.Emit(GetInstr(icPUSH, [Dest]), FDocPos);
    Result := Dest;
  end;

  PushArgsToStack();

  // inc stackptr by current frame size to pass by it local must now operate on a negative basis
  // this can be done in invoke
  totalSlots := Length(Args);
  if (FuncType.ReturnType <> nil) then
    totalSlots := totalSlots + 1;  // Account for return slot

  if SelfExpr <> nil then
    totalSlots += 1;

  if Func.MemPos = mpHeap then
  begin
    ctx.Emit(GetInstr(icINVOKEX, [Func, Immediate(totalSlots), Immediate(Ord(FuncType.ReturnType <> nil))]), FDocPos)
  end else
    ctx.Emit(GetInstr(icINVOKE, [Func, Immediate(totalSlots)]), FDocPos);
end;


// ============================================================================
// Simple index operation
//
constructor XTree_Index.Create(AExpr, AIndex: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.Expr  := AExpr;
  Self.Index := AIndex;
end;

function XTree_Index.ToString(Offset:string=''): string;
begin
  Result := Offset + 'Index('+Self.Expr.ToString() +', '+ Self.Index.ToString()+')';
end;

function XTree_Index.ResType(): XType;
begin
  Assert(Self.Expr.ResType is XType_Array);
  if (Self.FResType = nil) then
    FResType := XType_Array(Self.Expr.ResType()).ItemType;

  Result := inherited;
end;

function XTree_Index.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  ArrVar, IndexVar, AddressVar: TXprVar;
  ItemSize: Integer;
begin
  Assert(Self.Expr.ResType is XType_Array, 'Index target must be an array @ '+FDocPos.ToString);
  
  // Compile array base and index
  ArrVar   := Expr.Compile(NullResVar, Flags);
  IndexVar := Index.Compile(NullResVar, Flags);

  // Ensure vars are on stack! We need a way to deal with this centrally
  if ArrVar.Reference   then ArrVar   := ArrVar.DerefToTemp(ctx);
  if IndexVar.Reference then IndexVar := IndexVar.DerefToTemp(ctx);

  // Calculate address: arr + index * item_size
  ItemSize := XType_Array(Expr.ResType()).ItemType.Size;
  AddressVar := ctx.GetTempVar(ctx.GetType(EExpressBaseType.xtPointer));

  if ItemSize <> 1 then
    ctx.Emit(GetInstr(icFMA, [IndexVar, Immediate(ItemSize), ArrVar, AddressVar]), FDocPos)
  else
    ctx.Emit(GetInstr(icADD, [ArrVar, IndexVar, AddressVar]), FDocPos);


  // Reference is not meant for this, we already handle deref

  AddressVar.Reference := False;
  AddressVar.VarType   := ResType();
  // Handle read vs. write
  if cfIsAssigning in Flags then
    Result := AddressVar  // Return address for write (e.g., `a[x] := ...`)
  else
    Result := AddressVar.Deref(ctx, Dest);  // Dereference for read
end;


// ============================================================================
// IF statement
//   if (condition) then <stmts> end
//   if (condition) then <stmts> else <stmts> end
//   if (condition) <stmt>
//   if (condition) <stmt> else <stmt>
//
// NOT ALLOWED: if (condition) <stmt> else <stmts> end
constructor XTree_If.Create(AConds, ABodys: XNodeArray; AElseBody: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;

  Self.Conditions := AConds;
  Self.Bodys      := ABodys;
  Self.ElseBody  := AElseBody;
end;

function XTree_If.ToString(Offset:string=''): string;
begin
  Result := Offset + _AQUA_+'If'+_WHITE_+'(' + LineEnding;
  Result += Self.Conditions[0].ToString(Offset+'  ')+ ', ' + LineEnding;
  Result += Self.Bodys[0].ToString(Offset+'  ')+ ', ' + LineEnding;
  if Self.ElseBody <> nil then
    Result += Self.ElseBody.ToString(Offset+'  ') + LineEnding;
  Result += Offset + ')';
end;

function XTree_If.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  i: Int32;
  nextCondJumps: array of PtrInt;
  boolVar: TXprVar;
  skipRestJump: PtrInt;
begin
  SetLength(nextCondJumps, Length(Self.Conditions));

  // Process each condition in turn
  for i := 0 to High(Self.Conditions) do
  begin
    // Compile the condition
    boolVar := Self.Conditions[i].Compile(NullResVar, Flags);

    // Emit jump if false → skip to next condition check
    nextCondJumps[i] := ctx.Emit(
      GetInstr(icJZ, [boolVar, NullVar]),
      Self.Conditions[i].FDocPos
    );

    // Compile the corresponding body
    Self.Bodys[i].Compile(NullResVar, Flags);

    // After executing this body, skip the rest of the if-chain
    if (i < High(Self.Conditions)) or (Self.ElseBody <> nil) then
    begin
      skipRestJump := ctx.Emit(
        GetInstr(icRELJMP, [NullVar]),
        Self.Bodys[i].FDocPos
      );
      ctx.PatchJump(nextCondJumps[i]);
      nextCondJumps[i] := skipRestJump;
    end else
      ctx.PatchJump(nextCondJumps[i]);
  end;


  if Self.ElseBody <> nil then
    Self.ElseBody.Compile(NullResVar, Flags);

  for i:=0 to High(nextCondJumps) do
    if nextCondJumps[i] <> 0 then
      ctx.PatchJump(nextCondJumps[i]);

  Result := NullResVar;
end;


// ============================================================================
// WHILE loop
//   while (condition) do <stmts> end
//   while (condition) <stmt>
//
constructor XTree_While.Create(ACond: XTree_Node; ABody: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.Condition := ACond;
  Self.Body      := ABody;
end;

function XTree_While.ToString(Offset:string=''): string;
begin
  Result := Offset + _AQUA_+'While'+_WHITE_+'(' + LineEnding;
  Result += Self.Condition.ToString(Offset + '  ') + ', ' + LineEnding;
  Result += Self.Body.ToString(Offset + '  ') + LineEnding;
  Result += Offset + ')';
end;

function XTree_While.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  before, after: PtrInt;
  boolVar: TXprVar;
begin
  //while -->
  before := ctx.CodeSize();                                                    // ◄════════════════╗
  boolVar := Condition.Compile(NullVar, Flags);                                // Test condition   ║
  after := ctx.Emit(GetInstr(icJZ, [boolVar, NullVar]), Condition.FDocPos);    // ►═══False?═════╗ ║
  //-- do -->                                                                  //                ║ ║
  Body.Compile(NullVar, Flags);                                                //  execute me ☺  ║ ║
  ctx.Emit(GetInstr(icRELJMP, [ctx.RelAddr(before)]), Condition.FDocPos);      // ►═══JumpBack═══╫═╝
  //<--                                                                        //                ║
  ctx.PatchJump(after);                                                        // ◄═══GoHere═════╝
  Result := NullResVar;
end;


// ============================================================================
// TRY-EXCEPT
//   try <stmts> except <stmts> end
//
constructor XTree_Try.Create(ATryBody, AExceptBody: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.TryBody    := ATryBody;
  Self.ExceptBody := AExceptBody;
end;

function XTree_Try.ToString(Offset:string=''): string;
begin
  Result := Offset + _AQUA_+'Try'+_WHITE_+'(' + LineEnding;
  Result += Self.TryBody.ToString(Offset + '  ') + LineEnding;
  Result += Offset + ')'+ _AQUA_+' Try'+_WHITE_+'(' + LineEnding;
  Result += Self.ExceptBody.ToString(Offset + '  ') + LineEnding;
  Result += Offset + ')' + LineEnding;
end;

function XTree_Try.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  catch, noExcept: PtrInt;
  boolVar: TXprVar;
begin
  //try -->
  catch := ctx.Emit(GetInstr(icIncTry, [NullVar]), TryBody.FDocPos);
  TryBody.Compile(NullVar, Flags);
  ctx.Emit(GetInstr(icDecTry), TryBody.FDocPos);
  noExcept := ctx.Emit(GetInstr(icRELJMP, [NullVar]), ExceptBody.FDocPos);
  //except -->
  ctx.PatchArg(catch, ia1, ctx.CodeSize());
  ExceptBody.Compile(NullVar, Flags);
  //all good -->
  ctx.PatchJump(noExcept, ctx.CodeSize());

  Result := NullResVar;
end;


// ============================================================================
// FOR loop
//   for (pre_expr; condition; post_expr) do <stmts> end
//   for (pre_expr; condition; post_expr) <stmt>
//
// PS: Expressions and statements can be empty - for example to achieve inf loop
constructor XTree_For.Create(AEntryStmt, ACondition, ALoopStmt: XTree_Node; ABody: XTree_ExprList; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FContext := ACTX;
  Self.FDocPos  := DocPos;
  Self.EntryStmt := AEntryStmt;
  Self.Condition := ACondition;
  Self.LoopStmt  := ALoopStmt;
  Self.Body      := ABody;
end;

function XTree_For.ToString(Offset:string=''): string;
begin
  Result := Offset + _AQUA_+'For'+_WHITE_+'(' + LineEnding;
  Result += Self.EntryStmt.ToString(Offset + '  ') + ', ' + LineEnding;
  Result += Self.Condition.ToString(Offset + '  ') + ', ' + LineEnding;
  Result += Self.LoopStmt.ToString(Offset + '  ') + ', ' + LineEnding;
  Result += Self.Body.ToString(Offset + '  ') + LineEnding;
  Result += Offset + ')';
end;

function XTree_For.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  before, after: PtrInt;
  boolVar: TXprVar;
begin
  after := 0;
  if EntryStmt <> nil then
    EntryStmt.Compile(NullVar, Flags);                                         // Execute entry statement
                                                                               //
  //for -->                                                                    //
  before := ctx.CodeSize();                                                    // ◄════════════════╗
  if LoopStmt <> nil then                                                      //                  ║
  begin                                                                        // test condition   ║
    boolVar := Condition.Compile(NullVar, Flags);                              //   ...            ║
    after := ctx.Emit(GetInstr(icJZ, [boolVar, NullVar]), Condition.FDocPos);  // ►════False?════╗ ║
  end;                                                                         //                ║ ║
  //-- do -->                                                                  //                ║ ║
  Body.Compile(NullVar, Flags);                                                // exec body      ║ ║
  if LoopStmt <> nil then                                                      //                ║ ║
    LoopStmt.Compile(NullVar, Flags);                                          // exec post body ║ ║
                                                                               //       ... expr ║ ║
  ctx.Emit(GetInstr(icRELJMP, [ctx.RelAddr(before)]), Condition.FDocPos);      // ►══Back2Start══╫═╝
  //<--                                                                        //                ║
  if LoopStmt <> nil then                                                      //                ║
    ctx.PatchJump(after); {fix last jump}                                      // ◄════GoHere════╝

  Result := NullResVar;
end;


// ============================================================================
// Operators

constructor XTree_UnaryOp.Create(Operation: EOperator; ALeft: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FDocPos  := DocPos;
  Self.FContext := ACTX;
  Self.Left := ALeft;
  Self.OP   := Operation;
end;

function XTree_UnaryOp.ToString(Offset:string=''): string;
begin
  Result := Offset + _LBLUE_+'UnaryOp'+_WHITE_+'(';
  REsult += _GREEN_+OperatorToStr(OP)+_WHITE_ +', ';
  Result += Self.Left.ToString();
  Result += ')';
  if OP = op_Sub then OP := op_USUB;
end;

function XTree_UnaryOp.ResType(): XType;
begin
  if FResType = nil then
    if op = op_Addr then
      FResType := ctx.GetType(xtPointer)
    else
      FResType := Self.Left.ResType();
  Result := inherited;
end;

function XTree_UnaryOp.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  LeftVar: TXprVar;
  NewLeft, NewRight: XTree_Node;
  Instr: EIntermediate;
begin
  Result := Dest;
  if Result = NullResVar then Result := ctx.GetTempVar(ResType());

  if op = op_Add then
    Exit(Left.Compile(Dest, Flags))
  else if op = op_Addr then
  begin
    LeftVar := Left.Compile(NullResVar, Flags);
    ctx.Emit(GetInstr(OP2IC(OP), [LeftVar, Result]), FDocPos);
    Result.Reference := True;
  end else
  begin
    NewRight := Left;
    if Left.ResType() is XType_Ordinal then
      NewLeft  := XTree_Int.Create('0', ctx, FDocPos)
    else if Left.ResType() is XType_Float then
      NewLeft  := XTree_Float.Create('0', ctx, FDocPos)
    else
      RaiseException('Unaryop not supported here', FDocPos);

    with XTree_BinaryOp.Create(op_SUB, NewLeft, NewRight, ctx, FDocPos) do
      Result := Compile(Dest);
  end;
end;



(*
  This is what basically makes the magic happen..!
*)
constructor XTree_BinaryOp.Create(Operation:EOperator; ALeft, ARight: XTree_Node; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FDocPos  := DocPos;
  Self.FContext := ACTX;
  Self.Left := ALeft;
  Self.Right:= ARight;
  Self.OP   := Operation;
end;

function XTree_BinaryOp.ToString(Offset:string=''): string;
begin
  Result := Offset + _LBLUE_+'Operator'+_WHITE_+'(';
  Result += Self.Left.ToString()  + ', ';
  Result += Self.Right.ToString() + ', ';
  REsult += _GREEN_+OperatorToStr(OP)+_WHITE_;
  Result += ')';
end;

function XTree_BinaryOp.ResType(): XType;
begin
  Assert(Left <> nil);
  Assert(Right <> nil);
  if (FResType = nil) then
    FResType := Left.ResType().ResType(OP, Right.ResType(), FContext);

  Result := FResType;
end;


function XTree_BinaryOp.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  LeftVar, RightVar, TmpBool: TXprVar;
  Instr, InstrCast: EIntermediate;
  CommonType: EExpressBaseType;
  CommonTypeVar: XType;
  TmpLeft, TmpRight: TXprVar;

  function RedefineConstant(A,B: XTree_Node): Boolean;
  begin
    Result := (B <> nil) and (A is XTree_Const) and (B.ResType() <> A.ResType);
    if Result then Result := XTree_Const(A).SetExpectedType(B.ResType.BaseType);
  end;

  function DoShortCircuitOp(): TXprVar;
  var
    Instr: EIntermediate;
    PatchPos: PtrInt;
  begin
    TmpBool  := Left.Compile(NullResVar, Flags);
    Instr    := TmpBool.VarType.EvalCode(OP, TmpBool.VarType);
    PatchPos := ctx.Emit(GetInstr(Instr, [TmpBool, NullVar]), FDocPos);
    RightVar := Right.Compile(TmpBool, Flags);
    ctx.PatchJump(PatchPos);
    Result := TmpBool;
  end;

begin
  Assert(not(OP in AssignOps), 'Assignment does not belong here, dont come again!');

  RedefineConstant(Left, Right);
  RedefineConstant(Right, Left);

  if OP in [op_AND, op_OR] then
    Exit(DoShortCircuitOp());

  Result := Dest;
  if Dest = NullResVar then
    Result := ctx.GetTempVar(Self.ResType());

  // Handle arithmetic operations with type promotion
  if OP in ArithOps+LogicalOps then
  begin
    // Determine common arithmetic type
    CommonType := CommonArithmeticCast(Left.ResType().BaseType, Right.ResType().BaseType);
    CommonTypeVar := ctx.GetType(CommonType);

    // Compile left operand and cast if needed
    LeftVar := Left.Compile(NullResVar, Flags);

    // Ensure operands are in stack
    if LeftVar.Reference then LeftVar := LeftVar.DerefToTemp(ctx);

    if LeftVar.VarType.BaseType <> CommonType then
    begin
      TmpLeft := ctx.GetTempVar(CommonTypeVar);
      InstrCast := CommonTypeVar.EvalCode(op_Asgn, LeftVar.VarType);
      if InstrCast = icNOOP then
        RaiseExceptionFmt(eNotCompatible3, [OperatorToStr(op_Asgn), BT2S(LeftVar.VarType.BaseType), BT2S(CommonType)], FDocPos);
      ctx.Emit(GetInstr(InstrCast, [TmpLeft, LeftVar]), FDocPos);
      LeftVar := TmpLeft;
    end;

    // Compile right operand and cast if needed
    RightVar := Right.Compile(NullResVar, Flags);

    // Ensure operands are in stack
    if RightVar.Reference then RightVar := RightVar.DerefToTemp(ctx);

    if RightVar.VarType.BaseType <> CommonType then
    begin
      TmpRight := ctx.GetTempVar(CommonTypeVar);
      InstrCast := CommonTypeVar.EvalCode(op_Asgn, RightVar.VarType);
      if InstrCast = icNOOP then
        RaiseExceptionFmt(eNotCompatible3, [OperatorToStr(op_Asgn), BT2S(RightVar.VarType.BaseType), BT2S(CommonType)], FDocPos);
      ctx.Emit(GetInstr(InstrCast, [TmpRight, RightVar]), FDocPos);
      RightVar := TmpRight;
    end;
  end
  else
  begin
    // Non-arithmetic operations
    LeftVar  := Left.Compile(NullResVar, Flags);
    RightVar := Right.Compile(NullResVar, Flags);
    // Ensure operands are in stack
    if LeftVar.Reference  then LeftVar  := LeftVar.DerefToTemp(ctx);
    if RightVar.Reference then RightVar := RightVar.DerefToTemp(ctx);
  end;

  // Emit the binary operation
  Instr := LeftVar.VarType.EvalCode(OP, RightVar.VarType);
  if Instr <> icNOOP then
  begin
    ctx.Emit(GetInstr(Instr, [LeftVar, RightVar, Result]), FDocPos);
  end
  else
    RaiseExceptionFmt(eNotCompatible3, [OperatorToStr(OP), BT2S(Left.ResType.BaseType), BT2S(Right.ResType.BaseType)], Left.FDocPos);
end;




// ---------------------------------------------
// Assignment
function XTree_Assign.ResType(): XType;
begin
  Result := nil;
end;

function XTree_Assign.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var
  LeftVar, RightVar: TXprVar;
  Instr: EIntermediate;

  function GetBinop(): EOperator;
  begin
    case OP of
      op_AsgnBND: Result := op_BND;
      op_AsgnBOR: Result := op_BOR;
      op_AsgnDiv: Result := op_Div;
      op_AsgnSub: Result := op_Sub;
      op_AsgnMod: Result := op_Mod;
      op_AsgnMul: Result := op_Mul;
      op_AsgnAdd: Result := op_Add;
      op_AsgnXOR: Result := op_XOR;
      else Result := op_Unknown;
    end;
  end;

  procedure AssignToSimple();
  var
    BinOp: EOperator;
    TempVar: TXprVar;
  begin
    if OP in CompoundOps then
    begin
      RaiseException(eNotImplemented, FDocPos);
    end
    else
      ctx.Emit(GetInstr(OP2IC(OP), [LeftVar, RightVar]), FDocPos);
  end;

  procedure AssignToRecord();
  begin
    if OP <> op_Asgn then
      RaiseException('Compound assignment not supported for records', FDocPos);

    // not really implemented... todo
    if LeftVar.MemPos = mpHeap then
    begin
      // Emit single block move operation
      ctx.Emit(GetInstr(icMOVH, [
        LeftVar,             // Destination (stack offset)
        RightVar,            // Source (stack offset)
        Immediate(LeftVar.VarType.Size)   // Size in bytes
      ]), FDocPos);
    end else
    begin
      // Emit single block move operation
      ctx.Emit(GetInstr(icMOV, [
        LeftVar,             // Destination (stack offset)
        RightVar,            // Source (stack offset)
        Immediate(LeftVar.VarType.Size)   // Size in bytes
      ]), FDocPos);
    end;
  end;
begin
  Result := NullResVar;

  if Left is XTree_Const then // just fuck off
    RaiseException(eSyntaxError, eExpectedVar, Left.FDocPos);
  if Left is XTree_Index then
    Flags += [cfIsAssigning];



  // try to make the constant the same type as the value we are assigning to.
  if (Left <> nil) and (Right is XTree_Const) and (Left.ResType() <> Right.ResType) then
     XTree_Const(Right).SetExpectedType(Left.ResType.BaseType);

  if Left is XTree_Index then
    LeftVar  := Left.Compile(NullResVar, Flags + [cfIsAssigning])
  else
    LeftVar  := Left.Compile(NullResVar, Flags);


  // Compile index assignment
  if (Left is XTree_Index) or (LeftVar.Reference) then
  begin
    RightVar := Right.Compile(NullResVar, []);

     // Ensure right are in stack (very short route)
    if (RightVar.Reference) then RightVar := RightVar.DerefToTemp(ctx);

    //  write: `a^ := value`
    ctx.Emit(STORE_FAST(LeftVar, RightVar, True), FDocPos);
    Exit;
  end;

  // Compile RHS
  if (LeftVar.VarType.BaseType = Right.ResType().BaseType) and (LeftVar.MemPos = mpLocal) then
    RightVar := Right.Compile(LeftVar, Flags)
  else
    RightVar := Right.Compile(NullResVar, Flags);

  // Ensure right are in stack
  if RightVar.Reference then RightVar := RightVar.DerefToTemp(ctx);

  // drop assign to self to self
  if (LeftVar.MemPos = RightVar.MemPos) and (LeftVar.Addr = RightVar.Addr) then
      Exit;

  // Handle different assignment types
  if LeftVar.VarType.EvalCode(OP, RightVar.VarType) <> icNOOP then
  begin
    // Simple assignment: `x := value`
    Instr := LeftVar.VarType.EvalCode(OP, RightVar.VarType);
    if (Instr = icMOV) and (LeftVar.MemPos = mpLocal) then
      ctx.Emit(STORE_FAST(LeftVar, RightVar, False), FDocPos)
    else
      ctx.Emit(GetInstr(Instr, [LeftVar, RightVar]), FDocPos);
  end
  else if (LeftVar.VarType.BaseType = xtRecord) then
    AssignToRecord()
  else
    RaiseExceptionFmt(eNotCompatible3, [OperatorToStr(OP), BT2S(Left.ResType.BaseType), BT2S(Right.ResType.BaseType)], Left.FDocPos);
end;


// ============================================================================
// print keyword... meh
//
constructor XTree_Print.Create(ArgList: XNodeArray; ACTX: TCompilerContext; DocPos: TDocPos);
begin
  Self.FDocPos  := DocPos;
  Self.FContext := ACTX;
  Self.Args := ArgList;
end;

function XTree_Print.ToString(Offset:string=''): string;
var i:Int32;
begin
  Result := Offset + _AQUA_+'Print'+_WHITE_+'(';
  for i:=0 to High(Self.Args) do
  begin
    Result += Self.Args[i].ToString('');
    if i <> High(Self.Args) then Result += ', ';
  end;
  Result += ')';
end;

function XTree_Print.Compile(Dest: TXprVar; Flags: TCompilerFlags=[]): TXprVar;
var arg: TXprVar;
begin
  arg := Self.Args[0].Compile(NullResVar, Flags);
  if arg.Reference then arg := arg.DerefToTemp(ctx);

  ctx.Emit(GetInstr(icPRINT, [arg, Immediate(arg.VarType.Size)]), FDocPos);

  Result := NullVar;
end;


end.
