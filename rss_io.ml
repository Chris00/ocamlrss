(*********************************************************************************)
(*                OCamlrss                                                       *)
(*                                                                               *)
(*    Copyright (C) 2004-2012 Institut National de Recherche en Informatique     *)
(*    et en Automatique. All rights reserved.                                    *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU Library General Public License version       *)
(*    2.1 as published by the Free Software Foundation.                          *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Library General Public License for more details.                       *)
(*                                                                               *)
(*    You should have received a copy of the GNU Library General Public          *)
(*    License along with this program; if not, write to the Free Software        *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*                                                                               *)
(*********************************************************************************)

open Xmlm
open Rss_types

(** Parsing/Printing RSS documents. *)

type tree =
    E of Xmlm.tag * tree list
  | D of string

let string_of_xml tree =
  try
    let b = Buffer.create 256 in
    let output = Xmlm.make_output (`Buffer b) in
    let frag = function
    | E (tag, childs) -> `El (tag, childs)
    | D d -> `Data d
    in
    Xmlm.output_doc_tree frag output (None, tree);
    Buffer.contents b
  with
    Xmlm.Error ((line, col), error) ->
      let msg = Printf.sprintf "Line %d, column %d: %s"
        line col (Xmlm.error_message error)
      in
      failwith msg
;;

let source_string = function
  `String (n, s) -> String.sub s n (String.length s - n)
| `Channel _ | `Fun _ -> ""
;;


let xml_of_source source =
  try
    let input = Xmlm.make_input ~enc: (Some `UTF_8) source in
    let el tag childs = E (tag, childs)  in
    let data d = D d in
    let (_, tree) = Xmlm.input_doc_tree ~el ~data input in
    tree
  with
    Xmlm.Error ((line, col), error) ->
      let msg =
        Printf.sprintf "Line %d, column %d: %s\n%s"
        line col (Xmlm.error_message error) (source_string source)
      in
      failwith msg
  | Invalid_argument e ->
      let msg = Printf.sprintf "%s:\n%s" e (source_string source) in
      failwith msg
;;

(** {2 Parsing} *)

let find_ele name e =
    match e with
      E ((("",e),_),_) when name = String.lowercase e -> true
    | _ -> false

let apply_opt f = function
    None -> None
  | Some v -> Some (f v)

let get_att ?(required=true) atts name =
  let name = String.lowercase name in
  try snd (List.find (fun ((_,s),_) -> String.lowercase s = name) atts)
  with Not_found ->
    if required then raise Not_found else ""

let get_opt_att atts name =
  let name = String.lowercase name in
  try Some
      (snd (List.find
		 (fun ((_,s), _) -> String.lowercase s = name)
		 atts)
      )
  with Not_found ->
    None

let get_source xmls =
  try
    match List.find (find_ele "source") xmls with
      E ((_,atts),[D s]) ->
        Some {
          src_name = s ;
          src_url = get_att atts "url" ;
        }
    | _ ->
        None
  with
    Not_found ->
      None

let get_enclosure xmls =
  try
    match List.find (find_ele "enclosure") xmls with
      E ((_,atts),_) ->
	Some { encl_url = get_att atts "url" ;
	       encl_length = int_of_string (get_att atts "length") ;
	       encl_type = get_att atts "type" ;
	     }
    | _ ->
	None
  with
    _ ->
      None

let get_categories xmls =
  let f acc = function
    E ((("",tag),atts),[D s])
    when String.lowercase tag = "category"->
      { cat_name = s ;
        cat_domain = get_opt_att atts "domain" ;
      } :: acc
  | _ -> acc
  in
  List.rev (List.fold_left f [] xmls)

let get_guid xmls =
   try
    match List.find (find_ele "guid") xmls with
      E ((_,atts),[D s]) ->
	Some { guid_name = s ;
	       guid_permalink =
	         (get_att ~required: false atts "ispermalink") <> "false" ;
	     }
    | _ ->
	None
  with
    Not_found ->
      None

let get_image xmls =
  try
    match List.find (find_ele "image") xmls with
      E ((_,atts),subs) ->
	let f s =
	  match List.find (find_ele s) subs with
	    E ((_,_),[D s]) -> s
	  |	_ -> raise Not_found
	in
	let f_opt s =
	  try
	    match List.find (find_ele s) subs with
	      E ((_,_),[D s]) -> Some (f s)
	    |	_ -> None
	  with _ -> None
	in
	Some { image_url = f "url" ;
	       image_title = f "title" ;
	       image_link = f "link" ;
	       image_width = apply_opt int_of_string (f_opt "width") ;
	       image_height = apply_opt int_of_string (f_opt "height") ;
	       image_desc = f_opt "description" ;
	     }
    | _ ->
	None
  with
    _ ->
      None

let get_text_input xmls =
  try
    match List.find (find_ele "textinput") xmls with
      E ((_,atts),subs) ->
	let f s =
	  match List.find (find_ele s) subs with
	    E ((_,_),[D s]) -> s
	  |	_ -> raise Not_found
	in
	Some { ti_title = f "title" ;
	       ti_desc = f "description" ;
	       ti_name = f "name" ;
	       ti_link = f "link" ;
	     }
    | _ ->
	None
  with
    _ ->
      None

let item_of_xmls xmls =
  let f s =
    try
      match List.find (find_ele s) xmls with
	E ((_,_),[D s]) -> Some s
      |	_ -> None
    with Not_found -> None
  in
  let date =
    match f "pubdate" with
      None -> None
    | Some s ->
	try Some (Rss_date.parse s)
	with _ -> None
  in
  { item_title = f "title" ;
    item_link = f "link" ;
    item_desc = f "description" ;
    item_pubdate = date ;
    item_author = f "author" ;
    item_categories = get_categories xmls ;
    item_comments = f "comments" ;
    item_enclosure = get_enclosure xmls ;
    item_guid = get_guid xmls ;
    item_source = get_source xmls ;
  }

let items_of_xmls xmls =
  List.rev
  (List.fold_left
   (fun acc e ->
      match e with
        D _ -> acc
      |	E ((("",s),_),subs) when String.lowercase s = "item" ->
	     (item_of_xmls subs) :: acc
	 |	E _ -> acc
       )
       []
       xmls
    )

let channel_of_xmls xmls =
  let f s =
    try
      match List.find (find_ele s) xmls with
        E ((_,_),[D s]) -> s
      | E ((_,_),[]) -> ""
      |	_ -> raise Not_found
    with Not_found ->
      failwith ("Parse error: no correct "^s)
  in
  let f_opt s =
    try
      match List.find (find_ele s) xmls with
        E ((_,_),[D s]) -> Some s
      |	_ -> None
    with Not_found -> None
  in
  let pubdate =
    match f_opt "pubdate" with
      None -> None
    | Some s ->
	try Some (Rss_date.parse s)
	with _ -> None
  in
  let builddate =
    match f_opt "lastbuilddate" with
      None -> None
    | Some s ->
	try Some (Rss_date.parse s)
	with _ -> None
  in
  let ttl =
    match f_opt "ttl" with
      None -> None
    | Some s ->
	try Some (int_of_string s)
	with _ -> None
  in
  { ch_title = f "title" ;
    ch_link = f "link" ;
    ch_desc = f "description" ;
    ch_language = f_opt "language" ;
    ch_copyright = f_opt "copyright" ;
    ch_managing_editor = f_opt "managingeditor" ;
    ch_webmaster = f_opt "webmaster" ;
    ch_pubdate = pubdate ;
    ch_last_build_date = builddate ;
    ch_categories = get_categories xmls ;
    ch_generator = f_opt "generator" ;
    ch_docs = f_opt "docs" ;
    ch_ttl = ttl ;
    ch_image = get_image xmls ;
    ch_text_input = get_text_input xmls ;
    ch_items = items_of_xmls xmls ;
  }

let channel_of_source source =
  let xml = xml_of_source source in
  match xml with
  | D _ -> failwith "Parse error: not an element"
  | E (((_,e), atts), subs) ->
      match String.lowercase e with
        "rss" ->
          (
           match subs with
             [E ((("",e), atts), subs)] ->
               (
                match String.lowercase e with
                  "channel" -> channel_of_xmls subs
                | _ -> failwith "Parse error: not channel"
               )
           | _ ->
               failwith "Parse error: two much things in rss"
          )
      |	"rdf:rdf" ->
          (
           match subs with
           | [] ->
               failwith "Parse error: no channel"
           | (E ((("",e), atts), subs)) :: q ->
               (
                match String.lowercase e with
                  "channel" -> channel_of_xmls (subs @ q)
                | _ -> failwith "Parse error: not channel"
               )
           | _ ->
               failwith "Parse error: not channel"
          )
      |	_ ->
          failwith "Parse error: not rss"

let channel_of_string s =
  channel_of_source (`String (0, s))

let channel_of_file file =
  let ic = open_in file in
  try
    channel_of_source (`Channel ic)
  with
    e ->
      close_in ic;
      raise e
;;

let channel_of_channel ch = channel_of_source (`Channel ch);;

(** {2 Printing} *)

let opt_element opt s =
  match opt with
    None -> []
  | Some v -> [E ((("",s), []), [D v])]

let default_date_format = "%d %b %Y %T %z"
    (* ex: 19 May 2002 15:21:36 *)

let err_date d = ()
(*
  let module D = Rss_date in
  let p = Printf.eprintf in
  prerr_endline "{";
  p "year = %d\n" d.D.year ;
  p "month = %d\n" d.D.month ;
  p "day = %d\n" d.D.day ;
  p "hour = %d\n" d.D.hour ;
  p "minute = %d\n" d.D.minute ;
  p "second = %d\n" d.D.second ;
  p "zone = %d\n" d.D.zone ;
  p "week_day = %d\n" d.D.week_day ;
  prerr_endline "}"
*)

let xml_of_category c =
  let atts =
    match c.cat_domain with
      None -> []
    | Some d -> [("","domain"), d]
  in
  E ((("","category"), atts), [D c.cat_name])

let xmls_of_categories l = List.map xml_of_category l

let xmls_of_opt_f f v_opt =
  match v_opt with
    None -> []
  | Some v -> [f v]

let xml_of_enclosure e =
  E ((("","enclosure"),
	   [
	     ("","url"), e.encl_url ;
	     ("","length"), string_of_int e.encl_length ;
	     ("","type"), e.encl_type ;
	   ]),
	   []
	  )

let xmls_of_enclosure_opt =
  xmls_of_opt_f xml_of_enclosure


let xml_of_guid g =
  E ((("","guid"),
    [("","isPermaLink"), (if g.guid_permalink then "true" else "false") ]),
	   [D g.guid_name]
	  )

let xmls_of_guid_opt = xmls_of_opt_f xml_of_guid

let xml_of_source s =
  E ((("", "source"), [("","url"), s.src_url]),
	   [D s.src_name]
	  )

let xmls_of_source_opt = xmls_of_opt_f xml_of_source

let xml_of_image i =
  E ((("", "image"), []),
	   [ E((("","url"),[]), [D i.image_url]) ;
	     E((("","title"),[]), [D i.image_title]) ;
	     E((("","link"),[]), [D i.image_link])
	   ] @
    (List.flatten
     [ opt_element
       (apply_opt string_of_int i.image_width)
       "width";
       opt_element
       (apply_opt string_of_int i.image_height)
       "height";
       opt_element i.image_desc "description" ;
     ]
    )
	  )

let xmls_of_image_opt = xmls_of_opt_f xml_of_image

let xml_of_text_input t =
  E ((("","textInput"), []),
	   [
	     E((("","title"), []), [D t.ti_title]) ;
	     E((("","description"),[]), [D t.ti_desc]) ;
	     E((("","name"), []), [D t.ti_name]) ;
	     E((("","link"), []), [D t.ti_link]) ;
	   ]
	  )

let xmls_of_text_input_opt = xmls_of_opt_f xml_of_text_input

let xml_of_item ~date_fmt i =
  E ((("","item"), []),
   (List.flatten
    [ opt_element i.item_title "title" ;
      opt_element i.item_link "link" ;
      opt_element i.item_desc "description" ;
      opt_element
      (match i.item_pubdate with
         None -> None
       | Some d ->
           err_date d;
           Some (Rss_date.format ~fmt: date_fmt d))
      "pubDate" ;
      opt_element i.item_author "author" ;
      xmls_of_categories i.item_categories ;
      opt_element i.item_comments "comments" ;
      xmls_of_enclosure_opt i.item_enclosure ;
      xmls_of_guid_opt i.item_guid ;
      xmls_of_source_opt i.item_source ;
    ]
   )
	  )

let xml_of_channel ~date_fmt ch =
  let f v s = E ((("",s), []), [D v]) in
  let xml_ch =
    E ((("","channel"), []),
     (
      [ f ch.ch_title "title" ;
        f ch.ch_link "link" ;
        f ch.ch_desc "description" ;
      ] @
	      (List.flatten
       [ opt_element ch.ch_language "language" ;
         opt_element ch.ch_copyright "copyright" ;
         opt_element ch.ch_managing_editor "managingEditor" ;
         opt_element ch.ch_webmaster "webMaster" ;
         opt_element
         (match ch.ch_pubdate with
            None -> None
          | Some d ->
              err_date d ;
              Some (Rss_date.format ~fmt: date_fmt d)
         )
         "pubDate" ;
         opt_element
         (match ch.ch_last_build_date with
            None -> None
          | Some d ->
              err_date d ;
              Some (Rss_date.format ~fmt: date_fmt d))
         "lastBuildDate" ;
         xmls_of_categories ch.ch_categories ;
         opt_element ch.ch_generator "generator" ;
         opt_element ch.ch_docs "docs" ;
         opt_element
         (apply_opt string_of_int ch.ch_ttl)
         "ttl";
         xmls_of_image_opt ch.ch_image ;
         xmls_of_text_input_opt ch.ch_text_input ;
         List.map (xml_of_item ~date_fmt) ch.ch_items ;
       ]
      )
     )
    )
  in
  E ((("","rss"), [("","version"), "2.0"]), [xml_ch])


let print_channel ?(date_fmt=default_date_format) ?(encoding="ISO-8859-1")fmt ch =
  let xml = xml_of_channel ~date_fmt ch in
  Format.fprintf fmt "<?xml version=\"1.0\" encoding=\"%s\" ?>\n" encoding;
  Format.fprintf fmt "%s" (string_of_xml xml )
