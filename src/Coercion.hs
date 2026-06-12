module Coercion where

import Syntax
import Flatten
import Data.Maybe
import Data.List
import Debug.Trace

-- | Using Maybes as a form of backtracking,
-- but since contexts are shallow, there is not a lot to do

instance TypeCo RegFile where
    -- rf' < rf
    coerce delta rf' rf =
        foldl folder (Just emptyctx) registers
        where
            folder :: Maybe TypeVarContext -> Register -> Maybe TypeVarContext
            folder mdelta' r =
                do
                    t <- flatten delta $ rf r
                    mdelta' >>= \d -> coerce d (rf' r) t
                
            registers = [Zero ..]
            emptyctx = TypeVarContext {alpha = [], mem = [], stack = []}

instance TypeEq RegFile where
    equiv delta rf rf' =
        and [equiv delta (rf r) (rf' r) | r <- [Zero ..]]

instance TypeCo Type where
    -- coerce delta ta@(TVar a) ta'@(TVar a')
    --     | equiv delta ta ta'    = Just delta
    --     | otherwise             = Nothing
    coerce delta (TVar a) Top
        | not $ a `indom` delta = Just $ updateTD delta a Top
        | otherwise             = Nothing
    coerce delta (TVar a) TInt
        | not $ a `indom` delta = Just $ updateTD delta a TInt
        | otherwise             = Nothing
    coerce delta ta@(TVar a) t@(TDInt i) =
        updateTD delta a t <$ coerce delta ta TInt
    coerce delta (TVar a) c@(TCollection _)
        | not $ a `indom` delta = Just $ updateTD delta a c
        | a `indom` delta       = Nothing
    coerce delta (TVar a) t
        | Just t' <- a `lookupTD` delta
        , equiv delta t t'
        = Just delta
        | otherwise
        = Nothing
    coerce delta (TCollection c) (TCollection c') =
        coerce delta c c'
    coerce delta Top _      = Just delta
    coerce delta _ Top      = Just delta
    coerce delta t t'
        | equiv delta t t'  = Just delta
        | otherwise         = Nothing

instance TypeCo CollectionType where
    coerce delta (CStack m s) (CStack m' s') =
        coerce delta m m' >>= \d  -> coerce d s s'
    coerce delta (Array m t i) (Array m' t' j) =
        do
            delta'  <- coerce delta m m'
            delta'' <- coerce delta' t t'
            if i <= j then
                return delta''
            else
                Nothing
    coerce delta (Array m _ 0) (CStack m' _) =
        coerce delta m m'
    coerce delta (Array m t i) (CStack m' (t' `SCons` s)) =
        do
            delta'  <- coerce delta m m'
            delta'' <- coerce delta' t t'
            coerce delta'' (Array m t (i - 1)) (CStack m' s)

instance TypeCo StackType where
    coerce delta ts@(SVar rho) ts'@(SVar _)
        | equiv delta ts ts'    = Just delta
        | otherwise             = Nothing
    coerce delta (SVar rho) SEmpty
        | not $ rho `indom` delta   = Just $ updateSD delta rho SEmpty
        | otherwise                 = Nothing
    coerce delta sv@(SVar rho) (t `SCons` s)
        | not $ rho `indom` delta =
            do
                delta'  <- coerce delta sv s
                s'      <- rho `lookupSD` delta'
                return $ updateSD delta rho (t `SCons` s')
        | otherwise = Nothing
    coerce delta s s'
        | equiv delta s s'  = Just delta
        | otherwise         = Nothing

instance TypeCo MemType where
    coerce delta (MVar mu) (MVar mu')
        | mu `indom` delta , mu == mu' = Just delta
        | otherwise = Nothing
    coerce delta (MVar mu) Scratch
        | not $ mu `indom` delta = Just $ updateMD delta mu Scratch
        | Just Scratch <- mu `lookupMD` delta = Just delta
        | otherwise = Nothing
    coerce delta (MVar mu) Shared
        | not $ mu `indom` delta = Just $ updateMD delta mu Shared
        | Just Shared <- mu `lookupMD` delta = Just delta
        | otherwise = Nothing
    coerce delta Scratch Scratch = Just delta
    coerce delta Shared Shared = Just delta

instance TypeEq Type where
    equiv delta (TVar a) (TVar a') =
        let indom = isJust $ a `lookupTD` delta
        in  indom && a == a'
    equiv delta Top Top = True
    equiv delta TInt TInt = True
    equiv delta (TDInt i) (TDInt j) = i == j
    equiv delta (TCollection c) (TCollection c') =
        equiv delta c c'
    -- equiv _ _ _ = False

instance TypeEq CollectionType where
    equiv delta (CStack m s) (CStack m' s') =
        equiv delta m m'  && equiv delta s s'
    equiv delta (Array m t i) (Array m' t' i') =
        i == i' && equiv delta m m' && equiv delta t t'

instance TypeEq StackType where
    equiv delta (SVar rho) (SVar rho') =
        let indom = isJust $ rho `lookupSD` delta
        in  indom && rho == rho'
    equiv delta (t `SCons` s) (t' `SCons` s') =
        equiv delta t t' && equiv delta s s'
    equiv delta SEmpty SEmpty = True
    -- equiv _ _ _ = False

instance TypeEq MemType where
    equiv delta (MVar mu) (MVar mu') =
        let indom = isJust $ mu `lookupMD` delta
        in  indom && mu == mu'
    equiv delta Scratch Scratch = True
    equiv delta Shared Shared = True
    -- equiv _ _ _ = False

updateTD :: TypeVarContext -> TypeVar -> Type -> TypeVarContext
updateTD delta@(TypeVarContext { alpha = as}) a t =
        delta { alpha = (a, t) : as }

updateSD :: TypeVarContext -> StackTypeVar -> StackType -> TypeVarContext
updateSD delta@(TypeVarContext { stack = ss}) s t =
        delta { stack = (s, t) : ss }

updateMD :: TypeVarContext -> MemTypeVar -> MemType -> TypeVarContext
updateMD delta@(TypeVarContext { mem = ms}) m t =
        delta { mem = (m, t) : ms }

instance ContextVar TypeVar where
    indom a (TypeVarContext {alpha = as}) = isJust $ a `lookup` as
    -- lookupT x (TypeVarContext {alpha = as}) =
    --     snd <$> find ((== x) . fst) as

instance ContextVar MemTypeVar where
    indom m (TypeVarContext {mem = ms}) = isJust $ m `lookup` ms
    -- lookupT x (TypeVarContext {mem = mus}) =
    --     snd <$> find ((== x) . fst) mus

instance ContextVar StackTypeVar where
    indom s (TypeVarContext {stack = ss}) = isJust $ s `lookup` ss
    -- lookupT x (TypeVarContext {alpha = rhos}) =
    --     snd <$> find ((== x) . fst) rhos
