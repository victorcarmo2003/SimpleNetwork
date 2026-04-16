--!strict
local Interface = {}

-- Serviços
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Referências
local utils = script.Parent
local SimpleNetwork : {[any]: any}
local ScreenGui: ScreenGui
local MonitorVisible = false

-- Dados temporários para cálculo de taxa
local LastUpdate = 0
local LastSent = 0
local LastReceived = 0

-- Constantes
local GRAPH_FRAMES = 70
local GRAPH_INTERVAL = 0.15
local MAX_LOGS = 12
local MAX_TOP_CONSUMERS = 10

-- Histórico do gráfico (local ao Interface)
local GraphHistory = {}

-- Formatação
local function formatBytes(bytes: number): string
	if bytes < 1024 then
		return string.format("%.0f B", bytes)
	elseif bytes < 1024 * 1024 then
		return string.format("%.1f KB", bytes / 1024)
	elseif bytes < 1024 * 1024 * 1024 then
		return string.format("%.1f MB", bytes / (1024 * 1024))
	else
		return string.format("%.1f GB", bytes / (1024 * 1024 * 1024))
	end
end

local function formatRate(bytesPerSecond: number): string
	if bytesPerSecond < 1024 then
		return string.format("%.1f B/s", bytesPerSecond)
	elseif bytesPerSecond < 1024 * 1024 then
		return string.format("%.1f KB/s", bytesPerSecond / 1024)
	else
		return string.format("%.1f MB/s", bytesPerSecond / (1024 * 1024))
	end
end

-- Calcular totais
local function getTotalSent(): number
	local total = 0
	for _, bytes in SimpleNetwork._monitorData.sent do
		total += bytes
	end
	return total
end

local function getTotalReceived(): number
	local total = 0
	for _, bytes in SimpleNetwork._monitorData.received do
		total += bytes
	end
	return total
end

function Interface:UpdateUI()
	if not ScreenGui or not MonitorVisible then return end
	
	local block = ScreenGui:FindFirstChild("Block")
	if not block then return end
	
	-- Total Data
	local totalData = block:FindFirstChild("TotalData") :: TextLabel
	if totalData then
		local sent = getTotalSent()
		local received = getTotalReceived()
		totalData.Text = string.format("TOTAL DATA↑ %s  ↓ %s", formatBytes(sent), formatBytes(received))
	end
	
	-- Network Resume (taxa em tempo real)
	local status = block:FindFirstChild("Status")
	if status then
		local networkResume = status:FindFirstChild("NetworkResume") :: TextLabel
		if networkResume then
			local currentTime = os.clock()
			local deltaTime = currentTime - LastUpdate
			
			if deltaTime > 0 then
				local currentSent = getTotalSent()
				local currentReceived = getTotalReceived()
				
				local sentRate = (currentSent - LastSent) / deltaTime
				local receivedRate = (currentReceived - LastReceived) / deltaTime
				
				networkResume.Text = string.format("NETWORK↑ %s  ↓ %s", formatRate(sentRate), formatRate(receivedRate))
				
				-- Cores baseadas em limite
				local settings = SimpleNetwork._settings
				local totalRate = sentRate + receivedRate
				local limit = settings.bandwithLimit
				
				if totalRate >= limit then
					networkResume.TextColor3 = Color3.fromRGB(255, 85, 85)
				elseif totalRate >= limit * 0.8 then
					networkResume.TextColor3 = Color3.fromRGB(255, 170, 0)
				else
					networkResume.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end
	end
	
	self:UpdateTopConsumers(block)
	self:UpdateLiveLogs(block)
	self:UpdateGraph(block)
end

function Interface:UpdateTopConsumers(block: Frame)
	local logs = block:FindFirstChild("Logs")
	if not logs then return end
	
	local topEvents = logs:FindFirstChild("TopEvents")
	if not topEvents then return end
	
	local eventsLabel = topEvents:FindFirstChild("EventsLabel") :: TextLabel
	if not eventsLabel then return end
	
	-- Combinar sent e received
	local combined = {}
	for eventName, sent in SimpleNetwork._monitorData.sent do
		if not combined[eventName] then
			combined[eventName] = {sent = 0, received = 0}
		end
		combined[eventName].sent = sent
	end
	for eventName, received in SimpleNetwork._monitorData.received do
		if not combined[eventName] then
			combined[eventName] = {sent = 0, received = 0}
		end
		combined[eventName].received = received
	end
	
	-- Ordenar por total
	local sorted = {}
	for eventName, stats in combined do
		local total = stats.sent + stats.received
		table.insert(sorted, {name = eventName, total = total, sent = stats.sent, received = stats.received})
	end
	table.sort(sorted, function(a, b) return a.total :: number > b.total end)
	
	-- Montar texto
	local lines = {}
	for i = 1, math.min(MAX_TOP_CONSUMERS, #sorted) do
		local event = sorted[i]
		table.insert(lines, string.format("%d. %s - %s (↑%s ↓%s)\n", 
			i, 
			event.name, 
			formatBytes(event.total),
			formatBytes(event.sent),
			formatBytes(event.received)))
	end
	
	eventsLabel.Text = #lines > 0 and table.concat(lines, "") or "No events yet"
end

function Interface:UpdateLiveLogs(block: Frame)
	local logs = block:FindFirstChild("Logs")
	if not logs then return end
	
	local liveLog = logs:FindFirstChild("LiveLog")
	if not liveLog then return end
	
	local logsLabel = liveLog:FindFirstChild("Logs") :: TextLabel
	if not logsLabel then return end
	
	-- Montar texto com cores
	local lines = {}
	for i, log in ipairs(SimpleNetwork._monitorData.logs) do
		if i > MAX_LOGS then break end
		
		local arrow = log.direction == "sent" and "↑" or "↓"
		local colorTag = log.direction == "sent" and "<font color='#7FFF7F'>" or "<font color='#7F7FFF'>"
		
		table.insert(lines, string.format("%s%s %s</font> - %s\n", 
			colorTag, arrow, log.event, formatBytes(log.bytes)))
	end
	
	logsLabel.Text = #lines > 0 and table.concat(lines, "") or "No logs yet"
	logsLabel.RichText = true
end

function Interface:UpdateGraph(block: Frame)
	local graphFrame = block:FindFirstChild("GraphFrame")
	if not graphFrame then return end
	
	local graphic = graphFrame:FindFirstChild("Graphic")
	if not graphic then return end
	
	-- Encontrar pico máximo para escala
	local maxValue = 1
	for _, value in ipairs(GraphHistory) do
		if value :: number > maxValue :: number then
			maxValue = value
		end
	end
	
	-- Atualizar cada frame
	local frames = graphic:GetChildren()
	local frameIndex = 1
	for _, child in ipairs(frames) do
		if child:IsA("Frame") and child.Name == "Frame" then
			local historyIndex = #GraphHistory - frameIndex + 1
			if historyIndex > 0 and GraphHistory[historyIndex] then
				local value = GraphHistory[historyIndex]
				local normalizedHeight = value :: number / maxValue :: number
				
				child.Size = UDim2.new(0.013, 0, normalizedHeight, 0)
				child.Position = UDim2.new(0, frameIndex * 10, 1, -child.AbsoluteSize.Y)
			else
				child.Size = UDim2.new(0.013, 0, 0, 0)
			end
			
			frameIndex += 1
		end
	end
end

function Interface:UpdateGraphHistory()
	local currentTime = os.clock()
	
	if currentTime - LastUpdate >= GRAPH_INTERVAL then
		local currentSent = getTotalSent()
		local currentReceived = getTotalReceived()
		
		local sentDelta = currentSent - LastSent
		local receivedDelta = currentReceived - LastReceived
		local totalBytes = sentDelta + receivedDelta
		
		table.insert(GraphHistory, totalBytes)
		
		if #GraphHistory > GRAPH_FRAMES then
			table.remove(GraphHistory, 1)
		end
		
		LastSent = currentSent
		LastReceived = currentReceived
		LastUpdate = currentTime
	end
end

function Interface:Toggle()
	if not ScreenGui then
		self:Initialize()
	end
	
	MonitorVisible = not MonitorVisible
	ScreenGui.Enabled = MonitorVisible
	
	if MonitorVisible then
		LastUpdate = os.clock()
		LastSent = getTotalSent()
		LastReceived = getTotalReceived()
	else
		-- Limpar dados do SimpleNetwork._monitorData
		SimpleNetwork._monitorData.sent = {}
		SimpleNetwork._monitorData.received = {}
		SimpleNetwork._monitorData.logs = {}
		GraphHistory = {}
	end
end

function Interface:Initialize()
	local template = script:FindFirstChild("NetworkMonitor")
	if template then
		ScreenGui = template:Clone()
		ScreenGui.Parent = PlayerGui
		ScreenGui.Enabled = false
	else
		warn("[SimpleNetwork] NetworkMonitor template not found!")
		return
	end
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == SimpleNetwork._settings.showMenuBind then
			self:Toggle()
		end
	end)
	
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		TextChatService.MessageReceived:Connect(function(message: TextChatMessage)
			if message.TextSource and message.TextSource.UserId == Player.UserId then
				if message.Text == SimpleNetwork._settings.showMenuCommand then
					self:Toggle()
				end
			end
		end)
	end
	
	RunService.RenderStepped:Connect(function()
		if MonitorVisible then
			self:UpdateGraphHistory()
			self:UpdateUI()
		end
	end)
end

function Interface:Setup(networkModule)
	SimpleNetwork = networkModule
	self:Initialize()
end

return Interface