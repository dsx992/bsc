module AbSyn where

newtype RegionMemoryVariable = RegionMemVar String
data RegionMemory = Scratch
                  | Shared
                  | RegMemVar RegionMemoryVariable
newtype StackVariable = StackVar String





-- newtype Register = Reg Integer
--     deriving (Show, Eq)
-- 
-- newtype TypeVariable = TypeVariable String
--     deriving (Show)
-- 
-- data MemTypeVariable = Scratch
--                      | Shared
--                      | MemVar TypeVariable
--     deriving (Show)
-- 
-- newtype Label = Label String
--     deriving (Show)
-- 
-- data Instruction = Aop
--                  | Bop Label
--                  -- | JMP Label
--                  -- | BEQ Label    -- WCET needs both branch and no branch, so no more information is needed
--     deriving (Show)
-- 
-- data Block = Block [Instruction]
--     deriving (Show)
-- 
-- type Program = [Label -> Block]



-- data TypeVariable = String
-- type TypeState = (RegfileTypes, StackType)
-- type StateType = (TypeVariableContext, IndexContext, TypeState)
-- type RegfileTypes = [(Register, Type)]
-- type StackTypeVariable = String
-- data StackType = SNil 
--                | Bottom StackTypeVariable
--                | Cons Type StackType
-- type MemTypeVariable = String
-- data MemType = Scratch
--              | Shared
--              | MVar MemTypeVariable
-- data Type = TVar TypeVariable
--             | State StateType
--             | Top
--             | Int
--             | Array MemType Type
--             | Exists TypeVariable IndexSort Type
-- data TypeVariableContext = TVNil
--                          | TCons TypeVariableContext TypeVariable
--                          | SCons TypeVariableContext StackTypeVariable
--                          | MCons TypeVariableContext MemTypeVariable
-- data Register = Ra | R1 | R2
-- data Instruction = ADDI Register Register Value
--                  | ADD Register Register Register
-- data Constant = CNil
--               | Integer
--               | Label
-- data Value = Const Constant
--            | Reg Register
-- data InstructionSequence = JMP Value
--                          | Halt
--                          | Semi Instruction InstructionSequence
-- type Block = (TypeVariableContext, IndexContext, TypeState, InstructionSequence)
-- type Label = String
-- type LabelMap = Label -> StateType
-- type Program = [(Label, Block)]
-- 
-- data IndexExp = TypeVariable
--               | IntegerBLAH
--               -- TODO: finish
-- data IndexProp = LT IndexExp IndexExp
--               -- TODO: finish
-- data IndexSort = ISInt | ISTODO
-- data IndexContext = INil | ICTODO
