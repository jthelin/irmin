(*
 * Copyright (c) 2018-2021 Tarides <contact@tarides.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

module type S = sig
  val entries : int
  val stable_hash : int
end

module Default = struct
  let fresh = false
  let lru_size = 100_000
  let index_log_size = 500_000
  let readonly = false
  let merge_throttle = `Block_writes
  let freeze_throttle = `Block_writes
end

let fresh_key =
  Irmin.Private.Conf.key ~doc:"Start with a fresh disk." "fresh" Irmin.Type.bool
    Default.fresh

let lru_size_key =
  Irmin.Private.Conf.key ~doc:"Size of the LRU cache for pack entries."
    "lru-size" Irmin.Type.int Default.lru_size

let index_log_size_key =
  Irmin.Private.Conf.key ~doc:"Size of index logs." "index-log-size"
    Irmin.Type.int Default.index_log_size

let readonly_key =
  Irmin.Private.Conf.key ~doc:"Start with a read-only disk." "readonly"
    Irmin.Type.bool Default.readonly

type merge_throttle = [ `Block_writes | `Overcommit_memory ] [@@deriving irmin]

type freeze_throttle = [ `Block_writes | `Overcommit_memory | `Cancel_existing ]
[@@deriving irmin]

let merge_throttle_key =
  Irmin.Private.Conf.key
    ~doc:"Strategy to use for large writes when index caches are full."
    "merge-throttle"
    Irmin.Type.(
      enum "merge_throttle"
        [
          ("block-writes", `Block_writes);
          ("overcommit-memory", `Overcommit_memory);
        ])
    Default.merge_throttle

let freeze_throttle_key =
  Irmin.Private.Conf.key ~doc:"Strategy to use for long-running freezes."
    "freeze-throttle"
    Irmin.Type.(
      enum "merge_throttle"
        [
          ("block-writes", `Block_writes);
          ("overcommit-memory", `Overcommit_memory);
          ("cancel-existing", `Cancel_existing);
        ])
    Default.freeze_throttle

let root_key = Irmin.Private.Conf.root
let fresh config = Irmin.Private.Conf.get config fresh_key
let lru_size config = Irmin.Private.Conf.get config lru_size_key
let readonly config = Irmin.Private.Conf.get config readonly_key
let index_log_size config = Irmin.Private.Conf.get config index_log_size_key
let merge_throttle config = Irmin.Private.Conf.get config merge_throttle_key
let freeze_throttle config = Irmin.Private.Conf.get config freeze_throttle_key

let root config =
  match Irmin.Private.Conf.get config root_key with
  | None -> failwith "no root set"
  | Some r -> r

let v ?(fresh = Default.fresh) ?(readonly = Default.readonly)
    ?(lru_size = Default.lru_size) ?(index_log_size = Default.index_log_size)
    ?(merge_throttle = Default.merge_throttle)
    ?(freeze_throttle = Default.freeze_throttle) root =
  let config = Irmin.Private.Conf.empty in
  let config = Irmin.Private.Conf.add config fresh_key fresh in
  let config = Irmin.Private.Conf.add config root_key (Some root) in
  let config = Irmin.Private.Conf.add config lru_size_key lru_size in
  let config =
    Irmin.Private.Conf.add config index_log_size_key index_log_size
  in
  let config = Irmin.Private.Conf.add config readonly_key readonly in
  let config =
    Irmin.Private.Conf.add config merge_throttle_key merge_throttle
  in
  let config =
    Irmin.Private.Conf.add config freeze_throttle_key freeze_throttle
  in
  config
