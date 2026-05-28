module Coercion where

import Syntax
import Data.Maybe

-- | Using Maybes as a form of backtracking

instance TypeCo Type where
    coerce delta ta@(TVar a) ta'@(TVar a') =
        if equiv delta ta ta' then
            Just delta
        else
            Nothing
    coerce delta (TVar a) TInt =
        if not $ a `indom` delta then
            Just $ updateTD delta a TInt
        else
            Nothing
    coerce delta ta@(TVar a) t@(TDInt i) =
        updateTD delta a t <$ coerce delta ta TInt
    coerce delta (TVar a) c@(TCollection _)
        | not $ a `indom` delta = Just $ updateTD delta a c
        | a `indom` delta       = Nothing
    coerce delta (TVar a) t = undefined

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

instance ContextVar TypeVar where
    indom t delta = isJust $ t `lookup` delta
    lookup (TypeVarContext {alpha = as}) x =
        snd <$> find ((== x) . fst) as

instance ContextVar MemTypeVar where
    indom m delta = isJust $ m `lookup` delta
    lookup (TypeVarContext {mem = mus}) x =
        snd <$> find ((== x) . fst) mus

instance ContextVar StackTypeVar where
    indom s delta = isJust $ s `lookup` delta
    lookup (TypeVarContext {alpha = rhos}) x =
        snd <$> find ((== x) . fst) rhos
