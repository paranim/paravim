import paranim/opengl, paranim/glm
import paranim/gl, paranim/gl/uniforms, paranim/gl/attributes
from paranim/gl/entities import crop, color
import paratext, paratext/gl/text
from tree_sitter import Node
from colors import nil
from math import nil
import tables

const
  monoFontRaw = staticRead("assets/ttf/FiraCode-Regular.ttf")
  instancedTextVertexShader = staticRead("shaders/vertex.glsl")
  instancedTextFragmentShader = staticRead("shaders/fragment.glsl")

let
  monoFont* = initFont(ttf = monoFontRaw, fontHeight = 128, firstChar = 32, bitmapWidth = 1024, bitmapHeight = 1024, charCount = 2048)
  monoFontWidth* = monoFont.chars[0].xadvance

type
  ParavimTextEntityUniforms = tuple[
    u_matrix: Uniform[Mat3x3[GLfloat]],
    u_image: Uniform[Texture[GLubyte]],
    u_char_counts: Uniform[seq[GLint]],
    u_start_line: Uniform[GLint],
    u_start_column: Uniform[GLint],
    u_font_height: Uniform[GLfloat],
    u_alpha: Uniform[GLfloat],
    u_show_blocks: Uniform[GLuint],
  ]
  ParavimTextEntityAttributes = tuple[
    a_position: Attribute[GLfloat],
    a_translate_matrix: Attribute[GLfloat],
    a_scale_matrix: Attribute[GLfloat],
    a_texture_matrix: Attribute[GLfloat],
    a_color: Attribute[GLfloat]
  ]
  ParavimTextEntity* = object of InstancedEntity[ParavimTextEntityUniforms, ParavimTextEntityAttributes]
  UncompiledParavimTextEntity = object of UncompiledEntity[ParavimTextEntity, ParavimTextEntityUniforms, ParavimTextEntityAttributes]

proc initInstancedEntity*(entity: UncompiledTextEntity, font: Font): UncompiledParavimTextEntity =
  let e = gl.copy(entity) # make a copy to prevent unexpected problems if `entity` is changed later
  result.vertexSource = instancedTextVertexShader
  result.fragmentSource = instancedTextFragmentShader
  result.uniforms.u_matrix = e.uniforms.u_matrix
  result.uniforms.u_image = e.uniforms.u_image
  result.uniforms.u_char_counts.disable = true
  result.uniforms.u_start_column.data = 0
  result.uniforms.u_font_height.data = font.height
  result.uniforms.u_alpha.data = 1.0
  result.uniforms.u_show_blocks.data = 0
  result.attributes.a_translate_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_translate_matrix.data)
  result.attributes.a_scale_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_scale_matrix.data)
  result.attributes.a_texture_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_texture_matrix.data)
  result.attributes.a_color = Attribute[GLfloat](disable: true, divisor: 1, size: 4, iter: 1)
  new(result.attributes.a_color.data)
  result.attributes.a_position = e.attributes.a_position

proc addInstanceAttr[T](attr: var Attribute[T], uni: Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      attr.data[].add(uni.data.row(r)[c])
  attr.disable = false

proc addInstanceAttr[T](attr: var Attribute[T], uni: Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    attr.data[].add(uni.data[x])
  attr.disable = false

proc addInstanceAttr[T](attr: var Attribute[T], attr2: Attribute[T]) =
  attr.data[].add(attr2.data[])
  attr.disable = false

proc addInstanceUni[T](uni: var Uniform[seq[T]], uni2: Uniform[seq[T]]) =
  uni.data.add(uni2.data)
  uni.disable = false

proc setInstanceAttr[T](attr: var Attribute[T], i: int, uni: Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      attr.data[r*3+c+i*9] = uni.data.row(r)[c]
  attr.disable = false

proc setInstanceAttr[T](attr: var Attribute[T], i: int, uni: Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    attr.data[x+i*4] = uni.data[x]
  attr.disable = false

proc getInstanceAttr[T](attr: Attribute[T], i: int, uni: var Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      uni.data[r][c] = attr.data[r*3+c+i*9]
  uni.data = uni.data.transpose()
  uni.disable = false

proc getInstanceAttr[T](attr: Attribute[T], i: int, uni: var Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    uni.data[x] = attr.data[x+i*4]
  uni.disable = false

proc cropInstanceAttr[T](attr: var Attribute[T], i: int, j: int) =
  let
    size = attr.size * attr.iter
    data = attr.data
  new(attr.data)
  attr.data[] = data[][i*size ..< j*size]
  attr.disable = false

proc cropInstanceUni[T](uni: var Uniform[seq[T]], i: int, j: int) =
  uni.data = uni.data[i ..< j]
  uni.disable = false

proc add*(instancedEntity: var UncompiledParavimTextEntity, entity: UncompiledTextEntity) =
  addInstanceAttr(instancedEntity.attributes.a_translate_matrix, entity.uniforms.u_translate_matrix)
  addInstanceAttr(instancedEntity.attributes.a_scale_matrix, entity.uniforms.u_scale_matrix)
  addInstanceAttr(instancedEntity.attributes.a_texture_matrix, entity.uniforms.u_texture_matrix)
  addInstanceAttr(instancedEntity.attributes.a_color, entity.uniforms.u_color)
  # instanceCount will be computed by the `compile` proc

proc add*(instancedEntity: var ParavimTextEntity, entity: UncompiledTextEntity) =
  addInstanceAttr(instancedEntity.attributes.a_translate_matrix, entity.uniforms.u_translate_matrix)
  addInstanceAttr(instancedEntity.attributes.a_scale_matrix, entity.uniforms.u_scale_matrix)
  addInstanceAttr(instancedEntity.attributes.a_texture_matrix, entity.uniforms.u_texture_matrix)
  addInstanceAttr(instancedEntity.attributes.a_color, entity.uniforms.u_color)
  instancedEntity.instanceCount += 1

proc add*(instancedEntity: var ParavimTextEntity, entity: ParavimTextEntity) =
  addInstanceAttr(instancedEntity.attributes.a_translate_matrix, entity.attributes.a_translate_matrix)
  addInstanceAttr(instancedEntity.attributes.a_scale_matrix, entity.attributes.a_scale_matrix)
  addInstanceAttr(instancedEntity.attributes.a_texture_matrix, entity.attributes.a_texture_matrix)
  addInstanceAttr(instancedEntity.attributes.a_color, entity.attributes.a_color)
  addInstanceUni(instancedEntity.uniforms.u_char_counts, entity.uniforms.u_char_counts)
  instancedEntity.instanceCount += entity.instanceCount

proc `[]`*(instancedEntity: ParavimTextEntity or UncompiledParavimTextEntity, i: int): UncompiledTextEntity =
  result.attributes.a_position = instancedEntity.attributes.a_position
  result.attributes.a_position.disable = false
  result.uniforms.u_image = instancedEntity.uniforms.u_image
  result.uniforms.u_image.disable = false
  getInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, result.uniforms.u_translate_matrix)
  getInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, result.uniforms.u_scale_matrix)
  getInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, result.uniforms.u_texture_matrix)
  getInstanceAttr(instancedEntity.attributes.a_color, i, result.uniforms.u_color)

proc `[]=`*(instancedEntity: var ParavimTextEntity, i: int, entity: UncompiledTextEntity) =
  setInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, entity.uniforms.u_translate_matrix)
  setInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, entity.uniforms.u_scale_matrix)
  setInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, entity.uniforms.u_texture_matrix)
  setInstanceAttr(instancedEntity.attributes.a_color, i, entity.uniforms.u_color)

proc `[]=`*(instancedEntity: var UncompiledParavimTextEntity, i: int, entity: UncompiledTextEntity) =
  setInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, entity.uniforms.u_translate_matrix)
  setInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, entity.uniforms.u_scale_matrix)
  setInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, entity.uniforms.u_texture_matrix)
  setInstanceAttr(instancedEntity.attributes.a_color, i, entity.uniforms.u_color)

proc cropLines*(instancedEntity: var ParavimTextEntity, startLine: int, endLine: int) =
  let
    # startLine and endLine could be temporarily too big if LineCount hasn't been updated yet
    startLine = min(startLine, instancedEntity.uniforms.u_char_counts.data.len)
    endLine = min(endLine, instancedEntity.uniforms.u_char_counts.data.len)
    prevLines = instancedEntity.uniforms.u_char_counts.data[0 ..< startLine]
    currLines = instancedEntity.uniforms.u_char_counts.data[startLine ..< endLine]
    i = math.sum(prevLines)
    j = i + math.sum(currLines)
  cropInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, j)
  cropInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, j)
  cropInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, j)
  cropInstanceAttr(instancedEntity.attributes.a_color, i, j)
  cropInstanceUni(instancedEntity.uniforms.u_char_counts, startLine, endLine)
  instancedEntity.instanceCount = int32(j - i)

proc cropLines*(instancedEntity: var ParavimTextEntity, startLine: int) =
  cropLines(instancedEntity, startLine, instancedEntity.uniforms.u_char_counts.data.len)

proc getColor(col: int, parsedNodes: openArray[Node], defaultColor: glm.Vec4[GLfloat]): glm.Vec4[GLfloat] =
  result = defaultColor
  for (kind, startCol, endCol) in parsedNodes:
    if col >= startCol and (col < endCol or endCol == -1):
      return colors.syntaxColors[kind]

proc add*(instancedEntity: var ParavimTextEntity, entity: UncompiledTextEntity, font: Font, fontColor: glm.Vec4[GLfloat], text: string, parsedNodes: openArray[Node], startPos: float): float =
  let lineNum = instancedEntity.uniforms.u_char_counts.data.len - 1
  result = startPos
  for i in 0 ..< text.len:
    let
      ch = text[i]
      charIndex = int(ch) - font.firstChar
      bakedChar =
        if charIndex >= 0 and charIndex < font.chars.len:
          font.chars[charIndex]
        else: # if char isn't found, use the space char
          font.chars[0]
    let color = getColor(i, parsedNodes, fontColor)
    var e = entity
    e.crop(bakedChar, result, font.baseline)
    e.color(color)
    instancedEntity.add(e)
    instancedEntity.uniforms.u_char_counts.data[lineNum] += 1
    result += bakedChar.xadvance

proc addLine*(instancedEntity: var ParavimTextEntity, entity: UncompiledTextEntity, font: Font, fontColor: glm.Vec4[GLfloat], text: string, parsedNodes: openArray[Node]): float =
  instancedEntity.uniforms.u_char_counts.data.add(0)
  instancedEntity.uniforms.u_char_counts.disable = false
  add(instancedEntity, entity, font, fontColor, text, parsedNodes, 0f)

proc updateColors*(instancedEntity: var ParavimTextEntity, parsedNodes: tree_sitter.Nodes, lines: ref seq[string], fontColor: glm.Vec4[GLfloat]) =
  instancedEntity.attributes.a_color.data.new
  for lineNum in 0 ..< lines[].len:
    for colNum in 0 ..< lines[][lineNum].len:
      let color = getColor(colNum, parsedNodes[][lineNum], fontColor)
      for x in 0 .. 3:
        instancedEntity.attributes.a_color.data[].add(color[x])

proc updateUniforms*(e: var ParavimTextEntity, startLine: int, startColumn: int, showBlocks: bool) =
  e.uniforms.u_start_line.data = startLine.int32
  e.uniforms.u_start_line.disable = false
  e.uniforms.u_start_column.data = startColumn.int32
  e.uniforms.u_start_column.disable = false
  e.uniforms.u_show_blocks.data = if showBlocks: 1 else: 0
  e.uniforms.u_show_blocks.disable = false
