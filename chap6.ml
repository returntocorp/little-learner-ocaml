
(* Usually take the time of the day for init argument.
   Can also now use Random.self_init ()
 *)
let _ = Random.init 0

let res_frame_22 =
  Random.int 45

let rec sampled n i acc =
  if i = 0
  then acc
  else sampled n (Stdlib.(-) i 1) ((Random.int n)::acc)

let samples n s =
  sampled n s []

let res_frame_25 =
  samples 20 3

let trefs t xs =
  xs |> List.map (fun i -> tref t i) |> Array.of_list |> (fun arr -> T arr)

let batch_size = ref 4

let sampling_obj (expectant : expectant_fn) (xs : t) (ys : t) : objective_fn =
  let n = tlen xs in
  (fun theta ->
    let b = samples n !batch_size in
    expectant (trefs xs b) (trefs ys b) theta)

(* TODO: get S nan; S nan as result theta :( *)
let res_frame_37 =
  with_hyper revs 1000 (fun () ->
      with_hyper alpha 0.01 (fun () ->
         with_hyper batch_size 4 (fun () ->
             gradient_descent
               (sampling_obj (l2_loss line)
                  line_xs line_ys)
            [S 0.; S 0.])))

(* TODO I also get nan :( *)
let res_frame_42 =
  with_hyper revs 15000 (fun () ->
      with_hyper alpha 0.001 (fun () ->
         with_hyper batch_size 4 (fun () ->
             gradient_descent
               (sampling_obj (l2_loss plane)
                  plane_xs plane_ys)
            [T [| S 0.; S 0.|]; S 0.])))
