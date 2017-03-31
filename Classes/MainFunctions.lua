ClassCustomAchievement = ClassCustomAchievement or class()

ClassCustomAchievement.Directory = nil
ClassCustomAchievement.id_data = {}
ClassCustomAchievement.VERSION = 1 -- If the version changes, you need to update your mod in order.
ClassCustomAchievement.Directory = "mods/Custom Achievements Addons/"
ClassCustomAchievement.addons_path = "mods/Custom Achievements Addons/"

function ClassCustomAchievement:Load(id_achievement)

	self.id_data.data = id_achievement and {}

	if ClassCustomAchievement.Directory ~= nil then
		local file = io.open(ClassCustomAchievement.Directory .. id_achievement .. ".json", "r")

		if file then
			for k, v in pairs(json.custom_decode(file:read("*all")) or {}) do
				if k then
					self.id_data.data[k] = v
				end
			end
			file:close()
			--log("[CustomAchievement] Loaded Achievement data ID: " .. id_achievement)
		else
			log("[CustomAchievement] ERROR: Couldn't load the achievement " .. id_achievement .. ". Path is correctly set? The file exist? Current path: " .. ClassCustomAchievement.Directory .. id_achievement .. ".json")
		end
	else
		log("[CustomAchievement] ERROR: JSON path directory not set! Use ClassCustomAchievement:_set_json_directory(mod_name) first!!")
	end
end


function ClassCustomAchievement:Save(id_achievement)
	if ClassCustomAchievement.Directory ~= nil then
		local file = io.open( ClassCustomAchievement.Directory .. id_achievement .. ".json" , "w+")
		if file then
			file:write(json.custom_encode(self.id_data.data))
			file:close()
			--log("[CustomAchievement] Saved achievement data : " .. id_achievement)
		end
	else
		log("[CustomAchievement] ERROR: JSON path directory not set! Use ClassCustomAchievement:_set_json_directory(mod_name) first!!")
	end
end

function ClassCustomAchievement:Unlock(id_achievement) -- Once it's done, you unlock it
	self:Load(id_achievement)

	if self.id_data.data["unlocked"] ~= true then
		self:Reward()
		self.id_data.data["unlocked"] = true
	end

	if game_state_machine then
		if self.id_data.data["displayed"] == false then	
			local achievement_name = self.id_data.data["name"]
			local achievement_desc = self.id_data.data["objective"]

			--managers.mission:call_global_event(Message.OnSideJobComplete)
			managers.chat:achievement_unlocked_message(ChatManager.GAME, managers.localization:text("achievement_unlocked_chat"))
			managers.chat:achievement_unlocked_message(ChatManager.GAME, managers.localization:text(achievement_name))
			managers.chat:achievement_unlocked_message(ChatManager.GAME, managers.localization:text(achievement_desc))

			self.id_data.data["displayed"] = true
		end
	end

	self:Save(id_achievement)
end

function ClassCustomAchievement:Lock(id_achievement) -- Sometimes it's useful to lock achievements..
	self:Load(id_achievement)
	self.id_data.data["unlocked"] = false
	self.id_data.data["displayed"] = false
	self.id_data.data["number"] = 0
	self:Save(id_achievement)
end

function ClassCustomAchievement:Reward()
	-- Types supported: 
	-- cc (continental coins)
	-- money (spendable cash)

	if self.id_data.data then
		if self.id_data.data["reward_type"] and self.id_data.data["reward_amount"] then
			if self.id_data.data["unlocked"] == false then
				local json_reward_type = string.lower(self.id_data.data["reward_type"])
				local json_reward_amount = self.id_data.data["reward_amount"]

				if json_reward_amount < 0 then
					json_reward_amount = 0
				end

				if json_reward_type == "cc" then

					if json_reward_amount > 10 then
						json_reward_amount = 10
					end

					local current = Application:digest_value(managers.custom_safehouse._global.total)
					local future = current + json_reward_amount
					Global.custom_safehouse_manager.total = Application:digest_value(future, true)

				elseif json_reward_type == "money" then
					if json_reward_amount > 1000000 then
						json_reward_amount = 1000000
					end

					managers.money:_add_to_total(json_reward_amount, {no_offshore = true})

				elseif json_reward_type == "offshore" then

				elseif json_reward_type == "experience" then
					if json_reward_amount > 500000 then
						json_reward_amount = 500000
					end

					local current_level = managers.experience:current_level()
					local lv_div = 101 - current_level
					local real_xp = math.floor(json_reward_amount / lv_div)

					managers.experience:debug_add_points(real_xp, false)
				else
					log("[CustomAchievement] AVERT : No rewards or invalid type. Skipping reward")					
				end
			end
		else
			log("[CustomAchievement] AVERT : Cannot give rewards for the achievement " .. self.id_data.data["id"] .. ". You need to update your JSON file with 'reward_type' and 'reward_amount'. Skipping reward")
		end
	else
		log("[CustomAchievement] ERROR : No data loaded. Skipping reward")
	end
end

function ClassCustomAchievement:IncreaseCounter(id_achievement, amount) -- Increases "number" key in the json by amount. Useful of custom weapon kill counters and stuff.
	self:Load(id_achievement)

	if self.id_data.data["unlocked"] ~= true then -- No need to write 5000 things if already unlocked
		local original_number = self.id_data.data["number"]
		local new_number = original_number + amount
		self.id_data.data["number"] = new_number

		if self.id_data.data["number"] >= self.id_data.data["goal"] then
			self:Unlock(id_achievement)
		end
	end

	self:Save(id_achievement)
end

function ClassCustomAchievement:DecreaseCounter(id_achievement, amount, prevent_negative) -- Decreases "number" key in the json by amount.
	self:Load(id_achievement)

	if prevent_negative == true then
		if self.id_data.data["unlocked"] ~= true then -- No need to write 5000 things if already unlocked
			local calc = (self.id_data.data["number"]) - amount
			if calc > 0 then
				local original_number = self.id_data.data["number"]
				local new_number = original_number - amount
				self.id_data.data["number"] = new_number
			else
				self.id_data.data["number"] = 0
			end
		end
	else
		local original_number = self.id_data.data["number"]
		local new_number = original_number - amount
		self.id_data.data["number"] = new_number
	end

	ClassCustomAchievement:Save(id_achievement)
end

function ClassCustomAchievement:isHeistCompleted(id_achievement, id_level, id_diff)
	if game_state_machine then
		local required_level = id_level
		local required_difficulty = id_diff
		local current_level = managers.job:current_level_id()
		local current_diff = Global.game_settings.difficulty

		if required_level == current_level then
			if required_difficulty == current_diff then
				if managers.job:stage_success() then
					if managers.job:on_last_stage() then
						self:Unlock(id_achievement)
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isHeistCountCompleted(id_achievement, id_level, id_diff)
	if game_state_machine then
		local required_level = id_level
		local required_difficulty = id_diff
		local current_level = managers.job:current_level_id()
		local current_diff = Global.game_settings.difficulty

		if required_level == current_level then
			if required_difficulty == current_diff then
				if managers.job:stage_success() then
					if managers.job:on_last_stage() then
						self:IncreaseCounter(id_achievement, 1)

						if self.id_data.data["number"] >= self.id_data.data["goal"] then
							self:Unlock(id_achievement)
						end
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isDifficultyCompleted(id_achievement, id_diff)
	if game_state_machine then
		local required_difficulty = id_diff
		local current_diff = Global.game_settings.difficulty

		if required_difficulty == current_diff then
			if managers.job:stage_success() then
				if managers.job:on_last_stage() then
					self:Unlock(id_achievement)
				end
			end
		end
	end
end

function ClassCustomAchievement:isDifficultyCountCompleted(id_achievement, id_diff)
	if game_state_machine then
		local required_difficulty = id_diff
		local current_diff = Global.game_settings.difficulty

		if required_difficulty == current_diff then
			self:IncreaseCounter(id_achievement, 1)

			if self.id_data.data["number"] >= self.id_data.data["goal"] then
				self:Unlock(id_achievement)
			end
		end
	end
end

function ClassCustomAchievement:isPrimaryWeaponEquipped(id_achievement, id_weapon)
	local current_primary = managers.blackmarket:equipped_primary()
	local wanted_primary = id_weapon

	if current_primary and current_primary.weapon_id == wanted_primary then
		self:Unlock(id_achievement)
	end
end

function ClassCustomAchievement:isPrimaryWeaponCountEquipped(id_achievement, id_weapon)
	local current_primary = managers.blackmarket:equipped_primary()
	local wanted_primary = id_weapon

	if current_primary and current_primary.weapon_id == wanted_primary then
		self:IncreaseCounter(id_achievement, 1)
	end
end

function ClassCustomAchievement:isSecondaryWeaponEquipped(id_achievement, id_weapon)
	local current_secondary = managers.blackmarket:equipped_secondary()
	local wanted_secondary = id_weapon

	if current_secondary and current_secondary.weapon_id == wanted_secondary then
		self:Unlock(id_achievement)
	end
end

function ClassCustomAchievement:isSecondaryWeaponCountEquipped(id_achievement, id_weapon)
	local current_secondary = managers.blackmarket:equipped_secondary()
	local wanted_secondary = id_weapon

	if current_secondary and current_secondary.weapon_id == wanted_secondary then
		self:IncreaseCounter(id_achievement, 1)
	end
end

function ClassCustomAchievement:AddKillsByWeaponTotal(id_achievement, id_weapon)
	if game_state_machine then
		self:Load(id_achievement)

		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count then
			if current_weapon.name_id == id_weapon then
				if not self.id_data.data["unlocked"] then
					self.id_data.data["number"] = self.id_data.data["number"] + 1
					self:Save(id_achievement)

					if self.id_data.data["number"] >= self.id_data.data["goal"] then
						self:Unlock(id_achievement)
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isKillsFilledByWeaponSession(id_achievement, id_weapon)
	if game_state_machine then
		self:Load(id_achievement)

		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if current_weapon.name_id == id_weapon then
			if not self.id_data.data["unlocked"] then
				if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count >= self.id_data.data["goal"] then
					self:Unlock(id_achievement)
				end
			end
		end
	
	end
end

function ClassCustomAchievement:AddKillsByWeaponTotalOnMap(id_achievement, id_weapon, id_level)
	if game_state_machine then
		self:Load(id_achievement)

		local required_level = id_level
		local current_level = managers.job:current_level_id()
		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if current_level == required_level then
			if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count then
				if current_weapon.name_id == id_weapon then
					if not self.id_data.data["unlocked"] then
						self.id_data.data["number"] = self.id_data.data["number"] + 1
						self:Save(id_achievement)

						if self.id_data.data["number"] >= self.id_data.data["goal"] then
							self:Unlock(id_achievement)
						end
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isKillsFilledByWeaponSessionOnMap(id_achievement, id_weapon, id_level)
	if game_state_machine then
		self:Load(id_achievement)

		local required_level = id_level
		local current_level = managers.job:current_level_id()
		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if required_level == current_level then
			if current_weapon.name_id == id_weapon then
				if not self.id_data.data["unlocked"] then
					if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count >= self.id_data.data["goal"] then
						self:Unlock(id_achievement)
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:AddKillsByWeaponTotalOnDifficulty(id_achievement, id_weapon, id_diff)
	if game_state_machine then
		self:Load(id_achievement)

		local required_difficulty = id_diff
		local current_diff = Global.game_settings.difficulty
		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if current_diff == required_diff then
			if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count then
				if current_weapon.name_id == id_weapon then
					if not self.id_data.data["unlocked"] then
						self.id_data.data["number"] = self.id_data.data["number"] + 1
						self:Save(id_achievement)

						if self.id_data.data["number"] >= self.id_data.data["goal"] then
							self:Unlock(id_achievement)
						end
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isKillsFilledByWeaponSessionOnDifficulty(id_achievement, id_weapon, id_diff)
	if game_state_machine then
		self:Load(id_achievement)

		local required_difficulty = id_diff
		local current_diff = Global.game_settings.difficulty
		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if required_difficulty == current_diff then
			if current_weapon.name_id == id_weapon then
				if not self.id_data.data["unlocked"] then
					if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count >= self.id_data.data["goal"] then
						self:Unlock(id_achievement)
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:AddKillsByWeaponTotalOnMapAndDifficulty(id_achievement, id_weapon, id_level, id_diff)
	if game_state_machine then
		self:Load(id_achievement)

		local required_level = id_level
		local current_level = managers.job:current_level_id()
		local required_difficulty = id_diff
		local current_diff = Global.game_settings.difficulty
		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if current_level == required_level then
			if current_diff == required_diff then
				if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count then
					if current_weapon.name_id == id_weapon then
						if not self.id_data.data["unlocked"] then
							self.id_data.data["number"] = self.id_data.data["number"] + 1
							self:Save(id_achievement)

							if self.id_data.data["number"] >= self.id_data.data["goal"] then
								self:Unlock(id_achievement)
							end
						end
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isKillsFilledByWeaponSessionOnMapAndDifficulty(id_achievement, id_weapon, id_level, id_diff)
	if game_state_machine then
		self:Load(id_achievement)

		local required_level = id_level
		local current_level = managers.job:current_level_id()
		local required_difficulty = id_diff
		local current_diff = Global.game_settings.difficulty
		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if required_level == current_level then
			if required_difficulty == current_diff then
				if current_weapon.name_id == id_weapon then
					if not self.id_data.data["unlocked"] then
						if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count >= self.id_data.data["goal"] then
							self:Unlock(id_achievement)
						end
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:WeaponEquippedOnMapAndDiff(ach_id, id_level, weapon_id, diff_id)
	if game_state_machine then
		self:Load(ach_id)
		local current_primary = managers.blackmarket:equipped_primary()
		local wanted_primary = weapon_id
		local required_level = id_level
		local current_level = managers.job:current_level_id()
		local required_difficulty = diff_id
		local current_diff = Global.game_settings.difficulty

		if current_primary and current_primary.weapon_id == wanted_primary then
			if required_level == current_level then
				if required_difficulty == current_diff then
					if managers.job:on_last_stage() then
						if managers.job:stage_success() then
							self:Unlock(ach_id)
						end
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:WeaponEquippedOnDiff(ach_id, weapon_id, diff_id)
	if game_state_machine then
		self:Load(ach_id)
		local current_primary = managers.blackmarket:equipped_primary()
		local wanted_primary = weapon_id
		local required_difficulty = diff_id
		local current_diff = Global.game_settings.difficulty

		if current_primary and current_primary.weapon_id == wanted_primary then
			if required_difficulty == current_diff then
				if managers.job:on_last_stage() then
					if managers.job:stage_success() then
						self:Unlock(ach_id)
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isSpecialKilled(id_achievement, id_special, data)	-- Must be hooked on StatisticsManager:killed
	self:Load(id_achievement)
	
	if data then
		if data.name == id_special then
			self:IncreaseCounter(id_achievement, 1)
		end
	end
end

function ClassCustomAchievement:isSpecialKilledWithWeapon(id_achievement, id_weapon, id_special, data) -- Must be hooked on StatisticsManager:killed
	self:Load(id_achievement)

	if data then
		
		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if data.name == id_special then
			if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count then
				if current_weapon.name_id == id_weapon then
					if not self.id_data.data["unlocked"] then
						self.id_data.data["number"] = self.id_data.data["number"] + 1
						self:Save(id_achievement)

						if self.id_data.data["number"] >= self.id_data.data["goal"] then
							self:Unlock(id_achievement)
						end
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isSpecialKilledOnMap(id_achievement, id_map, id_special, data) -- Must be hooked on StatisticsManager:killed
	local required_level = id_map
	local current_level = managers.job:current_level_id()
	self:Load(id_achievement)

	if data then
		if current_level == required_level then
			if data.name == id_special then
				if not self.id_data.data["unlocked"] then
					self:IncreaseCounter(id_achievement, 1)
				end
			end
		end
	end
end

function ClassCustomAchievement:isSpecialKilledOnDifficulty(id_achievement, id_diff, id_special, data) -- Must be hooked on StatisticsManager:killed
	local required_difficulty = diff_id
	local current_diff = Global.game_settings.difficulty

	self:Load(id_achievement)

	if data then
		if required_difficulty == current_diff then
			if data.name == id_special then
				if not self.id_data.data["unlocked"] then
					self:IncreaseCounter(id_achievement, 1)
				end
			end
		end
	end
end

function ClassCustomAchievement:isSpecialKilledOnMapWithWeapon(id_achievement, id_map, id_weapon, id_special, data) -- Must be hooked on StatisticsManager:killed
	local required_level = id_map
	local current_level = managers.job:current_level_id()
	self:Load(id_achievement)

	if data then
		
		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if required_level == current_level then
			if data.name == id_special then
				if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count then
					if current_weapon.name_id == id_weapon then
						if not self.id_data.data["unlocked"] then
							self.id_data.data["number"] = self.id_data.data["number"] + 1
							self:Save(id_achievement)

							if self.id_data.data["number"] >= self.id_data.data["goal"] then
								self:Unlock(id_achievement)
							end
						end
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isSpecialKilledOnMapAndDifficultyWithWeapon(id_achievement, id_map, id_diff, id_weapon, id_special, data)
	local required_level = id_map
	local current_level = managers.job:current_level_id()
	local required_difficulty = diff_id
	local current_diff = Global.game_settings.difficulty

	self:Load(id_achievement)

	if data then
		local current_state = managers.player:get_current_state()
		local current_weapon = current_state:get_equipped_weapon()

		if required_level == current_level then
			if required_difficulty == current_diff then
				if data.name == id_special then
					if managers.statistics._global.session.killed_by_weapon[id_weapon] and managers.statistics._global.session.killed_by_weapon[id_weapon].count then
						if current_weapon.name_id == id_weapon then
							if not self.id_data.data["unlocked"] then
								self.id_data.data["number"] = self.id_data.data["number"] + 1
								self:Save(id_achievement)

								if self.id_data.data["number"] >= self.id_data.data["goal"] then
									self:Unlock(id_achievement)
								end
							end
						end
					end
				end
			end
		end
	end
end

function ClassCustomAchievement:isStealth()
	if managers.groupai:state():whisper_mode() then
		return true
	else
		return false
	end
end

function ClassCustomAchievement:isHeadshot(data) -- Must be hooked on StatisticsManager:killed
	if data then
		if data.head_shot == 1 then
			return true
		else
			return false
		end
	end
end

function ClassCustomAchievement:RetrieveData(id_achievement, key)
	self:Load(id_achievement)
	log("[CustomAchievement] Data retrieved for " .. id_achievement .. ": " .. tostring(self.id_data.data[key]))
	return self.id_data.data[key]
end