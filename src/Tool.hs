module Tool(eval, trace, decorate) where

import Syntax
-- import Coercion
-- import Result
import Flatten
import Data.List
import Data.Foldable
import Data.Maybe
import Control.Applicative (Applicative(liftA2))

{- EVAL
 - eval takes in a wrapped program with meta data,
 - finds the entrypoint start,
 - traces the program path through jumps,
 - Instantiates and decorates with typevariable contexts,
 -      by flattening the current block to remove type variables
 -      and coercing the next block regfile
 -      (producing the context as a side effect)
 - sums each instruction time based on the meta information and the context
 -}

type DecoratedP = [(Label, Block, TypeVarContext)]

type Block' = (TypeVarContext, Block)




defaultRegFile :: RegFile
defaultRegFile = f
    where
        f Zero  = TDInt 0
        f Sp    = TCollection $ CStack Scratch SEmpty
        f _     = Top


eval :: Meta -> Integer
eval m = undefined
-- eval
--     ( Timing
--         { scratch = scr
--         , shared = shr
--         , arithmetic = arit
--         , entrypoint = entry
--         }
--     , program
--     ) =
--     undefined


-- | trace find the execution path starting at entry
trace :: Program -> Label -> Maybe [Block]
-- 1. find entry
-- 2. get instructions in block
-- 3. find next label (jump)
-- 4. basecase if no label
-- 5. else trace next and concat
trace prog entry =
    do
        block@(Block (_, insns)) <- snd <$> find ((entry ==) . fst) prog
        -- let tail = fromMaybe [] (next insns >>= trace prog)
        -- return $ block : tail
        case next insns >>= trace prog of
            Just tail   -> return $ block : tail
            Nothing     -> return [block]

    where
        next :: InstructionSeq -> Maybe Label
        next (insn `ICons` insns)      = next insns
        next (Jump (Label label))      = Just label
        next Halt                      = Nothing


decorate :: [Block] -> Maybe [Block']
decorate (b:b':bs) =
    let Block (rf, _) = b
        Block (rf', _) = b'
    in
        undefined
    where
        -- | creates a new context by coercing
        instantiateD :: RegFile -> RegFile -> Maybe TypeVarContext
        instantiateD rf rf' = undefined
