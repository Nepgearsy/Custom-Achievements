local massive_font = tweak_data.menu.pd2_massive_font
local large_font = tweak_data.menu.pd2_large_font
local medium_font = tweak_data.menu.pd2_medium_font
local small_font = tweak_data.menu.pd2_small_font
local massive_font_size = tweak_data.menu.pd2_massive_font_size
local large_font_size = tweak_data.menu.pd2_large_font_size
local medium_font_size = tweak_data.menu.pd2_medium_font_size
local small_font_size = tweak_data.menu.pd2_small_font_size
local PANEL_PADDING = 10
local REWARD_SIZE = 100
local MAX_REWARDS_DISPLAYED = 2
CustomAchievementsPage = CustomAchievementsPage or class(CustomSafehouseGuiPage)
function CustomAchievementsPage:init_achievements()
	self.achievement_data = {}

	for _, filename in pairs(file.GetFiles("mods/Custom Achievements Addons/")) do
		local file = filename:gsub(".json", "")
		
		CustomAchievement:Load(file)
		table.insert(self.achievement_data, {
			id = CustomAchievement.id_data.data["id"],
			name_id = CustomAchievement.id_data.data["name"],
			desc_id = CustomAchievement.id_data.data["desc"],
			rank = CustomAchievement.id_data.data["rank"],
			objective_id = CustomAchievement.id_data.data["objective"],
			completed = CustomAchievement.id_data.data["unlocked"],
			reward_type = CustomAchievement.id_data.data["reward_type"],
			reward_amount = CustomAchievement.id_data.data["reward_amount"],
			objectives = {},
			progress = CustomAchievement.id_data.data["number"],
			goal = CustomAchievement.id_data.data["goal"],
			show_progress = true,
			image_id = CustomAchievement.id_data.data["texture"],
			is_hidden = CustomAchievement.id_data.data["is_hidden"]
		})
	end
end

function CustomAchievementsPage:init(page_id, page_panel, fullscreen_panel, gui)
	CustomAchievementsPage.super.init(self, page_id, page_panel, fullscreen_panel, gui)
	self.make_fine_text = BlackMarketGui.make_fine_text
	self._scrollable_panels = {}
	self:init_achievements()
	CustomAchievement:init_achievement_rank()
	self:_setup_trophies_counter()
	self:_setup_trophies_info()
	self:_setup_achievements_list()
end

function CustomAchievementsPage:format_int(number)

  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

  -- reverse the int-string and append a comma to all blocks of 3 digits
  int = int:reverse():gsub("(%d%d%d)", "%1,")

  -- reverse the int-string back remove an optional comma and put the 
  -- optional minus and fractional part back
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

function CustomAchievementsPage:set_achievement_info(trophy, update_size)
	local info_panel = self._info_scroll:canvas()
	local title_text = info_panel:child("TitleText")
	local trophy_rank_panel = info_panel:child("TrophyIconPanel")
	local trophy_rank_image = trophy_rank_panel:child("TrophyIcon")
	local achievement_rank = info_panel:child("RankText")
	local image_panel = info_panel:child("TrophyImagePanel")
	local trophy_image = image_panel:child("TrophyImage")
	local complete_banner = info_panel:child("CompleteBannerPanel")
	local complete_text = complete_banner:child("CompleteText")
	local complete_fill = complete_banner:child("CompleteBannerFill")
	local desc_text = info_panel:child("DescText")
	local objective_header = info_panel:child("ObjectiveHeader")
	local objective_text = info_panel:child("ObjectiveText")
	local progress_header = info_panel:child("ProgressHeader")
	local progress_text = info_panel:child("ProgressText")
	local reward_header = info_panel:child("RewardHeader")
	local reward_text = info_panel:child("RewardText")
	local data = trophy:trophy_data()
	local hide_informations = false

	if data.is_hidden and not data.completed then
		hide_informations = true
	else
		hide_informations = false
	end

	if data.rank and data.rank ~= "" then
		achievement_rank:set_text(utf8.to_upper(data.rank))

		if data.rank == "bronze" then
			achievement_rank:set_color(CustomAchievement.rank.bronze.color)
			trophy_rank_image:set_image("guis/textures/mods/CustomAchievement/trophy_icon_bronze")
		elseif data.rank == "silver" then
			achievement_rank:set_color(CustomAchievement.rank.silver.color)
			trophy_rank_image:set_image("guis/textures/mods/CustomAchievement/trophy_icon_silver")
		elseif data.rank == "gold" then
			achievement_rank:set_color(CustomAchievement.rank.gold.color)
			trophy_rank_image:set_image("guis/textures/mods/CustomAchievement/trophy_icon_gold")
		elseif data.rank == "platinum" then
			achievement_rank:set_color(CustomAchievement.rank.platinum.color)
			trophy_rank_image:set_image("guis/textures/mods/CustomAchievement/trophy_icon_platinum")
		end

		achievement_rank:set_visible(true)
		trophy_rank_panel:set_visible(true)
		image_panel:set_top(achievement_rank:bottom() + 3)
	else
		achievement_rank:set_visible(false)
		trophy_rank_panel:set_visible(false)
		image_panel:set_top(title_text:bottom() + 3)
	end

	if hide_informations then
		title_text:set_text(utf8.to_upper(managers.localization:text("achievement_menu_page_hidden_marks")))
		desc_text:set_text(managers.localization:text("achievement_menu_page_hidden_desc"))
		trophy_image:set_image("guis/textures/mods/CustomAchievement/hidden")
		complete_banner:set_visible(true)
		desc_text:set_top(complete_banner:bottom() + PANEL_PADDING)
		reward_header:set_visible(true)
		reward_text:set_visible(true)
	else
		title_text:set_text(utf8.to_upper(managers.localization:text(data.name_id)))
		desc_text:set_text(managers.localization:text(data.desc_id))
		trophy_image:set_image("guis/textures/mods/CustomAchievement/" .. data.image_id)
		complete_banner:set_visible(true)
		desc_text:set_top(complete_banner:bottom() + PANEL_PADDING)
		reward_header:set_visible(true)
		reward_text:set_visible(true)
	end

	if data.completed then
		complete_text:set_text(managers.localization:to_upper_text("achievement_menu_page_unlocked"))
		complete_text:set_color(Color(255, 128, 255, 0) / 255)
		complete_fill:set_color(Color(255, 128, 255, 0) / 255)
	else
		complete_text:set_text(managers.localization:to_upper_text("achievement_menu_page_locked"))
		complete_text:set_color(tweak_data.screen_colors.important_1)
		complete_fill:set_color(tweak_data.screen_colors.important_1)
	end
	
	local _, _, _, h = desc_text:text_rect()
	desc_text:set_h(h)
	objective_header:set_top(desc_text:bottom() + PANEL_PADDING)
	objective_text:set_top(objective_header:bottom())

	if hide_informations then
		objective_text:set_text(managers.localization:text("achievement_menu_page_hidden_marks"))
	else
		objective_text:set_text(managers.localization:text(data.objective_id))
	end

	local _, _, _, h = objective_text:text_rect()
	objective_text:set_h(h)
	
	if data.goal and data.goal > 0 and not hide_informations then
		if not data.completed then
			progress_header:set_visible(true)
			progress_text:set_visible(true)
			local percent_div = math.floor(data.progress * 100 / data.goal)
			local text = tostring(self:format_int(data.progress) .. " / " .. self:format_int(data.goal) .. " ( " .. percent_div .. "% )")
			progress_text:set_text(text)
		else
			progress_header:set_visible(true)
			progress_text:set_visible(true)
			local text = tostring(self:format_int(data.goal) .. " / " .. self:format_int(data.goal) .. " ( 100% )")
			progress_text:set_text(text)
		end
	else
		progress_header:set_visible(false)
		progress_text:set_visible(false)
	end

	if data.reward_type and data.reward_amount and not hide_informations then
		if data.reward_type ~= "none" and data.reward_amount > 0 then

			if data.reward_type == "cc" then
				local str_reward_type = " Continental Coins"
				local str_reward_amount = data.reward_amount

				if str_reward_amount < 0 then
					str_reward_amount = 0
				end

				if str_reward_amount > 10 then
					str_reward_amount = 0
				end

				reward_text:set_text(self:format_int(str_reward_amount) .. str_reward_type)
			elseif data.reward_type == "money" then
				local str_reward_type = "$ Spendable cash"
				local str_reward_amount = data.reward_amount

				if str_reward_amount < 0 then
					str_reward_amount = 0
				end

				if str_reward_amount > 1000000 then
					str_reward_amount = 0
				end

				reward_text:set_text(self:format_int(str_reward_amount) .. str_reward_type)
			elseif data.reward_type == "offshore" then
				local str_reward_type = "$ Offshore"
				local str_reward_amount = data.reward_amount

				if str_reward_amount < 0 then
					str_reward_amount = 0
				end

				if str_reward_amount > 2000000 then
					str_reward_amount = 0
				end

				reward_text:set_text(self:format_int(str_reward_amount) .. str_reward_type)

			elseif data.reward_type == "experience" then
				local str_reward_type = " EXP"
				local str_reward_amount = data.reward_amount

				if str_reward_amount < 0 then
					str_reward_amount = 0
				end

				if str_reward_amount > 500000 then
					str_reward_amount = 0
				end

				local current_level = managers.experience:current_level()
				local lv_div = current_level / 100
				local new_reward = str_reward_amount * lv_div
				local real_xp = math.floor(new_reward)

				reward_text:set_text(self:format_int(real_xp) .. str_reward_type)
			end
		else
			reward_header:set_visible(false)
			reward_text:set_visible(false)
		end
	else
		reward_header:set_visible(false)
		reward_text:set_visible(false)
	end
end

function CustomAchievementsPage:_setup_achievements_list()
	self._trophies = {}
	local scroll = ScrollablePanel:new(self:panel(), "TrophiesPanel", {padding = 0})
	BoxGuiObject:new(scroll:panel(), {
		sides = {
			1,
			1,
			1,
			1
		}
	})
	self._trophies_scroll = scroll
	table.insert(self._scrollable_panels, scroll)
	local trophies = {}
	for idx, trophy in ipairs(self.achievement_data) do
		if trophy.is_hidden and not trophy.completed then
			trophy.name_id = "achievement_menu_page_hidden_marks"
			table.insert(trophies, trophy)
		else
			table.insert(trophies, trophy)
		end
	end
	table.sort(trophies, function(a, b)
		return managers.localization:text(a.name_id) < managers.localization:text(b.name_id)
	end)
	for idx, trophy in ipairs(trophies) do
		local trophy_btn = CustomSafehouseGuiTrophyItem:new(scroll:canvas(), trophy, 0, idx)
		table.insert(self._trophies, trophy_btn)
	end
	table.sort(self._trophies, function(a, b)
		return a:priority() < b:priority()
	end)
	local canvas_h = 0
	for idx, trophy in ipairs(self._trophies or {}) do
		trophy:set_position(idx)
		trophy:link(self._trophies[idx - 1], self._trophies[idx + 1])
		canvas_h = math.max(canvas_h, trophy:bottom())
	end
	scroll:set_canvas_size(nil, canvas_h)
	if #self._trophies > 0 then
		self:_set_selected(self._trophies[1], true)
	end
end


function CustomAchievementsPage:_setup_trophies_info()
	local buttons_panel = self:info_panel():panel({
		name = "buttons_panel"
	})
	local trophy_panel = self:info_panel():panel({
		name = "trophy_panel"
	})
	local buttons = {}
	local button_panel_h
	if not Global.game_settings.is_playing then
		button_panel_h = 10 + #buttons * medium_font_size
	else
		button_panel_h = 0
	end
	self._buttons = {}
	self._controllers_pc_mapping = {}
	self._controllers_mapping = {}
	local btn_x = 10
	for idx, btn_data in pairs(buttons) do
		local new_button = CustomSafehouseGuiButtonItem:new(buttons_panel, btn_data, btn_x, idx)
		self._buttons[idx] = new_button
		if btn_data.pc_btn then
			self._controllers_mapping[btn_data.pc_btn:key()] = new_button
		end
	end
	if button_panel_h > 0 then
		trophy_panel:set_h(self:info_panel():h() - button_panel_h - PANEL_PADDING)
	else
		trophy_panel:set_h(self:info_panel():h())
	end
	buttons_panel:set_h(button_panel_h)
	buttons_panel:set_bottom(self:info_panel():bottom())
	self._buttons_box_panel = BoxGuiObject:new(buttons_panel, {
		sides = {
			1,
			1,
			1,
			1
		}
	})
	local scroll = ScrollablePanel:new(trophy_panel, "TrophyInfoPanel")
	scroll:on_canvas_updated_callback(callback(self, self, "update_info_panel_width"))
	self._trophy_box_panel = BoxGuiObject:new(scroll:panel(), {
		sides = {
			1,
			1,
			1,
			1
		}
	})
	self._info_scroll = scroll
	table.insert(self._scrollable_panels, scroll)
	local trophy_title = scroll:canvas():text({
		name = "TitleText",
		font_size = medium_font_size,
		font = medium_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = utf8.to_upper("Trophies"),
		w = scroll:canvas():w(),
		h = medium_font_size,
		align = "left",
		vertical = "top",
		halign = "left",
		valign = "top"
	})
	local trophy_rank_panel = scroll:canvas():panel({
		name = "TrophyIconPanel",
		layer = 10,
		w = 24,
		h = 24
	})
	trophy_rank_panel:set_top(trophy_title:bottom() + 3)
	local trophy_rank_image = trophy_rank_panel:bitmap({
		name = "TrophyIcon",
		texture = "guis/textures/mods/CustomAchievement/trophy_icon_platinum",
		texture_rect = {
			0,
			0,
			256,
			256
		},
		
		layer = 40,
		w = trophy_rank_panel:w(),
		h = trophy_rank_panel:h()
	})
	local achievement_rank = scroll:canvas():text({
		name = "RankText",
		font_size = medium_font_size,
		font = medium_font,
		layer = 1,
		blend_mode = "add",
		color = CustomAchievement.rank.gold.color,
		text = "",
		visible = false,
		w = scroll:canvas():w(),
		h = medium_font_size,
		align = "left",
		vertical = "top",
		halign = "left",
		valign = "top"
	})
	achievement_rank:set_top(trophy_title:bottom() + 3)
	achievement_rank:set_left(trophy_rank_panel:right() + 3)
	local image_panel = scroll:canvas():panel({
		name = "TrophyImagePanel",
		layer = 10
	})
	image_panel:set_w(scroll:canvas():w())
	image_panel:set_h(image_panel:w() / 2)
	image_panel:set_top(achievement_rank:bottom() + 3)
	local trophy_image = image_panel:bitmap({
		name = "TrophyImage",
		texture_rect = {
			0,
			0,
			256,
			256
		},
		layer = 40,
		w = image_panel:w(),
		h = image_panel:h()
	})
	local image_scanlines = image_panel:bitmap({
		name = "TrophyImageScanlines",
		texture = "guis/dlcs/chill/textures/pd2/rooms/safehouse_room_preview_effect",
		texture_rect = {
			0,
			0,
			512,
			512
		},
		wrap_mode = "wrap",
		layer = 50,
		w = image_panel:w(),
		h = image_panel:h() * 4,
		y = image_panel:h() * 2 * -1
	})
	self._scanline_effect = image_scanlines
	self._image_outline = BoxGuiObject:new(image_panel, {
		sides = {
			2,
			2,
			2,
			2
		}
	})
	self._image_outline:set_color(Color(0.2, 1, 1, 1))
	self._image_outline:set_blend_mode("add")
	local complete_banner = scroll:canvas():panel({
		name = "CompleteBannerPanel",
		h = small_font_size
	})
	complete_banner:set_top(image_panel:bottom() + PANEL_PADDING)
	complete_banner:rect({
		name = "CompleteBannerFill",
		color = tweak_data.screen_colors.challenge_completed_color,
		alpha = 0.4
	})
	local complete_text = complete_banner:text({
		name = "CompleteText",
		font_size = small_font_size,
		font = small_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.challenge_completed_color:with_alpha(0.8),
		text = managers.localization:to_upper_text("menu_trophy_displayed"),
		align = "center",
		vertical = "top",
		halign = "scale",
		valign = "scale"
	})
	local desc_text = scroll:canvas():text({
		name = "DescText",
		font_size = small_font_size,
		font = small_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = managers.localization:text("menu_cs_daily_available"),
		w = scroll:canvas():w(),
		wrap = true,
		word_wrap = true,
		align = "left",
		vertical = "top",
		halign = "left",
		valign = "top"
	})
	desc_text:set_top(complete_banner:bottom() + PANEL_PADDING)
	self:make_fine_text(desc_text)
	local unlock_text = scroll:canvas():text({
		name = "ObjectiveHeader",
		font_size = small_font_size,
		font = small_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.challenge_title,
		text = utf8.to_upper(managers.localization:text("menu_unlock_condition")),
		w = scroll:canvas():w(),
		align = "left",
		vertical = "top",
		halign = "left",
		valign = "top"
	})
	self:make_fine_text(unlock_text)
	unlock_text:set_top(desc_text:bottom() + PANEL_PADDING)
	local objective_text = scroll:canvas():text({
		name = "ObjectiveText",
		font_size = small_font_size,
		font = small_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = managers.localization:text("menu_cs_daily_available"),
		w = scroll:canvas():w(),
		wrap = true,
		word_wrap = true,
		align = "left",
		vertical = "top",
		halign = "left",
		valign = "top"
	})
	objective_text:set_top(unlock_text:bottom())
	self:make_fine_text(objective_text)
	local progress_header = scroll:canvas():text({
		name = "ProgressHeader",
		font_size = small_font_size,
		font = small_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.challenge_title,
		text = utf8.to_upper(managers.localization:text("menu_unlock_progress")),
		w = scroll:canvas():w(),
		wrap = true,
		word_wrap = true,
		align = "left",
		vertical = "top",
		halign = "left",
		valign = "top"
	})
	self:make_fine_text(progress_header)
	progress_header:set_top(objective_text:bottom() + PANEL_PADDING)
	local progress_text = scroll:canvas():text({
		name = "ProgressText",
		font_size = small_font_size,
		font = small_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = managers.localization:text("menu_cs_daily_available"),
		w = scroll:canvas():w(),
		wrap = true,
		word_wrap = true,
		align = "left",
		vertical = "top",
		halign = "left",
		valign = "top"
	})
	self:make_fine_text(progress_text)
	progress_text:set_top(progress_header:bottom())
	local reward_header_text = scroll:canvas():text({
		name = "RewardHeader",
		font_size = small_font_size,
		font = small_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.challenge_title,
		text = utf8.to_upper(managers.localization:text("achievement_menu_page_reward_header")),
		w = scroll:canvas():w(),
		align = "left",
		vertical = "top",
		halign = "left",
		valign = "top"
	})
	self:make_fine_text(reward_header_text)
	reward_header_text:set_top(progress_text:bottom())
	local reward_text = scroll:canvas():text({
		name = "RewardText",
		font_size = small_font_size,
		font = small_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.title,
		text = "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
		w = scroll:canvas():w(),
		align = "left",
		vertical = "top",
		halign = "left",
		valign = "top"
	})
	reward_text:set_top(reward_header_text:bottom())
	self:make_fine_text(reward_text)


	scroll:update_canvas_size()
end
function CustomAchievementsPage:_setup_trophies_counter()
	local total = 0
	local completed = 0

	for _, trophy in ipairs(self.achievement_data) do
		total = total + 1
		if trophy.completed then
			completed = completed + 1			
			if trophy.rank then
				if trophy.rank == "bronze" then
					CustomAchievement.total_points = CustomAchievement.total_points + CustomAchievement.rank.bronze.points
				elseif trophy.rank == "silver" then
					CustomAchievement.total_points = CustomAchievement.total_points + CustomAchievement.rank.silver.points
				elseif trophy.rank == "gold" then
					CustomAchievement.total_points = CustomAchievement.total_points + CustomAchievement.rank.gold.points
				elseif trophy.rank == "platinum" then
					CustomAchievement.total_points = CustomAchievement.total_points + CustomAchievement.rank.platinum.points
				end
			end
		end
	end
	local percent = math.floor(completed * 100 / total)
	local text = managers.localization:to_upper_text("achievement_menu_page_counter", {total = total, completed = completed, percent = percent})
	self._trophy_counter = self._gui._panel:text({
		text = text,
		font = medium_font,
		font_size = medium_font_size,
		color = tweak_data.screen_colors.text,
		visible = false
	})
	self:make_fine_text(self._trophy_counter)

	local points = self:format_int(CustomAchievement.total_points)
	local rank_level = CustomAchievement:get_rank_level()
	local points_text = managers.localization:to_upper_text("achievement_menu_page_points", {points = points, rank_level = rank_level})
	self._achievements_point_count = self._gui._panel:text({
		text = points_text,
		font = medium_font,
		font_size = medium_font_size,
		color = tweak_data.screen_colors.text,
		visible = false
	})
	self:make_fine_text(self._achievements_point_count)

	self._trophy_counter:set_right(self._gui._panel:w())
	self._achievements_point_count:set_right(self._gui._panel:w())
	self._achievements_point_count:set_top(self._trophy_counter:bottom())
end

function CustomAchievementsPage:set_active(active)
	self._trophy_counter:set_visible(active)
	self._achievements_point_count:set_visible(active)
	return CustomAchievementsPage.super.set_active(self, active)
end
function CustomAchievementsPage:update_info_panel_width(new_width)
	local info_panel = self._info_scroll:canvas()
	local desc_text = info_panel:child("DescText")
	local objective_text = info_panel:child("ObjectiveText")
	local image_panel = info_panel:child("TrophyImagePanel")
	desc_text:set_w(new_width)
	objective_text:set_w(new_width)
	image_panel:set_w(new_width)
	image_panel:set_h(new_width / 2)
	self._image_outline:close()
	self._image_outline = BoxGuiObject:new(image_panel, {
		sides = {
			2,
			2,
			2,
			2
		}
	})
	self._image_outline:set_color(Color(0.2, 1, 1, 1))
	self._image_outline:set_blend_mode("add")
	if self._progress_items then
		for _, item in ipairs(self._progress_items) do
			item:set_w(new_width)
		end
	end
	if self._selected_trophy then
		self:set_achievement_info(self._selected_trophy, false)
	end
end

function CustomAchievementsPage:_set_selected(trophy, skip_sound)
	if not trophy then
		return false
	end
	if self._selected_trophy then
		self._selected_trophy:set_selected(false)
	end
	self._selected_trophy = trophy
	self._selected_trophy:set_selected(true, not skip_sound)
	self:set_achievement_info(self._selected_trophy, true)
	local scroll_panel = self._trophies_scroll:scroll_panel()
	local y = self._trophies_scroll:canvas():y() + trophy:bottom()
	if y > scroll_panel:h() then
		self._trophies_scroll:perform_scroll(y - scroll_panel:h(), -1)
	else
		y = self._trophies_scroll:canvas():y() + trophy:top()
		if y < 0 then
			self._trophies_scroll:perform_scroll(math.abs(y), 1)
		end
	end
	if self._buttons[1] and self._buttons[1]:button_data().btn == "BTN_A" then
		self._buttons[1]:set_hidden(false)
		if trophy:trophy_data().completed then
			local text_id = trophy:trophy_data().displayed and "menu_trophy_change_display_to_off" or "menu_trophy_change_display_to_on"
			self._buttons[1]:set_text(managers.localization:to_upper_text(text_id))
		else
			self._buttons[1]:set_hidden(true)
		end
		self:update_info_panel_size()
	end
end
function CustomAchievementsPage:refresh()
	CustomAchievementsPage.super.refresh(self)
	self:_set_selected(self._selected_trophy, true)
end
function CustomAchievementsPage:update_info_panel_size()
	local active_buttons = 0
	local button_panel_h = 0
	if not Global.game_settings.is_playing then
		for i, button in ipairs(self._buttons) do
			if not button:hidden() then
				active_buttons = active_buttons + 1
				button:reorder(active_buttons)
			end
		end
		button_panel_h = 10 + active_buttons * medium_font_size
	end
	local trophy_panel = self:info_panel():child("trophy_panel")
	local buttons_panel = self:info_panel():child("buttons_panel")
	if button_panel_h > 0 then
		trophy_panel:set_h(self:info_panel():h() - button_panel_h - PANEL_PADDING)
	else
		trophy_panel:set_h(self:info_panel():h())
	end
	self._info_scroll:set_size(self._info_scroll:panel():w(), trophy_panel:h())
	buttons_panel:set_h(button_panel_h)
	buttons_panel:set_bottom(self:info_panel():bottom())
	if self._buttons_box_panel then
		self._buttons_box_panel:close()
		self._buttons_box_panel = nil
	end
	if self._trophy_box_panel then
		self._trophy_box_panel:close()
		self._trophy_box_panel = nil
	end
	self._buttons_box_panel = BoxGuiObject:new(buttons_panel, {
		sides = {
			1,
			1,
			1,
			1
		}
	})
	self._trophy_box_panel = BoxGuiObject:new(self._info_scroll:panel(), {
		sides = {
			1,
			1,
			1,
			1
		}
	})
end
function CustomAchievementsPage:update(t, dt)
	local cx, cy = managers.menu_component:get_right_controller_axis()
	if cy ~= 0 and self._info_scroll then
		self._info_scroll:perform_scroll(math.abs(cy * 500 * dt), math.sign(cy))
	end
	if self._scanline_effect then
		local h = self._scanline_effect:h() * 0.25 * -1
		self._scanline_effect:move(0, 10 * dt)
		if h <= self._scanline_effect:top() then
			self._scanline_effect:set_top(self._scanline_effect:top() + h)
		end
	end
end
function CustomAchievementsPage:mouse_moved(button, x, y)
	if not self._active then
		return
	end
	for i, panel in pairs(self._scrollable_panels) do
		local values = {
			panel:mouse_moved(button, x, y)
		}
		if panel and values[1] ~= nil then
			return unpack(values)
		end
	end
	if self:panel():inside(x, y) then
		for idx, trophy in ipairs(self._trophies or {}) do
			if trophy:inside(x, y) then
				if self._selected_trophy ~= trophy then
					self:_set_selected(trophy)
				end
				return true, "link"
			end
		end
	end
	local used, pointer
	for _, button in ipairs(self._buttons) do
		if button:inside(x, y) and not used then
			button:set_selected(true)
			used, pointer = true, "link"
		else
			button:set_selected(false)
		end
	end
	return used, pointer
end
function CustomAchievementsPage:confirm_pressed()
	if Global.game_settings.is_playing then
		return
	end
	if managers.menu:is_pc_controller() then
		for _, button in ipairs(self._buttons) do
			if button:is_selected() then
				button:trigger(self)
				return
			end
		end
	end
	if self._selected_trophy then
		self._selected_trophy:trigger(self)
	end
end
function CustomAchievementsPage:mouse_pressed(button, x, y)
	if not self._active then
		return
	end
	for i, panel in pairs(self._scrollable_panels) do
		local values = {
			panel:mouse_pressed(button, x, y)
		}
		if panel and values[1] ~= nil then
			return unpack(values)
		end
	end
	if self:panel():inside(x, y) then
		for idx, trophy in ipairs(self._trophies or {}) do
			if trophy:inside(x, y) and button == Idstring("0") then
				trophy:trigger(self)
				return true
			end
		end
	end
	for _, button in ipairs(self._buttons) do
		if button:inside(x, y) then
			button:trigger()
			return true
		end
	end
end
function CustomAchievementsPage:mouse_released(button, x, y)
	if not self._active then
		return
	end
	for i, panel in pairs(self._scrollable_panels) do
		local values = {
			panel:mouse_released(button, x, y)
		}
		if panel and values[1] ~= nil then
			self._prevent_click = (self._prevent_click or 0) + 1
			return unpack(values)
		end
	end
end
function CustomAchievementsPage:mouse_wheel_up(x, y)
	if not self._active then
		return
	end
	for i, panel in pairs(self._scrollable_panels) do
		local values = {
			panel:scroll(x, y, 1)
		}
		if panel and values[1] ~= nil then
			return unpack(values)
		end
	end
end
function CustomAchievementsPage:mouse_wheel_down(x, y)
	if not self._active then
		return
	end
	for i, panel in pairs(self._scrollable_panels) do
		local values = {
			panel:scroll(x, y, -1)
		}
		if panel and values[1] ~= nil then
			return unpack(values)
		end
	end
end
function CustomAchievementsPage:move_up()
	if self._selected_trophy then
		self:_set_selected(self._selected_trophy:get_linked("up"))
		self._gui:update_legend()
	end
end
function CustomAchievementsPage:move_down()
	if self._selected_trophy then
		self:_set_selected(self._selected_trophy:get_linked("down"))
		self._gui:update_legend()
	end
end
function CustomAchievementsPage:get_legend()
	local legend = {}
	table.insert(legend, "move")
	if self._info_scroll:is_scrollable() then
		table.insert(legend, "scroll")
	end
	table.insert(legend, "back")
	return legend
end

function CustomAchievementsPage:progress_init(parent_panel, progression, progression_max)
	self.h = small_font_size * 1.3
	self._parent = parent_panel
	self._progression = progression
	self._progression_max = progression_max
	self._panel = parent_panel:panel({
		w = parent_panel:w(),
		h = self.h
	})
	self._text = self._panel:text({
		name = "text",
		font_size = small_font_size,
		font = small_font,
		layer = 1,
		blend_mode = "add",
		color = tweak_data.screen_colors.text,
		text = "",
		w = self._panel:w(),
		h = self._panel:h(),
		align = "left",
		vertical = "center",
		halign = "scale",
		valign = "scale"
	})
	if 1 < self._progression_max then
		self._progress_panel = self._panel:panel({
			w = self._panel:w(),
			h = self._panel:h()
		})
		self._progress_outline = BoxGuiObject:new(self._progress_panel, {
			sides = {
				1,
				1,
				1,
				1
			}
		})
		local color = self._progression >= self._progression_max and tweak_data.screen_colors.challenge_completed_color or tweak_data.screen_colors.button_stage_3
		self._progress_fill = self._progress_panel:rect({
			w = self._panel:w() * (self._progression / self._progression_max),
			color = color:with_alpha(0.4)
		})
		self._text:set_x(PANEL_PADDING)
		self._progress_text = self._panel:text({
			name = "progress_text",
			font_size = small_font_size,
			font = small_font,
			layer = 1,
			blend_mode = "add",
			color = tweak_data.screen_colors.text,
			text = self._progression .. "/" .. self._progression_max,
			w = self._panel:w() - PANEL_PADDING * 2,
			h = self._progress_panel:h(),
			x = PANEL_PADDING,
			align = "right",
			vertical = "center",
			halign = "scale",
			valign = "scale"
		})
	end
end
function CustomAchievementsPage:destroy()
	self._parent:remove(self._panel)
end
function CustomAchievementsPage:top()
	return self._panel:top()
end
function CustomAchievementsPage:bottom()
	return self._panel:bottom()
end
function CustomAchievementsPage:set_top(y)
	return self._panel:set_top(y)
end
function CustomAchievementsPage:set_bottom(y)
	return self._panel:set_bottom(y)
end
function CustomAchievementsPage:set_w(w)
	self._panel:set_w(w)
	if alive(self._progress_panel) then
		self._progress_panel:set_w(w)
		self._progress_fill:set_w(w * (self._progression / self._progression_max))
		self._progress_text:set_w(self._panel:w() - PANEL_PADDING * 2)
		self._progress_outline:close()
		self._progress_outline = BoxGuiObject:new(self._progress_panel, {
			sides = {
				1,
				1,
				1,
				1
			}
		})
	end
	if alive(self._checkbox) then
		self._checkbox:set_right(self._panel:w())
	end
end

CustomSafehouseGuiTrophyItem = CustomSafehouseGuiTrophyItem or class(CustomSafehouseGuiItem)
function CustomSafehouseGuiTrophyItem:init(panel, data, x, priority)
	CustomSafehouseGuiTrophyItem.super.init(self, panel, data)
	self._data = data
	self._priority = priority or 0
	self._is_complete = false
	self._panel = panel:panel({
		x = x,
		y = x,
		w = panel:w() - x * 2,
		h = large_font_size,
		layer = 10
	})
	local size = self._panel:h() - 16
	self._complete_checkbox = self._panel:bitmap({
		w = size,
		h = size,
		x = 8,
		y = 8
	})
	self._complete_checkbox:set_image("guis/textures/pd2/mission_briefing/gui_tickbox")
	self._complete_checkbox_highlight = self._panel:bitmap({
		w = size,
		h = size,
		x = 8,
		y = 8
	})
	self._complete_checkbox_highlight:set_image("guis/textures/pd2/mission_briefing/gui_tickbox")
	self._complete_checkbox_highlight:set_visible(false)
	self._btn_text = self._panel:text({
		name = "text",
		text = "",
		align = "left",
		x = 10,
		font_size = medium_font_size,
		font = medium_font,
		color = tweak_data.screen_colors.button_stage_3,
		blend_mode = "add",
		layer = 1
	})
	self:set_text(managers.localization:text(data.name_id))
	self._select_rect = self._panel:rect({
		name = "select_rect",
		blend_mode = "add",
		color = tweak_data.screen_colors.button_stage_3,
		alpha = 0.3,
		valign = "scale",
		halign = "scale"
	})
	self._select_rect:set_visible(false)
	if data.completed then
		self:complete()
	end
	self:refresh()
end
function CustomSafehouseGuiTrophyItem:trophy_data()
	return self._data
end
function CustomSafehouseGuiTrophyItem:set_text(text)
	self._btn_text:set_text(utf8.to_upper(text))
	local _, _, w, h = self._btn_text:text_rect()
	self._btn_text:set_size(w, h)
	self._btn_text:set_left(self._complete_checkbox:right() + 10)
	self._btn_text:set_top(10)
end
function CustomSafehouseGuiTrophyItem:inside(x, y)
	return self._panel:inside(x, y)
end
function CustomSafehouseGuiTrophyItem:show()
	self._select_rect:set_visible(true)
	self._complete_checkbox_highlight:set_visible(true)
	self._btn_text:set_alpha(1)
	if self:trophy_data().completed and not self:trophy_data().displayed then
		self._btn_text:set_color(Color(255, 128, 255, 0) / 255)
	else
		self._btn_text:set_color(tweak_data.screen_colors.button_stage_2)
	end
end
function CustomSafehouseGuiTrophyItem:hide()
	self._select_rect:set_visible(false)
	self._complete_checkbox_highlight:set_visible(false)
	self._btn_text:set_alpha(1)
	if self:trophy_data().completed and not self:trophy_data().displayed then
		self._btn_text:set_color(Color(255, 128, 255, 0) / 255)
		self._btn_text:set_alpha(0.8)
	else
		self._btn_text:set_color(tweak_data.screen_colors.button_stage_3)
	end
end
function CustomSafehouseGuiTrophyItem:top()
	return self._panel:top()
end
function CustomSafehouseGuiTrophyItem:bottom()
	return self._panel:bottom()
end
function CustomSafehouseGuiTrophyItem:visible()
	return self._select_rect:visible()
end
function CustomSafehouseGuiTrophyItem:refresh()
	if self._selected then
		self:show()
	else
		self:hide()
	end
end
function CustomSafehouseGuiTrophyItem:_update_position()
	self._panel:set_y((self._scroll_offset or 0) + (self._priority - 1) * large_font_size + self._priority)
end
function CustomSafehouseGuiTrophyItem:set_position(i)
	self._priority = i
	self:_update_position()
end
function CustomSafehouseGuiTrophyItem:set_scroll_offset(offset)
	self._scroll_offset = offset
	self:_update_position()
end
function CustomSafehouseGuiTrophyItem:priority()
	return self._priority
end
function CustomSafehouseGuiTrophyItem:complete()
	if not self._is_complete then
		self._is_complete = true
		self._priority = self._priority + #tweak_data.safehouse.trophies
		local complete_color = tweak_data.screen_color_grey
		self._complete_checkbox:set_image("guis/textures/pd2/mission_briefing/gui_tickbox_ready")
	end
end
function CustomSafehouseGuiTrophyItem:is_complete()
	return self._is_complete
end
function CustomSafehouseGuiTrophyItem:link(up, down)
	self._links = {up = up, down = down}
end
function CustomSafehouseGuiTrophyItem:get_linked(link)
	return self._links and self._links[link]
end
function CustomSafehouseGuiTrophyItem:trigger(parent)
	if not Global.game_settings.is_playing then
		managers.custom_safehouse:set_trophy_displayed(self:trophy_data().id, not self:trophy_data().displayed)
		self:refresh()
		if parent then
			parent:refresh()
		end
	end
end