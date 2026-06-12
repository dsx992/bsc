module Main where

import Syntax
import Parser
import Data.Char

defscratch = "SCRATCH"
defshared = "SHARED"

main :: IO ()
main =
    getContents >>= codegen . parse . lexer

codegen :: Program -> IO ()
codegen (info, text) =
    do
        putStrLn $ "#define " ++ defscratch ++ " " ++ show scaddr
        putStrLn $ "#define " ++ defshared ++ " " ++ show shaddr
        putStrLn ""
        putStrLn "\t.text"
        putStrLn "\t.globl _start"
        putStrLn ""
        mapM_ (\(label, Block (_, insns)) ->
            do
                printlabel label
                mapM_ codegenI insns
                putStrLn "") text
  where
    Info {wordsize = wordsize, scratchaddr = scaddr, sharedaddr = shaddr} = info

    printlabel :: String -> IO ()
    printlabel = putStrLn . (++ ":")

    lowshow :: Show a => a -> String
    lowshow = map toLower . show

    codegenI :: Instruction -> IO ()
    codegenI (Add rd rs v )
        | Reg r' <- v =
            putStrLn
            $ "\taddi\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ lowshow r'
        | VInt i <- v =
            putStrLn
            $ "\taddi\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ show i
    codegenI (Sub rd rs v )
        | Reg r' <- v =
            putStrLn
            $ "\tsub\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ lowshow r'
        | VInt i <- v =
            putStrLn
            $ "\taddi\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ show (negate i)
    codegenI (Mul rd rs v )
        | Reg r' <- v =
            putStrLn
            $ "\tmul\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ lowshow r'
        | VInt i <- v =
            putStrLn
            $ "\tmuli\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ show i
    codegenI (Div rd rs v )
        | Reg r' <- v =
            putStrLn
            $ "\tdiv\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ lowshow r'
        | VInt i <- v =
            putStrLn
            $ "\tdivi\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ show i
    codegenI (Incr rd rs v)
        | Reg r' <- v =
            putStrLn
            $ "\tmul\t" ++ lowshow rd ++ ", " ++ lowshow r' ++ ", " ++ show wordsize
            ++ "\t\n"
            ++ "\tsub\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ lowshow rd
        | VInt i <- v =
            let imm = negate $ toInteger i * (wordsize `div` 8)
            in putStrLn
            $ "\taddi\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ show imm
    codegenI (Decr rd rs v)
        | Reg r' <- v =
            putStrLn
            $ "\tmul\t" ++ lowshow rd ++ ", " ++ lowshow r' ++ ", " ++ show wordsize
            ++ "\t\n"
            ++ "\taddi\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ lowshow rd
        | VInt i <- v =
            let imm = toInteger i * (wordsize `div` 8)
            in putStrLn
            $ "\taddi\t" ++ lowshow rd ++ ", " ++ lowshow rs ++ ", " ++ show imm
    codegenI (Mv rd rs) =
        putStrLn $ "\tmv\t" ++ lowshow rd ++ ", " ++ lowshow rs
    codegenI (Load rd rs (VInt i)) =
        let imm = toInteger i * (wordsize `div` 8)
        in putStrLn
        $ "\tlw\t" ++ lowshow rd ++ ", " ++ show imm ++ "(" ++ lowshow rs ++ ")"
    codegenI (Store rs rd (VInt i)) =
        let imm = toInteger i * (wordsize `div` 8)
        in putStrLn
        $ "\tsw\t" ++ lowshow rs ++ ", " ++ show imm ++ "(" ++ lowshow rd ++ ")"
    codegenI (Mvscr rd) =
        putStrLn
        $ "\tlui\t" ++ lowshow rd ++ ", %hi(" ++ defscratch ++ ")"
        ++ "\t\n"
        ++ "\taddi\t" ++ lowshow rd ++ ", " ++ lowshow rd ++ ", " ++ "%lo(" ++ defscratch ++ ")"
    codegenI (Mvshr rd) =
        putStrLn
        $ "\tlui\t" ++ lowshow rd ++ ", %hi(" ++ defshared ++ ")"
        ++ "\t\n"
        ++ "\taddi\t" ++ lowshow rd ++ ", " ++ lowshow rd ++ ", " ++ "%lo(" ++ defshared ++ ")"
    codegenI (Jump (Label label)) = putStrLn $ "\tj\t" ++ label
    codegenI Halt =
        putStr
        $ "\tcall exit"
        -- $ "\tli\t" ++ lowshow A7 ++ ", " ++ show 97 ++ "\n"
        -- ++ "\tli\t" ++ lowshow A0 ++ ", " ++ show 0 ++ "\n"
        -- ++ "\tecall"

-- codegenInfo :: Info -> IO a
-- codegenInfo 
