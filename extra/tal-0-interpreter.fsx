

type register = R1 | R2 | R3 | R4 | R5 | R6
and value =
    | I of int
    | A of address
and address =
    | Label of string
    | Pointer of int
and operand = 
    | V of value
    | R of register
and instruction =
    | Mov of register * operand
    | Add of register * operand * operand
    | If of register * operand
and sequence =
    | Jump of operand
    | Cons of instruction * sequence
    // | list?

let regadd (regs : register -> value option) ((r, v) : register * value): register -> value option =
    fun r' -> if r' = r then Some v else regs r'
    

let rec eval (s : sequence) (registers : register -> value option) (labels : address -> sequence) =
    match s with
    | Jump op ->
        match op with
        | R r ->
            match registers r with
            | Some v -> eval (Jump (V v)) registers labels
            | _ -> eprintf $"register {r} has is unbound"
        | Cons (insn, s') -> evali insn

and evali (insn : instruction) (registers : register -> value option) (labels : address -> sequence) =
    match insn with
    | Mov (r, o) ->
        match o with
        | V v -> regadd registers (r, v)
        | R r' ->
            match registers r' with
            | Some v -> regadd registers (r', v)
            | None -> registers
    | Add (r, o, p) ->
        
let program : sequence list * (address -> sequence) =
    let code = [
        "prod", Cons( Mov(R3, N 0), 
                      Jump (L (Label "loop")))
        "loop", Cons( If (R1, (L (Label "done"))),
                Cons( Add(R3, R R2, R R3),
                Cons( Add(R1, R R1, N -1),
                      Jump (L (Label "loop")))))
        "done",       Jump (R R4)
    ]
    let maddr a =
        match a with
        | Pointer _ -> failwith "No pointers"
        | Label l -> List.find (fst >> (=) l) code |> snd

    (List.map snd code), maddr
