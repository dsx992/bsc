module TAL0

type register = R0 | R1 | R2 | R3 | R4
and address =
    | Label of string
    | Pointer of int
and operand =
    | N of int
    | L of string
    | R of register
and instruction =
    | Mov of register * operand
    | Add of register * register * operand
    | Ifj of register * operand
    | Print of register
and sequence =
    | Jump of operand
    | Cons of instruction * sequence

let regadd (rlu : register -> operand) ((r, v) : register * operand) =
    fun r' -> if r = r' then v else rlu r'

let rec eval s rlu labels =
    match s with
    | Jump op ->
        match op with
        | R R0 -> rlu
        | N n -> eval (labels (Pointer n)) rlu labels
        | L l -> eval (labels (Label l)) rlu labels
        | R r -> let op' = rlu r in eval (Jump op') rlu labels
    | Cons (insn, s') ->
        match evali insn rlu labels with
        | rlu', None -> eval s' rlu' labels
        | rlu', Some s'' -> eval s'' rlu' labels

and evali insn rlu labels : (register -> operand) * sequence option =
    match insn with
    | Mov (rd, op) -> regadd rlu (rd, op), None
    | Add (rd, rs, v) ->
        let rec add = function
            | N n, N m -> regadd rlu (rd, N (n + m))
            | R r, v' -> add (rlu r, v')
            | v', R r -> add (v', rlu r)
            | L _, _
            | _, L _ -> failwith "cannot add labels"
        let r = rlu rs in add (r, v), None
    | Ifj (r, v) ->
        let rec bound = function
            | N n -> n = 0
            | L _ -> false
            | R r -> bound (rlu r)
        let rec code = function
            | N n -> labels (Pointer n)
            | L l -> labels (Label l)
            | R r -> code (rlu r)
        rlu, if bound (rlu r) then Some (code v) else None
    | Print r ->
        printfn "print: %A" (rlu r)
        rlu, None


let heap : (address -> sequence) =
    let code = [
        Label "prod",
          Cons(   Mov(R3, N 0), 
                  Jump (L  "loop"))
        Label "loop",
          Cons(   Ifj (R1, (L "done")),
          Cons(   Add(R3, R2, R R3),
          Cons(   Add(R1, R1, N -1),
                  Jump (L "loop"))))
        Label "done",
                    Jump (R R4)
        Label "print",
            Cons (  Print R3, Jump (R R0))
    ]
    fun l -> List.find (fst >> (=) l) code |> snd


let prod n m =
    let rlu r =
        match r with
        | R1 -> N n
        | R2 -> N m
        | R4 ->  L "print"
        | _ -> failwith $"register {r} not bound."

    (eval (heap (Label "prod")) rlu heap) R3


[<EntryPoint>]
let main _ =
    let n, m = 3, 4
    let rlu r =
        match r with
        | R1 -> N n
        | R2 -> N m
        | R4 ->  L "print"
        | _ -> failwith $"register {r} not bound."

    eval (heap (Label "prod")) rlu heap |> ignore
    0

