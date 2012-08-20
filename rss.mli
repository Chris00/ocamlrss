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

(** The RSS library to read and write RSS 2.0 files.

    Reference:
    {{:http://www.rss-specification.com/rss-2.0-specification.htm}RSS
    2.0 specification}. *)

(** {2 Types} *)

type date = {
    year : int;    (** complete (4 digits) year. *)
    month : int;   (** 1..12 *)
    day : int;     (** 1..31 *)
    hour : int;
    minute : int;
    second : int;
    zone : int;    (** in minutes; 60 = UTC+0100 *)
    week_day : int (** 0 = sunday; -1 if not given *)
  }

val since_epoch : date -> float
(** Convert a date/time record into the time (seconds since the epoch). *)

val float_to_date : float -> date
(** Convert the time (seconds since the epoch) to a date/time record. *)

val string_of_date : ?fmt: string -> date -> string
(** Format a date/time record as a string according to the format
    string [fmt].

    @param fmt The format string.  It consists of zero or more
    conversion specifications and ordinary characters.  All ordinary
    characters are kept as such in the final string.  A conversion
    specification consists of the '%' character and one other
    character.  See {!Rss_date.format_to} for more details.
    Default: ["%d %b %Y"].
 *)

type email = string (** can be, for example: foo\@bar.com (Mr Foo Bar) *)
type url = string


type category =
  {
    mutable cat_name : string ;
    (** A forward-slash-separated string that identifies a hierarchic
        location in the indicated taxonomy. *)
    mutable cat_domain : url option ;
    (** Identifies a categorization taxonomy. *)
  }

type image =
  {
    mutable image_url : url ;
    (** The URL of a GIF, JPEG or PNG image that represents the channel. *)
    mutable image_title : string ;
    (** Description of the image, it's used in the ALT attribute of
        the HTML <img> tag when the channel is rendered in HTML.  *)
    mutable image_link : url ;
    (** The URL of the site, when the channel is rendered, the image
        is a link to the site. (Note, in practice the [image_title]
        and [image_link] should have the same value as the {!channel}'s
        [ch_title] and [ch_link].)  *)
    mutable image_height : int option ;
    (** Height of the image, in pixels. *)
    mutable image_width : int option ;
    (** Width of the image, in pixels. *)
    mutable image_desc : string option ;
    (** Text to be included in the "title" attribute of the link formed
        around the image in the HTML rendering. *)
  }

type text_input =
    {
      mutable ti_title : string ;
      (** The label of the Submit button in the text input area. *)
      mutable ti_desc : string ;
      (** Explains the text input area. *)
      mutable ti_name : string ;
      (** The name of the text object in the text input area. *)
      mutable ti_link : string ;
      (** The URL of the CGI script that processes text input requests. *)
    }

type enclosure =
  {
    mutable encl_url : url ; (** URL of the enclosure *)
    mutable encl_length : int ; (** size in bytes *)
    mutable encl_type : string ; (** MIME type *)
  }

type guid =
  {
    mutable guid_name : string ;
    (** A string that uniquely identifies the item.  It can be a
        permanent url, if permalink is true *)
    mutable guid_permalink : bool ;
    (** If true, [guid_name] is a permanent URL pointing to the story.
        If its value is false, the guid may not be assumed to be a
        url, or a url to anything in particular. *)
  }

type source =
    {
      mutable src_name : string ;
      mutable src_url : url ;
    }

(** An item may represent a "story".  Its description is a synopsis of
    the story (or sometimes the full story), and the link points to
    the full story. *)
type item =
    {
      mutable item_title : string option; (** Optional title *)
    mutable item_link : url option; (** Optional link *)
    mutable item_desc : string option; (** Optional description *)
    mutable item_pubdate : date option ; (** Date of publication *)
    mutable item_author : email option ;
    (** The email address of the author of the item. *)
    mutable item_categories : category list ;
    (** Categories for the item.  See the field {!category}. *)
    mutable item_comments : url option ; (** Url of comments about this item *)
    mutable item_enclosure : enclosure option ;
    mutable item_guid : guid option ;
    (** A globally unique identifier for the item. *)
    mutable item_source : source option ;
  }

type channel =
  {
    mutable ch_title : string ;
    (** Mandatory.  The name of the channel, for example the title of
        your web site. *)
    mutable ch_link : url ;
    (** Mandatory.  The URL to the HTML website corresponding to the channel. *)
    mutable ch_desc : string ;
    (** Mandatory.  A sentence describing the channel. *)
    mutable ch_language : string option ;
    (** Language of the news, e.g. "en".  See the W3C
        {{:http://www.w3.org/TR/REC-html40/struct/dirlang.html#langcodes}
        language codes}. *)
    mutable ch_copyright : string option ; (** Copyright notice. *)
    mutable ch_managing_editor : email option ;
    (** Managing editor of the news. *)
    mutable ch_webmaster : email option ;
    (** The address of the webmasterof the site. *)
    mutable ch_pubdate : date option ;
    (** Publication date of the channel. *)
    mutable ch_last_build_date : date option ;
    (** When the channel content changed for the last time. *)
    mutable ch_categories : category list ;
    (** Categories for the channel.  See the field {!category}. *)
    mutable ch_generator : string option ;
    (** The tool used to generate this channel. *)
    mutable ch_docs : url option ; (** An url to a RSS format reference. *)
    mutable ch_ttl : int option ;
    (** Time to live, in minutes.  It indicates how long a channel can
        be cached before refreshing from the source. *)
    mutable ch_image : image option ;
    mutable ch_text_input : text_input option ;
    mutable ch_items : item list ;
  }

(** {2 Building items and channels} *)

val item :
  ?title: string ->
  ?link: url ->
  ?desc: string ->
  ?pubdate: date ->
  ?author: email ->
  ?cats: category list ->
  ?comments: url ->
  ?encl: enclosure ->
  ?guid: guid ->
  ?source: source ->
  unit ->
  item
(** [item()] creates a new item with all find set to [None].  Use the
    optional parameters to set fields. *)

val channel :
  title: string ->
  link: url ->
  desc: string ->
  ?language: string ->
  ?copyright: string ->
  ?managing_editor: email ->
  ?webmaster: email ->
  ?pubdate: date ->
  ?last_build_date: date ->
  ?cats: category list ->
  ?generator: string ->
  ?docs: url ->
  ?ttl: int ->
  ?image: image ->
  ?text_input: text_input ->
  item list ->
  channel
(** [channel items] creates a new channel containing [items].  Other
    fields are set to [None] unless the corresponding optional
    parameter is used. *)

val copy_item : item -> item
val copy_channel : channel -> channel


(** {2 Manipulating channels} *)

val keep_n_items : int -> channel -> channel
(** [keep_n_items n ch] returns a copy of the channel, keeping only
    [n] items maximum. *)

val sort_items_by_date : item list -> item list
(** Sort items by date, older last. *)

val merge_channels : channel -> channel -> channel
(** [merge_channels c1 c2] merges the given channels in a new channel,
    sorting items using {!sort_items_by_date}. Channel information are
    copied from the first channel [c1]. *)


(** {2 Reading channels} *)

val channel_of_file : string -> channel
val channel_of_string : string -> channel
val channel_of_channel : in_channel -> channel

(** {2 Writing channels} *)

val print_channel : ?date_fmt: string -> ?encoding: string ->
                    Format.formatter -> channel -> unit

val print_file : ?date_fmt: string -> ?encoding: string ->
                 string -> channel -> unit
