pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

--you against you 
--by wombart
--made for 42jam#2

local p_info = {x = 64, y = 64, tag = 'player', max_health = 15, move_speed = 1, 
money = 10, sprites = {idle ={1, 2}, running = {17, 18, 18, 19, 20, 20}}, 
sounds = {running = 0}, weapon_info = {reload_time = 0, bullet_sprite = 49, 
	name = 'pistol', attack_speed = 0.5, move_speed = 500, damage = 1, 
	backoff = 1, collision_backoff = 10, max_ammo = 5}}

local map_limit_left_x, map_limit_right_x = 0, 126

local co_patern
local co_timer

local player
local bot
local heal_timer = 0

local part = {}
local g = 0.3
local debugmode = false
local ground_y = 80
local shkx, shky = 0, 0
local main_camera
local gameobjects = {}
local game_state = 'start'

local colors = {black = 0, dark_blue = 1, dark_purple = 2, dark_green = 3,
	brown = 4, dark_gray = 5, light_gray = 6, white = 7, red = 8, orange = 9,
	yellow = 10, green = 11, blue = 12, indigo = 13, pink = 14, peach = 15, no_color}

local ground_bridge = {x0 = -70, y0 = ground_y, x1 = 276, y1 = 128, width = 15, 
	height = 0, light_color = colors.white, dark_color = colors.white}

local platform1 = {x0=30, y0=55, x1=60, y1=65,
	light_color = colors.white, dark_color = colors.white}
-- local platform2 = {x0=130, y0=45, x1=160, y1=53, hitboxy=40,
-- 	light_color = colors.white, dark_color = colors.light_gray}

function _init()
	start()
end

function start()
	init_all_gameobject()
    music(0, 500, 3)
end

function _update60()
	if game_state == 'start' then
        update_start()
	elseif game_state == 'game' then
		update_game()
	elseif game_state == 'gameover' then
        update_victory()
	elseif game_state == 'victory' then
		update_victory()
	end
end

function _draw()
	if game_state == 'start' then
        draw_start()
	elseif game_state == 'game' then
		draw_game()
	elseif game_state == 'gameover' then
        draw_victory()
	elseif game_state == 'victory' then
		draw_victory()
	end

	if (debugmode) then
	-- if btnp(5) then spawner.wave_number += 1 end
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

function update_start()
 if btn(5) then game_state = 'game' end
 -- update_all_gameobject()
 update_part()
 draw_bg_decors()
end

function draw_start()
    cls(0)
    draw_part()
-- function spe_print(text, x, y, col_in, col_out, bordercol)

    spe_print('you against you', 30, 32+cos(time()/3%1)*5, 
        colors.white, colors.blue)
    if time()%1 > 0.5 then spe_print('press ❎', 45, 64, 6, 7) end
    spe_print('by wombart', 45, 120, 9, 10)

    local offsetx, offsety = 50, -30

    -- spe_print('c to shoot', 55- offsetx, 70-offsety, 1, 12)
    -- spe_print('⬆️', 87  - offsetx,  60-offsety, 1, 12)
    -- spe_print('⬅️ ⬇️ ➡️ ',  75 - offsetx, 70-offsety, 1, 12)
end



function update_game()
	update_all_gameobject()
	do_camera_shake()
	update_part()
	block_object_map_limit()
    spawn_heal()
    -- if (btn(4)) then slow_motion(200) end
end

function draw_game()

	-- cls(((time()/2%15))+1)
	draw_background()
    whiteframe_update()
	draw_bg_decors()

	draw_part()
	draw_map()
	draw_all_gameobject()
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
	for p in all(part) do
		if (p.tpe == 3) circfill(p.x+shkx, p.y+shky, p.size, p.col)
	end

end

function draw_map()
	-- -- outline 
	-- rect(shkx+ground_bridge.x0-1, shky+ground_bridge.y0-1,
	-- 	shkx+ground_bridge.x1+1, shky+ground_bridge.y1+ground_bridge.height+1, 
	-- 	colors.black)

	-- -- light part
	-- rectfill(shkx+ground_bridge.x0,shky+ground_bridge.y0,shkx+ground_bridge.x1,
	-- 	shky+ground_bridge.y0, ground_bridge.light_color)

	-- dark part
	-- rectfill(shkx+ground_bridge.x0, shky+ground_bridge.y0 + 8,
	-- 	shkx+ground_bridge.x1,shky+ground_bridge.y1, ground_bridge.dark_color)
	-- platform 1
	map(0, 0, 0 + shkx, 0 + shky, 16, 16)
	-- spr(9, shkx+platform1.x0, shky+platform1.y1)
	-- rectfill(shkx+platform1.x0, shky+platform1.y0+9, shkx+platform1.x1,
	-- 	shky+platform1.y1+7, platform1.dark_color)
end

function update_victory()
 if btn(5) then run() end
 update_all_gameobject()
end

function draw_victory()
	cls(0)
	draw_game()
	if do_once == false then 
		do_once=true
	end
    if (game_state == 'victory') then
        print('you won !!!', 40 , main_camera.y-50-2*(cos(time())), 11, 3)
        print('❎ to restart', 40, main_camera.y, 10, 9)
    else
        print('you lost !!!', 40 , main_camera.y-50-2*(cos(time())), 11, 3)
        print('❎ to restart', 40, main_camera.y, 10, 9)
    end
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
	cls(colors.black)
end

function draw_interface()
	-- spe_print("wave "..spawner.wave_number,  main_camera.x, 4, colors.red, colors.dark_purple)
end

-- ##init
function init_all_gameobject()
	bot = make_character(true, 100, 65, 'bot', 'player')
	player = make_character(false, 20, 65, 'player', 'bot')
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

function is_player_on_a_platform(x, y)
	local collision = false
	if (fget(mget(x/8,y/8), 0)) then
		collision = true
	end
	return (collision)
	-- return (player.x >= platform1.x0 - 4 and player.x <= platform1.x1 + 4
	-- 	and (player.y > platform1.y0 and player.y < platform1.y1 + 1))
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
		rectfill(-100,-100, 200, 200, colors.white)
		whiteframe = false
	end
end



-- ##player
function make_character(is_bot, x, y, tag, target_tag)
	local obj = make_gameobject(x, y, tag, {
		is_bot = is_bot,
		target_tag = target_tag,
		current_health = p_info.max_health,
		max_health = p_info.max_health,
		c_sprite=1,
		dx=0,
		dy=1, 
		level = 1,
        meteor_reload_time = 0,
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
		bot_i = {state = 'loading', run_range = 8000, next_shoot = 2, freeze_d = 0, direction = -1, next_jump = 0.2},
		bot_state = 'loading',
		sfx_playing = false,
		look_to_left = true,
		grounded = true,
		timer = {walk_sfx_timer = 0},
		sounds = p_info.sounds,
		sprites = p_info.sprites,
		experience=0,
		move_speed = p_info.move_speed,
        summon_meteorites = function (self)
            if (self.meteor_reload_time > time()) then
                return
            end
            self.meteor_reload_time = time() + 2
            local d = 1
            for var=0, 0, 1 do
                if self.look_to_left then d = -1 end
                summon_meteorites(self.x + (10 + var * 5) * d, 0)
            end
        end,
		shoot = function(self, _x, _y)
			if self.weapon_info.reload_time < time() then
				local looking_direction = 1
				-- sfx(20 + flr(rnd(2)))
				if (self.look_to_left) looking_direction = -1
					make_muzzle_flash(self.x+6*looking_direction, self.y+4, 6, colors.white, 0.025)

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
					'bullet', target_tag)
				shake_h(1)
			end

		end,
		player_controller = function(self)
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
            -- if btn(5) then
            --     self:summon_meteorites()
            -- end
		end,
		bot_freeze_brain = function (self, duration)
			if self.bot_i.freeze_d <= time() then
				self.bot_i.freeze_d = time() + duration
			end
			return self.bot_i.freeze_d
		end,
		bot_debug = function(self)
			circ(self.x, self.y, self.bot_i.run_range, colors.red)
            local d = 1
            if self.look_to_left then d = -1 end
            -- rectfill(self.x,self.y, 128* d,  self.y + 10, colors.white)
            -- print(3, self.x, self.y - 30, colors.white)
		end,
		bot_controller = function(self)
			local dist = distance(self, player)

			-- shooting
			if ((abs(player.y - self.y) < 10) 
                and self.bot_i.next_shoot < time()) then

                if (player.x < self.x) then 
                self.look_to_left = true
                self.bot_i.direction = -1
                else
                    self.look_to_left = false
                    self.bot_i.direction = 1
                end
			
            	self.bot_i.next_shoot = 0.5 + time()
				self:shoot(self.x+200, self.y)
				self.weapon_info.reload_time = 0.25
			end

			if (self.bot_i.freeze_d < time()) then
				-- move randomly
				if (dist < self.bot_i.run_range) then
					if (self.x > 64 + rnd(20)) then
						self.bot_i.direction = -1
						self.look_to_left = true
					elseif (self.x < 64 + rnd(20)) then
						self.bot_i.direction = 1
						self.look_to_left = false
					end
				end

				-- jump
				if ((player.y == self.y or (abs(player.y - self.y) > 10 and player.y < self.y)) 
                    and self.bot_i.next_jump < time() and self.grounded) then
					self.bot_i.next_jump = rnd(3) + time()
					self:jump()
				end
			end
			self.x += self.move_speed * self.bot_i.direction
			self.state = 'running'
			self.bot_state = 'moving'
			self:bot_freeze_brain(rnd(1))
		end,
		update_sprite = function(self)
			local table = self.sprites.idle
			local speed = 6

			if self.state == 'running' then 
				table = self.sprites.running
				speed = self.move_speed*16
			end

			local n = flr(time()*speed%#table)+1
			self.c_sprite = table[n]
		end,
		am_i_dead = function(self)
			if (self.current_health <= 0) then
				self.current_health = 0
				self:death_event()
			end
			return true
		end,
		death_event = function(self)
			if (self.is_bot) then
				hit_part(self.x, self.y, {7, 6, 5})
				game_state = 'victory'
			else
				game_state = 'gameover'
			end
			dust_part(self.x, self.y, 5+3, {colors.red}, 4)
			dust_part(self.x+3, self.y, 5, {colors.dark_purple}, 4)
			dust_part(self.x-3, self.y, 5, {colors.dark_blue}, 4)
			self.sprites = {idle = {6}, running = {6}}
			self:disable()
		end,
		draw_sprite = function(self)
			-- outline_spr(self.c_sprite, self.x+shkx-4, self.y+shky, self.look_to_left, colors.white)
			if (self.is_bot) then
				pal(colors.blue, colors.red)
				pal(colors.dark_blue, colors.dark_purple)
				spr(self.c_sprite, self.x+shkx-4, self.y+shky, 1, 1, self.look_to_left)
				pal()
			else
				spr(self.c_sprite, self.x+shkx-4, self.y+shky, 1, 1, self.look_to_left)
			end
			if not (self.is_bot) then
				spr(8, self.x-4, self.y - 14)
			end
		end,
		player_sounds = function (self)
			if self.state == 'running' and self.grounded and self.timer.walk_sfx_timer < time() then
				sfx(3)
				self.timer.walk_sfx_timer = time() + self.move_speed/4
			end
		end,
		take_damage = function (self, damage, direction)
			local d = direction or 1
			self.current_health -= damage
			if self.current_health < 0 then
				self.current_health = 0
			end
			local colarr = {colors.blue, colors.dark_blue} 
			local colarr2 = {colors.dark_blue} 
			if (self.is_bot) then
				colarr = {colors.red, colors.dark_purple}
				colarr2 = {colors.dark_purple}
			end
			add_blood_part(self.x, self.y, d, colarr, colarr2)
            sfx(5)
            slow_motion(200)
            shake_camera(5)
			-- whiteframe = true
		end,
		jump=function(self)
			self.grounded = false

			self.y -= 5
			
			self.dy = -4
			-- shake_v(0.5)
			sfx(0)
			run_dust(self.x, self.y+13, 1)
			run_dust(self.x, self.y+13, -1)

		end,
		walk_particle = function(self)
			if self.state == 'running' and rnd()>0.5 and
			self.grounded then 
				dust_part(self.x+4, self.y+10, 2,{colors.white, colors.light_gray, colors.dark_gray, colors.dark_blue}) 
			end
		end,
		do_physics=function(self)
			if self.y > ground_y then
				self.y = ground_y
				self.grounded = true 
				self.dy = 0 

			end
			-- do gravity
			if self.y <= ground_y and is_player_on_a_platform(self.x, self.y + 8) == false then
				self.dy += g
			else
				if not self.grounded then
					sfx(2)
				end
					if self.dy > 0 then
						self.grounded = true 
						self.dy = 0 
					end
			end
			self.y += self.dy
		end,
		draw_health_rect = function (self)
			local pourcentage_fill = self.current_health / self.max_health
            draw_filled_rect(self.x - 4, self.y - 4, 8, 2, 
                pourcentage_fill, colors.green, colors.red)
            if (self.is_bot) then
                draw_filled_rect(80, 100, 15, 16, 
                    pourcentage_fill, colors.green, colors.dark_gray, false, true)
                spr(70, 80, 100, 2, 2)
            else
                draw_filled_rect(32, 100, 15, 16, 
                    pourcentage_fill, colors.green, colors.dark_gray, false, true)
                spr(68, 32, 100, 2, 2)
            end
            -- function draw_filled_rect(x, y, width, height, pc,
             -- font_col, back_col, bordercol)

			-- spe_print(self.current_health, self.x-3, self.y - 10,
             -- colors.green, colors.dark_green)
		end,
		update = function (self)
			self:player_sounds()
			if (self.is_bot == true) then
				self:bot_controller()
			else
				self:player_controller()
			end
			if (self.active) then
				self:am_i_dead()
				self:update_sprite()
				self:walk_particle()
			end
			self:do_physics()
		end,
		draw = function(self)
			self:draw_sprite()
			if (self.is_bot) then
				self:bot_debug()
			-- 	print(self.bot_state, self.x - 8, self.y - 10, colors.yellow)
			end
			if (self.active) then
				-- self:draw_health_rect()
				self:draw_health_rect()
			end
		end

	})
    return obj
end

function spawn_heal()
    if (heal_timer < time()) then
        local r = flr(rnd(3))
        if r == 0 then
            add_heal(60, 42)
        elseif r == 1 then
            add_heal(16, 50)
        else
            add_heal(104, 50)
        end        
    end
end
-- #here
function add_heal(x, y)
    local obj = make_gameobject(x, y, 'heal', {
        heal_amount = 4,
        collision_check = function(self)
            if (distance(self, player) < 10) then
                player.current_health += self.heal_amount
                if (player.current_health > player.max_health) then 
                    player.current_health = player.max_health
                end
            elseif (distance(self, bot) < 10) then
                bot.current_health += self.heal_amount
                if (bot.current_health > bot.max_health) then 
                    bot.current_health = bot.max_health
                end
            else
                return
            end
            sfx(6)
            self:destroy()
        end,
        destroy = function(self)
            heal_timer = time() + 2 + rnd(5)
            hit_part2(self.x, self.y, 3, 20, {colors.green, colors.dark_green})
            self:disable()
        end,
        update = function(self)
            self:collision_check()
            if self.active then
                heal_timer = time() + 1
            end
            if (rnd(1) > 0.8) then
            add_part(self.x+4+rnd(6)-rnd(6), self.y+7+rnd(3)-rnd(3), 2, rnd(2), rnd(50)+10, 0, -rnd(1), 
            {colors.green, colors.dark_green})
            end
        end,
        draw = function(self)
            -- outline_spr(24, x + shkx, (y + shky) - 3 * (cos(time())),
            --  false, false, colors.yellow)
            spr(24, x + shkx, (y + shky) - 3 * (cos(time())))
        -- endfunction outline_spr(n, x, y, _flip_x, _flip_y, outline_color

        end

        })
    add(gameobjects, obj)
    return obj
end

function make_muzzle_flash(x, y, radius, muzzle_color, duration)
	muzzle_color = muzzle_color or colors.white
	duration = duration or 0.025
	make_gameobject(x, y, 'muzzle_flash', {
		radius = radius,
		draw_layer = 1,
		muzzle_color = muzzle_color,
		death_time = time()+duration,
		update = function(self)
			if (self.death_time < time()) self:disable() 
		end,
		draw = function(self)
			circfill(self.x, self.y, self.radius, self.muzzle_color)
		end
		})
end

-- ##bullet
function make_bullet(x, y, direction, damage, backoff, move_speed, sprite, tag, target_tag)
  local bullet = make_gameobject (x, y, tag, {
	damage=damage,
	move_speed=move_speed,
	sprite=sprite,
	target_tag = target_tag,
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
	  -- hit_part(self.x, self.y,{7, 6, 5})
	  dust_part(self.x, self.y, 4 + rnd(3), {colors.yellow, colors.orange
        , colors.dark_purple, colors.dark_blue}, 6 + rnd(4), 60)
	  -- if self.target:get_tag() !='player' then sfx(0) end
	end,
	destroy = function (self)
		self:explode()
		self:disable()
	end,
	enemy_collision_check = function (self)
		local enemy = closest_obj(self, self.target_tag)
		if enemy != nil and distance(self, enemy) < self.range then
			-- sfx(1)
			local d = 1
			if enemy.x < self.x then d = -1 end
			enemy:take_damage(self.damage, d)
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
		-- outline_spr(self.sprite, self.x+shkx, self.y+shky)
		spr(self.sprite, self.x+shkx, self.y+shky)
		-- rectfill(self.x-5, self.y-2, self.x+5, self.y+2, colors.white)
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

function draw_filled_rect(x, y, width, height, pc, font_col, back_col, bordercol, v)
    local vertical = v or false
			-- draw_filled_rect(x, y, x+width, y+height, pourcentage_fill, colors.green, colors.black)
    height -= 1
    if bordercol then
    	rectfill(x-1,y-1,x+width+1,y+height+1,bordercol)
    end
    if back_col then
    	rectfill(x,y,x+width,y+height,back_col)
    end
    if pc > 0.001 then
        if vertical then
            rectfill(x, y + (height * (1 - pc)), x + width, y+height, font_col)
        else
            rectfill(x, y, x + width*pc, y+height, font_col)
        end
    end

end

function make_gameobject(x, y, tag, properties, draw_layer)
	local obj = {x = x, y= y, tag = tag, active = true,
		draw_layer = draw_layer or 0,
		get_tag = function(self)
			return self.tag
		end,
		disable = function(self)
			self.active = false
			del(gameobjects, self)
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

function slow_motion(len)
    for i=0, len do
    add_part(200, 2, 2, 1, 0.1, 0, 2, 
            {0})
    end
end

function draw_bg_decors()
    if (rnd(1) > 0.9) then
	local speed = -1 + -rnd(3)
	add_part(rnd(128), 128, 2, rnd(5), 200, 0, speed, 
			{colors.dark_blue})
    end
	-- for i=0, 2, 1 do
	-- 	add_part(rnd(128), 128, 2, rnd(3), rnd(20) + 0, rnd(2) - rnd(2), -rnd(1), 
	-- 		{colors.yellow, colors.orange, colors.red, colors.dark_purple, colors.dark_blue})
	-- end

end

function summon_meteor_main()
    if costatus(co_patern) != 'dead' then 
        coresume(co_patern) 
        co_timer = time() + 3
        return
    end

end

function do_meteor_pattern(n)
end

function meteor_pattern()
    for i=0, 10 do
        make_obstacle(x, y, 23, 1)
        yield()
    end
end

-- todo
function summon_meteorites(x, y, target_tag)
    make_obstacle(x, y, 23, 1)
end

function make_obstacle(x, y, sprite,speed)
 sfx(2)
 local obj = make_gameobject(x, y, 'obstacle', {
  f_speed=speed,
  speed=speed,
  sprite=sprite,
  destroy=function(self)
   self.speed = self.f_speed
   hit_part2(self.x, self.y-4, 5,6,{8,2})
   shake_camera(1)
   sfx(1)
   self:disable()
  end,
  draw=function(self)
   -- circfill(self.x,self.y, 5, 8)
   if rnd() > 0.5 then hit_part2(self.x+4, self.y, 3, 0,{8, 2}) end
   -- line(self.x+3,self.y,self.x+3, 128, 8)
   -- line(self.x+4,self.y,self.x+4, 128, 8)
   -- line(self.x+5,self.y,self.x+128, 128, 8)
   -- rectfill(self.x, self.y+4, 129, 128, 8)
   -- li
   -- outline_spr(self.sprite, self.x ,self.y)
   spr(self.sprite, self.x, self.y)
  end,
  update=function(self)
   self.x += self.speed
   self.y += self.speed
   self.speed+= g/6
   if is_player_on_a_platform(self.x, self.y) or self.y > 120 then self:destroy()
   elseif distance(self, player) < 5 then
        player:take_damage(2)
   elseif distance(self, bot) < 5 then
        bot:take_damage(2)
   end
  end
  })
 obj.speed, obj.f_speed = speed, speed 
 return obj
end

function hit_part2(x,y, size, quantity,colarr)
  for i=0, quantity do
  local p add_part(rnd(5)-rnd(5)+x, rnd(5)-rnd(5)+y, 1, rnd(size)+size-1, rnd(5)+35, (rnd(10)-rnd(10))/30, (rnd(10)-rnd(10))/30, colarr)
 end
end

-- ##part
function add_part(x, y ,tpe, size, mage, dx, dy, colarr, layer)
 local l = layer or 0
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
  layer=l

 }

 add(part, p)
 return p
end
function hit_part(x,y, size, quantity,colarr)
  for i=0, quantity do
  local p add_part(rnd(5)-rnd(5)+x, rnd(5)-rnd(5)+y, 1, rnd(size)+size-1, rnd(5)+35, (rnd(10)-rnd(10))/30, (rnd(10)-rnd(10))/30, colarr)
 end
end
function draw_part()
	local part = part
	for p in all(part) do
		if p.tpe==0 then
			pset(p.x+shkx, p.y+shky, p.col)
		elseif p.tpe==1 then
			circfill(p.x+shkx,p.y+shky,p.size, p.col)
			p.size -= 0.1
		elseif p.tpe == 2 then
			circfill(p.x+shkx, p.y+shky, p.size, p.col)
		elseif p.tpe == 3 then
			circfill(p.x+shkx, p.y+shky, p.size, p.col)
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
		-- if (p.tpe != 3 or ((p.tpe == 3 and p.y < ground_y+8))) then
		if (p.tpe != 3 or ((p.size < 3 and p.y < ground_y+8) 
			or (p.size > 3 and is_player_on_a_platform(p.x, p.y+16)))) then
		-- if (p.tpe != 3 or ((p.tpe == 3 and ((p.size < 3 and p.y < ground_y+8)
		--  or is_player_on_a_platform(p.x, p.y+16))))) then
			p.x+=p.dx
			p.y+=p.dy
		end
		if (p.tpe == 3 and p.size >= 3) then
			p.y+=p.dy/(10 + p.age)
		end
	end
end
function dust_part(x, y, size, colarr, number, mage)
	local number = number or 1
    local _mage = mage or 35
	for i=0, number, 1 do
		add_part(rnd(5)-rnd(5)+x, rnd(5)-rnd(5)+y,
		 1, rnd(size)+size-1, rnd(5)+_mage, (rnd(10)-rnd(10))/30, (rnd(10)-rnd(10))/30, colarr)
	end  
end

-- function add_part(x, y ,tpe, size, mage, dx, dy, colarr, layer)

function add_blood_part(x, y, direction, colarr, colarr2)
	local n = rnd(30) + 15
	for i=0, n, 1 do
		add_part(rnd(5)-rnd(5)+x, rnd(5)-rnd(5)+y, 3,
		 rnd(2) + 0.1, rnd(5)+200, (rnd(10) + 5) * direction, rnd(10), colarr, 1)
		-- add_part(rnd(5)-rnd(5)+x, rnd(5)-rnd(5)+y, 3,
		--  rnd(15) + 0.1, rnd(5)+50, (rnd(10) + 5) * direction, rnd(10), colarr2, 1)
	end  
end

function hit_part(x, y, colarr) 
	add_part(rnd(5)-rnd(5)+x, rnd(5)-rnd(5)+y, 1, rnd(1)+4-1, rnd(5)+35, (rnd(10)-rnd(10))/30, (rnd(10)-rnd(10))/30, colarr)
end

function run_dust(x, y, _dir)
 for i=0, rnd(6)+4 do
  local p add_part(rnd(5)-rnd(5)+x, rnd(5)-rnd(5)+y, 1, rnd(4)+2 -1, rnd(5)+35, 
  	(-rnd(40)/60)*_dir, (-rnd(20))/60, {colors.white, colors.light_gray, colors.dark_gray, colors.dark_blue})
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
00000000000000000000000000000000000000000000000000000000000000000000000066666666555555550066666666666600666666666666666600000000
00000000000700000000000000070000000000000000000000666600067000000000000077777767777776570677776667777760777777677677777700000000
0070070000ccc0000007000000888000000000000000000006665660066700000000000077777767667777576777776777777766777777677677777700000000
000770000c1c100000ccc00008282000000000000000000006655560006670000000000066666666555555556666666666666666666666666666666600000000
000770000a010a000c1c10000a020a000000000000000000086656600006679000aaaaa076777777757777677677777776777777067777777777776000000000
00700700000c00000a0c0a000008000000000000000000000666568000006900009aaa9076777777757776777677777776777777007777777777770000000000
0000000000c0c00000c0c00000808000000000000000000006885660000090900009a90066666666555555556666666666666666000666666666600000000000
0000000000a0a00000a0a00000a0a000000000000000000008885880000000000000900077777677766775767777767777777677000006777760000000000000
00000000000000000000700000000000000000000000000000000000aaaa00000000000000000000000000000055555555555500000000000000000000000000
000000000007000000cccc0000000000000070000000000000000000aaa99800000bb00000000000000000000777765777777650000000000000000000000000
0000000000ccc0000a01c1000a00700000cccc000000000000000000aa988440000bb00000000000000000006677775766777757000000000000000000000000
000000000c1c100000001a0000cccc000a01c1a00000000000000000a98844400bbbbbb000000000000000005555555555555555000000000000000000000000
000000000a010a000000c0000001c100000010000000000000000000088444200bbbbbb000000000000000007577776775777767000000000000000000000000
00000000000c0000000c0c00000010000000c000000000000000000002444220033bb33000000000000000007577767775777677000000000000000000000000
0000000000c0c00000a0a0000000c000000c0c00000000000000000000222200000bb00000000000000000005555555555555555000000000000000000000000
0000000000a0a00000000000000c0c0000ac0a000000000000000000000000000003300000000000000000007667757676677576000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700777777007777770000000000000000000000000000000000777777004449990099999900000000000000000000000000000000000000000
00777700777777777777777777777777000000000000000000000000007777707777777704667790097777900000000000000000000000000000000000000000
07777770777777777777777777777777000000000000000000000000077777777777777704667790097777900000000000000000000000000000000000000000
07777770777777777777777777777777000000000000000000000000077777777777777704667790046776400000000000000000000000000000000000000000
00777700077777770777777007777777000000000000000000000000007777700777777000467900004664000000000000000000000000000000000000000000
00000000077777700000000007777770000000000000000000000000000000000000000000049000000440000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003800000003800000380000033000000000077000000000000077000000000000000000000000000000000000000000000000000000000000000000000000
00003800000003300000380000038000000000777000000000000077700000000000000000000000000000000000000000000000000000000000000000000000
00330000000330000003000003300000000000777000000000000077700000000000000000000000000000000000000000000000000000000000000000000000
03033000000333300033000030330000000000c77000000000000077800000000000000000000000000000000000000000000000000000000000000000000000
000300000000300000033000003000000000ccccccc0000000008888888000000000000000000000000000000000000000000000000000000000000000000000
00303300000033000003300000330000000ccccccccc000000088888888800000000000000000000000000000000000000000000000000000000000000000000
03000300000330300003300003030000000ccccccccc000000088888888800000000000000000000000000000000000000000000000000000000000000000000
0000000000000030000030000300000000000ccccc00000000000888880000000000000000000000000000000000000000000000000000000000000000000000
99999999000000000000000000000000000001ccc100000000000288820000000000000000000000000000000000000000000000000000000000000000000000
99979797999999990000000099999999000000111000000000000022200000000000000000000000000000000000000000000000000000000000000000000000
99999999999797970000000099979797000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999990999999999999999999999999007070777070700000707077707070000000000000000000000000000000000000000000000000000000000000000000
00000000099999909997979709999990007070707070700000707070707070000000000000000000000000000000000000000000000000000000000000000000
00099000000000009999999900000000000700707070700000070070707070000000000000000000000000000000000000000000000000000000000000000000
99000000009909900999999000000000000700777077700000070077707770000000000000000000000000000000000000000000000000000000000000000000
00000000000000000009909999099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08777880007777000077770008877780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08777880077888700788877008877780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770077888700788877007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770077777700777777007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770077777700777777007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000c0000000800000007000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000cccc00008888000077770000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000cc111c0088222800776667000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000c1cc110082882200767766000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c1cccc10828888207677776000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c1c1cc1c828288287676776700000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c1cc1c1c828828287677676700000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c1cc1c1c828828287677676700000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c1cc1c1c828828287677676700000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c1c11c1c828228287676676700000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000c11cccc0822888807667777000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000c11c1c0082282800766767000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000ccc1cc0088828800777677000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000ccc000008880000077700000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000101010101010000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000b090909090c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001b0a1c00000000000000001b0a1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d09090909090909090909090909090e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0909090909090909090909090e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000d090909090909090909090e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000067400b7400f74014740187001a70020700247002c7002d70000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01010000336202e6202962027620226201f6201d6201b62016620136200f6200a6200a62005620036200362009600086000060000600006000060000600006000060000600006000060000600006000060000600
010100000000000000010400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000027400070004700007000870000700007000b740007000b70000700007000070006700007000070000700007000070033700007000470001700067000070000700007000070000700007000b7000f700
010100000000000000000000000012640106400904006040030400104001040010400104001040010400104000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003f650366402f6302b63026630236301f6201d6201c6201a6201822014220112200e2200c2200b22009210082100721003210032100221001210002000020001200012000a20007200072000520003200
01040000053430734308343093430a3430b3430c3430d3430e343103431234313343143431534317343193431b3431c3431f34321343233432434327343283432b3432d3432f3433234332343353433734339343
010100000144001400014000140001400014000140010600101001020010300106001010010200103001060010100102001030010600101001020010300106001010010200103001060010100102001030010600
010400003d64339643376433464332643306432e6432b6432a6432864326643256432364322643206431f6431d6431c6431a6431864317643156431464312643116430f6430d6430b64309643076430564302643
010200001b3130f013276131c61018610006100761007610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000036153321532f1532d1532a15327153241532315322153211531e1531e1531c1531b1531a1531a15318153171531615314153101530f1530d1530c1530e1530c1530b1530915307153071530515304153
010300003963339623396133961301013010130101308003070030600304003040030300303003020030200302003020030200301003000030000300003000030000300003000030000300003000030000300003
000200000c475152740f474186651646515264114540e6550d4550b24408445066440443502234014340062500424002240041500615000040000400004000040000400004000040000400004000040000400004
0002000012055112550f0450e2450d0450c2450b0350a235090350823507025062250502504225030150221501015012150400503205010050760506605066050560504605046050360502605016050160501605
01020000010541325514045142451203515235110351622510025172250e0250a2250702508225050250621503015042150400503205010050760506605066050560504605046050360502605016050160501605
010300000c343236450933520621063111b6110431116611023110f611013110a6110361104600036000260001600016000460003600026000160001600016000160004600036000260001600016000160001600
010200000c043236450903520621060111b6110401116611020110f611010110a6110361104100036000260001600016000460003600026000160001600016000160004600036000260001600016000160001600
010200000c343236450933520621063111b6110431116611023110f611013110a6110361104600036000260001600016000460003600026000160001600016000160004600036000260001600016000160001600
000500001235311353103530f3530e3530e3530d3530d3430c3430c3430b3430b3430a3430a343093330933308333083330733307333063330632305323053230432304323033230332302313023130131301313
0005000011574160741357418074155641a064165641b054185541d0541a7541f5441b044217441d544220441f744245342103426734220242772424014297140070400704007040070400704007040070400704
010200003d620346202c620236201a620056202a60027600246001960021600176001d600006001a6000060015600166001360000600006000060000600006000060000600006000060000600006000060000600
00010000336302e6302963027630226301f6301d6301b63016630136300f6300a6300a63005630036300363009600086000060000600006000060000600006000060000600006000060000600006000060000600
01010000166301e6302963027630226301f6301d6301b63016630136300f6300a6300a60005600036000360009600086000060000600006000060000600006000060000600006000060000600006000060000600
01190020071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155051550c155081550c155051550c155081550c155051550c155081550c155051550c137081550c155
00180020010630170000000010631f633000000000000000010630000000000000001f633000000000000000010630000000000010631f633000000000000000010630000001063000001f633000000000000000
01180020071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155081550f1370c1550f155
011800201305015050160501605016050160551305015050160501605016050160551605015050160501a05018050160501805018050180501805018050180550000000000000000000000000000000000000000
011800201305015050160501605016050160551305015050160501605016050160551605015050160501a0501b0501b0501b0501b0501b0501b0501b0501b0550000000000000000000000000000000000000000
011800202271024710267102671026710267152271024710267102671026710267152671024710267102971027710267102471024710247102471024710247150000000000000000000000000000000000000000
01180020227102471026710267102671026715227102471026710267102671026715267102471026710297102b7102b7102b7102b7102b7102b7102b7102b7150000000000000000000000000000000000000000
01180020081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155071550e1370a1550e155
011800201b1301a1301b1301b1301b1301b1351b1301a1301b1301b1301b1301b1351b1301a1301b1301f1301a130181301613016130161301613016130161350000000000000000000000000000000000000000
01180020081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155081550f1550c1550f1550a155111550e155111550a155111550e155111550a155111550e155111550a155111550e15511155
011800201b1301a1301b1301b1301b1301b1351b1301a1301b1301b1301b1301b1351b1301a1301b1301f1301d1301d1301d1301d1301d1301d1301d1301d1350000000000000000000000000000000000000000
011800202b720297202b7202b7202b7202b7252b720297202b7202b7202b7202b7252b720297202b7202e72029720277202672026720267202672026720267250000000000000000000000000000000000000000
011800202b720297202b7202b7202b7202b7252b720297202b7202b7202b7202b7252b720297202b7202e7202e7202e7202e7202e7202e7202e7202e7202e7250000000000000000000000000000000000000000
__music__
01 17454318
00 19424318
00 171a4344
00 191b4344
00 171a1c18
00 191b1d18
00 1e1f4344
00 20214344
00 1e1f2218
02 20212318

