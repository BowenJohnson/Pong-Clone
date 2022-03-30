require 'gosu'

class GameScreen < Gosu::Window

	attr_reader :score
	attr_reader :pad_ping
	attr_reader :score_beep
	attr_reader :wall_ping

	def initialize
		@width = 640
		@height = 480
		super @width, @height, false

		# make demo true for demo mode (AI controls both paddles)
		$demo = true
		
		#Title of gaming window
		self.caption = "Last Project For The Term!!!"

		margin = 20
		@ball = Ball.new(75, 75, { :x => 4.5, :y => 4.5 } )
		@player = Paddle.new( margin, margin )
		@last_mouse_y = margin
		@ai = Paddle.new( self.width - Paddle::WIDTH - margin, margin)
		@font = Gosu::Font.new(25)
		@score = [0, 0]
		@flash = {}
		load_sfx

	end

	#Push escape key to close

	def button_down(key)
		case key
		when Gosu::KbEscape
			close
		end
	end

	def update

		#Updating locations of objects moving in the screen
		#Where player paddle, AI paddle, and Ball are

		player_move
		ai_move
		@ball.update

		#Ball hits player paddle bounce back, play sfx, and increase ball speed a little

		if @ball.crash?(@player)
			@ball.reflect_horizontal
			@pad_ping.play
			increase_speed

			#Ball hits opponent paddle bounce back, play sfx, and increase ball speed a little

		elsif @ball.crash?(@ai)
			@ball.reflect_horizontal
			@pad_ping.play
			increase_speed

			#Ball hits wall behind player AI score increases

		elsif @ball.x <= 0
			@ball.x = @player.right
			score[1] += 1

			#adjust X of ball so it doesn't get stuck behind paddle!!!
			@ball.v[:x] = 4
			flash_side(:left)
			@score_beep.play

			#Ball hits wall behind AI player score increases

		elsif @ball.right >= self.width
			@ball.x = @ai.left
			score[0] += 1

			#adjust X of ball so it doesn't get stuck behind paddle!!!

			@ball.v[:x] = -4
			flash_side(:right)
			@score_beep.play
		end

		# include && so when ball hits top or bottom boundary it plays wall ping sfx

		@ball.reflect_vertical && wall_ping.play if @ball.y < 0 || @ball.bottom > self.height
	end

	#Equation to adjust for the ball speed after it hits a paddle
	#or the game is going to be boring AF

	def increase_speed
		@ball.v[:x] = @ball.v[:x] * 1.2
	end

	#player mouse control movement
	# by finding the difference in the Y position of the mouse

	def player_move

		#implement demo mode if demo bool is true

		if $demo == false
		y = mouse_y
		diff = y - @last_mouse_y
		@player.y += diff
		@player.y = 0 if @player.y <= 0
		@player.bottom = self.height if @player.bottom >= self.height
		@last_mouse_y = y
		else
			ai_speed = 0
			distance = @player.mid_x - @ball.mid_x
			if distance > self.width / 3
				ai_speed = 0.05
			elsif distance > self.width / 2
				ai_speed = 0.1
			else
				ai_speed = 0.14
			end

			diff = @ball.mid_y - @player.mid_y
			@player.y += diff * ai_speed

			@player.top = 0 if @ai.top <= 0
			@player.bottom = self.height if @player.bottom >= self.height
		end

	end

	# AI control paddle movement speed
	# adjusted so that the AI moves faster when ball is nearer

	def ai_move
		ai_speed = 0
		distance = @ai.mid_x - @ball.mid_x
			if distance > self.width / 3
				ai_speed = 0.1
			elsif distance > self.width / 2
				ai_speed = 0.15
			else
				ai_speed = 0.2
			end

		# base the AI paddle off of the center of the ball
		# so the movement isn't just random

		diff = @ball.mid_y - @ai.mid_y
		@ai.y += diff * ai_speed

		@ai.top = 0 if @ai.top <= 0
		@ai.bottom = self.height if @ai.bottom >= self.height
	end

	# scoring flash effect

	def flash_side(side)
		@flash[side] = true
	end

	def draw
		draw_background

		if @flash[:left]
			Gosu.draw_rect 0, 0, self.width / 2, self.height, Gosu::Color::RED
			@flash[:left] = nil
		end

		if @flash[:right]
			Gosu.draw_rect self.width / 2, 0, self.width, self.height, Gosu::Color::RED
			@flash[:right] = nil
		end

		draw_score
		draw_center_line
		@ball.draw
		@player.draw
		@ai.draw

	end

	def draw_background
		Gosu.draw_rect 0, 0, self.width, self.height, Gosu::Color::BLACK
	end

	# draw the score on the top of playing field
	# use gosu font and draw_text

	def draw_score
		char_width = 12
		mid_x = self.width / 2
		z_order = 100
		offset = 15

		@font.draw_text score[0].to_s, mid_x - offset - char_width, offset, z_order
		@font.draw_text score[1].to_s, mid_x + offset, offset, z_order
	end

	# add sounds when paddle hits, wall hits, and when player scores

	def load_sfx
		path = File.expand_path(File.dirname(__FILE__))
		@pad_ping = Gosu::Sample.new(File.join(path, "pad_ping.wav"))
		@wall_ping = Gosu::Sample.new(File.join(path, "wall_ping.wav"))
		@score_beep = Gosu::Sample.new(File.join(path, "score_beep.wav"))
	end
	
	# dividing line in the center
	# using draw_line to make it add a gap var to make it dashed
	# I'm thinking fuchsia...
	
	def draw_center_line
		mid_x = self.width / 2
		line_length = 50
		space = 15
		color = Gosu::Color::FUCHSIA
		y = 0
		begin
			draw_line mid_x, y, color,
								mid_x, y + line_length, color
			y += line_length + space
		end while y < self.height
	end
	
end

# X,Y and width and height of objects and borders

class GameObject
	attr_accessor :x
	attr_accessor :y
	attr_accessor :w
	attr_accessor :h


	def initialize(x, y, w, h)
		@x = x
		@y = y
		@w = w
		@h = h
	end

	def left
		x
	end

	def right
		x + w
	end
	
	def mid_x
		x + x/2
	end
	
	def right=(r)
		self.x = r - w
	end

	def top
		y
	end

	def mid_y
		y + h/2
	end
	
	def top=(t)
		self.y = t
	end

	def bottom
		y + h
	end

	def bottom=(b)
		self.y = b - h
	end

	#crashing is an overlap in objects
	# use _overlap (so glad I don't have to write this tool...)
	# use other to accept name of arg it receives....clever tool

	def crash?(other)
		x_overlap = [0, [right, other.right].min - [left, other.left].max].max
		y_overlap = [0, [bottom, other.bottom].min - [top, other.top].max].max
		x_overlap * y_overlap != 0
	end
end

# Visual Object designs Ball and Paddles

# Ball size specs

class Ball < GameObject

	WIDTH = 5
	HEIGHT = 5

	attr_reader :v
	def initialize(x, y, v)
		super(x, y, WIDTH, HEIGHT)
		@v = v
	end

	# update the x,y movement of the ball

	def update
		self.x += v[:x]
		self.y += v[:y]
	end

	def reflect_horizontal
		v[:x] = -v[:x]
	end

	def reflect_vertical
		v[:y] = -v[:y]
	end

	#draw the ball with draw_rect...I think I'll make it yellow

	def draw
		Gosu.draw_rect x, y, WIDTH, HEIGHT, Gosu::Color::YELLOW
	end
end

#Paddle size specs

class Paddle < GameObject
	WIDTH = 12
	HEIGHT = 60

	def initialize(x, y)
		super(x, y, WIDTH, HEIGHT)
	end

	#how to draw paddle to screen...maybe blue this time

	def draw
		Gosu.draw_rect x, y, w, h, Gosu::Color::BLUE
	end
end

GameScreen.new.show