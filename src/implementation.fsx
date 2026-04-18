module AbSyn =

    type TypeVariable = string
    and TypeState = (RegfileTypes * StackType)
    and StateType = TypeVariableContext * IndexContext * TypeState
    and RegfileTypes = (Register * Type) list
    and StackTypeVariable = String
    and StackType = SNil 
                   | Bottom of StackTypeVariable
                   | Cons of Type * StackType
    and MemTypeVariable = String
    and MemType = Scratch
                 | Shared
                 | MVar of MemTypeVariable
    and 'x Type = 
        |TVar of TypeVariable
        | State of StateType
        | Top
        | Int of 'x
        | Array of MemType * Type * 'x
        | Exists of TypeVariable * IndexSort * Type
    and TypeVariableContext = 
        | TVNil
        | TCons of TypeVariableContext * TypeVariable
        | SCons of TypeVariableContext * StackTypeVariable
        | MCons of TypeVariableContext * MemTypeVariable
    and Register = Ra | R1 | R2
    and Instruction = 
        | Addi of Register * Register * Value
        | Add of Register * Register * Register
    and Constant = CNil
                  | Integer
                  | Label
    and Value = Const Constant
               | Reg Register
    and InstructionSequence = Jmp Value
                             | Halt
                             | Semi Instruction InstructionSequence
    and Block = (TypeVariableContext * IndexContext * TypeState * InstructionSequence)
    and Label = String
    type LabelMap = Label -> StateType
    type Program = [Label * Block]

    type IndexExp = TypeVariable
                  | Integer
                  -- TODO: finish
    and IndexProp = LT IndexExp IndexExp
                  -- TODO: finish
    and IndexSort = Int
    and IndexContext = INil
