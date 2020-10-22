from text import nil
from paranim/gl import nil
from paranim/gl/entities import nil
from colors import nil

const minimapScale* = 6f

type
  Minimap = tuple[textEntity: text.ParavimTextEntity, rectsEntity: entities.InstancedTwoDEntity, show: bool]

proc initMinimap*(
    fullText: text.ParavimTextEntity,
    rectsEntity: entities.InstancedTwoDEntity,
    uncompiledRectEntity: entities.UncompiledTwoDEntity,
    windowWidth: int,
    windowHeight: int,
    fontSize: float,
    defaultFontSize: static[float],
    scrollX: float,
    scrollY: float,
    lineCount: int,
  ): Minimap =
  const
    minSizeToShowChars = (defaultFontSize * 2) / minimapScale
    minChars = 40 # minimum number of chars that minimap must be able to display
    maxLines = 1000 # u_char_counts can only hold this many
  let
    fontWidth = text.monoFontWidth * fontSize
    fontHeight = text.monoFont.height * fontSize
    minimapFontSize = fontSize / minimapScale
    minimapFontWidth = text.monoFontWidth * minimapFontSize
    minimapFontHeight = text.monoFont.height * minimapFontSize
    minimapHeight = max(0.0, float(windowHeight) - fontHeight)
    minimapWidth = float(windowWidth) / minimapScale
    # number of chars that can fit in minimap
    minimapChars = int(minimapWidth / minimapFontWidth)
    minimapLineCount = min(int(minimapHeight / minimapFontHeight), maxLines)
    minimapIsOverflowing = lineCount > minimapLineCount
    startColumn = int(scrollX / fontWidth)
    startLine =
      if minimapIsOverflowing:
        min(
          int(max(scrollY, 0) / fontHeight), # lines above
          lineCount - minimapLineCount # lines below
        )
      else:
        0
  # minimap text
  block:
    var e = fullText
    if minimapIsOverflowing:
      let endLine = min(minimapLineCount+startLine, lineCount)
      text.cropLines(e, startLine, endLine)
    text.updateUniforms(e, startLine, startColumn, minimapFontSize < minSizeToShowChars)
    e.project(float(windowWidth), float(windowHeight))
    e.translate(float(windowWidth) - minimapWidth, 0f)
    if startColumn > 0:
      e.translate(-(startColumn.float * minimapFontWidth), 0f)
    if startLine > 0:
      e.translate(0f, -(startLine.float * minimapFontHeight))
    e.scale(minimapFontSize, minimapFontSize)
    result.textEntity = e
  # minimap rects
  block:
    var e = gl.copy(rectsEntity)
    var bg = uncompiledRectEntity
    bg.project(float(windowWidth), float(windowHeight))
    bg.translate(float(windowWidth) - minimapWidth, 0)
    bg.scale(minimapWidth, minimapHeight)
    bg.color(colors.bgColor)
    e.add(bg)
    var view = uncompiledRectEntity
    view.project(float(windowWidth), float(windowHeight))
    view.translate(float(windowWidth) - minimapWidth, 0)
    view.translate(0f, scrollY / minimapScale - startLine.float * minimapFontHeight)
    view.scale(minimapWidth, minimapHeight / minimapScale)
    view.color(colors.minimapViewColor)
    e.add(view)
    result.rectsEntity = e
  # show minimap
  let
    textViewHeight = windowHeight.float - fontHeight
    visibleLines = int(textViewHeight / fontHeight)
    showMinimap = minimapChars >= minChars and lineCount > visibleLines
  result.show = showMinimap
