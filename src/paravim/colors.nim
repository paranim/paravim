import nimgl/opengl
from glm import nil
import tables

const
  bgColor* = glm.vec4(GLfloat(52/255), GLfloat(40/255), GLfloat(42/255), GLfloat(0.95))
  textColor* = glm.vec4(1f, 1f, 1f, 1f)
  asciiColor* = glm.vec4(1f, 1f, 1f, 0.5f)
  cursorColor* = glm.vec4(GLfloat(112/255), GLfloat(128/255), GLfloat(144/255), GLfloat(0.9))
  completionColor* = glm.vec4(GLfloat(52/255), GLfloat(40/255), GLfloat(42/255), GLfloat(0.65))
  selectColor* = glm.vec4(GLfloat(148/255), GLfloat(69/255), GLfloat(5/255), GLfloat(0.8))
  searchColor* = glm.vec4(Glfloat(127/255), GLfloat(52/255), GLfloat(83/255), GLfloat(0.8))

  yellowColor* = glm.vec4(Glfloat(255/255), GLfloat(193/255), GLfloat(94/255), GLfloat(1.0))
  tanColor* = glm.vec4(Glfloat(209/255), GLfloat(153/255), GLfloat(101/255), GLfloat(1.0))
  syntaxColors* = {"string": tanColor,
                   "template_string": tanColor,
                   "number": yellowColor}.toTable
