module Tool(Tool.trace, decorate, tool) where

import Syntax
import Coercion
import Flatten
import Eval
import Data.List
import Data.Foldable
import Data.Maybe
import Debug.Trace

{- WCET
 - wcet takes in a wrapped program with meta data,
 - finds the entrypoint,
 - traces the program path through jumps,
 - Instantiates and decorates with typevariable contexts,
 -      by flattening the current block to remove type variables
 -      Type eval the block for changes
 -      and coercing the next block regfile
 -      (producing the context as a side effect)
 - sums each instruction time based on the meta information and the context
 -}

-- 1. trace program to get path.
-- 2. get pairwise blocks b and b' and
-- 3. Flatten b and eval, coercing the last regfile, recursing over all pairs
-- 4. returning the cost of each (reg, insn) pair in each block'
--   + the recursive call.
-- 
-- [(b, b'), (b', b''), ..] ->
--      

tool :: Program -> Maybe Integer
tool (info, prog) =
    do
        blocks <- Tool.trace prog "start"
        -- append Halt hack such that the last block is calculated (is first in zip tuple)
        let pairs = zip blocks (tail blocks ++ [Block ((\r -> Top), [Halt])])
        let delta = TypeVarContext [] [] []
        f delta pairs
    where
        f :: TypeVarContext -> [(Block, Block)] -> Maybe Integer
        f _ [] = Just 0
        f delta ((b, Block (rf, _)) : pairs) =
            do
                fb <- flatten delta b
                eb <- evalB info delta fb
                rf' <- finalrf eb
                delta' <- coerce delta rf rf'
                (+) <$> (cost delta eb) <*> f delta' pairs

        finalrf :: Block' -> Maybe RegFile
        finalrf ([]) = Nothing
        finalrf ([(rf, _)]) = Just rf
        finalrf (ri : ris) = finalrf ris

        cost :: TypeVarContext -> Block' -> Maybe Integer
        cost delta (blocks) = 
            foldl
                (\macc (rf, insn) ->
                    (+)
                    <$> macc
                    <*> costI info delta rf insn
                )
                (Just 0)
                blocks
            -- costI info delta rf insn

-- | trace find the execution path starting at entry
trace :: Text -> Label -> Maybe [Block]
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
        case next insns >>= Tool.trace prog of
            Just tail   -> return $ block : tail
            Nothing     -> return [block]

    where
        next :: InstructionSeq -> Maybe Label
        next ([Jump (Label label)]) = Just label
        next [Halt]                 = Nothing
        next (insn : insns)         = next insns

decorate :: Info
    -> TypeVarContext
    -> [Block]
    -> Maybe [Block']
decorate info delta ([b]) =
    (: []) <$> evalB info delta b
decorate info delta (b@(Block(rf, _)) : b'@(Block(rf', _)) : bs) =
    do
        eb <- evalB info delta b
        let erf = fromMaybe rf $ finalrf eb
        delta' <- coerce delta rf' erf
        (eb :) <$> (decorate info delta' (b' : bs))

    where
        finalrf :: Block' -> Maybe RegFile
        finalrf ([(rf, _)]) = Just rf
        finalrf (b : bs) = finalrf bs
        finalrf ([]) = Nothing
    
--  | Calculates the cost of one instruction based on code gen and memory type
costI :: Info -> TypeVarContext -> RegFile -> Instruction -> Maybe Integer
costI info delta rf insn
    | Add {} <- insn            = Just arit
    | Sub {} <- insn            = Just arit
    | Mul {} <- insn            = Just arit
    | Div {} <- insn            = Just arit
    | Incr _ _ (Reg _) <- insn  = Just $ 2 * arit
    | Incr _ _ (VInt _) <- insn = Just arit
    | Decr _ _ (Reg _) <- insn  = Just $ 2 * arit
    | Decr _ _ (VInt _) <- insn = Just arit
    | Load _ rs (VInt i) <- insn
    , Just (TCollection c) <- flatten delta (rf rs) = costC c
    | Store rs rd (VInt i) <- insn
    , Just (TCollection c) <- flatten delta (rf rd) = costC c
    | Mvscr _ <- insn           = Just arit
    | Mvshr _ <- insn           = Just arit
    | Jump _ <- insn            = Just 0
    | Halt <- insn              = Just 0

    where
        (Info {scratchtime = scratch, sharedtime = shared, arittime = arit}) = info

        costC :: CollectionType -> Maybe Integer
        costC (CStack m _) = Just scratch
        costC (Array m _ _) = Just scratch

        costM :: MemType -> Maybe Integer
        costM Scratch = Just scratch
        costM Shared = Just shared
        costM (MVar mu) = mu `lookupMD` delta >>= costM

