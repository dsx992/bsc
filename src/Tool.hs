module Tool(eval, trace, decorate) where

import Syntax
-- import Coercion
import Result
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

registers :: [Register]
registers = [Zero ..]

-- | replaces variables with their bindings. R[Δ]
flattenRF :: RegFile -> TypeVarContext -> Maybe RegFile
flattenRF rf delta =
    let mts     = mapM (flattenT . rf) registers
        pairs   = zip registers <$> mts
    in  torf <$> pairs
    where
        torf :: [(Register, AType)] -> Register -> AType
        torf ((r', t):tail) r =
            if r == r' then t
            else torf tail r

        flattenT :: AType -> Maybe AType
        flattenT (TVar a)           = a `lookupTD` delta
        flattenT (TCollection c)    = TCollection <$> flattenC c
        flattenT t                  = Just t

        flattenC :: CollectionType -> Maybe CollectionType
        flattenC (Array m t i) =
            do
                m' <- flattenM m
                t' <- flattenT t
                return $ Array m' t' i
        flattenC (CStack m s) =
            do
                m' <- flattenM m
                s' <- flattenS s
                return $ CStack m' s'

        flattenM :: MemType -> Maybe MemType
        flattenM (MVar mu)  = mu `lookupMD` delta
        flattenM m          = Just m

        flattenS :: StackType -> Maybe StackType
        flattenS (SVar rho)     = rho `lookupSD` delta
        flattenS (t `SCons` s)  =
            do
                t' <- flattenT t
                s' <- flattenS s
                return $ t' `SCons` s'
        flattenS s              = Just s


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
