import nimgl/opengl, glm
import paranim/gl, paranim/gl/uniforms, paranim/gl/attributes
from paranim/gl/entities import crop
import paratext, paratext/gl/text

const
  monoFontRaw = staticRead("../assets/ttf/FiraCode-Regular.ttf")
  variFontRaw = staticRead("../assets/ttf/Roboto-Regular.ttf")

let
  monoFont* = initFont(ttf = monoFontRaw, fontHeight = 64, firstChar = 32, bitmapWidth = 512, bitmapHeight = 512, charCount = 2048)
  variFont* = initFont(ttf = variFontRaw, fontHeight = 64, firstChar = 32, bitmapWidth = 512, bitmapHeight = 512, charCount = 2048)

type
  ParavimTextEntityUniforms = tuple[u_matrix: Uniform[Mat3x3[GLfloat]], u_image: Uniform[Texture[GLubyte]]]
  ParavimTextEntityAttributes = tuple[
    a_position: Attribute[GLfloat],
    a_translate_matrix: Attribute[GLfloat],
    a_scale_matrix: Attribute[GLfloat],
    a_texture_matrix: Attribute[GLfloat],
    a_color: Attribute[GLfloat]
  ]
  ParavimTextEntity* = object of InstancedEntity[ParavimTextEntityUniforms, ParavimTextEntityAttributes]
  UncompiledParavimTextEntity* = object of UncompiledEntity[ParavimTextEntity, ParavimTextEntityUniforms, ParavimTextEntityAttributes]

const instancedTextVertexShader =
  """
  #version 410
  uniform mat3 u_matrix;
  in vec2 a_position;
  in vec4 a_color;
  in mat3 a_translate_matrix;
  in mat3 a_texture_matrix;
  in mat3 a_scale_matrix;
  out vec2 v_tex_coord;
  out vec4 v_color;
  void main()
  {
    gl_Position = vec4((u_matrix * a_translate_matrix * a_scale_matrix * vec3(a_position, 1)).xy, 0, 1);
    v_tex_coord = (a_texture_matrix * vec3(a_position, 1)).xy;
    v_color = a_color;
  }
  """

const instancedTextFragmentShader =
  """
  #version 410
  precision mediump float;
  uniform sampler2D u_image;
  in vec2 v_tex_coord;
  in vec4 v_color;
  out vec4 o_color;
  void main()
  {
    o_color = texture(u_image, v_tex_coord);
    if (o_color.rgb == vec3(0.0, 0.0, 0.0))
    {
      discard;
    }
    else
    {
      o_color = v_color;
    }
  }
  """

proc initInstancedEntity*(entity: UncompiledTextEntity): UncompiledParavimTextEntity =
  result.vertexSource = instancedTextVertexShader
  result.fragmentSource = instancedTextFragmentShader
  result.uniforms.u_matrix = entity.uniforms.u_matrix
  result.uniforms.u_image = entity.uniforms.u_image
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

proc add*(instancedEntity: var ParavimTextEntity, entity: UncompiledTextEntity, font: Font, text: cstring) =
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
