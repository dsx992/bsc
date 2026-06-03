module Main where
import Syntax
import Tool
import Coercion
import Eval
import Flatten
import Parser

emptyD :: TypeVarContext
emptyD = TypeVarContext {alpha = [], mem = [], stack = []}

-- example program
defaultRegFile :: RegFile
defaultRegFile = f
    where
        f Zero  = TDInt 0
        f Sp    = TCollection $ CStack Scratch SEmpty
        f _     = Top

r0 = f
    where
        -- f A0    = TInt
        -- f A1    = TInt
        -- f A2    = TInt
        -- f A3    = TInt
        f x     = defaultRegFile x
r1 = f
    where
        f Sp    = TCollection $ CStack Scratch $ SVar $ newvar "'sp"
        f x     = r0 x
r2 = f
    where
        f A4    = TCollection $ Array (MVar $ newvar "'m") TInt 4
        f x     = r0 x
i0 =
    [ Add A0 Zero $ VInt 0
    , Add A1 Zero $ VInt 1
    , Add A2 Zero $ VInt 2
    , Add A3 Zero $ VInt 3
    , Jump $ Label "alloc"
    ]
i1 = 
    [ Incr A4 Sp (VInt 4)
    , Jump $ Label "store"
    ]
i2 =
    [ Store A0 A4 (VInt 0)
    , Store A1 A4 (VInt 1)
    , Store A2 A4 (VInt 2)
    , Store A3 A4 (VInt 3) 
    , Halt
    ]

b0 = Block (r0, i0)
b1 = Block (r1, i1)
b2 = Block (r2, i2)

p :: Text
p = [("start", b0), ( "alloc", b1), ( "store", b2)]

main :: IO ()
main =
    getContents >>= print . parse . lexer
