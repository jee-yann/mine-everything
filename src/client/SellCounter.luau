local Shared = game:GetService("ReplicatedStorage").Shared
local Ores = require(Shared.Ores)
local Purity = require(Shared.OrePurity)
local W, Slider = require(script.Parent.Widgets), require(script.Parent.Slider)
local SellCounter = {}
local stride = 124

local function makeRow(menu, ore, slot)
	local title, detail, sell = menu:row(1, ore.name, "Crystal", ore.color)
	local row = title.Parent
	row.Position, row.Size = UDim2.fromOffset(1, 1 + slot * stride), UDim2.fromOffset(447, 117)
	title.Name, title.RichText = "Stock", true
	title.Size = UDim2.fromOffset(206, 27)
	title.TextScaled = true
	local stockFont = Instance.new("UITextSizeConstraint")
	stockFont.MinTextSize, stockFont.MaxTextSize, stockFont.Parent = 13, 22, title
	detail.Name, detail.RichText = "Unit price", true
	detail.Position, detail.Size, detail.TextSize = UDim2.fromOffset(67, 28), UDim2.fromOffset(205, 34), 16
	detail.TextScaled = true
	local detailFont = Instance.new("UITextSizeConstraint")
	detailFont.MinTextSize, detailFont.MaxTextSize, detailFont.Parent = 12, 16, detail
	sell.Name, sell.Position, sell.Size = "Sell quantity", UDim2.fromOffset(277, 8), UDim2.fromOffset(158, 51)
	sell.TextScaled = true
	local saleFont = Instance.new("UITextSizeConstraint")
	saleFont.MinTextSize, saleFont.MaxTextSize, saleFont.Parent = 13, 21, sell
	local stack = W.button(row, "Select stack", 277, 66, 158, 44, W.muted, "", "Select")
	local less = W.button(row, "Fewer", 9, 66, 44, 44, W.muted, "−", "Select")
	local more = W.button(row, "More", 222, 66, 44, 44, W.muted, "+", "Select")
	local tint = ore.color:Lerp(W.white, 0.5)
	local stock, quantity, multiplier = 0, 1, 1
	local grades = {}
	local paint
	local function draw()
		local available = stock > 0
		quantity = if available then math.clamp(quantity, 1, stock) else 0
		sell.Text = if available then string.format("Sell %s %s\n+%s gold", W.goldAmount(quantity), ore.name, W.goldAmount(Purity.quote(ore, stock, grades, quantity, menu.player:GetAttribute("SkillBroker")) * multiplier)) else "Sold out"
		sell.Interactable, sell.BackgroundColor3 = available, if available then W.gold else W.muted
		stack.Text = "Select all (" .. W.goldAmount(stock) .. ")"
		stack.Interactable = quantity < stock
		less.Interactable, more.Interactable = quantity > 1, quantity < stock
		less.TextTransparency = if less.Interactable then 0 else 0.55
		more.TextTransparency = if more.Interactable then 0 else 0.55
		local low, high = Purity.range(grades)
		local gradeText = if low then (if low == high then Purity.text(low) .. " pure · " .. Purity.multiplierText(low) .. " value" else Purity.text(low) .. "–" .. Purity.text(high) .. " pure · low sells first")
			else W.unitPrice(Purity.quote(ore, stock, grades, math.min(stock, 1), menu.player:GetAttribute("SkillBroker")) * multiplier)
		detail.Text = gradeText .. "\n" .. W.goldAmount(stock - quantity) .. " left after sale"
		paint(if stock > 1 then (quantity - 1) / (stock - 1) else 0, stock > 1)
	end
	local function step(delta)
		quantity += delta
		draw()
	end
	paint = Slider.new(menu, row, UDim2.fromOffset(54, 66), UDim2.fromOffset(166, 44), tint,
		function(fraction)
			quantity = 1 + math.round(fraction * (stock - 1))
			draw()
		end, step)
	less.Activated:Connect(function() step(-1) end)
	more.Activated:Connect(function() step(1) end)
	sell.Activated:Connect(function()
		if quantity > 0 then menu.net.Action:FireServer("Sell", ore.name, quantity) end
	end)
	stack.Activated:Connect(function()
		quantity = stock
		draw()
	end)
	return function(count, saleMultiplier)
		if count < stock then quantity = 1 end
		stock, multiplier = count, saleMultiplier
		grades = Purity.decode(menu.player:GetAttribute("Grades" .. ore.name))
		title.Text = ore.name .. "  " .. W.colored("×" .. W.goldAmount(count), tint) .. " in pack"
		draw()
	end
end

function SellCounter.build(menu)
	local rows, slots = {}, 0
	local empty = W.text(menu.list, "Your pack is empty", 0, 8, 447, 45, 18, W.muted)
	table.insert(menu.updates, function()
		local player = menu.player
		local multiplier = if player:GetAttribute("DoubleGold") then 2 else 1
		local value, blocks = (player:GetAttribute("BagValue") or 0) * multiplier, 0
		for _, ore in Ores.list do
			local count = player:GetAttribute("Held" .. ore.name) or 0
			-- Keep each stack in its slot until the menu closes, including after a sale.
			if count > 0 and not rows[ore.name] then
				rows[ore.name] = makeRow(menu, ore, slots)
				slots += 1
			end
			if rows[ore.name] then rows[ore.name](count, multiplier) end
			blocks += count
		end
		menu.sellAll.Text = string.format("Sell entire pack\n%s %s · +%s G", W.goldAmount(blocks),
			if blocks == 1 then "block" else "blocks", W.goldAmount(value))
		menu.sellAll.Interactable, menu.sellAll.BackgroundColor3 = value > 0, if value > 0 then W.gold else W.muted
		empty.Visible, empty.Position = value == 0, UDim2.fromOffset(0, slots * stride + 8)
		menu.list.CanvasSize = UDim2.fromOffset(0, slots * stride + (if empty.Visible then 61 else 0))
	end)
	return 0
end

return SellCounter
