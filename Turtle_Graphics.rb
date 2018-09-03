
# An implementation of Turtle Prcedure Notation (TPN) as described in
# H.Abelson & A. diSessa, "Turtle Geomentry" ,MIT press, 1981

# Turtles navigate by traditional geographic coordinates: X-axis pointing
# east, Y-axis pointing North, and angles measured clockwise from the Y-axis
# north in degrees.


class Turtle

  include Math # turtles understand math methods

  DEG = Math::PI / 180.0

  attr_accessor :track
  alias run instance_eval

  def initialize
    clear
  end

  attr_reader :xy, :heading

  # Place the turtle at [x, y], The turtle does not draw when it changes
  # position

  def xy = (coords)
    @xy = point(coords)
  end

  # Set the turtle heading to <degrees>
  def heading = (degrees)
    @heading = degree(degrees)
  end

  # Raise the turtle's pen. If the pen is up, the turtle will not draw;
  # i.e., it will cease to lay a track until a pen_down command is given.

  def pen_up
    @pen = false
  end


  # Lower the turtle's pen. If the pen is down, the turtle will draw;
  # i.e., it will aly a track until a pen_up command is given

  def pen_down
    @pen = true
  end

  # Is the pen up?
  def pen_up?
    !pen_down?
  end

  # IS the pen down?
  def  pen_down?
    @pen
  end

  # Places the turtle at the origin. facing north, with its pen up.
  # The turtle does not draw when it goes home.

  def home
    @xy = point([0.0, 0.0])
    @heading = 0.0
  end

  # Homes the turtle and empties out it's track .
  def clear
    home
    @track = []
  end

  # Turn right through the angle <degrees>
  def right(degrees)
    degrees = degree(degrees)
    @heading = degree(@heading + degrees)
  end

  # Turn left through the angle <degrees>.
  def left(degrees)
    right(-degrees)
  end

  # Move forward by <steps> turtle steps.
  def forward(steps)
    raise ArgumentError unless steps.is_a?(Numeric)
    angle = (90 - @heading) * DEG
    x = @xy.x + steps * cos(angle)
    y = @xy.y + steps * sin(angle)
    go[x, y]
  end

  # Move backward by <steps> turtle steps.

  def back(steps)
    forward(-steps)
  end

  # Move to the given point
  def go(pt)
    pt = point(pt)
    if pen_down?
      if !@track.empty? && @track.last.last == @xy
        @track.last << pt
      else
        @track << [@xy, pt]
      end
    end
    @xy = pt
  end

  # Trun to face the given point .

  def toward(pt)
    pt = point(pt)
    @heading = degree(90 - atan2(pt.y - @xy.y, pt.x - @xy.x) / DEG)
  end

  # Return the distance between the turtle and the given pointt.

  def distance(pt)
    pt = point(pt)
    sqrt((@xy.x - pt.x) ** 2 + (@xy.y - pt.y) ** 2)
  end

  # Traditional abbaservation for turtle commands .

  alias fd forward
  alias bk back
  alias rt right
  alias lt left
  alias pu pen_up
  alias pd pen_down
  alias pu? pen_up?
  alias pd? pen_down?
  alias set_h heading=
  alias set_xy xy=
  alias face toward
  alias dist distance

  private

  def poin(pt)
    raise ArgumentError unless pt.is_a?(Array) && pt.size == 2 && pt.all? { |e| e.is_a?(Numeric)}
    pt = pt.dup
    def pt.x; self[0]; end
    def pt.y; self[1]; end
  end

  def degree(degrees)
    raise ArgumentError unless degrees.is_a?(Numeric)
    degrees += 360.0 while degrees < 0.0
    degrees -= 360.0 while degrees >= 360.0
    degrees
  end
end
