module Eval where

-- | Using typing rules

import Syntax
import Coercion
import Data.Maybe


-- evalB :: Block -> Maybe Block
-- evalB block =
-- 
--     where
--         

evalB :: Info -> TypeVarContext -> Block -> Maybe Block'
evalB info delta (Block(rf, insn : insns)) =
    do
        rf' <- (evalI info delta rf insn)
        ((rf', insn) :) <$> (evalB info delta (Block (rf', insns)))
evalB _ _ (Block (rf, [])) = return []
-- evalB _ _ (Block (rf,  [Jump _])) = return []

-- eval needs Info to bind the shared and scratch regions.
evalI :: Info -> TypeVarContext -> RegFile -> Instruction -> Maybe RegFile
evalI info delta rf (Aop {}) = Just rf
evalI info delta rf (Incr rd rs (VInt i))
    | i >= 0 
    , c@(TCollection (CStack m s)) <- rf rs
    =
        if i == 0 then
            Just $ bind rf rd c
        else
            let c' = TCollection (CStack m $ Top `SCons` s)
                insn = Incr rd rd (VInt $ i - 1)
            in evalI info delta (bind rf rd c') insn
evalI info delta rf (Decr rd rs (VInt i))
    | i > 0
    , TCollection (CStack m (_ `SCons` s)) <- rf rs
    =
        let c' = TCollection (CStack m s)
            insn = Decr rd rd (VInt $ i - 1)
        in evalI info delta (bind rf rd c') insn
    | i == 0
    , c@(TCollection (CStack m _)) <- rf rs
    =
        Just $ bind rf rd c
evalI info delta rf (Mv rd rs) =
    Just (bind rf rd $ rf rs)
evalI info delta rf (Mvscr rd) =
    Just $ bind rf rd (TCollection scrt)
    where
        Info {scratchT = scrt} = info
evalI info delta rf (Mvshr rd) =
    Just $ bind rf rd (TCollection shrt)
    where
        Info {sharedT = shrt} = info
evalI info delta rf (Load rd rs (VInt i))
    | i >= 0
    , (TCollection (Array _ t j)) <- rf rs
    , i < j
    =
        Just $ bind rf rd t
    | i > 0
    , (TCollection (CStack m (_ `SCons` s))) <- rf rs
    =
        let rf' = bind rf rd (TCollection $ CStack m s)
            insn = Load rd rd (VInt $ i - 1)
        in evalI info delta rf' insn
    | i == 0
    , (TCollection (CStack _ (t `SCons` _))) <- rf rs
    =
        Just $ bind rf rd t
evalI info delta rf (Store rs rd (VInt i))
    | i >= 0
    , (TCollection (Array _ t j)) <- rf rd
    , i < j
    , t' <- rf rs
    , isJust $ coerce delta t' t
    =
        Just rf
    | i > 0
    , (TCollection (CStack m s)) <- rf rd
    , Just t <- getN s i
    , t' <- rf rs
    =
        do
            s' <- setN s i t'
            let c = TCollection (CStack m s')
            Just $ bind rf rd c
    where
        getN :: StackType -> Int -> Maybe Type
        getN (t `SCons` s) i
            | i == 0    = Just t
            | i > 0     = getN s (i - 1)
            | otherwise = Nothing
        getN SEmpty _ = Nothing
        setN :: StackType -> Int -> Type -> Maybe StackType
        setN (head `SCons` tail) i t
            | i > 0
            =
                SCons head <$> setN tail (i - 1) t
            | i == 0
            =
                Just (t `SCons` tail)
evalI info delta rf Halt = Just rf
evalI info delta rf (Jump _) = Just rf
-- evalI _ _ = Nothing

bind :: RegFile -> Register -> Type -> RegFile
bind rf reg t r = if r == reg then t else rf r
