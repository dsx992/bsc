module Main where
import Syntax
import Tool
import Coercion
import Eval
import Flatten

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
        f A0    = TInt
        f A1    = TInt
        f A2    = TInt
        f A3    = TInt
        f x     = defaultRegFile x
r1 = f
    where
        f Sp    = TCollection $ CStack Scratch $ SVar $ newvar "'sp"
        f x     = r0 x
r2 = f
    where
        f A4    = TCollection $ Array (MVar $ newvar "'m") TInt 4
        f x     = r0 x
i0 = [(Jump $ Label "alloc")]
i1 = Incr A4 Sp (VInt 4) : [Jump (Label "store")]
i2 = foldr (:) [Halt]
    [ Store A0 A4 (VInt 0)
    , Store A1 A4 (VInt 1)
    , Store A2 A4 (VInt 2)
    , Store A3 A4 (VInt 3) ]

b0 = Block (r0, i0)
b1 = Block (r1, i1)
b2 = Block (r2, i2)

p :: Program
p = [("start", b0), ( "alloc", b1), ( "store", b2)]

main :: IO ()
main =
    do
        putStrLn "hello world"
