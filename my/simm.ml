open Asm

let rec g env = function (* 命令列の13bit即値最適化 (caml2html: simm13_g) *)
  | Ans(exp) -> Ans(g' env exp)
  | Let((x, t), Add(zero,C(i)), e) when (zero=reg_zero) &&(-32768 <= i) && (i < 32768) ->
      let e' = g (M.add x i env) e in
      if List.mem x (fv e') then Let((x, t), Add(reg_zero,C(i)), e') else
      ((* Format.eprintf "erased redundant Set to %s@." x; *)
       e')
  | Let(xt, exp, e) -> Let(xt, g' env exp, g env e)
and g' env = function (* 各命令の13bit即値最適化 (caml2html: simm13_gprime) *)
  | Add(x, V(y)) when M.mem y env -> Add(x, C(M.find y env))
  | Add(x, V(y)) when M.mem x env -> Add(y, C(M.find x env))
  | Sub(x, V(y)) when M.mem y env -> Sub(x, C(M.find y env))
  | IfEq(x, V(y), e1, e2) when M.mem y env -> IfEq(x, C(M.find y env), g env e1, g env e2)
  | IfLE(x, V(y), e1, e2) when M.mem y env -> IfLE(x, C(M.find y env), g env e1, g env e2)
  | IfGE(x, V(y), e1, e2) when M.mem y env -> IfGE(x, C(M.find y env), g env e1, g env e2)
  | IfEq(x, V(y), e1, e2) when M.mem x env -> IfEq(y, C(M.find x env), g env e1, g env e2)
  | IfLE(x, V(y), e1, e2) when M.mem x env -> IfGE(y, C(M.find x env), g env e1, g env e2)
  | IfGE(x, V(y), e1, e2) when M.mem x env -> IfLE(y, C(M.find x env), g env e1, g env e2)
  | IfEq(x, y', e1, e2) -> IfEq(x, y', g env e1, g env e2)
  | IfLE(x, y', e1, e2) -> IfLE(x, y', g env e1, g env e2)
  | IfGE(x, y', e1, e2) -> IfGE(x, y', g env e1, g env e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(x, y, g env e1, g env e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(x, y, g env e1, g env e2)
  | e -> e

let h { name = l; args = xs; fargs = ys; body = e; ret = t } = (* トップレベル関数の13bit即値最適化 *)
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

let f (Prog(data, fundefs, e)) = (* プログラム全体の13bit即値最適化 *)
  Prog(data, List.map h fundefs, g M.empty e)
