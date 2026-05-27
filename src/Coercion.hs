module Coercion where

import Syntax

coerceAlpha :: TypeVarContext -> Type -> Type -> Maybe TypeVarContext
coerceAlpha delta (TVar a) (TVar a) =
    find ((== a) . fst) TypeVarContext
