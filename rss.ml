(******************************************************************************)
(*               OCamlrss                                                     *)
(*                                                                            *)
(*   Copyright (C) 2004-2012 Institut National de Recherche en Informatique   *)
(*   et en Automatique. All rights reserved.                                  *)
(*                                                                            *)
(*   This program is free software; you can redistribute it and/or modify     *)
(*   it under the terms of the GNU Lesser General Public License version      *)
(*   3 as published by the Free Software Foundation.                          *)
(*                                                                            *)
(*   This program is distributed in the hope that it will be useful,          *)
(*   but WITHOUT ANY WARRANTY; without even the implied warranty of           *)
(*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *)
(*   GNU Library General Public License for more details.                     *)
(*                                                                            *)
(*   You should have received a copy of the GNU Library General Public        *)
(*   License along with this program; if not, write to the Free Software      *)
(*   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                 *)
(*   02111-1307  USA                                                          *)
(*                                                                            *)
(*   Contact: Maxence.Guesdon@inria.fr                                        *)
(*                                                                            *)
(*                                                                            *)
(******************************************************************************)

type date = Netdate.t

let since_epoch = Netdate.since_epoch
let float_to_date t = Netdate.create t
let string_of_date ?(fmt="%d %b %Y") date = Netdate.format ~fmt date

type email = string (** can be, for example: foo@bar.com (Mr Foo Bar) *)
type pics_rating = string
type skip_hours = int list (** 0 .. 23 *)
type skip_days = int list (** 0 is Sunday, 1 is Monday, ... *)

type url = Neturl.url

type category = Rss_types.category =
    {
      cat_name : string ;
      cat_domain : url option ;
    }

type image = Rss_types.image =
    {
      image_url : url ;
      image_title : string ;
      image_link : url ;
      image_height : int option ;
      image_width : int option ;
      image_desc : string option ;
    }

type text_input = Rss_types.text_input =
    {
      ti_title : string ; (** The label of the Submit button in the text input area. *)
      ti_desc : string ; (** Explains the text input area. *)
      ti_name : string ; (** The name of the text object in the text input area. *)
      ti_link : url ; (** The URL of the CGI script that processes text input requests. *)
    }

type enclosure = Rss_types.enclosure =
    {
      encl_url : url ; (** URL of the enclosure *)
      encl_length : int ; (** size in bytes *)
      encl_type : string ; (** MIME type *)
    }

(** See {{:http://cyber.law.harvard.edu/rss/soapMeetsRss.html#rsscloudInterface} specification} *)
type cloud = Rss_types.cloud =
  {
    cloud_domain : string ;
    cloud_port : int ;
    cloud_path : string ;
    cloud_register_procedure : string ;
    cloud_protocol : string ;
  }

type guid = Rss_types.guid = Guid_permalink of url | Guid_name of string

type source = Rss_types.source =
  {
    src_name : string ;
    src_url : url ;
  }

type 'a item_t = 'a Rss_types.item_t =
  {
    item_title : string option ;
    item_link : url option ;
    item_desc : string option ;
    item_pubdate : Netdate.t option ;
    item_author : email option ;
    item_categories : category list ;
    item_comments : url option ;
    item_enclosure : enclosure option ;
    item_guid : guid option ;
    item_source : source option ;
    item_data : 'a option ;
  }

type ('a, 'b) channel_t = ('a, 'b) Rss_types.channel_t =
  {
    ch_title : string ;
    ch_link : url ;
    ch_desc : string ;
    ch_language : string option ;
    ch_copyright : string option ;
    ch_managing_editor : email option ;
    ch_webmaster : email option ;
    ch_pubdate : Netdate.t option ;
    ch_last_build_date : Netdate.t option ;
    ch_categories : category list ;
    ch_generator : string option ;
    ch_cloud : cloud option ;
    ch_docs : url option ;
    ch_ttl : int option ;
    ch_image : image option ;
    ch_rating : pics_rating option ;
    ch_text_input : text_input option ;
    ch_skip_hours : skip_hours option ;
    ch_skip_days : skip_days option ;
    ch_items : 'b item_t list ;
    ch_data : 'a option ;
    }

type item = unit item_t
type channel = (unit, unit) channel_t

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
    ?data
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
    item_data = data ;
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
    ?cloud
    ?docs
    ?ttl
    ?image
    ?rating
    ?text_input
    ?skip_hours
    ?skip_days
    ?data
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
    ch_cloud = cloud ;
    ch_docs = docs ;
    ch_ttl = ttl ;
    ch_image = image ;
    ch_rating = rating ;
    ch_text_input = text_input ;
    ch_skip_hours = skip_hours ;
    ch_skip_days = skip_days ;
    ch_items = items ;
    ch_data = data ;
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
             (Netdate.since_epoch d2)
             (Netdate.since_epoch d2)
    );;

let merge_channels c1 c2 =
  let items = sort_items_by_date (c1.ch_items @ c2.ch_items) in
  let c = copy_channel c1 in
  { c with ch_items = items }
;;

type xmltree = Rss_io.xmltree =
    E of Xmlm.tag * xmltree list
  | D of string

exception Error = Rss_io.Error

type ('a, 'b) opts = ('a, 'b) Rss_io.opts

let make_opts = Rss_io.make_opts
let default_opts = Rss_io.default_opts

let channel_t_of_file = Rss_io.channel_of_file
let channel_t_of_string = Rss_io.channel_of_string
let channel_t_of_channel = Rss_io.channel_of_channel

let channel_of_file = Rss_io.channel_of_file default_opts
let channel_of_string = Rss_io.channel_of_string default_opts
let channel_of_channel = Rss_io.channel_of_channel default_opts

type 'a data_printer = 'a -> xmltree list

let print_channel = Rss_io.print_channel

let print_file ?channel_data_printer ?item_data_printer ?indent ?date_fmt ?encoding file ch =
  let oc = open_out file in
  let fmt = Format.formatter_of_out_channel oc in
  print_channel ?channel_data_printer ?item_data_printer ?indent ?date_fmt ?encoding fmt ch;
  Format.pp_print_flush fmt ();
  close_out oc

let keep_n_items n channel =
   let rec iter acc m = function
    [] -> List.rev acc
  | i :: q when m > n -> List.rev acc
  | i :: q -> iter (i :: acc) (m+1) q
  in
  let c = copy_channel channel in
  { c with ch_items = iter [] 1 c.ch_items }
;;
  