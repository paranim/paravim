import paranim/opengl
from paranim/glm import nil
import tables

const
  bgColor* = glm.vec4(GLfloat(52/255), GLfloat(40/255), GLfloat(42/255), GLfloat(0.95))
  textColor* = glm.vec4(1f, 1f, 1f, 1f)
  asciiColor* = glm.vec4(1f, 1f, 1f, 0.5f)
  minimapViewColor* = glm.vec4(1f, 1f, 1f, 0.25f)
  cursorColor* = glm.vec4(GLfloat(112/255), GLfloat(128/255), GLfloat(144/255), GLfloat(0.9))
  completionColor* = glm.vec4(GLfloat(52/255), GLfloat(40/255), GLfloat(42/255), GLfloat(0.65))
  selectColor* = glm.vec4(GLfloat(148/255), GLfloat(69/255), GLfloat(5/255), GLfloat(0.8))
  searchColor* = glm.vec4(Glfloat(127/255), GLfloat(52/255), GLfloat(83/255), GLfloat(0.8))

  yellowColor* = glm.vec4(Glfloat(255/255), GLfloat(193/255), GLfloat(94/255), GLfloat(1.0))
  tanColor* = glm.vec4(Glfloat(209/255), GLfloat(153/255), GLfloat(101/255), GLfloat(1.0))
  cyanColor* = glm.vec4(Glfloat(86/255), GLfloat(181/255), GLfloat(194/255), GLfloat(1.0))
  grayColor* = glm.vec4(Glfloat(150/255), GLfloat(129/255), GLfloat(133/255), GLfloat(1.0))
  orangeColor* = glm.vec4(Glfloat(220/255), GLfloat(103/255), GLfloat(44/255), GLfloat(1.0))
  redColor* = glm.vec4(Glfloat(210/255), GLfloat(45/255), GLfloat(58/255), GLfloat(1.0))
  greenColor* = glm.vec4(Glfloat(65/255), GLfloat(174/255), GLfloat(122/255), GLfloat(1.0))
  syntaxColors* = {"string": tanColor,
                   "string_literal": tanColor,
                   "template_string": tanColor,
                   "number": yellowColor,
                   "number_literal": yellowColor,
                   "integer": yellowColor,
                   "float": yellowColor,
                   "comment": grayColor,
                   "op": grayColor,
                   "public_id": cyanColor,
                   }.toTable
