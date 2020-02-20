import paravim/libvim

vimInit(0, nil)
#discard vimBufferOpen("paravim.nimble".cstring, 1, 0)
vimOptionSetTabSize(2)
echo vimOptionGetTabSize()

proc getWelcomeMessage*(): string = "Hello, World!"
