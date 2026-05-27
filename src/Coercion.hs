module Coercion where

import Syntax
import Data.Maybe

-- | Using Maybes as a form of backtracking


coerce :: TypeVarContext -> AType -> AType -> Maybe TypeVarContext
coerce delta ta@(TVar a) ta'@(TVar a')
    | ta === ta'    = Just delta
    | _             = Nothing
    where (===) = equiv delta

coerce delta (TVar a) TInt
    | not indom     = Just $ updateTD delta a TInt
    | _             = Nothing
    where indom = isJust $ a `lookupTD` delta

coerce delta (TVar a) (TCollection c) = undefined

equiv :: TypeVarContext -> AType -> AType -> Bool
equiv delta (TVar a) (TVar a') =
    let indom = isJust $ a `lookupTD` delta
    in  indom && a == a'

equiv delta Top Top = True
equiv delta TInt TInt = True
equiv delta (TDInt i) (TDInt j) = i == j
equiv delta (TCollection c) (TCollection c') =
    undefined

equiv _ _ _ = False

equivC :: TypeVarContext -> CollectionType -> CollectionType -> Bool
equivC delta (CStack m s) (CStack m' s') = undefined

equivM :: TypeVarContext -> MemType -> MemType -> bool
equivM delta (MemTypeVar mu) (MemTypeVar mu') =
    let indom = isJust $ mu `lookupMD` delta
    in  indom && mu == mu'
equivM delta m m' =
    m == m'
equivM _ _ _ = False

equivS :: TypeVarContext -> StackType -> StackType -> Bool
equivS delta SEmpty SEmpty = True
equivS delta 

updateTD :: TypeVarContext -> TypeVar -> AType -> TypeVarContext
updateTD delta@(TypeVarContext { alpha = as}) a t =
        delta { alpha = (a, t) : as }

