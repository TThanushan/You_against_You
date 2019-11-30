pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

--you against you 
--by wombart
--made for 42jam#2

local p_info = {x = 64, y = 64, tag = 'player', max_health = 3, move_speed = 2, 
money = 10, sprites = {idle ={1, 2}, running = {17, 18, 18, 19, 20, 20}}, 
sounds = {running = 0}, weapon_info = {reload_time = 0, bullet_sprite = 49, 
	name = 'pistol', attack_speed = 0.5, move_speed = 1000, damage = 1, 
	backoff = 1, collision_backoff = 10, max_ammo = 5}}

local map_limit_left_x, map_limit_right_x = 0, 300


local player
local part = {}
local g = 0.3
local debugmode = false
local ground_y = 64
local shkx, shky = 0, 0
local main_camera
local gameobjects = {}
local game_state = 'game'

local colors = {black = 0, dark_blue = 1, dark_purple = 2, dark_green = 3,
	brown = 4, dark_gray = 5, light_gray = 6, white = 7, red = 8, orange = 9,
	yellow = 10, green = 11, blue = 12, indigo = 13, pink = 14, peach = 15, no_color}

local ground_bridge = {x0 = -70, y0 = 65, x1 = 276, y1 = 95, width = 15, 
	height = 10, light_color = colors.white, dark_color = colors.light_gray}

local platform1 = {x0=60, y0=45, x1=90, y1=53, hitboxy=40, 
	light_color = colors.white, dark_color = colors.light_gray}
local platform2 = {x0=130, y0=45, x1=160, y1=53, hitboxy=40,
	light_color = colors.white, dark_color = colors.light_gray}

function _init()
	start()
end

function start()
	init_all_gameobject()

end

function _update60()
 if game_state == 'start' then

 elseif game_state == 'game' then
  update_game()
 elseif game_state == 'gameover' then

 end
end

function _draw()
 if game_state == 'start' then
 elseif game_state == 'game' then
  draw_game()
 elseif game_state == 'gameover' then

 end

 if (debugmode) then
  -- if btnp(5) then spawner.wave_number += 1 end
  if btnp(5) then platform_button1.level += 1 end

  local pos_x, pos_y = main_camera.x - 60, main_camera.y - 60
  -- if (btn(5)) shake_v(1)
  -- print('time:'..flr(time()/2),main_camera.x-64, main_camera.y-64, 8, 2)
  -- print('e:'..spawner.alivee,main_camera.x-30, 30 +main_camera.y, 8, 2)

  -- print('mem_use:'..stat(0),main_camera.x+ 0, 30+main_camera.y, 8, 2)
  print('obj:'..#gameobjects,  pos_x, pos_y, 10)
  print('cpu:'..stat(1), pos_x, pos_y+5, 12)
  print('fps:'..stat(7), pos_x, pos_y+10, 11, 3)
  print('particles:'..#part, pos_x, pos_y+15, 8, 2)
  print(time(), pos_x, pos_y+20, 8, 2)
  print(camera_lerp_timer, pos_x, pos_y+25, 8, 2)
  print(distance(main_camera, player), pos_x, pos_y+32, 8, 2)
  print(btn(0), pos_x, pos_y+40, 8, 2)
 end
end

function update_game()
	update_all_gameobject()
	do_camera_shake()
	update_part()
	whiteframe_update()
	block_object_map_limit()
end

function draw_game()

	-- cls(((time()/2%15))+1)
	draw_background()
	draw_map()
	draw_all_gameobject()
	draw_part()
	draw_interface()
	-- print(main_camera.get_tag())
end

function update_all_gameobject()
	for obj in all(gameobjects) do
		obj:update()
	end
end

function draw_all_gameobject()
	for obj in all(gameobjects) do
		if (obj.draw_layer == -1) obj:draw()
	end
	for obj in all(gameobjects) do
		if (obj.draw_layer == 0) obj:draw()
	end
	
	player:draw()

	for obj in all(gameobjects) do
		if (obj.draw_layer == 1) obj:draw()
	end

end

function draw_map()
	

	-- outline 
	rect(shkx+ground_bridge.x0-1, shky+ground_bridge.y0-1,
		shkx+ground_bridge.x1+1, shky+ground_bridge.y1+ground_bridge.height+1, 
		colors.black)

	-- light part
	rectfill(shkx+ground_bridge.x0,shky+ground_bridge.y0,shkx+ground_bridge.x1,
		shky+ground_bridge.y0+ground_bridge.width, ground_bridge.light_color)

	-- dark part
	rectfill(shkx+ground_bridge.x0, shky+ground_bridge.y0+ground_bridge.width,
		shkx+ground_bridge.x1,shky+ground_bridge.y1+ground_bridge.height, ground_bridge.dark_color)


	-- platform 1
	rect(shkx+platform1.x0-1, shky+platform1.y0-1, shkx+platform1.x1+1,
		shky+platform1.y1+1, colors.black)

	-- light part
	rectfill(shkx+platform1.x0, shky+platform1.y0, shkx+platform1.x1,
		shky+platform1.y1, platform1.light_color)

	-- dark part
	rectfill(shkx+platform1.x0, shky+platform1.y0+5, shkx+platform1.x1,
		shky+platform1.y1, platform1.dark_color)

	-- platform 2
	rect(shkx+platform2.x0-1, shky+platform2.y0-1, shkx+platform2.x1+1,
		shky+platform2.y1+1, colors.black)

	-- light part
	rectfill(shkx+platform2.x0, shky+platform2.y0, shkx+platform2.x1,
		shky+platform2.y1, platform2.light_color)

	-- dark part
	rectfill(shkx+platform2.x0, shky+platform2.y0+5, shkx+platform2.x1,
		shky+platform2.y1, platform2.dark_color)

end

function do_camera_shake()
	if abs(shkx)<0.1 then
		shkx=0
	else
		shkx*=-0.7-rnd(0.2)
	end

	if abs(shky)<0.1 then
		shky=0
	else
		shky*=-0.7-rnd(0.2)
	end
end

function draw_background()
	cls(1)
end

function draw_interface()
	-- spe_print("wave "..spawner.wave_number,  main_camera.x, 4, colors.red, colors.dark_purple)
end

-- ##init
function init_all_gameobject()
	make_player()
	main_camera = make_gameobject(128, 64, 'main_camera', {newposition = {x=0, y=0}})

end

function block_object_map_limit()
	for obj in all(gameobjects) do
		if type(obj.x) != 'table' and obj.tag != 'main_camera' then
			if obj.x > map_limit_right_x then
				obj.x = map_limit_right_x
			elseif obj.x < map_limit_left_x then
				obj.x = map_limit_left_x 
			end
		end
	end
end

function distance(current, target)
	local x0, x1, y0, y1 = current.x, target.x, current.y, target.y  
	-- scale inputs down by 6 bits
	local dx=(x0-x1)/64
	local dy=(y0-y1)/64

	-- get distance squared
	local dsq=dx*dx+dy*dy

	-- in case of overflow/wrap
	if(dsq<0) return 32767.99999

	-- scale output back up by 6 bits
	return sqrt(dsq)*64
end

function is_player_on_a_platform()
	return (player.x >= platform1.x0 and player.x <= platform1.x1
		and (player.y > platform1.hitboxy-3 and player.y < platform1.hitboxy+3))
		or (player.x > platform2.x0 and player.x < platform2.x1
		and (player.y > platform2.hitboxy-3 and player.y < platform2.hitboxy+3))
end

function closest_obj(target, tag)
  local dist=0
  local shortest_dist=32000
  local closest=nil

  for obj in all(gameobjects) do
	  if(obj:get_tag() == tag) then
		dist = distance(target, obj)
		if(dist < shortest_dist) then
		  closest = obj
		  shortest_dist = dist
		end
	  end

  end
  return closest
end

function whiteframe_update()
	if whiteframe == true then
		rectfill(-100,-100, 200, 200, 8)
		whiteframe = false
	end
end

-- ##player
function make_player()
	player = make_gameobject(p_info.x, p_info.y, p_info.tag, {
		current_health = p_info.max_health,
		max_health = p_info.max_health,
		c_sprite=1,
		dx=0,
		dy=1, 
		level = 1,
		weapon_info = {reload_time = p_info.weapon_info.reload_time, 
			bullet_sprite = p_info.weapon_info.bullet_sprite, 
			name = p_info.weapon_info.name, 
			attack_speed = p_info.weapon_info.attack_speed,
			move_speed = p_info.weapon_info.move_speed, 
			damage = p_info.weapon_info.damage, 
			backoff = p_info.weapon_info.backoff, 
			collision_backoff = p_info.weapon_info.collision_backoff,
			current_ammo = p_info.weapon_info.max_ammo, 
			max_ammo = p_info.weapon_info.max_ammo},
		state = 'idle',
		sfx_playing = false,
		look_to_left = true,
		grounded = true,
		timer = {walk_sfx_timer = 0},
		sounds = p_info.sounds,
		sprites = p_info.sprites,
		experience=0,
		money=p_info.money,
		move_speed = p_info.move_speed,
		move = function(self)
			if btn(0) then
				self.x -= self.move_speed
				self.state = 'running'
				-- allow player to shoot to the right and walk to the left
				if not btn(4) then
					self.look_to_left = true 
				end
				-- self:walk_particle()
			end
			if btn(1) then
				self.x += self.move_speed
				self.state = 'running'
				if not btn(4) then
					self.look_to_left = false
				end
				-- self:walk_particle()
			end
			-- need to be falling to jump 
			if btn(2) and self.grounded and self.dy >= 0 then
				self:jump()

			end
			if not btn(0) and not btn(1) then
				self.state = 'idle'
			end
			if btn(4) then
				self:shoot(self.x+200, self.y)
			end
		end,
		shoot = function(self, _x, _y)
			if self.weapon_info.reload_time < time() then
				local looking_direction = 1
				if (self.look_to_left) looking_direction = -1
				make_muzzle_flash(self.x+6*looking_direction, self.y+4, 6)
				-- sfx(20 + flr(rnd(2)))
				sfx(1)
				sfx(15 + flr(rnd(3)))
				self.weapon_info.reload_time = time()+self.weapon_info.attack_speed
				local direction = 1
				if self.look_to_left then direction = -1 end
				self.x += self.weapon_info.backoff * -direction

				local bullet = make_bullet(
					self.x,
					self.y,
					{x=_x*direction, y=_y},
					self.weapon_info.damage,
					self.weapon_info.collision_backoff,
					self.weapon_info.move_speed,
					self.weapon_info.bullet_sprite,
					'bullet')
				shake_h(2)
			end

		end,
		update_sprite = function(self)
			local table = self.sprites.idle
			local speed = 8

			if self.state == 'running' then 
				table = self.sprites.running
				speed = self.move_speed*12
			end

			local n = flr(time()*speed%#table)+1
			self.c_sprite = table[n]
		end,
		draw_money = function(self)
			spe_print('$'..self.money, self.x-5, self.y-15, colors.green, colors.dark_green)
		end,
		draw_sprite = function(self)
			outline_spr(self.c_sprite, self.x+shkx-4, self.y+shky, self.look_to_left)
			spr(self.c_sprite, self.x+shkx-4, self.y+shky, 1, 1, self.look_to_left)
		end,
		player_sounds = function (self)
			if self.state == 'running' and self.grounded and self.timer.walk_sfx_timer < time() then
				sfx(3)
				self.timer.walk_sfx_timer = time() + self.move_speed/4
			end
		end,
		take_damage = function (self, damage)
			self.current_health -= damage
			if self.current_health < 0 then
				self.current_health = 0
			end
			sfx(5)
			whiteframe = true
		end,
		jump=function(self)
			self.grounded = false

			self.y -= 5
			
			self.dy = -4
			shake_v(1)
			sfx(0) 
			run_dust(self.x, self.y+13, 1)
			run_dust(self.x, self.y+13, -1)

		end,
		walk_particle = function(self)
			if rnd()>0.5 and self.grounded then dust_part(self.x+4, self.y+10, 3,{6, 5}) end

		end,
		do_physics=function(self)
			if self.y > ground_y then
				self.y = ground_y
				self.grounded = true 
				self.dy = 0 

			end
			-- do gravity
			if self.y <= ground_y and not is_player_on_a_platform() then
				self.dy += g
			else
				if not self.grounded then
					sfx(2)
				end
					if self.dy > 0 and is_player_on_a_platform() then
						self.grounded = true 
						self.dy = 0 
					end
			end
			
			self.y += self.dy
		end,
		draw_health_rect = function (self)
			local percentage = self.current_health/self.max_health
			local width, height = self.max_health*3, 2
			local bar_x, bar_y = self.x - self.max_health-2, self.y-4
			
			rect(bar_x-1, bar_y-1, bar_x + width + 1, bar_y + height,
				colors.black)
			draw_filled_rect(bar_x, bar_y, width, height, percentage, 
				colors.green, colors.dark_gray)
			
			for i=0, self.current_health do
				pset(bar_x+i*3, bar_y, colors.dark_green)
				pset(bar_x+i*3, bar_y+1, colors.dark_green)
				-- print(bar_x+width/i, 50, 50+i*10)
			end
			-- stop()
		end,
		update = function (self)
			self:player_sounds()
			self:move()
			self:update_sprite()
			self:do_physics()
		end,
		draw = function(self)
			self:draw_sprite()
			self:draw_health_rect()
			self:draw_money()
		end

	})
end

-- ##bullet
function make_bullet(x, y, direction, damage, backoff, move_speed, sprite, tag)
  local bullet = make_gameobject (x, y, tag, {
	damage=damage,
	move_speed=move_speed,
	sprite=sprite,
	range = 10,
	backoff = backoff,
	direction=direction,
	end_life_time = time()+3,
	out_of_screen = function (self)
		if (self.x <= map_limit_left_x or self.x >= map_limit_right_x) then
			-- sfx(4)
			self:destroy()
		end
	end,
	explode=function(self)
	  hit_part(self.x, self.y,{7, 6, 5})
	  -- if self.target:get_tag() !='player' then sfx(0) end
	end,
	destroy = function (self)
		self:explode()
		self:disable()
	end,
	enemy_collision_check = function (self)
		local enemy = closest_obj(self, 'enemy')
		if enemy != nil and distance(self, enemy) < self.range then
			-- sfx(1)            
			enemy:take_damage(self.damage)
			-- enemy backoff
			move_toward(enemy, {x=self.x, y=enemy.y}, -self.backoff)

			self:destroy()
		end
	end,
	check_end_life_time = function (self)
		if (self.end_life_time < time()) self:destroy()
	end,
	update=function(self)
		self:check_end_life_time()
		self:out_of_screen()
		self:enemy_collision_check()
		move_toward(self, self.direction, self.move_speed)

			-- backoff the target    
		-- move_toward(self.target, self, -self.backoff)
	end,
	draw=function(self)
		outline_spr(self.sprite, self.x+shkx, self.y+shky)
		spr(self.sprite, self.x+shkx, self.y+shky)
	end,
	reset=function(self)
	  self:enable()
	end
  })
  
end

function incubic2 (t, b, c, d, endval)
	c = endval - b
	t = t / d
	return c * (t^3) + b, endval - b
end

-- b is the value being ease
function move_incubic(t, b, c, endval)
	if b != endval then
		b, c = incubic2(t, b, c, d, endval)
	end
	return b,c
end

function move_toward(current, target, move_speed)
	if(move_speed == 0) then move_speed = 1 end

	local dist= distance(current, target)
	local direction_x = (target.x - current.x) / 60 * move_speed
	local direction_y = (target.y - current.y) / 60 * move_speed

	if(dist > 1) then
		current.x += direction_x / dist
		current.y += direction_y / dist
	end
	return current.x, y
end

function shake_camera(power)
	local shka=rnd(1)
	shkx+=power*cos(shka)
	shky+=power*sin(shka)
end

function shake_h(power)
	local shka=rnd(1)
	shkx+=power*cos(shka)
end

function shake_v(power)
	local shka=rnd(1)
	shky+=power*sin(shka)
end

function draw_filled_rect(x, y, width, height, pc, font_col, back_col, bordercol)
			-- draw_filled_rect(x, y, x+width, y+height, pourcentage_fill, colors.green, colors.black)
	height -= 1
	local length = (x+width) - x
	if bordercol then
		rectfill(x-1,y-1,x+width+1,y+height+1,bordercol)
	end
	if back_col then
		rectfill(x,y,x+width,y+height,back_col)
	end
	if pc > 0.001 then
	rectfill(x,y, x + length*pc,y+height,font_col)
end
end

function make_gameobject(x, y, tag, properties, draw_layer)
	local obj = {x = x, y= y, tag = tag, active = true,
		draw_layer = draw_layer or 0,
		get_tag = function(self)
			return self.tag
		end,
		draw = function(self)
		end,
		update = function (self)
		end
	}
	if properties != nil then
		for k, v in pairs(properties) do
			obj[k] = v
		end
	end
	add(gameobjects, obj)
	return obj
end

-- ##part
function add_part(x, y ,tpe, size, mage, dx, dy, colarr)

 local p = {
  x=x,
  y=y,
  tpe=tpe,
  dx=dx,
  dy=dy,
  move_speed=0,
  size=size,
  age=0,
  mage=mage,
  col=col,
  colarr=colarr,
  layer=0

 }

 add(part, p)
 return p
end

function draw_part()
	local part = part
	for p in all(part) do
		if p.tpe==0 then
			pset(p.x+shkx, p.y+shky, p.col)
		elseif p.tpe==1 then
			circfill(p.x+shkx,p.y+shky,p.size, p.col)
			p.size -= 0.1
		end
	end
end

function update_part()
	local part = part
	for p in all(part) do
		p.age+=1
		if p.mage != 0 and p.age >= p.mage or (p.size <= 0 and p.mage!=0) then
			del(part, p)
		end

		-- if p.colarr == nil then return end
		if #p.colarr == 1 then
			p.col = p.colarr[1]
		else
			local ci = p.age/p.mage
			ci = 1+flr(ci*#p.colarr)
			p.col = p.colarr[ci]
		end
		p.x+=p.dx
		p.y+=p.dy
	end
end

-- ##spe_print
function spe_print(text, x, y, col_in, col_out, bordercol)
	local outlinecol = 0
	if bordercol != nil then outlinecol = bordercol end
	if bordercol != 16 then
	col_in = col_in or colors.pink
	col_out = col_out or colors.dark_purple

	-- draw outline color.
	print(text, x-1, y, outlinecol) 
	print(text, x+1, y, outlinecol)
	print(text, x+1, y-1, outlinecol)
	print(text, x-1, y-1, outlinecol)
	print(text, x, y-1, outlinecol)
	print(text, x+1, y+1, outlinecol)
	print(text, x-1, y+1, outlinecol)
	print(text, x+1, y+2, outlinecol)
	print(text, x-1, y+2, outlinecol)
	print(text, x, y+2, outlinecol)
	end
	-- draw col_out.
	print(text,x, y+1, col_out)
	-- draw text.
	print(text,x, y, col_in)
end

function outline_spr(n, x, y, _flip_x, _flip_y, outline_color)
  local out_col = outline_color or 0
  local flip_x, flip_y = false, false
  if _flip_x then flip_x = _flip_x end
  if _flip_y then flip_y = _flip_y end

  local pal, spr = pal, spr
  for i=0, 15 do pal(i, out_col) end

  spr(n, x+1, y, 1, 1, flip_x, flip_y)
  spr(n, x-1, y, 1, 1, flip_x, flip_y)
  spr(n, x, y+1, 1, 1, flip_x, flip_y)
  spr(n, x, y-1, 1, 1, flip_x, flip_y)
  pal()
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
