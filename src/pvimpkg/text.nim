import paranim/gl
import paratext, paratext/gl/text

const
  monoFontRaw = staticRead("../assets/ttf/FiraCode-Regular.ttf")
  variFontRaw = staticRead("../assets/ttf/Roboto-Regular.ttf")

let
  monoFont* = initFont(ttf = monoFontRaw, fontHeight = 64, firstChar = 32, bitmapWidth = 512, bitmapHeight = 512, charCount = 2048)
  variFont* = initFont(ttf = variFontRaw, fontHeight = 64, firstChar = 32, bitmapWidth = 512, bitmapHeight = 512, charCount = 2048)

var
  baseMonoEntity*: UncompiledTextEntity
  monoEntity*: InstancedTextEntity

proc add*(instancedEntity: var InstancedTextEntity, entity: UncompiledTextEntity, font: Font, text: cstring) =
  var
    x = 0f
    i = 0
  for ch in text:
    let
      charIndex = int(ch) - font.firstChar
      bakedChar = font.chars[charIndex]
    var e = entity
    e.crop(bakedChar, x, font.baseline)
    if i == instancedEntity.instanceCount:
      instancedEntity.add(e)
    else:
      instancedEntity[i] = e
    x += bakedChar.xadvance
    i += 1

proc init*(game: var RootGame) =
  baseMonoEntity = initTextEntity(monoFont)
  let
    uncompiledMonoEntity = initInstancedEntity(baseMonoEntity)
    compiledMonoEntity = compile(game, uncompiledMonoEntity)
  monoEntity = deepCopy(compiledMonoEntity)
