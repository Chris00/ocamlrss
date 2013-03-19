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

(** *)

type email = string (** can be, for example: foo\@bar.com (Mr Foo Bar) *)
type pics_rating = string
type skip_hours = int list (** 0 .. 23 *)
type skip_days = int list (** 0 is Sunday, 1 is Monday, ... *)

type url = Neturl.url

type category =
    {
      cat_name : string ;
      cat_domain : url option ;
    }

type image =
    {
      image_url : url ;
      image_title : string ;
      image_link : url ;
      image_height : int option ;
      image_width : int option ;
      image_desc : string option ;
    }

type text_input =
    {
      ti_title : string ; (** The label of the Submit button in the text input area. *)
      ti_desc : string ; (** Explains the text input area. *)
      ti_name : string ; (** The name of the text object in the text input area. *)
      ti_link : url ; (** The URL of the CGI script that processes text input requests. *)
    }

type enclosure =
    {
      encl_url : url ; (** URL of the enclosure *)
      encl_length : int ; (** size in bytes *)
      encl_type : string ; (** MIME type *)
    }

(** See {{:http://cyber.law.harvard.edu/rss/soapMeetsRss.html#rsscloudInterface} specification} *)
type cloud = {
    cloud_domain : string ;
    cloud_port : int ;
    cloud_path : string ;
    cloud_register_procedure : string ;
    cloud_protocol : string ;
  }

type guid = Guid_permalink of url | Guid_name of string

type source =
    {
      src_name : string ;
      src_url : url ;
    }

type 'a item_t =
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



type ('a, 'b) channel_t =
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
      ch_namespaces : (string * string) list ;
    }

type item = unit item_t
type channel = (unit, unit) channel_t
