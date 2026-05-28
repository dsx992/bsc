module Flatten where

import Syntax

registers :: [Register]
registers = [Zero ..]

class Flatten a where
    flatten :: TypeVarContext -> a -> Maybe a

instance Flatten Type where
    flatten delta (TVar a)           = a `lookupTD` delta
    flatten delta (TCollection c)    = TCollection <$> flatten delta c
    flatten delta t                  = Just t

instance Flatten CollectionType where
        flatten delta (Array m t i) =
            do
                m' <- flatten delta m
                t' <- flatten delta t
                return $ Array m' t' i
        flatten delta (CStack m s) =
            do
                m' <- flatten delta m
                s' <- flatten delta s
                return $ CStack m' s'

instance Flatten MemType where
    flatten delta (MVar mu)  = mu `lookupMD` delta
    flatten delta m          = Just m

instance Flatten StackType where
    flatten delta (SVar rho)     = rho `lookupSD` delta
    flatten delta (t `SCons` s)  =
        do
            t' <- flatten delta t
            s' <- flatten delta s
            return $ t' `SCons` s'
    flatten delta s              = Just s

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
