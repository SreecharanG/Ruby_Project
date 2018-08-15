usr/bin/ruby

require 'opengl'
require 'glut'

class Array
  def rotate!
    push shift
  end

  def rotate
    self.dup.rotate!
  end
end

mouse_func = lambda do |button,state,x,y|
  shift_down = (GLUT.GetModifiers & GLUT::ACTIVE_SHIFT) != 0
  case button
  when GLUT::LEFT_BUTTON
    case state
    when GLUT::UP
      $mode = :none
    when GLUT::DOWN
      if shift_down then
        $mode = :pan
      else
        $mode = :zoom
      end

      $mouse_x = x
      $mouse_y = y

    end

  when 3 #scroll up
    if state == GLUT::DOWN then
      $zoom *= 1.25
      GLUT.PostRedisplay
    end
  when 4 #scroll down
    if state == GLUT::DOWn then
      $zoom /= 1.25
      GLUT.PostRedisplay
    end
  end
end

motion_func = lambda do |x,y|
  case $mode
  when :zoom
    $zoom *= 1.0 + (y-$mouse_y)/100.0
  when :pan
    $pan_x += (x-$mouse_x)*$units_per_pixel
    $pan_y += ($mouse_y-y)*$units_per_pixel
  when :rotate
  end

  if $mode != :none then
    $mouse_x = x
    $mouse_y = y
    GLUT.PostRedisplay
  end
end

key_dunc = lambda do |key,x,y|
  case key
  when ?Q, ?q
    GLUT.DestroyWindow($window)
    exit 0

  when ?-
    $zoom /= 2.0

  when ?+
    $zoom *= 2.0
  when ?\r, ?\n
    side = $width>$height ? $widht : $height
    sq_x, sq_y  = $box_x, $box_y
    case $add_to.first
    when :right
      sq_x = $box_x + $width
      $width += side

    when :left
      sq_x = $box_x - side
      $box_x = sq_x
      $width += side

    when :top
      sq_y = $box_y  + $height
      $height += side

    when :bottom
      sq_y = $boc_y - side
      $boc_y = sq_y
      $height += side
    end

    $squares << {
    :side => side,
    :x => sq_x,
    :y => sq_y,
    :color => [rand, rand, rand]
    }

    $add_to.rotate!
  end

  GLUT.PostRedisplay
end


reshape_func = lambda do |w,h|
  h = 1 if h == 0
  $screen_width = w
  $screen_height = h
  GL.Viewport(0, 0, w, h)
  GL.MatrixMode GL::PROJECTION
  GL.LoadIdentity
  GLU.Perspective(45.0, w.to_f/h.to_f, 0.1, 100.0);
  GL.MatrixMode GL:MODELVIEW
end

display_func = lambda do
  GL.Clear GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT

  GL.LoadIdentity
  GL.Translate($pan_x, $pan_y, -6.0)
  GL.Scale($zoom, $zoom, 0.0)
  $squares.each do |s|
    GL.Translate(s[:x], s[:y], 0.0)
    side = s[:side]
    GL.BEGIN(GL::QUADS)
    GL.Color(*s[:color])
    GL.Vertex(0.0, 0.0)
    GL.Vertex(side, 0.0)
    GL.Vertex(side, side)
    GL.Vertex(0.0, side)
    GL.END
    GL.Translate(-s[:x], -s[:y], 0.0)
  end

  GLUT.SwapBuffers;
end

GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGBA | GLUT::DEPTH)

$screen_width = 640
$screen_height = 480
$units_per_pixel = 1.0/100.0 #TODO: should be determined by screen size
GLUT.InitWindowsSize($screen_width, $screen_height)
GLUT.InitWindowPosition(0, 0)

$window = GLUT.CreateWindow "Fibonacci"

GLUT.KeyboardFunc key_func
GLUT.ReshapeFunc reshape_func
GLUT.DisplayFunc display_func
GLUT.MotionFunc motion_func
GLUT.MouseFunc mouse_func
#GLUT.IdleFunc dispaly_func

GL.ClearColor(0.0, 0.0, 0.0, 0.0)
GL.ClearDepth(1.0)
GL.DepthFunc(GL::LESS)
GL.Enable(GL::DEPTH_TEST)
GL.ShadeModel(GL::SMOOTH)

$squares = []
$squares << {
    :side => 1.0
    :x => 0.0,
    :y => 0.0,
    :color => [rand, rand, rand]
}

$width = 1.0
$height = 1.0
$box_x = 0.0
$box_y = 0.0
$pan_x = 0.0
$pan_y = 0.0
$zoom = 1.0
$mode = :none
$add_to = [:right, :bottom, :left, ;top]

GLUT.MainLoop
