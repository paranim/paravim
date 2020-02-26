type
  BufferUpdateTuple* = tuple[bufferId: int, lines: seq[string], firstLine: int, lineCountChange: int]
  RangeTuple* = tuple[startLine: int, startColumn: int, endLine: int, endColumn: int]
  RectTuple* = tuple[left: float, top: float, width: float, height: float]

proc updateLines*(lines: seq[string], bu: BufferUpdateTuple): seq[string] =
  if bu.lineCountChange == 0:
    result = lines
    for i in 0 ..< bu.lines.len:
      let lineNum = i + bu.firstLine
      if result.len == lineNum:
        result.add(bu.lines[i])
      else:
        result[lineNum] = bu.lines[i]
  else:
    let linesToRemove =
      if bu.lineCountChange < 0:
        (-1 * bu.lineCountChange) + bu.lines.len
      else:
        bu.lines.len - bu.lineCountChange
    result = @[]
    result.add(lines[0 ..< bu.firstLine])
    result.add(bu.lines)
    if lines.len > 0: # see test: "delete all lines"
      result.add(lines[bu.firstLine + linesToRemove ..< lines.len])

proc normalizeRange*(rangeData: RangeTuple): RangeTuple =
  var (startLine, startCol, endLine, endCol) = rangeData
  # make sure the range is always going the same direction
  if startLine > endLine or (startLine == endLine and startCol > endCol):
    startLine = rangeData.endLine
    startCol = rangeData.endColumn
    endLine = rangeData.startLine
    endCol = rangeData.startColumn
  # the column the cursor is in doesn't seem to be included in the range
  # add it manually so it is included in the selection
  endCol += 1
  (startLine, startCol, endLine, endCol)

proc rangeToRects*(rangeData: RangeTuple, lines: seq[string]): seq[RectTuple] =
  var (startLine, startCol, endLine, endCol) = rangeData
  result = newSeq[RectTuple]()
  for lineNum in startLine .. endLine:
    let
      startCol = if lineNum == startLine: startCol else: 0
      endCol = if lineNum == endLine: endCol else: lines[lineNum].len
    result.add((
      left: startCol.float,
      top: lineNum.float,
      width: float(endCol - startCol),
      height: 1.float
    ))
