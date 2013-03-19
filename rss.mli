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

type date = Netdate.t

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
    character.  See [Netdate.format_to] for more details.
    Default: ["%d %b %Y"].
 *)

type email = string (** can be, for example: foo\@bar.com (Mr Foo Bar) *)
type pics_rating = string
type skip_hours = int list (** 0 .. 23 *)
type skip_days = int list (** 0 is Sunday, 1 is Monday, ... *)

type url = Neturl.url

type category =
  {
    cat_name : string ;
    (** A forward-slash-separated string that identifies a hierarchic
        location in the indicated taxonomy. *)
    cat_domain : url option ;
    (** Identifies a categorization taxonomy. *)
  }

type image =
  {
    image_url : url ;
    (** The URL of a GIF, JPEG or PNG image that represents the channel. *)
    image_title : string ;
    (** Description of the image, it's used in the ALT attribute of
        the HTML <img> tag when the channel is rendered in HTML.  *)
    image_link : url ;
    (** The URL of the site, when the channel is rendered, the image
        is a link to the site. (Note, in practice the [image_title]
        and [image_link] should have the same value as the {!channel}'s
        [ch_title] and [ch_link].)  *)
    image_height : int option ;
    (** Height of the image, in pixels. *)
    image_width : int option ;
    (** Width of the image, in pixels. *)
    image_desc : string option ;
    (** Text to be included in the "title" attribute of the link formed
        around the image in the HTML rendering. *)
  }

type text_input =
    {
      ti_title : string ;
      (** The label of the Submit button in the text input area. *)
      ti_desc : string ;
      (** Explains the text input area. *)
      ti_name : string ;
      (** The name of the text object in the text input area. *)
      ti_link : url ;
      (** The URL of the CGI script that processes text input requests. *)
    }

type enclosure =
  {
    encl_url : url ; (** URL of the enclosure *)
    encl_length : int ; (** size in bytes *)
    encl_type : string ; (** MIME type *)
  }

type guid =
  | Guid_permalink of url (** A permanent URL pointing to the story. *)
  | Guid_name of string   (** A string that uniquely identifies the item.  *)

type source =
    {
      src_name : string ;
      src_url : url ;
    }

(** See {{:http://cyber.law.harvard.edu/rss/soapMeetsRss.html#rsscloudInterface} specification} *)
type cloud = {
    cloud_domain : string ;
    cloud_port : int ;
    cloud_path : string ;
    cloud_register_procedure : string ;
    cloud_protocol : string ;
  }

(** An item may represent a "story".  Its description is a synopsis of
    the story (or sometimes the full story), and the link points to
    the full story. *)
type 'a item_t =
  {
    item_title : string option; (** Optional title *)
    item_link : url option; (** Optional link *)
    item_desc : string option; (** Optional description *)
    item_pubdate : date option ; (** Date of publication *)
    item_author : email option ;
    (** The email address of the author of the item. *)
    item_categories : category list ;
    (** Categories for the item.  See the field {!category}. *)
    item_comments : url option ; (** Url of comments about this item *)
    item_enclosure : enclosure option ;
    item_guid : guid option ;
    (** A globally unique identifier for the item. *)
    item_source : source option ;
    item_data : 'a option ;
    (** Additional data, since RSS can be extended with namespace-prefixed nodes.*)
  }

type ('a, 'b) channel_t =
  {
    ch_title : string ;
    (** Mandatory.  The name of the channel, for example the title of
        your web site. *)
    ch_link : url ;
    (** Mandatory.  The URL to the HTML website corresponding to the channel. *)
    ch_desc : string ;
    (** Mandatory.  A sentence describing the channel. *)
    ch_language : string option ;
    (** Language of the news, e.g. "en".  See the W3C
        {{:http://www.w3.org/TR/REC-html40/struct/dirlang.html#langcodes}
        language codes}. *)
    ch_copyright : string option ; (** Copyright notice. *)
    ch_managing_editor : email option ;
    (** Managing editor of the news. *)
    ch_webmaster : email option ;
    (** The address of the webmasterof the site. *)
    ch_pubdate : date option ;
    (** Publication date of the channel. *)
    ch_last_build_date : date option ;
    (** When the channel content changed for the last time. *)
    ch_categories : category list ;
    (** Categories for the channel.  See the field {!category}. *)
    ch_generator : string option ;
    (** The tool used to generate this channel. *)
    ch_cloud : cloud option ;
    (** Allows processes to register with a cloud to be notified of updates to the channel. *)
    ch_docs : url option ; (** An url to a RSS format reference. *)
    ch_ttl : int option ;
    (** Time to live, in minutes.  It indicates how long a channel can
        be cached before refreshing from the source. *)
    ch_image : image option ;
    ch_rating : pics_rating option;
    (** The PICS rating for the channel. *)
    ch_text_input : text_input option ;
    ch_skip_hours : skip_hours option ;
    (** A hint for aggregators telling them which hours they can skip.*)
    ch_skip_days : skip_days option ;
    (** A hint for aggregators telling them which days they can skip. *)
    ch_items : 'b item_t list ;
    ch_data : 'a option ;
        (** Additional data, since RSS can be extended with namespace-prefixed nodes.*)
  }

type item = unit item_t
type channel = (unit, unit) channel_t

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
  ?data: 'a ->
  unit ->
  'a item_t
(** [item()] creates a new item with all fields set to [None].  Use the
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
  ?cloud: cloud ->
  ?docs: url ->
  ?ttl: int ->
  ?image: image ->
  ?rating: pics_rating ->
  ?text_input: text_input ->
  ?skip_hours: skip_hours ->
  ?skip_days: skip_days ->
  ?data: 'a ->
  'b item_t list ->
  ('a, 'b) channel_t

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

(** This represents XML trees. Such XML trees are given to
  functions provided to read additional data from RSS channels and items. *)
type xmltree =
    E of Xmlm.tag * xmltree list
  | D of string

(** Use this exception to indicate an error is functions given to [make_opts] used
  to read additional data from prefixed XML nodes. *)
exception Error of string

(** Options used when reading source. *)
type ('a, 'b) opts

(** See Neturl documentation for [schemes] and [base_syntax] options.
  They are used to parse URLs.
  @param read_channel_data provides a way to read additional information from the
  subnodes of the channels. All these subnodes are prefixed by an expanded namespace.
  @param read_item_data is the equivalent of [read_channel_data] parameter but
  is called of each item with its prefixed subnodes.
  *)
val make_opts :
  ?schemes: (string, Neturl.url_syntax) Hashtbl.t ->
  ?base_syntax: Neturl.url_syntax ->
  ?read_channel_data: (xmltree list -> 'a option) ->
  ?read_item_data: (xmltree list -> 'b option) ->
  unit -> ('a, 'b) opts

val default_opts : (unit, unit) opts

(** [channel_[t_]of_X] returns the parsed channel and a list of encountered errors.
  @raise Failure if the channel could not be parsed.
*)
val channel_t_of_file : ('a, 'b) opts -> string -> (('a, 'b) channel_t * string list)
val channel_t_of_string : ('a, 'b) opts -> string -> (('a, 'b) channel_t * string list)
val channel_t_of_channel : ('a, 'b) opts -> in_channel -> (('a, 'b) channel_t * string list)

val channel_of_file : string -> (channel * string list)
val channel_of_string : string -> (channel * string list)
val channel_of_channel : in_channel -> (channel * string list)

(** {2 Writing channels} *)

type 'a data_printer = 'a -> xmltree list

val print_channel :
  ?channel_data_printer: 'a data_printer ->
  ?item_data_printer: 'b data_printer ->
  ?indent: int -> ?date_fmt: string -> ?encoding: string ->
    Format.formatter -> ('a, 'b) channel_t -> unit

val print_file :
  ?channel_data_printer: 'a data_printer ->
  ?item_data_printer: 'b data_printer ->
    ?indent: int -> ?date_fmt: string -> ?encoding: string ->
    string -> ('a, 'b) channel_t -> unit
