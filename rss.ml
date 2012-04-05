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

type date = Rss_date.t = {
  year : int;		(** complete year *)
  month : int;		(** 1..12 *)
  day : int;		(** 1..31 *)
  hour : int;
  minute : int;
  second : int;
  zone : int;		(** in minutes; 60 = UTC+0100 *)
  week_day : int	(** 0 = sunday; -1 if not given *)
}

let since_epoch = Rss_date.since_epoch
let float_to_date t = Rss_date.create t
let string_of_date ?(fmt="%d %b %Y") date = Rss_date.format ~fmt date

type email = string (** can be, for example: foo@bar.com (Mr Foo Bar) *)
type url = string
type category = Rss_types.category =
    {
      mutable cat_name : string ;
      mutable cat_domain : url option ;
    }

type image = Rss_types.image =
    {
      mutable image_url : url ;
      mutable image_title : string ;
      mutable image_link : url ;
      mutable image_height : int option ;
      mutable image_width : int option ;
      mutable image_desc : string option ;
    }

type text_input = Rss_types.text_input =
    {
      mutable ti_title : string ; (** The label of the Submit button in the text input area. *)
      mutable ti_desc : string ; (** Explains the text input area. *)
      mutable ti_name : string ; (** The name of the text object in the text input area. *)
      mutable ti_link : string ; (** The URL of the CGI script that processes text input requests. *)
    }

type enclosure = Rss_types.enclosure =
    {
      mutable encl_url : url ; (** URL of the enclosure *)
      mutable encl_length : int ; (** size in bytes *)
      mutable encl_type : string ; (** MIME type *)
    }

type guid = Rss_types.guid =
    {
      mutable guid_name : string ; (** can be a permanent url, if permalink is true *)
      mutable guid_permalink : bool ; (** default is true when no value was specified *)
    }

type source = Rss_types.source =
    {
      mutable src_name : string ;
      mutable src_url : url ;
    }

type item = Rss_types.item =
    {
      mutable item_title : string option;
      mutable item_link : url option;
      mutable item_desc : string option;
      mutable item_pubdate : date option ;
      mutable item_author : email option ;
      mutable item_categories : category list ;
      mutable item_comments : url option ;
      mutable item_enclosure : enclosure option ;
      mutable item_guid : guid option ;
      mutable item_source : source option ;
    }

type channel = Rss_types.channel =
    {
      mutable ch_title : string ;
      mutable ch_link : url ;
      mutable ch_desc : string ;
      mutable ch_language : string option ;
      mutable ch_copyright : string option ;
      mutable ch_managing_editor : email option ;
      mutable ch_webmaster : email option ;
      mutable ch_pubdate : date option ;
      mutable ch_last_build_date : date option ;
      mutable ch_categories : category list ;
      mutable ch_generator : string option ;
      mutable ch_docs : url option ;
      mutable ch_ttl : int option ;
      mutable ch_image : image option ;
      mutable ch_text_input : text_input option ;
      mutable ch_items : item list ;
    }

let item ?title
    ?link
    ?desc
    ?pubdate
    ?author
    ?(cats=[])
    ?comments
    ?encl
    ?guid
    ?source
    () =
  {
    item_title = title ;
    item_link = link ;
    item_desc = desc;
    item_pubdate = pubdate ;
    item_author = author ;
    item_categories = cats ;
    item_comments = comments ;
    item_enclosure = encl ;
    item_guid = guid ;
    item_source = source ;
  }

let channel ~title ~link ~desc
    ?language
    ?copyright
    ?managing_editor
    ?webmaster
    ?pubdate
    ?last_build_date
    ?(cats=[])
    ?generator
    ?docs
    ?ttl
    ?image
    ?text_input
    items
    =
  {
    ch_title = title ;
    ch_link = link ;
    ch_desc = desc ;
    ch_language = language ;
    ch_copyright = copyright ;
    ch_managing_editor = managing_editor ;
    ch_webmaster = webmaster ;
    ch_pubdate = pubdate ;
    ch_last_build_date = last_build_date ;
    ch_categories = cats ;
    ch_generator = generator ;
    ch_docs = docs ;
    ch_ttl = ttl ;
    ch_image = image ;
    ch_text_input = text_input ;
    ch_items = items ;
  }

let copy_item i = { i with item_title = i.item_title };;

let copy_channel c =
  { c with ch_items = List.map copy_item c.ch_items }
;;

let sort_items_by_date =
  List.sort
    (fun i1 i2 ->
      match i1.item_pubdate, i2.item_pubdate with
        None, None -> 0
       | Some _, None -> -1
       | None, Some _ -> 1
       | Some d1, Some d2 ->
           compare
             (Rss_date.since_epoch d2)
             (Rss_date.since_epoch d2)
    );;

let merge_channels c1 c2 =
  let items = sort_items_by_date (c1.ch_items @ c2.ch_items) in
  let c = copy_channel c1 in
  c.ch_items <- items ;
  c
;;



let channel_of_file = Rss_io.channel_of_file
let channel_of_string = Rss_io.channel_of_string
let channel_of_channel = Rss_io.channel_of_channel

let print_channel = Rss_io.print_channel

let print_file ?date_fmt ?encoding file ch =
  let oc = open_out file in
  let fmt = Format.formatter_of_out_channel oc in
  print_channel ?date_fmt ?encoding fmt ch;
  Format.pp_print_flush fmt ();
  close_out oc

let keep_n_items n channel =
   let rec iter acc m = function
    [] -> List.rev acc
  | i :: q when m > n -> List.rev acc
  | i :: q -> iter (i :: acc) (m+1) q
  in
  let c = copy_channel channel in
  c.ch_items <- iter [] 1 c.ch_items;
  c
;;
  