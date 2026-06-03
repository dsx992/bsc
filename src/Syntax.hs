module Syntax where

import Data.List
import Data.Foldable
import Data.Maybe
import Data.Char

class Var a where
    name :: a -> String
    newvar :: String -> a

newtype TypeVar = TypeVar String
    deriving (Eq, Show)
instance Var TypeVar where
    name (TypeVar str) = str
    newvar = TypeVar

newtype MemTypeVar = MemTypeVar String
    deriving (Eq, Show)
instance Var MemTypeVar where
    name (MemTypeVar str) = str
    newvar = MemTypeVar

newtype StackTypeVar = StackTypeVar String
    deriving (Eq, Show)
instance Var StackTypeVar where
    name (StackTypeVar str) = str
    newvar = StackTypeVar

data Register = Zero | Ra | Sp | Gp | Tp | T0 | T1 | T2 | Fp | S1 | A0 | A1 | A2 | A3 | A4 | A5 | A6 | A7 | S2 | S3 | S4 | S5 | S6 | S7 | S8 | S9 | S10 | S11 | T3 | T4 | T5 | T6

    deriving (Eq, Show, Enum)

instance Read Register where
    readsPrec _ input
        | Just r <- map toLower reg `lookup` registers = [(r, rest)]
        | otherwise  = []
        where
            registers = [(map toLower $ show r, r) | r <- [Zero ..]]
            (reg, rest) = span isAlphaNum input

-- newtype StateType = StateType TypeVarContext RegFile

data TypeVarContext =
    TypeVarContext
    { alpha :: [(TypeVar, Type)]
    , mem   :: [(MemTypeVar, MemType)]
    , stack :: [(StackTypeVar, StackType)]
    }
    deriving (Show)

-- [(TypeVar, Type)]

type RegFile = (Register -> Type)

data Type 
    = TVar TypeVar
    | Top
    | TInt
    | TDInt Int
    | TCollection CollectionType
    deriving (Show)

data StackType = SEmpty | SVar StackTypeVar | Type `SCons` StackType
    deriving (Show)

data MemType = Scratch | Shared | MVar MemTypeVar
    deriving (Show)

data CollectionType
    = Array MemType Type Int
    | CStack MemType StackType
    deriving (Show)
type Label = String
data Value = VInt Int | Label Label | Reg Register
    deriving (Show)

-- data ArithOp = Add | Sub | Mul | Div
data Instruction
    = Add Register Register Value
    | Sub Register Register Value
    | Mul Register Register Value
    | Div Register Register Value
    | Incr Register Register Value
    | Decr Register Register Value
    | Mv Register Register
    | Jump Value
    | Halt
    | Load Register Register Value
    | Store Register Register Value
    | Mvscr Register
    | Mvshr Register
    deriving (Show)
-- data InstructionTerminal = Jump Value | Halt
--     deriving (Show)
type InstructionSeq = [Instruction]
    -- =  Instruction `ICons` InstructionSeq
    -- | Terminal InstructionTerminal
    -- deriving (Show)
newtype StateType = StateType (TypeVarContext, RegFile)
newtype Block = Block (RegFile, InstructionSeq)
    deriving (Show)
newtype LabelMap = LabelMap (Label -> StateType)
type Text = [(Label, Block)]
data Info = Info { wordsize     :: Integer
                 , scratchaddr  :: Integer
                 , scratchsize  :: Integer
                 , scratchtime  :: Integer
                 , sharedaddr   :: Integer
                 , sharedsize   :: Integer
                 , sharedtime   :: Integer
                 , arittime     :: Integer
                 }
    deriving (Show)
type Program = (Info, Text)

type Block' = [(RegFile, Instruction)]

instance Show RegFile where
    show rf = show $ map rf [Zero ..]

lookupTD :: TypeVar -> TypeVarContext -> Maybe Type
lookupTD x (TypeVarContext {alpha = as}) =
    snd <$> find ((== x) . fst) as

lookupMD :: MemTypeVar -> TypeVarContext -> Maybe MemType
lookupMD x (TypeVarContext {mem = mus}) =
    snd <$> find ((== x) . fst) mus

lookupSD :: StackTypeVar -> TypeVarContext -> Maybe StackType
lookupSD x (TypeVarContext {stack = rhos}) =
    snd <$> find ((== x) . fst) rhos

class TypeEq t where
    equiv :: TypeVarContext -> t -> t -> Bool

class TypeEq t => TypeCo t where
    coerce :: TypeVarContext -> t -> t -> Maybe TypeVarContext

class ContextVar a where
    indom :: a -> TypeVarContext -> Bool
    -- lookupT  :: TypeEq t => a -> TypeVarContext -> Maybe t
