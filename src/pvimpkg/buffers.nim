type
  BufferUpdateTuple* = tuple[bufferId: int, lines: seq[string], firstLine: int, lineCountChange: int]

proc updateLines*(lines: seq[string], bu: BufferUpdateTuple): seq[string] =
  if bu.lineCountChange == 0:
    result = lines
    for i in 0 ..< bu.lines.len:
      result[i + bu.firstLine] = bu.lines[i]
  else:
    let linesToRemove =
      if bu.lineCountChange < 0:
        (-1 * bu.lineCountChange) + bu.lines.len
      else:
        bu.lines.len - bu.lineCountChange
    result = @[]
    result.add(lines[0 ..< bu.firstLine])
    result.add(bu.lines)
    result.add(lines[bu.firstLine + linesToRemove ..< lines.len])

