module Flatten where

import Syntax
import Data.List
import Data.Maybe

registers :: [Register]
registers = [Zero ..]

class Flatten a where
    flatten :: TypeVarContext -> a -> Maybe a

instance Flatten Block where
    flatten delta (Block (rf, insns)) =
        do
            pairs <- mapM moveM $ zip regs (flatrf <$> regs)
            let rf' = fromMaybe Top . (`lookup` pairs)
            return $ Block (rf', insns)
        where
            regs = [Zero ..]
            flatrf = flatten delta . rf
            moveM :: Monad m =>  (a, m b) -> m (a, b)
            moveM (a, mb) =
                do
                    b <- mb
                    return (a, b)

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
