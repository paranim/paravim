<p align="center">
  <img src="screenshot.png" width="510" >
</p>

Paravim (or pvim) is an editor for Nim powered by Vim (via [libvim](https://github.com/paranim/libvim)) and rendered with OpenGL (via [paranim](https://github.com/paranim/paranim)). It is very alpha right now, and doesn't have any Nim-specific features yet, like syntax highlighting or code completion.

To use it, [install Nim](https://nim-lang.org/install.html) and do:

```
nimble install pvim
```

Then, as long as you have `~/.nimble/bin` on your PATH, you should be able to run `pvim` in any directory.
