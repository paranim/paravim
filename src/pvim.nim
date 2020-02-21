import paravim/libvim

vimInit(0, nil)
let buf = vimBufferOpen("pvim.nimble", 1, 0)
vimOptionSetTabSize(2)
echo vimOptionGetTabSize()
echo vimBufferGetLine(buf, 1)

proc getWelcomeMessage*(): string = "Hello, World!"
