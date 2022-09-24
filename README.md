# vim-netrw-link-resolve

Reopens files opened with `netrw` at their resolved path to avoid
a file-exists error on save.

## Introduction

After a file is opened via `netrw`, e.g., using `:Explore`, this plugin
closes the opened file if if was opened from a symlink path, and reopens
the file using its real path.

This avoids a problem that occurs if you open the same file using
two different paths, as Vim will treat the buffers independently
and will not let you save changes without a bang, e.g., `:w!`,
and scolds you otherwise:

  ```
  E13: File exists (add ! to override)
  ```

## Commands

None. Uses the `g:Netrw_funcref` callback to run.

## Prerequisites

There's an old `netrw` bug in Vim that breaks this plugin.

The bug was fixed in patch 8.2.3386, so you'll need to ensure you're
running that version or better. (Alternatively, you could copy `netrw.vim`
from the latest Vim source to this plugin's `autoload/` directory, if you
are unable to find or build a newer version of Vim.)

## Installation

Take advantage of Vim's packages feature (`:h packages`), e.g.,:

  ```shell
  mkdir -p ~/.vim/pack/landonb/start
  cd ~/.vim/pack/landonb/start
  git clone https://github.com/landonb/vim-netrw-link-resolve.git
  vim -u NONE -c "helptags vim-netrw-link-resolve/doc" -c q
  ```

To load the plugin manually, install to
`~/.vim/pack/landonb/opt` instead and call
`:packadd vim-netrw-link-resolve` when ready.

## License

Copyright (c) Landon Bouma. This work is distributed
wholly under CC0 and dedicated to the Public Domain.

https://creativecommons.org/publicdomain/zero/1.0/

