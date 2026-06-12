{
module Parser where

import Syntax
import Data.Char
}

%name parse
%tokentype { Token }
%error { parseError }
%token
    meta        { TokenMeta }
    wordsz      { TokenWordSize }
    scaddr      { TokenScratchAddress }
    scsz        { TokenScratchSize }
    sctime      { TokenScratchTime }
    shaddr      { TokenSharedAddress }
    shsz        { TokenSharedSize }
    shtime      { TokenSharedTime }
    aritime     { TokenArithTime }
    int         { TokenInt $$ }
    scratch     { TokenScratch }
    shared      { TokenShared }
    top         { TokenTop }
    inttype     { TokenIntType }
    array       { TokenArray }
    ':'         { TokenColon }
    '('         { TokenLParen }
    ')'         { TokenRParen }
    '['         { TokenLBracket }
    ']'         { TokenRBracket }
    ','         { TokenComma }
    add         { TokenAdd }
    sub         { TokenSub }
    mul         { TokenMul }
    div         { TokenDiv }
    incr        { TokenIncr }
    decr        { TokenDecr }
    mv          { TokenMv }
    j           { TokenJ }
    halt        { TokenHalt }
    mvscr       { TokenMvscr }
    mvshr       { TokenMvshr }
    load        { TokenLoad }
    store       { TokenStore }
    var         { TokenVar $$ }

%right ':' 'r' ']'

%%

Program : Meta Text             { ($1, $2) }
Meta    : meta
            wordsz int
            scaddr int
            scsz int
            sctime int
            shaddr int
            shsz int
            shtime int
            aritime int         { Info $3 $5 $7 $9 $11 $13 $15 $17 }
Text    : Text1 Text            { $1 : $2 }
        |                       { [] }
Text1   : var ':' Block         { ($1, $3) }
Block   : '[' Context ']' Instructions  {Block ($2, $4) }
Context : var ':' Type ',' Context { \r -> if r == (read $1) then $3 else $5 r }
        | var ':' Type          { \r -> if r == (read $1) then $3 else defaultRegfile r }
        |                       { defaultRegfile }
Instructions
        : Instruction Instructions { $1 : $2 }
        | j var                 { [Jump (Label $2)] }
        | halt                  { [Halt] }
Type    : var                   { TVar (TypeVar $1) }
        | top                   { Top }
        | inttype               { TInt }
        | inttype '(' int ')'   { TDInt (fromIntegral $3) }
        | C                     { TCollection $1 }
C       : MVar Type array '(' int ')' { Array $1 $2 (fromIntegral $5) }
        | MVar S                { CStack $1 $2 }
S       : Type ':' ':' S        { SCons $1 $4 }
        | '[' ']'               { SEmpty }
        | var                   { SVar (StackTypeVar $1) }
MVar    : scratch               { Scratch }
        | shared                { Shared }
        | var                   { MVar (MemTypeVar $1) }
Instruction
        : add var ',' var ',' var   { Add (read $2) (read $4) (Reg (read $6)) }
        | add var ',' var ',' int   { Add (read $2) (read $4) (toVInt $6) }
        | sub var ',' var ',' var   { Sub (read $2) (read $4) (Reg (read $6)) }
        | sub var ',' var ',' int   { Sub (read $2) (read $4) (toVInt $6) }
        | mul var ',' var ',' var   { Mul (read $2) (read $4) (Reg (read $6)) }
        | mul var ',' var ',' int   { Mul (read $2) (read $4) (toVInt $6) }
        | div var ',' var ',' var   { Div (read $2) (read $4) (Reg (read $6)) }
        | div var ',' var ',' int   { Div (read $2) (read $4) (toVInt $6) }
        | incr var ',' var ',' int  { Incr (read $2) (read $4) (toVInt $6) }
        | decr var ',' var ',' int  { Decr (read $2) (read $4) (toVInt $6) }
        | mv var ',' var            { Mv (read $2) (read $4) }
        | mvscr var                 { Mvscr (read $2) }
        | mvshr var                 { Mvshr (read $2) }
        | load var ',' int '(' var ')' { Load (read $2) (read $6) (toVInt $4) }
        | store var ',' int '(' var ')' { Store (read $2) (read $6) (toVInt $4) }

{
parseError :: [Token] -> a
parseError (tokens) = error ("parse error: " ++ (show tokens))

defaultRegfile :: Register -> Type
defaultRegfile Zero = TDInt 0
defaultRegfile Sp   = TCollection $ CStack Scratch SEmpty
defaultRegfile _    = Top

toVInt :: Integral a => a -> Value
toVInt = VInt . fromIntegral


data Token
    = TokenMeta
    | TokenWordSize
    | TokenScratchAddress
    | TokenScratchSize
    | TokenScratchTime
    | TokenSharedAddress
    | TokenSharedSize
    | TokenSharedTime
    | TokenArithTime
    | TokenInt Integer
    | TokenColon
    | TokenArray
    | TokenLParen
    | TokenRParen
    | TokenLBracket
    | TokenRBracket
    | TokenComma
    | TokenAdd
    | TokenSub
    | TokenMul
    | TokenDiv
    | TokenIncr
    | TokenDecr
    | TokenMv
    | TokenJ
    | TokenHalt
    | TokenMvscr
    | TokenMvshr
    | TokenLoad
    | TokenStore
    | TokenVar String
    | TokenScratch
    | TokenShared
    | TokenTop
    | TokenIntType
    deriving (Show)

lexer [] = []
lexer (c:cs)
    | isSpace c = lexer cs
    | c == '(' = TokenLParen : lexer cs
    | c == ')' = TokenRParen : lexer cs
    | c == '[' = TokenLBracket : lexer cs
    | c == ']' = TokenRBracket : lexer cs
    | c == ':' = TokenColon : lexer cs
    | c == ',' = TokenComma : lexer cs
    | c == '.' = lexDot cs
    | isAlpha c || c == '_' = lexAlpha (c:cs)
    | isDigit c = lexNum (c:cs)

lexNum ('0' : 'x' : cs) =
    TokenInt (read $ "0x" ++ num) : lexer rest
    where (num, rest) = span isDigit cs
lexNum cs =
    TokenInt (read num) : lexer rest
    where (num, rest) = span isDigit cs

lexDot cs =
    case span isAlphaNum cs of
        ("meta", rest) -> TokenMeta : lexer rest
        ("wordsize", rest) -> TokenWordSize : lexer rest
        ("scaddr", rest) -> TokenScratchAddress : lexer rest
        ("scsize", rest) -> TokenScratchSize : lexer rest
        ("sctime", rest) -> TokenScratchTime : lexer rest
        ("shaddr", rest) -> TokenSharedAddress : lexer rest
        ("shsize", rest) -> TokenSharedSize : lexer rest
        ("shtime", rest) -> TokenSharedTime : lexer rest
        ("artime", rest) -> TokenArithTime : lexer rest

lexAlpha cs =
    case span (\c -> isAlphaNum c || c == '_') cs  of
        (label, ':' : rest) -> TokenVar label : TokenColon : lexer rest
        ("add", rest) -> TokenAdd : lexer rest
        ("sub", rest) -> TokenSub : lexer rest
        ("mul", rest) -> TokenMul : lexer rest
        ("div", rest) -> TokenDiv : lexer rest
        ("incr", rest) -> TokenIncr : lexer rest
        ("decr", rest) -> TokenDecr : lexer rest
        ("halt", rest) -> TokenHalt : lexer rest
        ("j", rest) -> TokenJ : lexer rest
        ("mvscr", rest) -> TokenMvscr : lexer rest
        ("mvshr", rest) -> TokenMvshr : lexer rest
        ("mv", rest) -> TokenMv : lexer rest
        ("load", rest) -> TokenLoad : lexer rest
        ("store", rest) -> TokenStore : lexer rest
        ("array", rest) -> TokenArray : lexer rest
        ("scratch", rest) -> TokenScratch : lexer rest
        ("shared", rest) -> TokenShared : lexer rest
        ("int", rest) -> TokenIntType : lexer rest
        ("top", rest) -> TokenTop : lexer rest
        (reg, rest) -> TokenVar reg : lexer rest
}
