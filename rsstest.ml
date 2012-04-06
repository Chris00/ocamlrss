(* Testing *)

let fatal msg = prerr_endline msg; exit 1;;

let main () =
  if Array.length Sys.argv < 2 then
    fatal (Printf.sprintf "Usage: %s <rss file>" Sys.argv.(0));
  try
    let channel = Rss.channel_of_file Sys.argv.(1) in
    Rss.print_channel Format.std_formatter channel
  with
    | Sys_error s | Failure s -> fatal s
;;

let () = main ();;