module Git_impl = Irmin_git.Mem
module Sync = Git.Mem.Sync (Git_impl)
module Maker = Irmin_git.KV (Git_impl) (Sync)
include Maker.Make (Model)
