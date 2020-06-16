import pararules

type
  Scroll = tuple[x: float, y: float, targetX: float, targetY: float, speedX: float, speedY: float]

const
  scrollSpeed = 40.0
  scrollLimit = 10.0
  minScrollSpeed* = 5.0
  deceleration = 0.8

func decelerate(speed: float): float =
  let speed = speed * deceleration
  if abs(speed) < minScrollSpeed:
    minScrollSpeed
  else:
    speed

func startScrollingCamera*(scroll: Scroll, xoffset: float, yoffset: float): Scroll =
  let
    xoffset = block:
      const stickiness = 2.5
      let xoffset =
        # make the left edge "sticky" so it doesn't move unintentionally
        if scroll.x == 0 and abs(xoffset) < stickiness:
          0.0
        else:
          xoffset
      min(xoffset, scrollLimit).max(-scrollLimit)
    yoffset = min(yoffset, scrollLimit).max(-scrollLimit)
    # flip the sign because the camera must go the opposite direction
    xdiff = -1 * scrollSpeed * xoffset
    ydiff = -1 * scrollSpeed * yoffset
  (
    scroll.x,
    scroll.y,
    scroll.targetX + xdiff,
    scroll.targetY + ydiff,
    scroll.speedX + abs(xdiff),
    scroll.speedY + abs(ydiff)
  )

func animateCamera*(scroll: Scroll, deltaTime: float): Scroll =
  const minDiff = 1.0
  let
    xdiff = scroll.targetX - scroll.x
    ydiff = scroll.targetY - scroll.y
    newX =
      if abs(xdiff) < minDiff:
        scroll.targetX
      else:
        scroll.x + (xdiff * min(1.0, deltaTime * scroll.speedX))
    newY =
      if abs(ydiff) < minDiff:
        scroll.targetY
      else:
        scroll.y + (ydiff * min(1.0, deltaTime * scroll.speedY))
    newSpeedX =
      if newX == scroll.targetX:
        0.0
      else:
        decelerate(scroll.speedX)
    newSpeedY =
      if newY == scroll.targetY:
        0.0
      else:
        decelerate(scroll.speedY)
  (
    newX,
    newY,
    scroll.targetX,
    scroll.targetY,
    newSpeedX,
    newSpeedY
  )
