from text import nil
from math import nil

type
  BufferUpdateTuple* = tuple[lines: seq[string], firstLine: int, lineCountChange: int]
  RangeTuple* = tuple[startLine: int, startColumn: int, endLine: int, endColumn: int]
  RectTuple* = tuple[left: float, top: float, width: float, height: float]

proc updateLines*(lines: ref seq[string], bu: BufferUpdateTuple): ref seq[string] =
  new(result)
  if bu.lineCountChange == 0:
    result[] = lines[]
    for i in 0 ..< bu.lines.len:
      let lineNum = i + bu.firstLine
      if result[].len == lineNum:
        result[].add(bu.lines[i])
      else:
        result[][lineNum] = bu.lines[i]
  else:
    let linesToRemove =
      if bu.lineCountChange < 0:
        (-1 * bu.lineCountChange) + bu.lines.len
      else:
        bu.lines.len - bu.lineCountChange
    result[].add(lines[][0 ..< bu.firstLine])
    result[].add(bu.lines)
    result[].add(lines[][bu.firstLine + linesToRemove ..< lines[].len])

proc normalizeRange*(rangeData: RangeTuple, forceLeftToRight: bool): RangeTuple =
  var (startLine, startCol, endLine, endCol) = rangeData
  # make sure the range is always going the same direction
  if startLine > endLine or (startLine == endLine and startCol > endCol):
    startLine = rangeData.endLine
    startCol = rangeData.endColumn
    endLine = rangeData.startLine
    endCol = rangeData.startColumn
  # make sure the block is top left to bottom right
  if forceLeftToRight and startCol > endCol:
    swap(startCol, endCol)
  # include the last column in the selection
  endCol += 1
  (startLine, startCol, endLine, endCol)

proc rangeToRects*(rangeData: RangeTuple, lines: ref seq[string]): seq[RectTuple] =
  var (startLine, startCol, endLine, endCol) = rangeData
  result = newSeq[RectTuple]()
  for lineNum in startLine .. endLine:
    let
      startCol = if lineNum == startLine: startCol else: 0
      endCol = if lineNum == endLine: endCol else: lines[][lineNum].len
    result.add((
      left: startCol.float,
      top: lineNum.float,
      width: float(endCol - startCol),
      height: 1.float
    ))

proc rangeToRect*(rangeData: RangeTuple): RectTuple =
  let (startLine, startCol, endLine, endCol) = rangeData
  (
    left: startCol.float,
    top: startLine.float,
    width: float(endCol - startCol),
    height: float(endLine - startLine + 1)
  )
