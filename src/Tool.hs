module Tool(trace, decorate, tool) where

import Syntax
import Coercion
import Flatten
import Eval
import Data.List
import Data.Foldable
import Data.Maybe
-- import Control.Applicative (Applicative(liftA2))

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

-- type DecoratedP = [(Label, Block, TypeVarContext)]


-- tool :: Meta -> Maybe Int
-- 
-- tool meta =
--     do
--         path    <- trace prog "_start"
--         path'   <- decorate rf path
-- where
--     Meta (info, prog) = meta
--     rf :: RegFile
--     rf = f
--         where
--             f Zero  = TDInt 0
--             f Sp    = TCollection $ CStack Scratch SEmpty
--             f _     = Top


-- eval :: Meta -> Integer
-- eval m = undefined
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

-- 1. trace program to get path
-- 2. eval each block to get their final regfile (and block')
-- 3. coerce regfiles pairwise, threading the new delta through in a scan,
--    resulting in a [(delta, block)]
--
--
-- 1. trace program to get path.
-- 2. get pairwise blocks b and b' and
-- 3. Flatten b and eval, coercing the last regfile, recursing over all pairs
-- 4. returning the cost of each (reg, insn) pair in each block'
--   + the recursive call.
-- 
-- [(b, b'), (b', b''), ..] ->
--      

tool :: Meta -> Maybe Integer
tool (info, prog) =
    do
        blocks <- trace prog "start"
        let pairs = zip blocks (tail blocks)
        let delta = TypeVarContext [] [] []
        f delta pairs
    where
        f :: TypeVarContext -> [(Block, Block)] -> Maybe Integer
        f delta ((b, Block (rf, _)) : pairs) =
            do
                fb <- flatten delta b
                eb <- evalB info delta fb
                rf' <- finalrf eb
                delta' <- coerce delta rf rf'
                (+) <$> cost delta eb <*> f delta pairs
        finalrf :: Block' -> Maybe RegFile
        finalrf ([]) = Nothing
        finalrf ([(rf, _)]) = Just rf
        finalrf (ri : ris) = finalrf ris
        cost :: TypeVarContext -> Block' -> Maybe Integer
        cost delta (blocks) = 
            foldl
                (\mi (rf, insn) ->
                    (+)
                    <$> mi
                    <*> costI info delta rf insn
                )
                (Just 0)
                blocks
            -- costI info delta rf insn
            


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
        next ([Jump (Label label)]) = Just label
        next [Halt]                 = Nothing
        next (insn : insns)         = next insns

-- type Block' = (TypeVarContext, Block)
-- newtype Block' = Block' (Maybe RegFile, InstructionSeq)

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
    
-- decorate delta ([]) = Nothing
-- decorate delta (Block (rf, insns) : []) =
--     Just $ Block (flatten delta . rf, insns)
-- decorate delta (Block (rf, insns) : Block (rf', insns') : bs) =
--     do
--         rfF <- flatten delta . rf
--     coerce delta rf' (flatten delta . rf)

-- decorate delta (b:bs) =
--     let b' = Just (delta, b)
--     in sequenceA $ scanl f b' bs
--     where
--         -- coerce current block down to next block
--         f :: Maybe Block' -> Block -> Maybe Block'
--         f mb b' =
--             do
--                 (d, b@(Block(rf, _))) <- mb
--                 let (Block(rf', _)) = b'
--                 d' <- coerce d rf' rf
--                 return (d', b')

--  | Calculates the cost of one instruction based on code gen and memory type
costI :: Info -> TypeVarContext -> RegFile -> Instruction -> Maybe Integer
costI info delta rf insn
    | Aop {} <- insn            = Just arit
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
        (Info scratch shared arit scratchT sharedT _) = info

        costC :: CollectionType -> Maybe Integer
        costC (CStack m _) = Just scratch
        costC (Array m _ _) = Just scratch

        costM :: MemType -> Maybe Integer
        costM Scratch = Just scratch
        costM Shared = Just shared
        costM (MVar mu) = mu `lookupMD` delta >>= costM

