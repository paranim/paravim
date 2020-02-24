import nimgl/opengl, glm
import paranim/gl, paranim/gl/uniforms, paranim/gl/attributes
from paranim/gl/entities import crop
import paratext, paratext/gl/text

const
  monoFontRaw = staticRead("../assets/ttf/FiraCode-Regular.ttf")
  variFontRaw = staticRead("../assets/ttf/Roboto-Regular.ttf")
  instancedTextVertexShader = staticRead("shaders/vertex.glsl")
  instancedTextFragmentShader = staticRead("shaders/fragment.glsl")

let
  monoFont* = initFont(ttf = monoFontRaw, fontHeight = 128, firstChar = 32, bitmapWidth = 1024, bitmapHeight = 1024, charCount = 2048)
  variFont* = initFont(ttf = variFontRaw, fontHeight = 128, firstChar = 32, bitmapWidth = 1024, bitmapHeight = 1024, charCount = 2048)

type
  ParavimTextEntityUniforms = tuple[
    u_matrix: Uniform[Mat3x3[GLfloat]],
    u_image: Uniform[Texture[GLubyte]],
    u_char_counts: Uniform[seq[GLint]],
    u_start_line: Uniform[GLint],
    u_font_height: Uniform[GLfloat],
    u_alpha: Uniform[GLfloat]
  ]
  ParavimTextEntityAttributes = tuple[
    a_position: Attribute[GLfloat],
    a_translate_matrix: Attribute[GLfloat],
    a_scale_matrix: Attribute[GLfloat],
    a_texture_matrix: Attribute[GLfloat],
    a_color: Attribute[GLfloat]
  ]
  ParavimTextEntity* = object of InstancedEntity[ParavimTextEntityUniforms, ParavimTextEntityAttributes]
  UncompiledParavimTextEntity* = object of UncompiledEntity[ParavimTextEntity, ParavimTextEntityUniforms, ParavimTextEntityAttributes]

proc initInstancedEntity*(entity: UncompiledTextEntity, font: Font): UncompiledParavimTextEntity =
  result.vertexSource = instancedTextVertexShader
  result.fragmentSource = instancedTextFragmentShader
  result.uniforms.u_matrix = entity.uniforms.u_matrix
  result.uniforms.u_image = entity.uniforms.u_image
  result.uniforms.u_char_counts.disable = true
  result.uniforms.u_font_height.data = font.height
  result.uniforms.u_alpha.data = 1.0
  result.attributes.a_translate_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_translate_matrix.data)
  result.attributes.a_scale_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_scale_matrix.data)
  result.attributes.a_texture_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_texture_matrix.data)
  result.attributes.a_color = Attribute[GLfloat](disable: true, divisor: 1, size: 4, iter: 1)
  new(result.attributes.a_color.data)
  deepCopy(result.attributes.a_position, entity.attributes.a_position)

proc addInstanceAttr[T](attr: var Attribute[T], uni: Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      attr.data[].add(uni.data.row(r)[c])
  attr.disable = false

proc addInstanceAttr[T](attr: var Attribute[T], uni: Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    attr.data[].add(uni.data[x])
  attr.disable = false

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

var
  baseMonoEntity*: UncompiledTextEntity
  monoEntity*: ParavimTextEntity

proc addLine*(instancedEntity: var ParavimTextEntity, entity: UncompiledTextEntity, font: Font, text: cstring) =
  instancedEntity.uniforms.u_char_counts.data.add(0)
  instancedEntity.uniforms.u_char_counts.disable = false
  let lineNum = instancedEntity.uniforms.u_char_counts.data.len - 1
  var
    x = 0f
    i = 0
  for ch in text:
    let
      charIndex = int(ch) - font.firstChar
      bakedChar = font.chars[charIndex]
    var e = entity
    e.crop(bakedChar, x, font.baseline)
    instancedEntity.add(e)
    instancedEntity.uniforms.u_char_counts.data[lineNum] += 1
    x += bakedChar.xadvance
    i += 1

proc init*(game: var RootGame) =
  baseMonoEntity = initTextEntity(monoFont)
  let
    uncompiledMonoEntity = initInstancedEntity(baseMonoEntity, monoFont)
    compiledMonoEntity = compile(game, uncompiledMonoEntity)
  monoEntity = deepCopy(compiledMonoEntity)
