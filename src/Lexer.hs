module Lexer where

data Tokens = Zero
            | Ra
            | Sp
            | Gp
            | Tp
            | T0
            | T1
            | T2
            | Fp
            | S1
            | A0
            | A1
            -- instructions
            | Add
            | Addi
            -- types
            | Int
            | Float
            | Array
            -- Operators
            | LT
            | GT
            | LTE
            | GTE
            | EQ
            -- symbols
            | Colon
            | Vert
            | Comma
            -- parenthesis
            | LParen
            | RParen
            | LBrack
            | RBrack
            | LCurly
            | RCurly
            | EOF
            | Name String
            | CInt Integer
            | CFloat Float




