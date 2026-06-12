module Main where

import Syntax
import Coercion
import Flatten
import Eval
import Data.List
import Data.Foldable
import Data.Maybe
import System.Exit
import Parser

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

main :: IO ()
main =
    getContents >>= printResult . tool . parse . lexer
    -- getContents >>= print
    where
        printResult (Just time) =
            do
                print time
                exitWith ExitSuccess
        printResult Nothing =
            do
                putStr "Error.\n"
                exitWith $ ExitFailure 1
--      

tool :: Program -> Maybe Integer
tool (info, prog) =
    do
        blocks <- trace prog "_start"
        -- append Halt hack such that the last block is calculated (is first in zip tuple)
        let pairs = zip blocks (tail blocks ++ [Block (\r -> Top, [Halt])])
        let delta = TypeVarContext [] [] []
        totalcost delta pairs
    where
        totalcost :: TypeVarContext -> [(Block, Block)] -> Maybe Integer
        totalcost _ [] = Just 0
        totalcost delta ((b, Block (rf, _)) : pairs) =
            do
                fb <- flatten delta b           -- flatten current block.
                eb <- evalB info delta fb       -- eval block to get block',
                                                -- instruction regfile pair.
                rf' <- finalrf eb               -- gets the final regfile.
                delta' <- coerce delta rf rf'   -- coerce next regfile to resolve type variables
                (+) <$> cost delta eb <*> totalcost delta' pairs

        finalrf :: Block' -> Maybe RegFile
        finalrf ([]) = Nothing
        finalrf ([(rf, _)]) = Just rf
        finalrf (ri : ris) = finalrf ris

        cost :: TypeVarContext -> Block' -> Maybe Integer
        cost delta blocks = 
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
        case next insns >>= trace prog of
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
--  | https://docs.amd.com/r/en-US/ug1629-microblaze-v-user-guide/Instructions
costI :: Info -> TypeVarContext -> RegFile -> Instruction -> Maybe Integer
costI info delta rf insn
    | Add {} <- insn            = Just arit
    | Sub {} <- insn            = Just arit
    | Mul {} <- insn            = Just arit
    | Div {} <- insn            = Just $ arit * 30
    | Mv _ _ <- insn            = Just arit
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
    | Jump _ <- insn            = Just arit
    | Halt <- insn              = Just $ (1 + 1 + 5) * arit -- ecall + li's

    where
        (Info {scratchtime = scratch, sharedtime = shared, arittime = arit}) = info

        costC :: CollectionType -> Maybe Integer
        costC (CStack m _) = costM m
        costC (Array m _ _) = costM m

        costM :: MemType -> Maybe Integer
        costM Scratch = Just scratch
        costM Shared = Just shared
        costM (MVar mu) = mu `lookupMD` delta >>= costM

