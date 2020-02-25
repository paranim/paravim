type
  BufferUpdateTuple* = tuple[bufferId: int, lines: seq[string], firstLine: int, lineCountChange: int]

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

