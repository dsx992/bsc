module Tool(eval, flattenRF) where

import Syntax
-- import Coercion
import Result
import Data.List
import Data.Foldable
import Data.Maybe

{- EVAL
 - eval takes in a wrapped program with meta data,
 - finds the entrypoint start,
 - traces the program path through jumps,
 - instantias typevariable contexts,
 -      by flattening the current block to remove type variables
 -      and coercing the next block regfile
 -      (producing the context as a side effect)
 - sums each instruction time based on the meta information and the context
 -}

type DecoratedP = [(Label, Block, TypeVarContext)]

registers :: [Register]
registers = [Zero ..]

lookupTD :: TypeVar -> TypeVarContext -> Maybe Type
lookupTD x (TypeVarContext {alpha = as}) =
    snd <$> find ((== x) . fst) as

lookupMD :: MemTypeVar -> TypeVarContext -> Maybe MemType
lookupMD x (TypeVarContext {mem = mus}) =
    snd <$> find ((== x) . fst) mus

lookupSD :: StackTypeVar -> TypeVarContext -> Maybe StackType
lookupSD x (TypeVarContext {stack = rhos}) =
    snd <$> find ((== x) . fst) rhos

-- | replaces variables with their bindings. R[Δ]
flattenRF :: RegFile -> TypeVarContext -> Maybe RegFile
flattenRF rf delta =
    let mts     = mapM (flattenT . rf) registers
        pairs   = zip registers <$> mts
    in  torf <$> pairs
    where
        torf :: [(Register, Type)] -> Register -> Type
        torf ((r', t):tail) r =
            if r == r' then t
            else torf tail r

        flattenT :: Type -> Maybe Type
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
trace :: Program -> Label -> [Block]
-- 1. find entry
-- 2. get instructions in block
-- 3. find next label (jump)
-- 4. basecase if no label
-- 5. else trace next and concat
trace prog entry =
        let mblock  = snd <$> find ((== entry) . fst) prog
            minsns  = (\ (Block (_, insns)) -> insns) <$> mblock
            mnext   = minsns >>= next
            mtail   = trace prog <$> mnext :: Maybe [Block]
        in
            fromMaybe [] $ ((:) <$> mblock) <*> mtail

    where
        next :: InstructionSeq -> Maybe Label
        next (insn `ICons` insns)   = next insns
        next (Jump (Label label))   = Just label
        next Halt                   = Nothing

        cat :: [Block] -> Block -> Maybe [Block]
        cat bs b = Just $ b : bs


-- decorate :: Program -> Label -> DecoratedP
-- decorate prog entry =
--     decorate' defaultRegFile prog entry
--     where
--         decorate' :: RegFile -> Program -> Label -> DecoratedP
--         decorate' rf prog entry =
--             let b@(Block (rf', _)) = fst $ find ((==) entry . fst) prog
--                 pairs   = [(rf r, rf' r) | r <- registers]
--                 folder  = (\delta (r, r') -> coerce delta r' r)
--                 delta   = foldl folder [] $ pairs


-- top i x =
--     let evalI (Aop _ _ _) = x
--     in evalI i
-- 

