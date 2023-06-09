(* interlude5.ml, but really a followup to interlude1.ml *)

(* update: now in tensor.ml *)

let rec tmap f t =
  match t with
  | S _x -> f t
  | T ts ->
     (* bugfix: if you do 'T (Array.map (tmap f) ts)'
      * then function like 'let sum = ext1 sum_1 1' would loop forever.
      *)
     T (Array.map f ts)

let res_frame_4 =
  tmap (function S f -> S (f +. 1.)) (T [| S 3.; S 5.; S 4. |])

(* this is invalid with the latest tmap! *)
let res_frame_4_invalid =
  tmap (function S f -> S (f +. 1.)) (T [| T [| S 3.|]; T [|S 5.|]; T [|S 4.|] |])

let rec tmap2 g t u =
  match t, u with
  | S _x, S _y -> g t u
  | T xs, T ys ->
     T (Array.map2 g xs ys)
  | _ -> failwith "tmap2: tensor have different shapes"

let plus0 t u =
  match t, u with
  | S x, S y -> S (x +. y)
  | _ -> failwith "plus0: one of the argument is not a tensor0"
    
let res_frame_6 =
  tmap2 plus0
   (T [| S 3.; S 4.; S 6.; S 1.|])
   (T [| S 1.; S 3.; S 5.; S 5.|])

let is_rank_basic n t =
  rank t = n

(* scheme: was called of_rank? *)
let rec is_rank n t =
  match t with
  | _ when n = 0 -> is_scalar t
  | S _ -> false
  | T _ -> is_rank (n - 1) (tref t 0)

let res_frame_12 =
  let t =
      T [| T [| T [|S 8.|]; T [|S 9.|] |];
       T [| T [|S 4.|]; T [|S 7.|] |];
    |]
  in
  is_rank 3 t

let sqrt0 = function
  | S f -> S (Float.sqrt f)
  | T _ -> failwith "sqrt0: not a scalar"
    
let rec sqrt_basic t =
  if is_rank 0 t
  then sqrt0 t
  else tmap sqrt_basic t

let rec ext1_basic f = fun t ->
  if is_rank 0 t
  then f t
  else tmap (ext1_basic f) t
  
let sqrt = ext1_basic sqrt0

let res_sqrt =
  sqrt (T [| S 3.; S 5.; S 4. |])

let zeroes =
  ext1_basic (fun _t -> S 0.)

let rec ext1 f n = fun t ->
  if is_rank n t
  then f t
  else tmap (ext1 f n) t

let sqrt =
  ext1 sqrt0 0

let res_sqrt_bis =
  sqrt (T [| S 3.; S 5.; S 4. |])

let zeroes =
  ext1 (fun _ -> S 0.) 0

let sum =
  ext1 sum_1 1

let res_sum =
  sum (T [| S 3.; S 5.; S 4. |])

(* was looping forever with original version of tmap  *)
let res_sum_bis =
  let t = T [| (T [| S 3.; S 5.; S 4. |]); (T [| S 3.; S 5.; S 4. |]) |] in
  sum t

let ex_frame_26 =
  T [|
      T [| S 1.0; S 0.5|];
      T [| S 3.1; S 2.2|];
      T [| S 7.3; S 2.1|];
    |]

let res_shape_frame_26 =
  shape ex_frame_26

(* Base.Array.concat_map is the faster. See 
https://stackoverflow.com/questions/34752023/what-is-the-fastest-way-to-flatten-an-array-of-arrays-in-ocaml
 *)
let flatten_2 t2 =
  match t2 with
  | S _ -> failwith "flatten_2: not a tensor2"
  | T ts ->
     T (Base.Array.concat_map ~f:(function
            | S _ -> failwith "flatten_2: not a tensor2"
            | T ts -> ts)                      
             ts)
  
let res_frame_26 =
  flatten_2 ex_frame_26

 
let flatten =
  ext1 flatten_2 2

let ex_frame_28 =
  T [|
    T [|
      T [| S 1.0; S 0.5|];
      T [| S 3.1; S 2.2|];
      T [| S 7.3; S 2.1|];
      |];
    T [|
      T [| S 2.9; S 3.5|];
      T [| S 0.7; S 1.5|];
      T [| S 2.5; S 6.4|];
      |];
    |]    

(* this works also with flatten_2 though *)
let res_frame_28 =
  flatten ex_frame_28

let rank_gt_basic t u =
  rank t > rank u

let rec rank_gt t u =
  match t, u with
  | S _, _ -> false
  | _, S _ -> true
  | _else_ -> rank_gt (tref t 0) (tref u 0)

(* scheme: was called of_ranks? *)
let is_ranks n t m u =
  if is_rank n t
  then is_rank m u
  else false

let res_frame_34 =
  is_ranks
    3
    (T [|
         T [|
             T [| S 8.|];
             T [| S 9.|];
           |];
         T [|
             T [| S 2.|];
             T [| S 1.|];
           |];
       |])
    2
    (T [| S 5. |])
         

let desc_t g t u =
  tmap (fun et -> g et u) t
let desc_u g t u =
  tmap (fun eu -> g t eu) u

let desc g n t m u =
  match () with
  | _ when is_rank n t -> desc_u g t u
  | _ when is_rank m u -> desc_t g t u
  | _ when tlen t = tlen u -> tmap2 g t u
  | _ when rank_gt t u -> desc_t g t u
  | _else_ -> desc_u g t u

let rec ext2 f n m = fun t u ->
  if is_ranks n t m u
  then f t u
  else
    desc (ext2 f n m) n t m u 

let mult0 t u =
  match t, u with
  | S x, S y -> S (x *. y)
  | _ -> failwith "mult0: one of the argument is not a tensor0"

let (+) =
  ext2 plus0 0 0

let ( * ) =
  ext2 mult0 0 0

let sqr t =
  t * t

let dotproduct_1_1 w t =
  sum_1 (w * t)

let res_frame_106_27 =
  dotproduct_1_1
    (T [| S 2.0; S 1.0; S 7.0|])
    (T [| S 8.0; S 4.0; S 3.0|])

let dotproduct =
  ext2 dotproduct_1_1 1 1

let mult_2_1 =
  ext2 ( * ) 2 1

let res_frame_45 =
  let p =
    T [|
        T [| S 3.; S 4.; S 5.|];
        T [| S 7.; S 8.; S 9.|];
      |] in
  let t =
    T [| S 2.; S 4.; S 3.|] in
  mult_2_1 p t
  (* same than p * t, because already at base rank *)

let res_frame_47_and_48 =
  let q =
    T [|
        T [| S 8.; S 1. |];
        T [| S 7.; S 3. |];
        T [| S 5.; S 4. |];
      |] in
  let r =
    T [|
        T [| S 6.; S 2. |];
        T [| S 4.; S 9. |];
        T [| S 3.; S 8. |];
      |] in
  (* this time different from: q * r *)
  mult_2_1 q r
