--[[
-- This file is generated automatically and is not intended to be modified.
-- To view the source code, see the 'src' folder on GitHub!
--
-- Author: 0866
-- License: MIT
-- GitHub: https://github.com/richie0866/remote-spy
--]]

local instanceFromId = {}
local idFromInstance = {}

local modules = {}
local currentlyLoading = {}

-- Module resolution

local function loadModule(object, caller)
	local module = modules[object]

	if module.isLoaded then
		return module.data
	end

	if caller then
		currentlyLoading[caller] = object

		local currentObject = object
		local depth = 0
	
		-- Keep looping until we reach the top of the dependency chain.
		-- Throw an error if we encounter a circular dependency.
		while currentObject do
			depth = depth + 1
			currentObject = currentlyLoading[currentObject]
	
			if currentObject == object then
				local str = currentObject:GetFullName()
	
				for _ = 1, depth do
					currentObject = currentlyLoading[currentObject]
					str = str .. "  ⇒ " .. currentObject:GetFullName()
				end
	
				error("Failed to load '" .. object:GetFullName() .. "'! Detected a circular dependency chain: " .. str, 2)
			end
		end
	end

	local data = module.fn()

	if currentlyLoading[caller] == object then -- Thread-safe cleanup!
		currentlyLoading[caller] = nil
	end

	module.data = data
	module.isLoaded = true

	return data
end

local function start()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	for object in pairs(modules) do
		if object:IsA("LocalScript") and not object.Disabled then
			task.defer(loadModule, object)
		end
	end
end

-- Project setup

local globalMt = {
	__index = getfenv(0),
	__metatable = "This metatable is locked",
}

local function _env(id)
	local object = instanceFromId[id]

	return setmetatable({
		script = object,
		require = function (target)
			if modules[target] and target:IsA("ModuleScript") then
				return loadModule(target, object)
			else
				return require(target)
			end
		end,
	}, globalMt)
end

local function _module(name, className, path, parent, fn)
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = instanceFromId[parent]

	instanceFromId[path] = instance
	idFromInstance[instance] = path

	modules[instance] = {
		fn = fn,
		isLoaded = false,
		value = nil,
	}
end

local function _instance(name, className, path, parent)
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = instanceFromId[parent]

	instanceFromId[path] = instance
	idFromInstance[instance] = path
end


_instance("RemoteSpy", "Folder", "RemoteSpy", nil)

_module("acrylic", "LocalScript", "RemoteSpy.acrylic", "RemoteSpy", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.include.RuntimeLib)
local Make = TS.import(script, TS.getModule(script, "@rbxts", "make"))
local IS_ACRYLIC_ENABLED = TS.import(script, script.Parent, "constants").IS_ACRYLIC_ENABLED
local _services = TS.import(script, TS.getModule(script, "@rbxts", "services"))
local Lighting = _services.Lighting
local Workspace = _services.Workspace
local changed = TS.import(script, script.Parent, "store").changed
local selectIsClosing = TS.import(script, script.Parent, "reducers", "action-bar").selectIsClosing
local baseEffect = Make("DepthOfFieldEffect", {
	FarIntensity = 0,
	InFocusRadius = 0.1,
	NearIntensity = 1,
})
local depthOfFieldDefaults = {}
local function enable()
	for effect in pairs(depthOfFieldDefaults) do
		effect.Enabled = false
	end
	baseEffect.Parent = Lighting
end
local function disable()
	for effect, defaults in pairs(depthOfFieldDefaults) do
		effect.Enabled = defaults.enabled
	end
	baseEffect.Parent = nil
end
local function registerDefaults()
	local register = function(object)
		if object:IsA("DepthOfFieldEffect") then
			local _arg1 = {
				enabled = object.Enabled,
			}
			depthOfFieldDefaults[object] = _arg1
		end
	end
	local _exp = Lighting:GetChildren()
	for _k, _v in ipairs(_exp) do
		register(_v, _k - 1, _exp)
	end
	local _result = Workspace.CurrentCamera
	if _result ~= nil then
		local _exp_1 = _result:GetChildren()
		for _k, _v in ipairs(_exp_1) do
			register(_v, _k - 1, _exp_1)
		end
	end
end
if IS_ACRYLIC_ENABLED then
	registerDefaults()
	enable()
	changed(selectIsClosing, function(active)
		return active and disable()
	end)
end
 end, _env("RemoteSpy.acrylic"))() end)

_module("app", "LocalScript", "RemoteSpy.app", "RemoteSpy", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Provider = TS.import(script, TS.getModule(script, "@rbxts", "roact-rodux-hooked").out).Provider
local App = TS.import(script, script.Parent, "components", "App").default
local IS_LOADED = TS.import(script, script.Parent, "constants").IS_LOADED
local _store = TS.import(script, script.Parent, "store")
local changed = _store.changed
local configureStore = _store.configureStore
local _global_util = TS.import(script, script.Parent, "utils", "global-util")
local getGlobal = _global_util.getGlobal
local setGlobal = _global_util.setGlobal
local selectIsClosing = TS.import(script, script.Parent, "reducers", "action-bar").selectIsClosing
if getGlobal(IS_LOADED) == true then
	error("The global " .. (IS_LOADED .. " is already defined."))
end
local store = configureStore()
local tree = Roact.mount(Roact.createElement(Provider, {
	store = store,
}, {
	Roact.createElement(App),
}))
changed(selectIsClosing, function(active)
	if active then
		Roact.unmount(tree)
		setGlobal(IS_LOADED, false)
		task.defer(function()
			return store:destruct()
		end)
	end
end)
setGlobal(IS_LOADED, true)
 end, _env("RemoteSpy.app"))() end)

_instance("components", "Folder", "RemoteSpy.components", "RemoteSpy")

_module("Acrylic", "ModuleScript", "RemoteSpy.components.Acrylic", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "Acrylic").default
return exports
 end, _env("RemoteSpy.components.Acrylic"))() end)

_module("Acrylic", "ModuleScript", "RemoteSpy.components.Acrylic.Acrylic", "RemoteSpy.components.Acrylic", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local AcrylicImpl = TS.import(script, script.Parent, "AcrylicImpl").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local IS_ACRYLIC_ENABLED = TS.import(script, script.Parent.Parent.Parent, "constants").IS_ACRYLIC_ENABLED
local function Acrylic(_param)
	local distance = _param.distance
	if not IS_ACRYLIC_ENABLED then
		return Roact.createFragment()
	end
	return Roact.createElement(AcrylicImpl, {
		distance = distance,
	})
end
return {
	default = Acrylic,
}
 end, _env("RemoteSpy.components.Acrylic.Acrylic"))() end)

_module("AcrylicImpl", "ModuleScript", "RemoteSpy.components.Acrylic.AcrylicImpl", "RemoteSpy.components.Acrylic", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Workspace = TS.import(script, TS.getModule(script, "@rbxts", "services")).Workspace
local createAcrylic = TS.import(script, script.Parent, "create-acrylic").createAcrylic
local _utils = TS.import(script, script.Parent, "utils")
local getOffset = _utils.getOffset
local viewportPointToWorld = _utils.viewportPointToWorld
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useCallback = _roact_hooked.useCallback
local useEffect = _roact_hooked.useEffect
local useMemo = _roact_hooked.useMemo
local useMutable = _roact_hooked.useMutable
local function AcrylicImpl(_param)
	local distance = _param.distance
	if distance == nil then
		distance = 0.001
	end
	local positions = useMutable({
		topLeft = Vector2.zero,
		topRight = Vector2.zero,
		bottomRight = Vector2.zero,
	})
	local model = useMemo(function()
		local model = createAcrylic()
		model.Parent = Workspace
		return model
	end, {})
	useEffect(function()
		return function()
			return model:Destroy()
		end
	end, {})
	local updatePositions = useCallback(function(size, position)
		local _object = {
			topLeft = position,
		}
		local _left = "topRight"
		local _vector2 = Vector2.new(size.X, 0)
		_object[_left] = position + _vector2
		_object.bottomRight = position + size
		positions.current = _object
	end, { distance })
	local render = useCallback(function()
		local _result = Workspace.CurrentCamera
		if _result ~= nil then
			_result = _result.CFrame
		end
		local _condition = _result
		if _condition == nil then
			_condition = CFrame.new()
		end
		local camera = _condition
		local _binding = positions.current
		local topLeft = _binding.topLeft
		local topRight = _binding.topRight
		local bottomRight = _binding.bottomRight
		local topLeft3D = viewportPointToWorld(topLeft, distance)
		local topRight3D = viewportPointToWorld(topRight, distance)
		local bottomRight3D = viewportPointToWorld(bottomRight, distance)
		local width = (topRight3D - topLeft3D).Magnitude
		local height = (topRight3D - bottomRight3D).Magnitude
		model.CFrame = CFrame.fromMatrix((topLeft3D + bottomRight3D) / 2, camera.XVector, camera.YVector, camera.ZVector)
		model.Mesh.Scale = Vector3.new(width, height, 0)
	end, { distance })
	local onChange = useCallback(function(rbx)
		local offset = getOffset()
		local _absoluteSize = rbx.AbsoluteSize
		local _vector2 = Vector2.new(offset, offset)
		local size = _absoluteSize - _vector2
		local _absolutePosition = rbx.AbsolutePosition
		local _vector2_1 = Vector2.new(offset / 2, offset / 2)
		local position = _absolutePosition + _vector2_1
		updatePositions(size, position)
		task.spawn(render)
	end, {})
	useEffect(function()
		local camera = Workspace.CurrentCamera
		local cframeChanged = camera:GetPropertyChangedSignal("CFrame"):Connect(render)
		local fovChanged = camera:GetPropertyChangedSignal("FieldOfView"):Connect(render)
		local screenChanged = camera:GetPropertyChangedSignal("ViewportSize"):Connect(render)
		task.spawn(render)
		return function()
			cframeChanged:Disconnect()
			fovChanged:Disconnect()
			screenChanged:Disconnect()
		end
	end, { render })
	return Roact.createElement("Frame", {
		[Roact.Change.AbsoluteSize] = onChange,
		[Roact.Change.AbsolutePosition] = onChange,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	})
end
local default = pure(AcrylicImpl)
return {
	default = default,
}
 end, _env("RemoteSpy.components.Acrylic.AcrylicImpl"))() end)

_module("create-acrylic", "ModuleScript", "RemoteSpy.components.Acrylic.create-acrylic", "RemoteSpy.components.Acrylic", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Make = TS.import(script, TS.getModule(script, "@rbxts", "make"))
local function createAcrylic()
	return Make("Part", {
		Name = "Body",
		Color = Color3.new(0, 0, 0),
		Material = Enum.Material.Glass,
		Size = Vector3.new(1, 1, 0),
		Anchored = true,
		CanCollide = false,
		Locked = true,
		CastShadow = false,
		Transparency = 0.999,
		Children = { Make("SpecialMesh", {
			MeshType = Enum.MeshType.Brick,
			Offset = Vector3.new(0, 0, -0.000001),
		}) },
	})
end
return {
	createAcrylic = createAcrylic,
}
 end, _env("RemoteSpy.components.Acrylic.create-acrylic"))() end)

_module("utils", "ModuleScript", "RemoteSpy.components.Acrylic.utils", "RemoteSpy.components.Acrylic", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Workspace = TS.import(script, TS.getModule(script, "@rbxts", "services")).Workspace
local map = TS.import(script, script.Parent.Parent.Parent, "utils", "number-util").map
local function viewportPointToWorld(location, distance)
	local unitRay = Workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
	local _origin = unitRay.Origin
	local _arg0 = unitRay.Direction * distance
	return _origin + _arg0
end
local function getOffset()
	return map(Workspace.CurrentCamera.ViewportSize.Y, 0, 2560, 8, 56)
end
return {
	viewportPointToWorld = viewportPointToWorld,
	getOffset = getOffset,
}
 end, _env("RemoteSpy.components.Acrylic.utils"))() end)

_module("ActionBar", "ModuleScript", "RemoteSpy.components.ActionBar", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "ActionBar").default
return exports
 end, _env("RemoteSpy.components.ActionBar"))() end)

_module("ActionBar", "ModuleScript", "RemoteSpy.components.ActionBar.ActionBar", "RemoteSpy.components.ActionBar", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local ActionBarEffects = TS.import(script, script.Parent, "ActionBarEffects").default
local ActionButton = TS.import(script, script.Parent, "ActionButton").default
local ActionLine = TS.import(script, script.Parent, "ActionLine").default
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function ActionBar()
	return Roact.createFragment({
		Roact.createElement("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.92,
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0, 83),
			BorderSizePixel = 0,
		}),
		Roact.createElement(ActionBarEffects),
		Roact.createElement(Container, {
			size = UDim2.new(1, 0, 0, 36),
			position = UDim2.new(0, 0, 0, 42),
		}, {
			Roact.createElement(ActionButton, {
				id = "navigatePrevious",
				icon = "rbxassetid://9887696242",
			}),
			Roact.createElement(ActionButton, {
				id = "navigateNext",
				icon = "rbxassetid://9887978919",
			}),
			Roact.createElement(ActionLine),
			Roact.createElement(ActionButton, {
				id = "copy",
				icon = "rbxassetid://9887696628",
			}),
			Roact.createElement(ActionButton, {
				id = "save",
				icon = "rbxassetid://9932819855",
			}),
			Roact.createElement(ActionButton, {
				id = "delete",
				icon = "rbxassetid://9887696922",
			}),
			Roact.createElement(ActionLine),
			Roact.createElement(ActionButton, {
				id = "traceback",
				icon = "rbxassetid://9887697255",
				caption = "Traceback",
			}),
			Roact.createElement(ActionButton, {
				id = "copyPath",
				icon = "rbxassetid://9887697099",
				caption = "Copy as path",
			}),
			Roact.createElement("UIListLayout", {
				Padding = UDim.new(0, 4),
				FillDirection = "Horizontal",
				HorizontalAlignment = "Left",
				VerticalAlignment = "Center",
			}),
			Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
			}),
		}),
	})
end
return {
	default = ActionBar,
}
 end, _env("RemoteSpy.components.ActionBar.ActionBar"))() end)

_module("ActionBarEffects", "ModuleScript", "RemoteSpy.components.ActionBar.ActionBarEffects", "RemoteSpy.components.ActionBar", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _tab_group = TS.import(script, script.Parent.Parent.Parent, "reducers", "tab-group")
local TabType = _tab_group.TabType
local deleteTab = _tab_group.deleteTab
local selectActiveTab = _tab_group.selectActiveTab
local _utils = TS.import(script, script.Parent, "utils")
local codifyOutgoingSignal = _utils.codifyOutgoingSignal
local stringifyRemote = _utils.stringifyRemote
local _instance_util = TS.import(script, script.Parent.Parent.Parent, "utils", "instance-util")
local getInstanceFromId = _instance_util.getInstanceFromId
local getInstancePath = _instance_util.getInstancePath
local _remote_log = TS.import(script, script.Parent.Parent.Parent, "reducers", "remote-log")
local makeSelectRemoteLog = _remote_log.makeSelectRemoteLog
local removeOutgoingSignal = _remote_log.removeOutgoingSignal
local selectRemoteIdSelected = _remote_log.selectRemoteIdSelected
local selectSignalSelected = _remote_log.selectSignalSelected
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useEffect = _roact_hooked.useEffect
local removeRemoteLog = TS.import(script, script.Parent.Parent.Parent, "reducers", "remote-log").removeRemoteLog
local setActionEnabled = TS.import(script, script.Parent.Parent.Parent, "reducers", "action-bar").setActionEnabled
local useActionEffect = TS.import(script, script.Parent.Parent.Parent, "hooks", "use-action-effect").useActionEffect
local _use_root_store = TS.import(script, script.Parent.Parent.Parent, "hooks", "use-root-store")
local useRootDispatch = _use_root_store.useRootDispatch
local useRootSelector = _use_root_store.useRootSelector
local useRootStore = _use_root_store.useRootStore
local selectRemoteLog = makeSelectRemoteLog()
local function ActionBarEffects()
	local store = useRootStore()
	local dispatch = useRootDispatch()
	local currentTab = useRootSelector(selectActiveTab)
	local remoteId = useRootSelector(selectRemoteIdSelected)
	local remote = useRootSelector(function(state)
		return if remoteId ~= nil then selectRemoteLog(state, remoteId) else nil
	end)
	local signal = useRootSelector(selectSignalSelected)
	useActionEffect("copy", function()
		if remote then
			local _result = setclipboard
			if _result ~= nil then
				_result(getInstancePath(remote.object))
			end
		elseif signal then
			local _result = setclipboard
			if _result ~= nil then
				_result(codifyOutgoingSignal(signal))
			end
		end
	end)
	useActionEffect("copyPath", function()
		local _result = remote
		if _result ~= nil then
			_result = _result.object
		end
		local _condition = _result
		if _condition == nil then
			_condition = (currentTab and getInstanceFromId(currentTab.id))
		end
		local object = _condition
		if object then
			local _result_1 = setclipboard
			if _result_1 ~= nil then
				_result_1(getInstancePath(object))
			end
		end
	end)
	useActionEffect("save", function()
		if remote then
			local remoteName = string.gsub(string.sub(getInstancePath(remote.object), -66, -1), "[^a-zA-Z0-9]+", "_")
			local fileName = remoteName .. ".txt"
			local fileContents = stringifyRemote(remote)
			local _result = writefile
			if _result ~= nil then
				_result(fileName, fileContents)
			end
		elseif signal then
			local remote = selectRemoteLog(store:getState(), signal.remoteId)
			local _outgoing = remote.outgoing
			local _arg0 = function(s)
				return s.id == signal.id
			end
			-- ▼ ReadonlyArray.findIndex ▼
			local _result = -1
			for _i, _v in ipairs(_outgoing) do
				if _arg0(_v, _i - 1, _outgoing) == true then
					_result = _i - 1
					break
				end
			end
			-- ▲ ReadonlyArray.findIndex ▲
			local signalOrder = _result
			local remoteName = string.gsub(string.sub(getInstancePath(remote.object), -66, -1), "[^a-zA-Z0-9]+", "_")
			local fileName = remoteName .. ("_Signal" .. (tostring(signalOrder + 1) .. ".txt"))
			local fileContents = stringifyRemote(remote, function(s)
				return signal.id == s.id
			end)
			local _result_1 = writefile
			if _result_1 ~= nil then
				_result_1(fileName, fileContents)
			end
		end
	end)
	useActionEffect("delete", function()
		if remote then
			dispatch(removeRemoteLog(remote.id))
			dispatch(deleteTab(remote.id))
		elseif signal then
			dispatch(removeOutgoingSignal(signal.remoteId, signal.id))
		end
	end)
	useEffect(function()
		local remoteEnabled = remoteId ~= nil
		local _condition = signal ~= nil
		if _condition then
			local _result = currentTab
			if _result ~= nil then
				_result = _result.id
			end
			_condition = _result == signal.remoteId
		end
		local signalEnabled = _condition
		local _result = currentTab
		if _result ~= nil then
			_result = _result.type
		end
		local isHome = _result == TabType.Home
		dispatch(setActionEnabled("copy", remoteEnabled or signalEnabled))
		dispatch(setActionEnabled("save", remoteEnabled or signalEnabled))
		dispatch(setActionEnabled("delete", remoteEnabled or signalEnabled))
		dispatch(setActionEnabled("traceback", signalEnabled))
		dispatch(setActionEnabled("copyPath", remoteEnabled or not isHome))
	end, { remoteId == nil, signal, currentTab })
	return Roact.createFragment()
end
local default = pure(ActionBarEffects)
return {
	default = default,
}
 end, _env("RemoteSpy.components.ActionBar.ActionBarEffects"))() end)

_module("ActionButton", "ModuleScript", "RemoteSpy.components.ActionBar.ActionButton", "RemoteSpy.components.ActionBar", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Button = TS.import(script, script.Parent.Parent, "Button").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _action_bar = TS.import(script, script.Parent.Parent.Parent, "reducers", "action-bar")
local activateAction = _action_bar.activateAction
local selectActionById = _action_bar.selectActionById
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local Instant = _flipper.Instant
local Spring = _flipper.Spring
local TextService = TS.import(script, TS.getModule(script, "@rbxts", "services")).TextService
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useMemo = _roact_hooked.useMemo
local useGroupMotor = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).useGroupMotor
local _use_root_store = TS.import(script, script.Parent.Parent.Parent, "hooks", "use-root-store")
local useRootDispatch = _use_root_store.useRootDispatch
local useRootSelector = _use_root_store.useRootSelector
local MARGIN = 10
local BUTTON_DEFAULT = { Spring.new(1, {
	frequency = 6,
}), Spring.new(0, {
	frequency = 6,
}) }
local BUTTON_HOVERED = { Spring.new(0.94, {
	frequency = 6,
}), Spring.new(0, {
	frequency = 6,
}) }
local BUTTON_PRESSED = { Instant.new(0.96), Instant.new(0.2) }
local function ActionButton(_param)
	local id = _param.id
	local icon = _param.icon
	local caption = _param.caption
	local dispatch = useRootDispatch()
	local actionState = useRootSelector(function(state)
		return selectActionById(state, id)
	end)
	local _binding = useGroupMotor({ 1, 0 })
	local transparency = _binding[1]
	local setGoal = _binding[2]
	local backgroundTransparency = if actionState.disabled then 1 else transparency:map(function(t)
		return t[1]
	end)
	local foregroundTransparency = if actionState.disabled then 0.5 else transparency:map(function(t)
		return t[2]
	end)
	local textSize = useMemo(function()
		return if caption ~= nil then TextService:GetTextSize(caption, 11, "Gotham", Vector2.new(150, 36)) else Vector2.new()
	end, { caption })
	local _attributes = {
		onClick = function()
			setGoal(BUTTON_HOVERED)
			local _ = not actionState.disabled and (not actionState.active and dispatch(activateAction(id)))
		end,
		onPress = function()
			return setGoal(BUTTON_PRESSED)
		end,
		onHover = function()
			return setGoal(BUTTON_HOVERED)
		end,
		onHoverEnd = function()
			return setGoal(BUTTON_DEFAULT)
		end,
		active = not actionState.disabled,
		size = UDim2.new(0, if caption ~= nil then textSize.X + 16 + MARGIN * 3 else 36, 0, 36),
		transparency = backgroundTransparency,
		cornerRadius = UDim.new(0, 4),
	}
	local _children = {
		Roact.createElement("ImageLabel", {
			Image = icon,
			ImageTransparency = foregroundTransparency,
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0, MARGIN, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}),
	}
	local _length = #_children
	local _child = caption ~= nil and (Roact.createElement("TextLabel", {
		Text = caption,
		Font = "Gotham",
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = foregroundTransparency,
		TextSize = 11,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, MARGIN * 2 + 16, 0, 0),
		BackgroundTransparency = 1,
	}))
	if _child then
		_children[_length + 1] = _child
	end
	return Roact.createElement(Button, _attributes, _children)
end
local default = pure(ActionButton)
return {
	default = default,
}
 end, _env("RemoteSpy.components.ActionBar.ActionButton"))() end)

_module("ActionLine", "ModuleScript", "RemoteSpy.components.ActionBar.ActionLine", "RemoteSpy.components.ActionBar", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function ActionLine()
	return Roact.createElement(Container, {
		size = UDim2.new(0, 13, 0, 32),
	}, {
		Roact.createElement("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.92,
			Size = UDim2.new(0, 1, 0, 24),
			Position = UDim2.new(0, 6, 0, 4),
			BorderSizePixel = 0,
		}),
	})
end
return {
	default = ActionLine,
}
 end, _env("RemoteSpy.components.ActionBar.ActionLine"))() end)

_module("utils", "ModuleScript", "RemoteSpy.components.ActionBar.utils", "RemoteSpy.components.ActionBar", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local stringifySignalTraceback = TS.import(script, script.Parent.Parent.Parent, "reducers", "remote-log").stringifySignalTraceback
local codifyTable = TS.import(script, script.Parent.Parent.Parent, "utils", "codify").codifyTable
local _function_util = TS.import(script, script.Parent.Parent.Parent, "utils", "function-util")
local describeFunction = _function_util.describeFunction
local stringifyFunctionSignature = _function_util.stringifyFunctionSignature
local getInstancePath = TS.import(script, script.Parent.Parent.Parent, "utils", "instance-util").getInstancePath
local line = "-----------------------------------------------------"
local stringifyOutgoingSignal
local function stringifyRemote(remote, filter)
	local lines = {}
	local _arg0 = "Remote name: " .. remote.object.Name
	table.insert(lines, _arg0)
	local _arg0_1 = "Remote type: " .. remote.object.ClassName
	table.insert(lines, _arg0_1)
	local _arg0_2 = "Remote location: " .. getInstancePath(remote.object)
	table.insert(lines, _arg0_2)
	local _outgoing = remote.outgoing
	local _arg0_3 = function(signal, index)
		if if filter then filter(signal) else true then
			local _arg0_4 = line .. "\n" .. stringifyOutgoingSignal(signal, index)
			table.insert(lines, _arg0_4)
		end
	end
	for _k, _v in ipairs(_outgoing) do
		_arg0_3(_v, _k - 1, _outgoing)
	end
	return table.concat(lines, "\n")
end
function stringifyOutgoingSignal(signal, index)
	local lines = {}
	local description = describeFunction(signal.callback)
	if index ~= nil then
		local _arg0 = "(OUTGOING SIGNAL " .. (tostring(index + 1) .. ")")
		table.insert(lines, _arg0)
	end
	local _arg0 = "Calling script: " .. (if signal.caller then signal.caller.Name else "Not called from a script")
	table.insert(lines, _arg0)
	local _arg0_1 = "Remote name: " .. signal.name
	table.insert(lines, _arg0_1)
	local _arg0_2 = "Remote location: " .. signal.pathFmt
	table.insert(lines, _arg0_2)
	local _arg0_3 = "Remote parameters: " .. codifyTable(signal.parameters)
	table.insert(lines, _arg0_3)
	local _arg0_4 = "Function signature: " .. stringifyFunctionSignature(signal.callback)
	table.insert(lines, _arg0_4)
	local _arg0_5 = "Function source: " .. description.source
	table.insert(lines, _arg0_5)
	table.insert(lines, "Function traceback:")
	for _, line in ipairs(stringifySignalTraceback(signal)) do
		local _arg0_6 = "	" .. line
		table.insert(lines, _arg0_6)
	end
	return table.concat(lines, "\n")
end
local function codifyOutgoingSignal(signal)
	local lines = {}
	local _arg0 = "local remote = " .. signal.pathFmt
	table.insert(lines, _arg0)
	local _arg0_1 = "local arguments = " .. codifyTable(signal.parameters)
	table.insert(lines, _arg0_1)
	if signal.remote:IsA("RemoteEvent") then
		table.insert(lines, "remote:FireServer(unpack(arguments))")
	else
		table.insert(lines, "local results = remote:InvokeServer(unpack(arguments))")
	end
	return table.concat(lines, "\n\n")
end
return {
	stringifyRemote = stringifyRemote,
	stringifyOutgoingSignal = stringifyOutgoingSignal,
	codifyOutgoingSignal = codifyOutgoingSignal,
}
 end, _env("RemoteSpy.components.ActionBar.utils"))() end)

_module("App", "ModuleScript", "RemoteSpy.components.App", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "App").default
return exports
 end, _env("RemoteSpy.components.App"))() end)

_module("App", "ModuleScript", "RemoteSpy.components.App.App", "RemoteSpy.components.App", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local MainWindow = TS.import(script, script.Parent.Parent, "MainWindow").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function App()
	return Roact.createFragment({
		Roact.createElement(MainWindow),
	})
end
return {
	default = App,
}
 end, _env("RemoteSpy.components.App.App"))() end)

_module("App.story", "ModuleScript", "RemoteSpy.components.App.App.story", "RemoteSpy.components.App", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local App = TS.import(script, script.Parent, "App").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Provider = TS.import(script, TS.getModule(script, "@rbxts", "roact-rodux-hooked").out).Provider
local configureStore = TS.import(script, script.Parent.Parent.Parent, "store").configureStore
local _remote_log = TS.import(script, script.Parent.Parent.Parent, "reducers", "remote-log")
local createOutgoingSignal = _remote_log.createOutgoingSignal
local createRemoteLog = _remote_log.createRemoteLog
local pushOutgoingSignal = _remote_log.pushOutgoingSignal
local pushRemoteLog = _remote_log.pushRemoteLog
local getInstanceId = TS.import(script, script.Parent.Parent.Parent, "utils", "instance-util").getInstanceId
local pure = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).pure
local useRootDispatch = TS.import(script, script.Parent.Parent.Parent, "hooks", "use-root-store").useRootDispatch
local rng = Random.new()
local function testFn(x, y)
end
local function testFnCaller(x, ...)
	local args = { ... }
	testFn()
end
local function topLevelCaller(x, y, z)
	testFnCaller()
end
local Dispatcher = pure(function()
	local dispatch = useRootDispatch()
	local names = { "SendMessage", "UpdateCameraLook", "TryGetValue", "GetEnumerator", "ToString", "RequestStoreState", "ReallyLongNameForSomeReason \n ☆*: .｡. o(≧▽≦)o .｡.:*☆ \n Lol", "PurchaseProduct", "IsMessaging", "TestDispatcher", "RequestAction" }
	for _, name in ipairs(names) do
		local className = if rng:NextInteger(0, 1) == 1 then "RemoteEvent" else "RemoteFunction"
		local remote = {
			Name = name,
			ClassName = className,
			Parent = game:GetService("ReplicatedStorage"),
			IsA = function(self, name)
				return className == name
			end,
			GetFullName = function(self)
				return "ReplicatedStorage." .. name
			end,
		}
		dispatch(pushRemoteLog(createRemoteLog(remote)))
		local max = rng:NextInteger(-3, 30)
		do
			local i = 0
			local _shouldIncrement = false
			while true do
				if _shouldIncrement then
					i += 1
				else
					_shouldIncrement = true
				end
				if not (i < max) then
					break
				end
				if i < 0 then
					break
				end
				local signal = createOutgoingSignal(remote, nil, testFn, { testFn, testFnCaller, topLevelCaller }, { "Hello", rng:NextInteger(100, 1000), {
					message = "Hello, world!",
					receivers = {},
				}, rng:NextInteger(100, 1000), game:GetService("Workspace") })
				dispatch(pushOutgoingSignal(getInstanceId(remote), signal))
			end
		end
	end
	return Roact.createFragment()
end)
return function(target)
	local handle = Roact.mount(Roact.createElement(Provider, {
		store = configureStore(),
	}, {
		Roact.createElement(Dispatcher),
		Roact.createElement(App),
	}), target, "App")
	return function()
		Roact.unmount(handle)
	end
end
 end, _env("RemoteSpy.components.App.App.story"))() end)

_module("Button", "ModuleScript", "RemoteSpy.components.Button", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function Button(props)
	local _attributes = {
		[Roact.Event.Activated] = props.onClick,
		[Roact.Event.MouseButton1Down] = props.onPress,
		[Roact.Event.MouseButton1Up] = props.onRelease,
		[Roact.Event.MouseEnter] = props.onHover,
		[Roact.Event.MouseLeave] = props.onHoverEnd,
		Active = props.active,
		BackgroundColor3 = props.background or Color3.new(1, 1, 1),
	}
	local _condition = props.transparency
	if _condition == nil then
		_condition = 1
	end
	_attributes.BackgroundTransparency = _condition
	_attributes.Size = props.size
	_attributes.Position = props.position
	_attributes.AnchorPoint = props.anchorPoint
	_attributes.ZIndex = props.zIndex
	_attributes.LayoutOrder = props.layoutOrder
	_attributes.Text = ""
	_attributes.BorderSizePixel = 0
	_attributes.AutoButtonColor = false
	local _children = {}
	local _length = #_children
	local _child = props[Roact.Children]
	if _child then
		for _k, _v in pairs(_child) do
			if type(_k) == "number" then
				_children[_length + _k] = _v
			else
				_children[_k] = _v
			end
		end
	end
	_length = #_children
	local _child_1 = props.cornerRadius and Roact.createElement("UICorner", {
		CornerRadius = props.cornerRadius,
	})
	if _child_1 then
		_children[_length + 1] = _child_1
	end
	return Roact.createElement("TextButton", _attributes, _children)
end
return {
	default = Button,
}
 end, _env("RemoteSpy.components.Button"))() end)

_module("Container", "ModuleScript", "RemoteSpy.components.Container", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function Container(_param)
	local size = _param.size
	if size == nil then
		size = UDim2.new(1, 0, 1, 0)
	end
	local position = _param.position
	local anchorPoint = _param.anchorPoint
	local order = _param.order
	local clipChildren = _param.clipChildren
	local children = _param[Roact.Children]
	local _attributes = {
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		LayoutOrder = order,
		ClipsDescendants = clipChildren,
		BackgroundTransparency = 1,
	}
	local _children = {}
	local _length = #_children
	if children then
		for _k, _v in pairs(children) do
			if type(_k) == "number" then
				_children[_length + _k] = _v
			else
				_children[_k] = _v
			end
		end
	end
	return Roact.createElement("Frame", _attributes, _children)
end
return {
	default = Container,
}
 end, _env("RemoteSpy.components.Container"))() end)

_module("FunctionTree", "ModuleScript", "RemoteSpy.components.FunctionTree", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "FunctionTree").default
return exports
 end, _env("RemoteSpy.components.FunctionTree"))() end)

_module("FunctionTree", "ModuleScript", "RemoteSpy.components.FunctionTree.FunctionTree", "RemoteSpy.components.FunctionTree", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _SidePanel = TS.import(script, script.Parent.Parent, "SidePanel")
local SidePanel = _SidePanel.default
local useSidePanelContext = _SidePanel.useSidePanelContext
local pure = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).pure
local Divider = function()
	return Roact.createElement("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.92,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BorderSizePixel = 0,
	})
end
local function FunctionTree()
	local _binding = useSidePanelContext()
	local setUpperHidden = _binding.setUpperHidden
	local upperHidden = _binding.upperHidden
	local upperSize = _binding.upperSize
	return Roact.createElement(Container, {
		size = upperSize,
	}, {
		Roact.createElement(SidePanel.TitleBar, {
			caption = "Function Tree",
			hidden = upperHidden,
			toggleHidden = function()
				return setUpperHidden(not upperHidden)
			end,
		}),
		Roact.createElement(Divider),
	})
end
local default = pure(FunctionTree)
return {
	default = default,
}
 end, _env("RemoteSpy.components.FunctionTree.FunctionTree"))() end)

_module("MainWindow", "ModuleScript", "RemoteSpy.components.MainWindow", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "MainWindow").default
return exports
 end, _env("RemoteSpy.components.MainWindow"))() end)

_module("AcrylicBackground", "ModuleScript", "RemoteSpy.components.MainWindow.AcrylicBackground", "RemoteSpy.components.MainWindow", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Acrylic = TS.import(script, script.Parent.Parent, "Acrylic").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Window = TS.import(script, script.Parent.Parent, "Window").default
local function AcrylicBackground()
	return Roact.createElement(Window.Background, {
		background = Color3.fromHex("#FFFFFF"),
		transparency = 0.9,
	}, {
		Roact.createElement(Acrylic),
		Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromHex("#1C1F28"),
			BackgroundTransparency = 0.4,
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
		}, {
			Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}),
		Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromHex("#FFFFFF"),
			BackgroundTransparency = 0.4,
			Size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
		}, {
			Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			Roact.createElement("UIGradient", {
				Color = ColorSequence.new(Color3.fromHex("#252221"), Color3.fromHex("#171515")),
				Rotation = 90,
			}),
		}),
		Roact.createElement("ImageLabel", {
			Image = "rbxassetid://9968344105",
			ImageTransparency = 0.98,
			ScaleType = "Tile",
			TileSize = UDim2.new(0, 128, 0, 128),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}),
		Roact.createElement("ImageLabel", {
			Image = "rbxassetid://9968344227",
			ImageTransparency = 0.85,
			ScaleType = "Tile",
			TileSize = UDim2.new(0, 128, 0, 128),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}),
	})
end
return {
	default = AcrylicBackground,
}
 end, _env("RemoteSpy.components.MainWindow.AcrylicBackground"))() end)

_module("MainWindow", "ModuleScript", "RemoteSpy.components.MainWindow.MainWindow", "RemoteSpy.components.MainWindow", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local AcrylicBackground = TS.import(script, script.Parent, "AcrylicBackground").default
local ActionBar = TS.import(script, script.Parent.Parent, "ActionBar").default
local FunctionTree = TS.import(script, script.Parent.Parent, "FunctionTree").default
local PageGroup = TS.import(script, script.Parent.Parent, "PageGroup").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Root = TS.import(script, script.Parent.Parent, "Root").default
local SidePanel = TS.import(script, script.Parent.Parent, "SidePanel").default
local TabGroup = TS.import(script, script.Parent.Parent, "TabGroup").default
local Traceback = TS.import(script, script.Parent.Parent, "Traceback").default
local Window = TS.import(script, script.Parent.Parent, "Window").default
local activateAction = TS.import(script, script.Parent.Parent.Parent, "reducers", "action-bar").activateAction
local pure = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).pure
local useRootDispatch = TS.import(script, script.Parent.Parent.Parent, "hooks", "use-root-store").useRootDispatch
local function MainWindow()
	local dispatch = useRootDispatch()
	return Roact.createElement(Root, {}, {
		Roact.createElement(Window.Root, {
			initialSize = UDim2.new(0, 1080, 0, 700),
			initialPosition = UDim2.new(0.5, -540, 0.5, -350),
		}, {
			Roact.createElement(Window.DropShadow),
			Roact.createElement(AcrylicBackground),
			Roact.createElement(ActionBar),
			Roact.createElement(TabGroup),
			Roact.createElement(PageGroup),
			Roact.createElement(SidePanel.Root, {}, {
				Roact.createElement(Traceback),
				Roact.createElement(FunctionTree),
			}),
			Roact.createElement(Window.TitleBar, {
				onClose = function()
					return dispatch(activateAction("close"))
				end,
				caption = '<font color="#FFFFFF">RemoteSpy</font>    <font color="#B2B2B2">' .. ("0.2.0-alpha" .. "</font>"),
				captionTransparency = 0.1,
				icon = "rbxassetid://9886981409",
			}),
			Roact.createElement(Window.Resize, {
				minSize = Vector2.new(650, 450),
			}),
		}),
	})
end
local default = pure(MainWindow)
return {
	default = default,
}
 end, _env("RemoteSpy.components.MainWindow.MainWindow"))() end)

_module("MainWindow.story", "ModuleScript", "RemoteSpy.components.MainWindow.MainWindow.story", "RemoteSpy.components.MainWindow", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local MainWindow = TS.import(script, script.Parent, "MainWindow").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Provider = TS.import(script, TS.getModule(script, "@rbxts", "roact-rodux-hooked").out).Provider
local configureStore = TS.import(script, script.Parent.Parent.Parent, "store").configureStore
return function(target)
	local handle = Roact.mount(Roact.createElement(Provider, {
		store = configureStore(),
	}, {
		Roact.createElement(MainWindow),
	}), target, "MainWindow")
	return function()
		Roact.unmount(handle)
	end
end
 end, _env("RemoteSpy.components.MainWindow.MainWindow.story"))() end)

_module("PageGroup", "ModuleScript", "RemoteSpy.components.PageGroup", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "PageGroup").default
return exports
 end, _env("RemoteSpy.components.PageGroup"))() end)

_module("Home", "ModuleScript", "RemoteSpy.components.PageGroup.Home", "RemoteSpy.components.PageGroup", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "Home").default
return exports
 end, _env("RemoteSpy.components.PageGroup.Home"))() end)

_module("Home", "ModuleScript", "RemoteSpy.components.PageGroup.Home.Home", "RemoteSpy.components.PageGroup.Home", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Row = TS.import(script, script.Parent, "Row").default
local Selection = TS.import(script, script.Parent.Parent.Parent, "Selection").default
local arrayToMap = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).arrayToMap
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useEffect = _roact_hooked.useEffect
local _remote_log = TS.import(script, script.Parent.Parent.Parent.Parent, "reducers", "remote-log")
local selectRemoteIdSelected = _remote_log.selectRemoteIdSelected
local selectRemoteLogIds = _remote_log.selectRemoteLogIds
local setRemoteSelected = TS.import(script, script.Parent.Parent.Parent.Parent, "reducers", "remote-log").setRemoteSelected
local _use_root_store = TS.import(script, script.Parent.Parent.Parent.Parent, "hooks", "use-root-store")
local useRootDispatch = _use_root_store.useRootDispatch
local useRootSelector = _use_root_store.useRootSelector
local function Home(_param)
	local pageSelected = _param.pageSelected
	local dispatch = useRootDispatch()
	local remoteLogIds = useRootSelector(selectRemoteLogIds)
	local selection = useRootSelector(selectRemoteIdSelected)
	useEffect(function()
		local _value = not pageSelected and selection
		if _value ~= "" and _value then
			dispatch(setRemoteSelected(nil))
		end
	end, { pageSelected })
	useEffect(function()
		if selection ~= nil and not (table.find(remoteLogIds, selection) ~= nil) then
			dispatch(setRemoteSelected(nil))
		end
	end, { remoteLogIds })
	local selectionOrder = if selection ~= nil then (table.find(remoteLogIds, selection) or 0) - 1 else -1
	local _attributes = {
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, (#remoteLogIds + 1) * (64 + 4)),
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	}
	local _children = {
		Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
		}),
		Roact.createElement(Selection, {
			height = 64,
			offset = if selectionOrder ~= -1 then selectionOrder * (64 + 4) else nil,
			hasSelection = selection ~= nil,
		}),
	}
	local _length = #_children
	for _k, _v in pairs(arrayToMap(remoteLogIds, function(id, order)
		return { id, Roact.createElement(Row, {
			id = id,
			order = order,
			selected = selection == id,
			onClick = function()
				return if selection ~= id then dispatch(setRemoteSelected(id)) else dispatch(setRemoteSelected(nil))
			end,
		}) }
	end)) do
		_children[_k] = _v
	end
	return Roact.createElement("ScrollingFrame", _attributes, _children)
end
local default = pure(Home)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Home.Home"))() end)

_module("Row", "ModuleScript", "RemoteSpy.components.PageGroup.Home.Row", "RemoteSpy.components.PageGroup.Home", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Button = TS.import(script, script.Parent.Parent.Parent, "Button").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local Instant = _flipper.Instant
local Spring = _flipper.Spring
local _tab_group = TS.import(script, script.Parent.Parent.Parent.Parent, "reducers", "tab-group")
local TabType = _tab_group.TabType
local createTabColumn = _tab_group.createTabColumn
local pushTab = _tab_group.pushTab
local selectTab = _tab_group.selectTab
local setActiveTab = _tab_group.setActiveTab
local formatEscapes = TS.import(script, script.Parent.Parent.Parent.Parent, "utils", "format-escapes").formatEscapes
local getInstancePath = TS.import(script, script.Parent.Parent.Parent.Parent, "utils", "instance-util").getInstancePath
local _remote_log = TS.import(script, script.Parent.Parent.Parent.Parent, "reducers", "remote-log")
local makeSelectRemoteLogObject = _remote_log.makeSelectRemoteLogObject
local makeSelectRemoteLogOutgoing = _remote_log.makeSelectRemoteLogOutgoing
local makeSelectRemoteLogType = _remote_log.makeSelectRemoteLogType
local multiply = TS.import(script, script.Parent.Parent.Parent.Parent, "utils", "number-util").multiply
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useCallback = _roact_hooked.useCallback
local useMemo = _roact_hooked.useMemo
local useMutable = _roact_hooked.useMutable
local _roact_hooked_plus = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out)
local useGroupMotor = _roact_hooked_plus.useGroupMotor
local useSpring = _roact_hooked_plus.useSpring
local _use_root_store = TS.import(script, script.Parent.Parent.Parent.Parent, "hooks", "use-root-store")
local useRootSelector = _use_root_store.useRootSelector
local useRootStore = _use_root_store.useRootStore
local ROW_DEFAULT = { Spring.new(1, {
	frequency = 6,
}), Spring.new(0, {
	frequency = 6,
}) }
local ROW_HOVERED = { Spring.new(0.95, {
	frequency = 6,
}), Spring.new(0, {
	frequency = 6,
}) }
local ROW_PRESSED = { Instant.new(0.97), Instant.new(0.2) }
local function Row(_param)
	local onClick = _param.onClick
	local id = _param.id
	local order = _param.order
	local selected = _param.selected
	local store = useRootStore()
	local selectType = useMemo(makeSelectRemoteLogType, {})
	local remoteType = useRootSelector(function(state)
		return selectType(state, id)
	end)
	local selectObject = useMemo(makeSelectRemoteLogObject, {})
	local remoteObject = useRootSelector(function(state)
		return selectObject(state, id)
	end)
	local selectOutgoing = useMemo(makeSelectRemoteLogOutgoing, {})
	local outgoing = useRootSelector(function(state)
		return selectOutgoing(state, id)
	end)
	local _binding = useGroupMotor({ 1, 0 })
	local transparency = _binding[1]
	local setGoal = _binding[2]
	local backgroundTransparency = transparency:map(function(t)
		return t[1]
	end)
	local foregroundTransparency = transparency:map(function(t)
		return t[2]
	end)
	local highlight = useSpring(if selected then 0.95 else 1, {
		frequency = 6,
	})
	local yOffset = useSpring(order * (64 + 4), {
		frequency = 6,
	})
	local lastClickTime = useMutable(0)
	local openOnDoubleClick = useCallback(function()
		if not remoteObject then
			return nil
		end
		local now = tick()
		if now - lastClickTime.current > 0.3 then
			lastClickTime.current = now
			return false
		end
		lastClickTime.current = now
		if selectTab(store:getState(), id) == nil then
			local tab = createTabColumn(id, remoteObject.Name, remoteType)
			store:dispatch(pushTab(tab))
		end
		store:dispatch(setActiveTab(id))
		return true
	end, { id })
	if not remoteObject then
		return Roact.createFragment()
	end
	return Roact.createElement(Button, {
		onClick = function()
			setGoal(ROW_HOVERED)
			local _ = (not openOnDoubleClick() or selected) and onClick()
		end,
		onPress = function()
			return setGoal(ROW_PRESSED)
		end,
		onHover = function()
			return setGoal(ROW_HOVERED)
		end,
		onHoverEnd = function()
			return setGoal(ROW_DEFAULT)
		end,
		size = UDim2.new(1, 0, 0, 64),
		position = yOffset:map(function(y)
			return UDim2.new(0, 0, 0, y)
		end),
		transparency = backgroundTransparency,
		cornerRadius = UDim.new(0, 4),
		layoutOrder = order,
	}, {
		Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = highlight,
		}, {
			Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),
		}),
		Roact.createElement("ImageLabel", {
			Image = if remoteType == TabType.Event then "rbxassetid://9904941486" else "rbxassetid://9904941685",
			ImageTransparency = foregroundTransparency,
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 18, 0, 20),
			BackgroundTransparency = 1,
		}),
		Roact.createElement("TextLabel", {
			Text = formatEscapes(if outgoing and #outgoing > 0 then remoteObject.Name .. (" • " .. tostring(#outgoing)) else remoteObject.Name),
			Font = "Gotham",
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = foregroundTransparency,
			TextSize = 13,
			TextXAlignment = "Left",
			TextYAlignment = "Bottom",
			Size = UDim2.new(1, -100, 0, 12),
			Position = UDim2.new(0, 58, 0, 18),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIGradient", {
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.9, 0), NumberSequenceKeypoint.new(1, 1) }),
			}),
		}),
		Roact.createElement("TextLabel", {
			Text = formatEscapes(getInstancePath(remoteObject)),
			Font = "Gotham",
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = foregroundTransparency:map(function(t)
				return multiply(t, 0.2)
			end),
			TextSize = 11,
			TextXAlignment = "Left",
			TextYAlignment = "Top",
			Size = UDim2.new(1, -100, 0, 12),
			Position = UDim2.new(0, 58, 0, 39),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIGradient", {
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.9, 0), NumberSequenceKeypoint.new(1, 1) }),
			}),
		}),
		Roact.createElement("ImageLabel", {
			Image = "rbxassetid://9913448173",
			ImageTransparency = foregroundTransparency,
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(1, -18, 0, 24),
			BackgroundTransparency = 1,
		}),
	})
end
local default = pure(Row)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Home.Row"))() end)

_module("Logger", "ModuleScript", "RemoteSpy.components.PageGroup.Logger", "RemoteSpy.components.PageGroup", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "Logger").default
return exports
 end, _env("RemoteSpy.components.PageGroup.Logger"))() end)

_module("Header", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Header", "RemoteSpy.components.PageGroup.Logger", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Button = TS.import(script, script.Parent.Parent.Parent, "Button").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local Instant = _flipper.Instant
local Spring = _flipper.Spring
local TabType = TS.import(script, script.Parent.Parent.Parent.Parent, "reducers", "tab-group").TabType
local clearOutgoingSignals = TS.import(script, script.Parent.Parent.Parent.Parent, "reducers", "remote-log").clearOutgoingSignals
local formatEscapes = TS.import(script, script.Parent.Parent.Parent.Parent, "utils", "format-escapes").formatEscapes
local getInstancePath = TS.import(script, script.Parent.Parent.Parent.Parent, "utils", "instance-util").getInstancePath
local _remote_log = TS.import(script, script.Parent.Parent.Parent.Parent, "reducers", "remote-log")
local makeSelectRemoteLogObject = _remote_log.makeSelectRemoteLogObject
local makeSelectRemoteLogType = _remote_log.makeSelectRemoteLogType
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useMemo = _roact_hooked.useMemo
local useGroupMotor = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).useGroupMotor
local _use_root_store = TS.import(script, script.Parent.Parent.Parent.Parent, "hooks", "use-root-store")
local useRootDispatch = _use_root_store.useRootDispatch
local useRootSelector = _use_root_store.useRootSelector
local deleteSprings = {
	default = { Spring.new(0.94, {
		frequency = 6,
	}), Spring.new(0, {
		frequency = 6,
	}) },
	hovered = { Spring.new(0.9, {
		frequency = 6,
	}), Spring.new(0, {
		frequency = 6,
	}) },
	pressed = { Instant.new(0.94), Instant.new(0.2) },
}
local captionTransparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.85, 0), NumberSequenceKeypoint.new(1, 1) })
local function Header(_param)
	local id = _param.id
	local dispatch = useRootDispatch()
	local selectType = useMemo(makeSelectRemoteLogType, {})
	local remoteType = useRootSelector(function(state)
		return selectType(state, id)
	end)
	local selectObject = useMemo(makeSelectRemoteLogObject, {})
	local remoteObject = useRootSelector(function(state)
		return selectObject(state, id)
	end)
	local _binding = useGroupMotor({ 0.94, 0 })
	local deleteTransparency = _binding[1]
	local setDeleteTransparency = _binding[2]
	local deleteButton = useMemo(function()
		return {
			background = deleteTransparency:map(function(t)
				return t[1]
			end),
			foreground = deleteTransparency:map(function(t)
				return t[2]
			end),
		}
	end, {})
	return Roact.createElement("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.96,
		Size = UDim2.new(1, 0, 0, 64),
		LayoutOrder = -1,
	}, {
		Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
		Roact.createElement(Button, {
			onClick = function()
				setDeleteTransparency(deleteSprings.hovered)
				dispatch(clearOutgoingSignals(id))
			end,
			onPress = function()
				return setDeleteTransparency(deleteSprings.pressed)
			end,
			onHover = function()
				return setDeleteTransparency(deleteSprings.hovered)
			end,
			onHoverEnd = function()
				return setDeleteTransparency(deleteSprings.default)
			end,
			anchorPoint = Vector2.new(1, 0),
			size = UDim2.new(0, 94, 0, 28),
			position = UDim2.new(1, -18, 0, 18),
			transparency = deleteButton.background,
			cornerRadius = UDim.new(0, 4),
		}, {
			Roact.createElement("TextLabel", {
				Text = "Delete history",
				Font = "Gotham",
				TextColor3 = Color3.new(1, 1, 1),
				TextTransparency = deleteButton.foreground,
				TextSize = 11,
				TextXAlignment = "Center",
				TextYAlignment = "Center",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
			}, {
				Roact.createElement("UIGradient", {
					Transparency = captionTransparency,
				}),
			}),
		}),
		Roact.createElement("ImageLabel", {
			Image = if remoteType == TabType.Event then "rbxassetid://9904941486" else "rbxassetid://9904941685",
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 18, 0, 20),
			BackgroundTransparency = 1,
		}),
		Roact.createElement("TextLabel", {
			Text = if remoteObject then formatEscapes(remoteObject.Name) else "Unknown",
			Font = "Gotham",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 13,
			TextXAlignment = "Left",
			TextYAlignment = "Bottom",
			Size = UDim2.new(1, -170, 0, 12),
			Position = UDim2.new(0, 58, 0, 18),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIGradient", {
				Transparency = captionTransparency,
			}),
		}),
		Roact.createElement("TextLabel", {
			Text = if remoteObject then formatEscapes(getInstancePath(remoteObject)) else "Unknown",
			Font = "Gotham",
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0.2,
			TextSize = 11,
			TextXAlignment = "Left",
			TextYAlignment = "Top",
			Size = UDim2.new(1, -170, 0, 12),
			Position = UDim2.new(0, 58, 0, 39),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIGradient", {
				Transparency = captionTransparency,
			}),
		}),
	})
end
local default = pure(Header)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Logger.Header"))() end)

_module("Logger", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Logger", "RemoteSpy.components.PageGroup.Logger", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent.Parent, "Container").default
local Header = TS.import(script, script.Parent, "Header").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Row = TS.import(script, script.Parent, "Row").default
local Selection = TS.import(script, script.Parent.Parent.Parent, "Selection").default
local arrayToMap = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).arrayToMap
local _remote_log = TS.import(script, script.Parent.Parent.Parent.Parent, "reducers", "remote-log")
local makeSelectRemoteLogOutgoing = _remote_log.makeSelectRemoteLogOutgoing
local selectSignalIdSelected = _remote_log.selectSignalIdSelected
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useBinding = _roact_hooked.useBinding
local useMemo = _roact_hooked.useMemo
local useRootSelector = TS.import(script, script.Parent.Parent.Parent.Parent, "hooks", "use-root-store").useRootSelector
local function Logger(_param)
	local id = _param.id
	local selectOutgoing = useMemo(makeSelectRemoteLogOutgoing, {})
	local outgoing = useRootSelector(function(state)
		return selectOutgoing(state, id)
	end)
	local selection = useRootSelector(selectSignalIdSelected)
	local selectionOrder = useMemo(function()
		local _result = outgoing
		if _result ~= nil then
			local _arg0 = function(signal)
				return signal.id == selection
			end
			-- ▼ ReadonlyArray.findIndex ▼
			local _result_1 = -1
			for _i, _v in ipairs(_result) do
				if _arg0(_v, _i - 1, _result) == true then
					_result_1 = _i - 1
					break
				end
			end
			-- ▲ ReadonlyArray.findIndex ▲
			_result = _result_1
		end
		local _condition = _result
		if _condition == nil then
			_condition = -1
		end
		return _condition
	end, { outgoing, selection })
	local _binding = useBinding(0)
	local contentHeight = _binding[1]
	local setContentHeight = _binding[2]
	if not outgoing then
		return Roact.createFragment()
	end
	local _attributes = {
		CanvasSize = contentHeight:map(function(h)
			return UDim2.new(0, 0, 0, h + 48)
		end),
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	}
	local _children = {
		Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
		}),
		Roact.createElement(Selection, {
			height = 64,
			offset = if selection ~= nil and selectionOrder ~= -1 then (selectionOrder + 1) * (64 + 4) else nil,
			hasSelection = selection ~= nil and selectionOrder ~= -1,
		}),
	}
	local _length = #_children
	local _children_1 = {
		Roact.createElement("UIListLayout", {
			[Roact.Change.AbsoluteContentSize] = function(rbx)
				return setContentHeight(rbx.AbsoluteContentSize.Y)
			end,
			SortOrder = "LayoutOrder",
			FillDirection = "Vertical",
			Padding = UDim.new(0, 4),
			VerticalAlignment = "Top",
		}),
		Roact.createElement(Header, {
			id = id,
		}),
	}
	local _length_1 = #_children_1
	for _k, _v in pairs(arrayToMap(outgoing, function(signal, order)
		return { signal.id, Roact.createElement(Row, {
			signal = signal,
			order = order,
			selected = selection == signal.id,
		}) }
	end)) do
		_children_1[_k] = _v
	end
	_children[_length + 1] = Roact.createElement(Container, {}, _children_1)
	return Roact.createElement("ScrollingFrame", _attributes, _children)
end
local default = pure(Logger)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Logger.Logger"))() end)

_module("Row", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Row", "RemoteSpy.components.PageGroup.Logger", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "Row").default
return exports
 end, _env("RemoteSpy.components.PageGroup.Logger.Row"))() end)

_module("Row", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Row.Row", "RemoteSpy.components.PageGroup.Logger.Row", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local RowView = TS.import(script, script.Parent, "RowView").default
local Spring = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src).Spring
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useBinding = _roact_hooked.useBinding
local useEffect = _roact_hooked.useEffect
local useSingleMotor = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).useSingleMotor
local function Row(_param)
	local signal = _param.signal
	local order = _param.order
	local selected = _param.selected
	local _binding = useBinding(0)
	local contentHeight = _binding[1]
	local setContentHeight = _binding[2]
	local _binding_1 = useSingleMotor(0)
	local animation = _binding_1[1]
	local setGoal = _binding_1[2]
	useEffect(function()
		setGoal(Spring.new(if selected then 1 else 0, {
			frequency = 6,
		}))
	end, { selected })
	return Roact.createElement(Container, {
		order = order,
		size = Roact.joinBindings({ contentHeight, animation }):map(function(_param_1)
			local y = _param_1[1]
			local a = _param_1[2]
			return UDim2.new(1, 0, 0, 64 + math.round(y * a))
		end),
		clipChildren = true,
	}, {
		Roact.createElement(RowView, {
			signal = signal,
			onHeightChange = setContentHeight,
			selected = selected,
		}),
	})
end
local default = pure(Row)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Logger.Row.Row"))() end)

_module("RowBody", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Row.RowBody", "RemoteSpy.components.PageGroup.Logger.Row", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local RowCaption = TS.import(script, script.Parent, "RowCaption").default
local RowDoubleCaption = TS.import(script, script.Parent, "RowDoubleCaption").default
local RowLine = TS.import(script, script.Parent, "RowLine").default
local stringifySignalTraceback = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "reducers", "remote-log").stringifySignalTraceback
local codify = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "utils", "codify").codify
local _function_util = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "utils", "function-util")
local describeFunction = _function_util.describeFunction
local stringifyFunctionSignature = _function_util.stringifyFunctionSignature
local formatEscapes = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "utils", "format-escapes").formatEscapes
local getInstancePath = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "utils", "instance-util").getInstancePath
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useMemo = _roact_hooked.useMemo
local function stringifyTypesAndValues(list)
	local types = {}
	local values = {}
	for index, value in pairs(list) do
		if index > 12 then
			table.insert(types, "...")
			table.insert(values, "...")
			break
		end
		if typeof(value) == "Instance" then
			local _className = value.ClassName
			table.insert(types, _className)
		else
			local _arg0 = typeof(value)
			table.insert(types, _arg0)
		end
		local _arg0 = formatEscapes(string.sub(codify(value, -1), 1, 256))
		table.insert(values, _arg0)
	end
	return { types, values }
end
local function RowBody(_param)
	local signal = _param.signal
	local description = useMemo(function()
		return describeFunction(signal.callback)
	end, {})
	local tracebackNames = useMemo(function()
		return stringifySignalTraceback(signal)
	end, {})
	local _binding = useMemo(function()
		return stringifyTypesAndValues(signal.parameters)
	end, {})
	local parameterTypes = _binding[1]
	local parameterValues = _binding[2]
	local _binding_1 = useMemo(function()
		return if signal.returns then stringifyTypesAndValues(signal.returns) else { { "void" }, { "void" } }
	end, {})
	local returnTypes = _binding_1[1]
	local returnValues = _binding_1[2]
	local _children = {
		Roact.createElement(RowLine),
		Roact.createElement("Frame", {
			AutomaticSize = "Y",
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.98,
			BorderSizePixel = 0,
		}, {
			Roact.createElement(RowCaption, {
				text = "Remote name",
				description = formatEscapes(signal.name),
				wrapped = true,
			}),
			Roact.createElement(RowCaption, {
				text = "Remote location",
				description = formatEscapes(signal.path),
				wrapped = true,
			}),
			Roact.createElement(RowCaption, {
				text = "Remote caller",
				description = if signal.caller then formatEscapes(getInstancePath(signal.caller)) else "No script found",
				wrapped = true,
			}),
			Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 58),
				PaddingRight = UDim.new(0, 58),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			}),
			Roact.createElement("UIListLayout", {
				FillDirection = "Vertical",
				Padding = UDim.new(),
				VerticalAlignment = "Top",
			}),
		}),
	}
	local _length = #_children
	local _child = #parameterTypes > 0 and (Roact.createFragment({
		Roact.createElement(RowLine),
		Roact.createElement("Frame", {
			AutomaticSize = "Y",
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.98,
			BorderSizePixel = 0,
		}, {
			Roact.createElement(RowDoubleCaption, {
				text = "Parameters",
				hint = table.concat(parameterTypes, "\n"),
				description = table.concat(parameterValues, "\n"),
			}),
			returnTypes and (Roact.createElement(RowDoubleCaption, {
				text = "Returns",
				hint = table.concat(returnTypes, "\n"),
				description = table.concat(returnValues, "\n"),
			})),
			Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 58),
				PaddingRight = UDim.new(0, 58),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			}),
			Roact.createElement("UIListLayout", {
				FillDirection = "Vertical",
				Padding = UDim.new(),
				VerticalAlignment = "Top",
			}),
		}),
	}))
	if _child then
		_children[_length + 1] = _child
	end
	_length = #_children
	_children[_length + 1] = Roact.createElement(RowLine)
	_children[_length + 2] = Roact.createElement("ImageLabel", {
		AutomaticSize = "Y",
		Image = "rbxassetid://9913871236",
		ImageColor3 = Color3.new(1, 1, 1),
		ImageTransparency = 0.98,
		ScaleType = "Slice",
		SliceCenter = Rect.new(4, 4, 4, 4),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
	}, {
		Roact.createElement(RowCaption, {
			text = "Signature",
			description = stringifyFunctionSignature(signal.callback),
			wrapped = true,
		}),
		Roact.createElement(RowCaption, {
			text = "Source",
			description = description.source,
			wrapped = true,
		}),
		Roact.createElement(RowCaption, {
			text = "Traceback",
			wrapped = true,
			description = table.concat(tracebackNames, "\n"),
		}),
		Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 58),
			PaddingRight = UDim.new(0, 58),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
		Roact.createElement("UIListLayout", {
			FillDirection = "Vertical",
			Padding = UDim.new(),
			VerticalAlignment = "Top",
		}),
	})
	return Roact.createFragment(_children)
end
local default = pure(RowBody)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Logger.Row.RowBody"))() end)

_module("RowCaption", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Row.RowCaption", "RemoteSpy.components.PageGroup.Logger.Row", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function RowCaption(_param)
	local text = _param.text
	local description = _param.description
	local wrapped = _param.wrapped
	local richText = _param.richText
	return Roact.createElement("TextLabel", {
		Text = text,
		Font = "Gotham",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 11,
		AutomaticSize = "Y",
		Size = UDim2.new(1, 50, 0, 23),
		TextXAlignment = "Left",
		TextYAlignment = "Top",
		BackgroundTransparency = 1,
	}, {
		Roact.createElement("TextLabel", {
			RichText = richText,
			Text = description,
			Font = "Gotham",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 11,
			TextTransparency = 0.3,
			TextWrapped = wrapped,
			AutomaticSize = "Y",
			Size = UDim2.new(1, -114, 0, 0),
			Position = UDim2.new(0, 114, 0, 0),
			TextXAlignment = "Left",
			TextYAlignment = "Top",
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIPadding", {
				PaddingBottom = UDim.new(0, 6),
			}),
		}),
		Roact.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 4),
		}),
	})
end
return {
	default = RowCaption,
}
 end, _env("RemoteSpy.components.PageGroup.Logger.Row.RowCaption"))() end)

_module("RowDoubleCaption", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Row.RowDoubleCaption", "RemoteSpy.components.PageGroup.Logger.Row", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function RowDoubleCaption(_param)
	local text = _param.text
	local hint = _param.hint
	local description = _param.description
	return Roact.createElement("TextLabel", {
		Text = text,
		Font = "Gotham",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 11,
		AutomaticSize = "Y",
		Size = UDim2.new(1, 0, 0, 23),
		TextXAlignment = "Left",
		TextYAlignment = "Top",
		BackgroundTransparency = 1,
	}, {
		Roact.createElement("TextLabel", {
			Text = hint,
			Font = "Gotham",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 11,
			TextTransparency = 0.5,
			AutomaticSize = "Y",
			Size = UDim2.new(1, -114, 0, 0),
			Position = UDim2.new(0, 114, 0, 0),
			TextXAlignment = "Left",
			TextYAlignment = "Top",
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIPadding", {
				PaddingBottom = UDim.new(0, 6),
			}),
		}),
		Roact.createElement("TextLabel", {
			Text = description,
			Font = "Gotham",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 11,
			TextTransparency = 0.3,
			AutomaticSize = "Y",
			Size = UDim2.new(1, -114 - 100, 0, 0),
			Position = UDim2.new(0, 114 + 100, 0, 0),
			TextXAlignment = "Left",
			TextYAlignment = "Top",
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIPadding", {
				PaddingBottom = UDim.new(0, 6),
			}),
		}),
		Roact.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 4),
		}),
	})
end
return {
	default = RowDoubleCaption,
}
 end, _env("RemoteSpy.components.PageGroup.Logger.Row.RowDoubleCaption"))() end)

_module("RowHeader", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Row.RowHeader", "RemoteSpy.components.PageGroup.Logger.Row", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Button = TS.import(script, script.Parent.Parent.Parent.Parent, "Button").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local Instant = _flipper.Instant
local Spring = _flipper.Spring
local formatEscapes = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "utils", "format-escapes").formatEscapes
local getInstancePath = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "utils", "instance-util").getInstancePath
local multiply = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "utils", "number-util").multiply
local pure = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).pure
local stringifyFunctionSignature = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "utils", "function-util").stringifyFunctionSignature
local useGroupMotor = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).useGroupMotor
local rowSprings = {
	default = { Spring.new(0.97, {
		frequency = 6,
	}), Spring.new(0, {
		frequency = 6,
	}) },
	defaultOpen = { Spring.new(0.96, {
		frequency = 6,
	}), Spring.new(0, {
		frequency = 6,
	}) },
	hovered = { Spring.new(0.93, {
		frequency = 6,
	}), Spring.new(0, {
		frequency = 6,
	}) },
	pressed = { Instant.new(0.98), Instant.new(0.2) },
}
local captionTransparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.9, 0), NumberSequenceKeypoint.new(1, 1) })
local function RowHeader(_param)
	local signal = _param.signal
	local open = _param.open
	local onClick = _param.onClick
	local _binding = useGroupMotor({ 0.97, 0 })
	local rowTransparency = _binding[1]
	local setRowTransparency = _binding[2]
	local rowButton = {
		background = rowTransparency:map(function(t)
			return t[1]
		end),
		foreground = rowTransparency:map(function(t)
			return t[2]
		end),
	}
	return Roact.createElement(Button, {
		onClick = function()
			setRowTransparency(rowSprings.hovered)
			onClick()
		end,
		onPress = function()
			return setRowTransparency(rowSprings.pressed)
		end,
		onHover = function()
			return setRowTransparency(rowSprings.hovered)
		end,
		onHoverEnd = function()
			return setRowTransparency(if open then rowSprings.defaultOpen else rowSprings.default)
		end,
		size = UDim2.new(1, 0, 0, 64),
	}, {
		Roact.createElement("ImageLabel", {
			Image = if open then "rbxassetid://9913260292" else "rbxassetid://9913260388",
			ImageColor3 = Color3.new(1, 1, 1),
			ImageTransparency = rowButton.background,
			ScaleType = "Slice",
			SliceCenter = Rect.new(4, 4, 4, 4),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}),
		Roact.createElement("ImageLabel", {
			Image = "rbxassetid://9913356706",
			ImageTransparency = rowButton.foreground,
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 18, 0, 20),
			BackgroundTransparency = 1,
		}),
		Roact.createElement("TextLabel", {
			Text = (if signal.caller then formatEscapes(signal.caller.Name) else "No script") .. (" • " .. stringifyFunctionSignature(signal.callback)),
			Font = "Gotham",
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = rowButton.foreground,
			TextSize = 13,
			TextXAlignment = "Left",
			TextYAlignment = "Bottom",
			Size = UDim2.new(1, -100, 0, 12),
			Position = UDim2.new(0, 58, 0, 18),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIGradient", {
				Transparency = captionTransparency,
			}),
		}),
		Roact.createElement("TextLabel", {
			Text = if signal.caller then formatEscapes(getInstancePath(signal.caller)) else "Not called from a script",
			Font = "Gotham",
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = rowButton.foreground:map(function(t)
				return multiply(t, 0.2)
			end),
			TextSize = 11,
			TextXAlignment = "Left",
			TextYAlignment = "Top",
			Size = UDim2.new(1, -100, 0, 12),
			Position = UDim2.new(0, 58, 0, 39),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement("UIGradient", {
				Transparency = captionTransparency,
			}),
		}),
		Roact.createElement("ImageLabel", {
			Image = if open then "rbxassetid://9913448536" else "rbxassetid://9913448364",
			ImageTransparency = rowButton.foreground,
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(1, -18, 0, 24),
			BackgroundTransparency = 1,
		}),
	})
end
local default = pure(RowHeader)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Logger.Row.RowHeader"))() end)

_module("RowLine", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Row.RowLine", "RemoteSpy.components.PageGroup.Logger.Row", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function RowLine()
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
	})
end
return {
	default = RowLine,
}
 end, _env("RemoteSpy.components.PageGroup.Logger.Row.RowLine"))() end)

_module("RowView", "ModuleScript", "RemoteSpy.components.PageGroup.Logger.Row.RowView", "RemoteSpy.components.PageGroup.Logger.Row", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local RowBody = TS.import(script, script.Parent, "RowBody").default
local RowHeader = TS.import(script, script.Parent, "RowHeader").default
local toggleSignalSelected = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "reducers", "remote-log").toggleSignalSelected
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useBinding = _roact_hooked.useBinding
local useCallback = _roact_hooked.useCallback
local useRootDispatch = TS.import(script, script.Parent.Parent.Parent.Parent.Parent, "hooks", "use-root-store").useRootDispatch
local function RowView(_param)
	local signal = _param.signal
	local selected = _param.selected
	local onHeightChange = _param.onHeightChange
	local dispatch = useRootDispatch()
	local _binding = useBinding(0)
	local contentHeight = _binding[1]
	local setContentHeight = _binding[2]
	local toggle = useCallback(function()
		return dispatch(toggleSignalSelected(signal.remoteId, signal.id))
	end, {})
	local _children = {
		Roact.createElement(RowHeader, {
			signal = signal,
			open = selected,
			onClick = toggle,
		}),
	}
	local _length = #_children
	local _attributes = {
		clipChildren = true,
		size = contentHeight:map(function(y)
			return UDim2.new(1, 0, 0, y)
		end),
		position = UDim2.new(0, 0, 0, 64),
	}
	local _children_1 = {
		Roact.createElement("UIListLayout", {
			[Roact.Change.AbsoluteContentSize] = function(_param_1)
				local AbsoluteContentSize = _param_1.AbsoluteContentSize
				setContentHeight(AbsoluteContentSize.Y)
				onHeightChange(AbsoluteContentSize.Y)
			end,
			SortOrder = "LayoutOrder",
			FillDirection = "Vertical",
			Padding = UDim.new(),
			VerticalAlignment = "Top",
		}),
	}
	local _length_1 = #_children_1
	local _child = selected and Roact.createElement(RowBody, {
		signal = signal,
	})
	if _child then
		_children_1[_length_1 + 1] = _child
	end
	_children[_length + 1] = Roact.createElement(Container, _attributes, _children_1)
	return Roact.createFragment(_children)
end
local default = pure(RowView)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Logger.Row.RowView"))() end)

_module("Page", "ModuleScript", "RemoteSpy.components.PageGroup.Page", "RemoteSpy.components.PageGroup", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Home = TS.import(script, script.Parent, "Home").default
local Logger = TS.import(script, script.Parent, "Logger").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Script = TS.import(script, script.Parent, "Script").default
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local Instant = _flipper.Instant
local Spring = _flipper.Spring
local _tab_group = TS.import(script, script.Parent.Parent.Parent, "reducers", "tab-group")
local TabType = _tab_group.TabType
local selectActiveTabId = _tab_group.selectActiveTabId
local selectActiveTabOrder = _tab_group.selectActiveTabOrder
local selectTabOrder = _tab_group.selectTabOrder
local selectTabType = _tab_group.selectTabType
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useEffect = _roact_hooked.useEffect
local useMutable = _roact_hooked.useMutable
local useRootSelector = TS.import(script, script.Parent.Parent.Parent, "hooks", "use-root-store").useRootSelector
local useSingleMotor = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).useSingleMotor
local function Page(_param)
	local id = _param.id
	local tabType = useRootSelector(function(state)
		return selectTabType(state, id)
	end)
	local tabOrder = useRootSelector(function(state)
		return selectTabOrder(state, id)
	end)
	local activeTabOrder = useRootSelector(selectActiveTabOrder)
	local activeTabId = useRootSelector(selectActiveTabId)
	local lastActiveTabId = useMutable("")
	local targetSide = if tabOrder < activeTabOrder then -1 elseif tabOrder > activeTabOrder then 1 else 0
	local _binding = useSingleMotor(if targetSide == 0 then 1 else targetSide)
	local side = _binding[1]
	local setSide = _binding[2]
	useEffect(function()
		local isOrWasActive = id == activeTabId or id == lastActiveTabId.current
		local activeTabChanged = activeTabId ~= lastActiveTabId.current
		if isOrWasActive and activeTabChanged then
			setSide(Spring.new(targetSide))
		else
			setSide(Instant.new(targetSide))
		end
	end, { targetSide })
	useEffect(function()
		lastActiveTabId.current = activeTabId
	end)
	local _attributes = {
		position = side:map(function(s)
			return UDim2.new(s, 0, 0, 0)
		end),
	}
	local _children = {}
	local _length = #_children
	local _child = if tabType == TabType.Event or tabType == TabType.Function then (Roact.createElement(Logger, {
		id = id,
	})) elseif tabType == TabType.Home then (Roact.createElement(Home, {
		pageSelected = activeTabId == id,
	})) elseif tabType == TabType.Script then (Roact.createElement(Script)) else nil
	if _child then
		_children[_length + 1] = _child
	end
	return Roact.createElement(Container, _attributes, _children)
end
local default = pure(Page)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Page"))() end)

_module("PageGroup", "ModuleScript", "RemoteSpy.components.PageGroup.PageGroup", "RemoteSpy.components.PageGroup", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Page = TS.import(script, script.Parent, "Page").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local SIDE_PANEL_WIDTH = TS.import(script, script.Parent.Parent.Parent, "constants").SIDE_PANEL_WIDTH
local arrayToMap = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).arrayToMap
local pure = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).pure
local useTabs = TS.import(script, script.Parent.Parent, "TabGroup").useTabs
local function PageGroup()
	local tabs = useTabs()
	local _attributes = {
		BackgroundTransparency = 0.96,
		BackgroundColor3 = Color3.fromHex("#FFFFFF"),
		Size = UDim2.new(1, -SIDE_PANEL_WIDTH - 5, 1, -129),
		Position = UDim2.new(0, 5, 0, 124),
		ClipsDescendants = true,
	}
	local _children = {
		Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
	}
	local _length = #_children
	for _k, _v in pairs(arrayToMap(tabs, function(tab)
		return { tab.id, Roact.createElement(Page, {
			id = tab.id,
		}) }
	end)) do
		_children[_k] = _v
	end
	return Roact.createElement("Frame", _attributes, _children)
end
local default = pure(PageGroup)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.PageGroup"))() end)

_module("Script", "ModuleScript", "RemoteSpy.components.PageGroup.Script", "RemoteSpy.components.PageGroup", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "Script").default
return exports
 end, _env("RemoteSpy.components.PageGroup.Script"))() end)

_module("Script", "ModuleScript", "RemoteSpy.components.PageGroup.Script.Script", "RemoteSpy.components.PageGroup.Script", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local pure = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).pure
local function Script()
	return Roact.createElement(Container, {}, {
		Roact.createElement("TextLabel", {
			Text = "Script page",
			TextSize = 30,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}),
	})
end
local default = pure(Script)
return {
	default = default,
}
 end, _env("RemoteSpy.components.PageGroup.Script.Script"))() end)

_module("Root", "ModuleScript", "RemoteSpy.components.Root", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local DISPLAY_ORDER = TS.import(script, script.Parent.Parent, "constants").DISPLAY_ORDER
local Players = TS.import(script, TS.getModule(script, "@rbxts", "services")).Players
local function hasCoreAccess()
	local _arg0 = function()
		return game:GetService("CoreGui").Name
	end
	local _success, _valueOrError = pcall(_arg0)
	return (_success and {
		success = true,
		value = _valueOrError,
	} or {
		success = false,
		error = _valueOrError,
	}).success
end
local function getTarget()
	if gethui then
		return gethui()
	end
	if hasCoreAccess() then
		return game:GetService("CoreGui")
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end
local function Root(_param)
	local displayOrder = _param.displayOrder
	if displayOrder == nil then
		displayOrder = 0
	end
	local children = _param[Roact.Children]
	local _attributes = {
		target = getTarget(),
	}
	local _children = {}
	local _length = #_children
	local _attributes_1 = {
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = "Sibling",
		DisplayOrder = DISPLAY_ORDER + displayOrder,
	}
	local _children_1 = {}
	local _length_1 = #_children_1
	if children then
		for _k, _v in pairs(children) do
			if type(_k) == "number" then
				_children_1[_length_1 + _k] = _v
			else
				_children_1[_k] = _v
			end
		end
	end
	_children[_length + 1] = Roact.createElement("ScreenGui", _attributes_1, _children_1)
	return Roact.createElement(Roact.Portal, _attributes, _children)
end
return {
	default = Root,
}
 end, _env("RemoteSpy.components.Root"))() end)

_module("Selection", "ModuleScript", "RemoteSpy.components.Selection", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local Instant = _flipper.Instant
local Linear = _flipper.Linear
local Spring = _flipper.Spring
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useEffect = _roact_hooked.useEffect
local _roact_hooked_plus = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out)
local useSingleMotor = _roact_hooked_plus.useSingleMotor
local useSpring = _roact_hooked_plus.useSpring
local function Selection(_param)
	local height = _param.height
	local offset = _param.offset
	local hasSelection = _param.hasSelection
	local _binding = useSingleMotor(-100)
	local offsetAnim = _binding[1]
	local setOffsetGoal = _binding[2]
	local offsetSpring = _binding[3]
	local _binding_1 = useSingleMotor(0)
	local speedAnim = _binding_1[1]
	local setSpeedGoal = _binding_1[2]
	local heightAnim = useSpring(if hasSelection then 20 else 0, {
		frequency = 8,
	})
	useEffect(function()
		if offset ~= nil then
			setOffsetGoal(Spring.new(offset, {
				frequency = 5,
			}))
		end
	end, { offset })
	useEffect(function()
		if hasSelection and offset ~= nil then
			setOffsetGoal(Instant.new(offset))
		end
	end, { hasSelection })
	useEffect(function()
		if not hasSelection then
			setSpeedGoal(Instant.new(0))
			return nil
		end
		local lastValue = offset
		local lastTime = 0
		local handle = offsetSpring:onStep(function(value)
			local now = tick()
			local deltaTime = now - lastTime
			if lastValue ~= nil then
				setSpeedGoal(Linear.new(math.abs(value - lastValue) / (deltaTime * 60), {
					velocity = 300,
				}))
				lastValue = value
			end
			lastTime = now
		end)
		return function()
			return handle:disconnect()
		end
	end, { hasSelection })
	return Roact.createElement(Container, {
		size = UDim2.new(0, 4, 0, height),
		position = offsetAnim:map(function(y)
			return UDim2.new(0, 0, 0, math.round(y))
		end),
	}, {
		Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = Roact.joinBindings({ heightAnim, speedAnim }):map(function(_param_1)
				local h = _param_1[1]
				local s = _param_1[2]
				return UDim2.new(0, 4, 0, math.round(h + s * 1.7))
			end),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Color3.fromHex("#4CC2FF"),
		}, {
			Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
		}),
	})
end
local default = pure(Selection)
return {
	default = default,
}
 end, _env("RemoteSpy.components.Selection"))() end)

_module("SidePanel", "ModuleScript", "RemoteSpy.components.SidePanel", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
local SidePanel = TS.import(script, script, "SidePanel").default
local TitleBar = TS.import(script, script, "TitleBar").default
for _k, _v in pairs(TS.import(script, script, "use-side-panel-context") or {}) do
	exports[_k] = _v
end
local default = {
	Root = SidePanel,
	TitleBar = TitleBar,
}
exports.default = default
return exports
 end, _env("RemoteSpy.components.SidePanel"))() end)

_module("SidePanel", "ModuleScript", "RemoteSpy.components.SidePanel.SidePanel", "RemoteSpy.components.SidePanel", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local SIDE_PANEL_WIDTH = TS.import(script, script.Parent.Parent.Parent, "constants").SIDE_PANEL_WIDTH
local SidePanelContext = TS.import(script, script.Parent, "use-side-panel-context").SidePanelContext
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useBinding = _roact_hooked.useBinding
local useMemo = _roact_hooked.useMemo
local useState = _roact_hooked.useState
local useSpring = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).useSpring
local MIN_PANEL_HEIGHT = 40
local function SidePanel(_param)
	local children = _param[Roact.Children]
	local _binding = useBinding(200)
	local lowerHeight = _binding[1]
	local setLowerHeight = _binding[2]
	local _binding_1 = useState(false)
	local lowerHidden = _binding_1[1]
	local setLowerHidden = _binding_1[2]
	local _binding_2 = useState(false)
	local upperHidden = _binding_2[1]
	local setUpperHidden = _binding_2[2]
	local lowerAnim = useSpring(if lowerHidden then 1 else 0, {
		frequency = 8,
	})
	local upperAnim = useSpring(if upperHidden then 1 else 0, {
		frequency = 8,
	})
	local lowerSize = useMemo(function()
		return Roact.joinBindings({ lowerHeight, lowerAnim, upperAnim }):map(function(_param_1)
			local height = _param_1[1]
			local n = _param_1[2]
			local ftn = _param_1[3]
			local lowerShown = UDim2.new(1, 0, 0, height)
			local lowerHidden = UDim2.new(1, 0, 0, MIN_PANEL_HEIGHT)
			local upperHidden = UDim2.new(1, 0, 1, -MIN_PANEL_HEIGHT)
			return lowerShown:Lerp(upperHidden, ftn):Lerp(lowerHidden, n)
		end)
	end, {})
	local lowerPosition = useMemo(function()
		return Roact.joinBindings({ lowerHeight, lowerAnim, upperAnim }):map(function(_param_1)
			local height = _param_1[1]
			local n = _param_1[2]
			local ftn = _param_1[3]
			local lowerShown = UDim2.new(0, 0, 1, -height)
			local lowerHidden = UDim2.new(0, 0, 1, -MIN_PANEL_HEIGHT)
			local upperHidden = UDim2.new(0, 0, 0, MIN_PANEL_HEIGHT)
			return lowerShown:Lerp(lowerHidden, n):Lerp(upperHidden, ftn)
		end)
	end, {})
	local upperSize = useMemo(function()
		return Roact.joinBindings({ lowerHeight, upperAnim, lowerAnim }):map(function(_param_1)
			local height = _param_1[1]
			local n = _param_1[2]
			local tn = _param_1[3]
			local upperShown = UDim2.new(1, 0, 1, -height)
			local upperHidden = UDim2.new(1, 0, 0, MIN_PANEL_HEIGHT)
			local lowerHidden = UDim2.new(1, 0, 1, -MIN_PANEL_HEIGHT)
			return upperShown:Lerp(lowerHidden, tn):Lerp(upperHidden, n)
		end)
	end, {})
	local _attributes = {
		value = {
			upperHidden = upperHidden,
			upperSize = upperSize,
			setUpperHidden = setUpperHidden,
			lowerHidden = lowerHidden,
			lowerSize = lowerSize,
			lowerPosition = lowerPosition,
			setLowerHidden = setLowerHidden,
			setLowerHeight = setLowerHeight,
		},
	}
	local _children = {}
	local _length = #_children
	local _attributes_1 = {
		anchorPoint = Vector2.new(1, 0),
		size = UDim2.new(0, SIDE_PANEL_WIDTH, 1, -84),
		position = UDim2.new(1, 0, 0, 84),
	}
	local _children_1 = {}
	local _length_1 = #_children_1
	if children then
		for _k, _v in pairs(children) do
			if type(_k) == "number" then
				_children_1[_length_1 + _k] = _v
			else
				_children_1[_k] = _v
			end
		end
	end
	_children[_length + 1] = Roact.createElement(Container, _attributes_1, _children_1)
	return Roact.createElement(SidePanelContext.Provider, _attributes, _children)
end
local default = pure(SidePanel)
return {
	default = default,
}
 end, _env("RemoteSpy.components.SidePanel.SidePanel"))() end)

_module("TitleBar", "ModuleScript", "RemoteSpy.components.SidePanel.TitleBar", "RemoteSpy.components.SidePanel", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Button = TS.import(script, script.Parent.Parent, "Button").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local Instant = _flipper.Instant
local Spring = _flipper.Spring
local pure = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).pure
local useGroupMotor = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).useGroupMotor
local CHEVRON_DEFAULT = { Spring.new(1, {
	frequency = 6,
}), Spring.new(0, {
	frequency = 6,
}) }
local CHEVRON_HOVERED = { Spring.new(0.95, {
	frequency = 6,
}), Spring.new(0, {
	frequency = 6,
}) }
local CHEVRON_PRESSED = { Instant.new(0.97), Instant.new(0.2) }
local function TitleBar(_param)
	local caption = _param.caption
	local hidden = _param.hidden
	local toggleHidden = _param.toggleHidden
	local _binding = useGroupMotor({ 1, 0 })
	local chevronTransparency = _binding[1]
	local setChevronGoal = _binding[2]
	local chevronBackgroundTransparency = chevronTransparency:map(function(t)
		return t[1]
	end)
	local chevronForegroundTransparency = chevronTransparency:map(function(t)
		return t[2]
	end)
	return Roact.createFragment({
		Roact.createElement("TextLabel", {
			Text = caption,
			TextColor3 = Color3.new(1, 1, 1),
			Font = "GothamBold",
			TextSize = 11,
			TextXAlignment = "Left",
			TextYAlignment = "Top",
			Size = UDim2.new(1, -24, 0, 20),
			Position = UDim2.new(0, 12, 0, 14),
			BackgroundTransparency = 1,
		}),
		Roact.createElement(Button, {
			onClick = function()
				setChevronGoal(CHEVRON_HOVERED)
				toggleHidden()
			end,
			onPress = function()
				return setChevronGoal(CHEVRON_PRESSED)
			end,
			onHover = function()
				return setChevronGoal(CHEVRON_HOVERED)
			end,
			onHoverEnd = function()
				return setChevronGoal(CHEVRON_DEFAULT)
			end,
			transparency = chevronBackgroundTransparency,
			size = UDim2.new(0, 24, 0, 24),
			position = UDim2.new(1, -8, 0, 8),
			anchorPoint = Vector2.new(1, 0),
			cornerRadius = UDim.new(0, 4),
		}, {
			Roact.createElement("ImageLabel", {
				Image = if hidden then "rbxassetid://9888526164" else "rbxassetid://9888526348",
				ImageTransparency = chevronForegroundTransparency,
				Size = UDim2.new(0, 16, 0, 16),
				Position = UDim2.new(0, 4, 0, 4),
				BackgroundTransparency = 1,
			}),
		}),
	})
end
local default = pure(TitleBar)
return {
	default = default,
}
 end, _env("RemoteSpy.components.SidePanel.TitleBar"))() end)

_module("use-side-panel-context", "ModuleScript", "RemoteSpy.components.SidePanel.use-side-panel-context", "RemoteSpy.components.SidePanel", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local useContext = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useContext
local SidePanelContext = Roact.createContext(nil)
local function useSidePanelContext()
	return useContext(SidePanelContext)
end
return {
	useSidePanelContext = useSidePanelContext,
	SidePanelContext = SidePanelContext,
}
 end, _env("RemoteSpy.components.SidePanel.use-side-panel-context"))() end)

_module("TabGroup", "ModuleScript", "RemoteSpy.components.TabGroup", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
for _k, _v in pairs(TS.import(script, script, "use-tab-group") or {}) do
	exports[_k] = _v
end
exports.default = TS.import(script, script, "TabGroup").default
return exports
 end, _env("RemoteSpy.components.TabGroup"))() end)

_module("TabColumn", "ModuleScript", "RemoteSpy.components.TabGroup.TabColumn", "RemoteSpy.components.TabGroup", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Button = TS.import(script, script.Parent.Parent, "Button").default
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local Instant = _flipper.Instant
local Spring = _flipper.Spring
local _tab_group = TS.import(script, script.Parent.Parent.Parent, "reducers", "tab-group")
local MAX_TAB_CAPTION_WIDTH = _tab_group.MAX_TAB_CAPTION_WIDTH
local deleteTab = _tab_group.deleteTab
local getTabCaptionWidth = _tab_group.getTabCaptionWidth
local getTabWidth = _tab_group.getTabWidth
local _services = TS.import(script, TS.getModule(script, "@rbxts", "services"))
local RunService = _services.RunService
local UserInputService = _services.UserInputService
local formatEscapes = TS.import(script, script.Parent.Parent.Parent, "utils", "format-escapes").formatEscapes
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useBinding = _roact_hooked.useBinding
local useEffect = _roact_hooked.useEffect
local useMemo = _roact_hooked.useMemo
local useState = _roact_hooked.useState
local tabIcons = TS.import(script, script.Parent, "constants").tabIcons
local _use_tab_group = TS.import(script, script.Parent, "use-tab-group")
local useDeleteTab = _use_tab_group.useDeleteTab
local useMoveTab = _use_tab_group.useMoveTab
local useSetActiveTab = _use_tab_group.useSetActiveTab
local useTabIsActive = _use_tab_group.useTabIsActive
local useTabOffset = _use_tab_group.useTabOffset
local useTabWidth = _use_tab_group.useTabWidth
local useRootStore = TS.import(script, script.Parent.Parent.Parent, "hooks", "use-root-store").useRootStore
local _roact_hooked_plus = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out)
local useSingleMotor = _roact_hooked_plus.useSingleMotor
local useSpring = _roact_hooked_plus.useSpring
local FOREGROUND_ACTIVE = Instant.new(0)
local FOREGROUND_DEFAULT = Spring.new(0.4, {
	frequency = 6,
})
local FOREGROUND_HOVERED = Spring.new(0.2, {
	frequency = 6,
})
local CLOSE_DEFAULT = Spring.new(1, {
	frequency = 6,
})
local CLOSE_HOVERED = Spring.new(0.9, {
	frequency = 6,
})
local CLOSE_PRESSED = Instant.new(0.94)
local function TabColumn(_param)
	local tab = _param.tab
	local canvasPosition = _param.canvasPosition
	local store = useRootStore()
	local active = useTabIsActive(tab.id)
	local width = useTabWidth(tab)
	local offset = useTabOffset(tab.id)
	local captionWidth = useMemo(function()
		return getTabCaptionWidth(tab)
	end, { tab })
	local activate = useSetActiveTab(tab.id)
	local move = useMoveTab(tab.id)
	local close = useDeleteTab(tab.id)
	local _binding = useSingleMotor(if active then 0 else 0.4)
	local foreground = _binding[1]
	local setForeground = _binding[2]
	local _binding_1 = useSingleMotor(1)
	local closeBackground = _binding_1[1]
	local setCloseBackground = _binding_1[2]
	local offsetAnim = useSpring(offset, {
		frequency = 30,
		dampingRatio = 3,
	})
	useEffect(function()
		setForeground(if active then FOREGROUND_ACTIVE else FOREGROUND_DEFAULT)
	end, { active })
	local _binding_2 = useState()
	local dragState = _binding_2[1]
	local setDragState = _binding_2[2]
	local _binding_3 = useBinding(nil)
	local dragPosition = _binding_3[1]
	local setDragPosition = _binding_3[2]
	useEffect(function()
		if not dragState then
			return nil
		end
		local tabs
		local estimateNewIndex = function(dragOffset)
			local totalWidth = 0
			for _, t in ipairs(tabs) do
				totalWidth += getTabWidth(t)
				if totalWidth > dragOffset + width / 2 then
					return (table.find(tabs, t) or 0) - 1
				end
			end
			return #tabs - 1
		end
		tabs = store:getState().tabGroup.tabs
		local startCanvasPosition = canvasPosition:getValue()
		local lastIndex = estimateNewIndex(0)
		local mouseMoved = RunService.Heartbeat:Connect(function()
			local current = UserInputService:GetMouseLocation()
			local position = current.X - dragState.mousePosition + dragState.tabPosition
			local canvasDelta = canvasPosition:getValue().X - startCanvasPosition.X
			setDragPosition(position + canvasDelta)
			local newIndex = estimateNewIndex(position + canvasDelta)
			if newIndex ~= lastIndex then
				lastIndex = newIndex
				move(newIndex)
			end
		end)
		local mouseUp = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				setDragState(nil)
				setDragPosition(nil)
			end
		end)
		return function()
			mouseMoved:Disconnect()
			mouseUp:Disconnect()
		end
	end, { dragState })
	local _attributes = {
		onPress = function(_, x)
			if not active then
				activate()
			end
			setDragState({
				dragging = false,
				mousePosition = x,
				tabPosition = offset,
			})
		end,
		onClick = function()
			return not active and setForeground(FOREGROUND_HOVERED)
		end,
		onHover = function()
			return not active and setForeground(FOREGROUND_HOVERED)
		end,
		onHoverEnd = function()
			return not active and setForeground(FOREGROUND_DEFAULT)
		end,
		size = UDim2.new(0, width, 1, 0),
		position = Roact.joinBindings({
			dragPosition = dragPosition,
			offsetAnim = offsetAnim,
		}):map(function(binding)
			local xOffset = if binding.dragPosition ~= nil then math.max(binding.dragPosition, 0) else math.round(binding.offsetAnim)
			return UDim2.new(0, xOffset, 0, 0)
		end),
		zIndex = dragPosition:map(function(drag)
			return if drag ~= nil then 1 else 0
		end),
	}
	local _children = {
		Roact.createElement("ImageLabel", {
			Image = "rbxassetid://9896472554",
			ImageTransparency = if active then 0.96 else 1,
			ImageColor3 = Color3.fromHex("#FFFFFF"),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ScaleType = "Slice",
			SliceCenter = Rect.new(8, 8, 8, 8),
		}),
		Roact.createElement("ImageLabel", {
			Image = "rbxassetid://9896472759",
			ImageTransparency = if active then 0.96 else 1,
			ImageColor3 = Color3.fromHex("#FFFFFF"),
			Size = UDim2.new(0, 5, 0, 5),
			Position = UDim2.new(0, -5, 1, -5),
			BackgroundTransparency = 1,
		}),
		Roact.createElement("ImageLabel", {
			Image = "rbxassetid://9896472676",
			ImageTransparency = if active then 0.96 else 1,
			ImageColor3 = Color3.fromHex("#FFFFFF"),
			Size = UDim2.new(0, 5, 0, 5),
			Position = UDim2.new(1, 0, 1, -5),
			BackgroundTransparency = 1,
		}),
	}
	local _length = #_children
	local _children_1 = {
		Roact.createElement("ImageLabel", {
			Image = tabIcons[tab.type],
			ImageTransparency = foreground,
			Size = UDim2.new(0, 16, 0, 16),
			BackgroundTransparency = 1,
		}),
	}
	local _length_1 = #_children_1
	local _attributes_1 = {
		Text = formatEscapes(tab.caption),
		Font = "Gotham",
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = foreground,
		TextSize = 11,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.new(0, captionWidth, 1, 0),
		BackgroundTransparency = 1,
	}
	local _children_2 = {}
	local _length_2 = #_children_2
	local _child = captionWidth == MAX_TAB_CAPTION_WIDTH and (Roact.createElement("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.9, 0), NumberSequenceKeypoint.new(1, 1) }),
	}))
	if _child then
		_children_2[_length_2 + 1] = _child
	end
	_children_1[_length_1 + 1] = Roact.createElement("TextLabel", _attributes_1, _children_2)
	local _child_1 = tab.canClose and (Roact.createElement(Button, {
		onClick = function()
			deleteTab(tab.id)
			close()
		end,
		onPress = function()
			return setCloseBackground(CLOSE_PRESSED)
		end,
		onHover = function()
			return setCloseBackground(CLOSE_HOVERED)
		end,
		onHoverEnd = function()
			return setCloseBackground(CLOSE_DEFAULT)
		end,
		transparency = closeBackground,
		size = UDim2.new(0, 17, 0, 17),
		cornerRadius = UDim.new(0, 4),
	}, {
		Roact.createElement("ImageLabel", {
			Image = "rbxassetid://9896553856",
			ImageTransparency = foreground,
			Size = UDim2.new(0, 16, 0, 16),
			BackgroundTransparency = 1,
		}),
	}))
	if _child_1 then
		_children_1[_length_1 + 2] = _child_1
	end
	_length_1 = #_children_1
	_children_1[_length_1 + 1] = Roact.createElement("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
	})
	_children_1[_length_1 + 2] = Roact.createElement("UIListLayout", {
		Padding = UDim.new(0, 6),
		FillDirection = "Horizontal",
		HorizontalAlignment = "Left",
		VerticalAlignment = "Center",
	})
	_children[_length + 1] = Roact.createElement(Container, {}, _children_1)
	return Roact.createElement(Button, _attributes, _children)
end
local default = pure(TabColumn)
return {
	default = default,
}
 end, _env("RemoteSpy.components.TabGroup.TabColumn"))() end)

_module("TabGroup", "ModuleScript", "RemoteSpy.components.TabGroup.TabGroup", "RemoteSpy.components.TabGroup", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local TabColumn = TS.import(script, script.Parent, "TabColumn").default
local SIDE_PANEL_WIDTH = TS.import(script, script.Parent.Parent.Parent, "constants").SIDE_PANEL_WIDTH
local arrayToMap = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).arrayToMap
local getTabWidth = TS.import(script, script.Parent.Parent.Parent, "reducers", "tab-group").getTabWidth
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useBinding = _roact_hooked.useBinding
local useMemo = _roact_hooked.useMemo
local useTabs = TS.import(script, script.Parent, "use-tab-group").useTabs
local function TabGroup()
	local tabs = useTabs()
	local _binding = useBinding(Vector2.new())
	local canvasPosition = _binding[1]
	local setCanvasPosition = _binding[2]
	local totalWidth = useMemo(function()
		local _arg0 = function(acc, tab)
			return acc + getTabWidth(tab)
		end
		-- ▼ ReadonlyArray.reduce ▼
		local _result = 0
		local _callback = _arg0
		for _i = 1, #tabs do
			_result = _callback(_result, tabs[_i], _i - 1, tabs)
		end
		-- ▲ ReadonlyArray.reduce ▲
		return _result
	end, tabs)
	local _attributes = {
		[Roact.Change.CanvasPosition] = function(rbx)
			return setCanvasPosition(rbx.CanvasPosition)
		end,
		CanvasSize = UDim2.new(0, totalWidth + 100, 0, 0),
		ScrollingDirection = "X",
		HorizontalScrollBarInset = "None",
		ScrollBarThickness = 0,
		Size = UDim2.new(1, -SIDE_PANEL_WIDTH - 5, 0, 35),
		Position = UDim2.new(0, 5, 0, 89),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}
	local _children = {
		Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
		}),
	}
	local _length = #_children
	for _k, _v in pairs(arrayToMap(tabs, function(tab)
		return { tab.id, Roact.createElement(TabColumn, {
			tab = tab,
			canvasPosition = canvasPosition,
		}) }
	end)) do
		_children[_k] = _v
	end
	return Roact.createElement("ScrollingFrame", _attributes, _children)
end
local default = pure(TabGroup)
return {
	default = default,
}
 end, _env("RemoteSpy.components.TabGroup.TabGroup"))() end)

_module("constants", "ModuleScript", "RemoteSpy.components.TabGroup.constants", "RemoteSpy.components.TabGroup", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local TabType = TS.import(script, script.Parent.Parent.Parent, "reducers", "tab-group").TabType
local tabIcons = {
	[TabType.Home] = "rbxassetid://9896611868",
	[TabType.Event] = "rbxassetid://9896665149",
	[TabType.Function] = "rbxassetid://9896665330",
	[TabType.Script] = "rbxassetid://9896665034",
}
return {
	tabIcons = tabIcons,
}
 end, _env("RemoteSpy.components.TabGroup.constants"))() end)

_module("use-tab-group", "ModuleScript", "RemoteSpy.components.TabGroup.use-tab-group", "RemoteSpy.components.TabGroup", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local _tab_group = TS.import(script, script.Parent.Parent.Parent, "reducers", "tab-group")
local deleteTab = _tab_group.deleteTab
local getTabWidth = _tab_group.getTabWidth
local makeSelectTabOffset = _tab_group.makeSelectTabOffset
local moveTab = _tab_group.moveTab
local pushTab = _tab_group.pushTab
local selectActiveTabId = _tab_group.selectActiveTabId
local selectTab = _tab_group.selectTab
local selectTabCount = _tab_group.selectTabCount
local selectTabGroup = _tab_group.selectTabGroup
local selectTabIsActive = _tab_group.selectTabIsActive
local selectTabOrder = _tab_group.selectTabOrder
local selectTabType = _tab_group.selectTabType
local selectTabs = _tab_group.selectTabs
local setActiveTab = _tab_group.setActiveTab
local useMemo = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useMemo
local _use_root_store = TS.import(script, script.Parent.Parent.Parent, "hooks", "use-root-store")
local useRootDispatch = _use_root_store.useRootDispatch
local useRootSelector = _use_root_store.useRootSelector
local function useTabWidth(tab)
	return getTabWidth(tab)
end
local function useTabType(id)
	return useRootSelector(function(state)
		return selectTabType(state, id)
	end)
end
local function useTabOffset(id)
	local selectTabOffset = useMemo(makeSelectTabOffset, {})
	return useRootSelector(function(state)
		return selectTabOffset(state, id)
	end)
end
local function useTabGroup()
	return useRootSelector(selectTabGroup)
end
local function useTabs()
	return useRootSelector(selectTabs)
end
local function useTabCount()
	return useRootSelector(selectTabCount)
end
local function useActiveTabId()
	return useRootSelector(selectActiveTabId)
end
local function useTab(id)
	return useRootSelector(function(state)
		return selectTab(state, id)
	end)
end
local function useTabIsActive(id)
	return useRootSelector(function(state)
		return selectTabIsActive(state, id)
	end)
end
local function useTabOrder(id)
	return useRootSelector(function(state)
		return selectTabOrder(state, id)
	end)
end
local function useSetActiveTab(id)
	local dispatch = useRootDispatch()
	return function()
		return dispatch(setActiveTab(id))
	end
end
local function useDeleteTab(id)
	local dispatch = useRootDispatch()
	return function()
		return dispatch(deleteTab(id))
	end
end
local function useMoveTab(id)
	local dispatch = useRootDispatch()
	return function(to)
		return dispatch(moveTab(id, to))
	end
end
local function usePushTab()
	local dispatch = useRootDispatch()
	return function(tab)
		return dispatch(pushTab(tab))
	end
end
return {
	useTabWidth = useTabWidth,
	useTabType = useTabType,
	useTabOffset = useTabOffset,
	useTabGroup = useTabGroup,
	useTabs = useTabs,
	useTabCount = useTabCount,
	useActiveTabId = useActiveTabId,
	useTab = useTab,
	useTabIsActive = useTabIsActive,
	useTabOrder = useTabOrder,
	useSetActiveTab = useSetActiveTab,
	useDeleteTab = useDeleteTab,
	useMoveTab = useMoveTab,
	usePushTab = usePushTab,
}
 end, _env("RemoteSpy.components.TabGroup.use-tab-group"))() end)

_module("Traceback", "ModuleScript", "RemoteSpy.components.Traceback", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
exports.default = TS.import(script, script, "Traceback").default
return exports
 end, _env("RemoteSpy.components.Traceback"))() end)

_module("Traceback", "ModuleScript", "RemoteSpy.components.Traceback.Traceback", "RemoteSpy.components.Traceback", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local SidePanel = TS.import(script, script.Parent.Parent, "SidePanel").default
local pure = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).pure
local useSidePanelContext = TS.import(script, script.Parent.Parent, "SidePanel").useSidePanelContext
local function Traceback()
	local _binding = useSidePanelContext()
	local lowerHidden = _binding.lowerHidden
	local setLowerHidden = _binding.setLowerHidden
	local lowerSize = _binding.lowerSize
	local lowerPosition = _binding.lowerPosition
	return Roact.createElement(Container, {
		size = lowerSize,
		position = lowerPosition,
	}, {
		Roact.createElement(SidePanel.TitleBar, {
			caption = "Traceback",
			hidden = lowerHidden,
			toggleHidden = function()
				return setLowerHidden(not lowerHidden)
			end,
		}),
	})
end
local default = pure(Traceback)
return {
	default = default,
}
 end, _env("RemoteSpy.components.Traceback.Traceback"))() end)

_module("Window", "ModuleScript", "RemoteSpy.components.Window", "RemoteSpy.components", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local Window = TS.import(script, script, "Window").default
local WindowBackground = TS.import(script, script, "WindowBackground").default
local WindowDropShadow = TS.import(script, script, "WindowDropShadow").default
local WindowResize = TS.import(script, script, "WindowResize").default
local WindowTitleBar = TS.import(script, script, "WindowTitleBar").default
local default = {
	Root = Window,
	TitleBar = WindowTitleBar,
	Background = WindowBackground,
	DropShadow = WindowDropShadow,
	Resize = WindowResize,
}
return {
	default = default,
}
 end, _env("RemoteSpy.components.Window"))() end)

_module("Window", "ModuleScript", "RemoteSpy.components.Window.Window", "RemoteSpy.components.Window", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local WindowContext = TS.import(script, script.Parent, "use-window-context").WindowContext
local lerp = TS.import(script, script.Parent.Parent.Parent, "utils", "number-util").lerp
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useBinding = _roact_hooked.useBinding
local useState = _roact_hooked.useState
local _roact_hooked_plus = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out)
local useSpring = _roact_hooked_plus.useSpring
local useViewportSize = _roact_hooked_plus.useViewportSize
local apply = function(v2, udim)
	return Vector2.new(v2.X * udim.X.Scale + udim.X.Offset, v2.Y * udim.Y.Scale + udim.Y.Offset)
end
local function Window(_param)
	local initialSize = _param.initialSize
	local initialPosition = _param.initialPosition
	local children = _param[Roact.Children]
	local viewportSize = useViewportSize()
	local _binding = useBinding(apply(viewportSize:getValue(), initialSize))
	local size = _binding[1]
	local setSize = _binding[2]
	local _binding_1 = useBinding(apply(viewportSize:getValue(), initialPosition))
	local position = _binding_1[1]
	local setPosition = _binding_1[2]
	local _binding_2 = useState(false)
	local maximized = _binding_2[1]
	local setMaximized = _binding_2[2]
	local maximizeAnim = useSpring(if maximized then 1 else 0, {
		frequency = 6,
	})
	local _attributes = {
		value = {
			size = size,
			setSize = setSize,
			position = position,
			setPosition = setPosition,
			maximized = maximized,
			setMaximized = setMaximized,
		},
	}
	local _children = {}
	local _length = #_children
	local _attributes_1 = {
		BackgroundTransparency = 1,
		Size = Roact.joinBindings({
			size = size,
			viewportSize = viewportSize,
			maximizeAnim = maximizeAnim,
		}):map(function(_param_1)
			local size = _param_1.size
			local viewportSize = _param_1.viewportSize
			local maximizeAnim = _param_1.maximizeAnim
			return UDim2.new(0, math.round(lerp(size.X, viewportSize.X, maximizeAnim)), 0, math.round(lerp(size.Y, viewportSize.Y, maximizeAnim)))
		end),
		Position = Roact.joinBindings({
			position = position,
			maximizeAnim = maximizeAnim,
		}):map(function(_param_1)
			local position = _param_1.position
			local maximizeAnim = _param_1.maximizeAnim
			return UDim2.new(0, math.round(position.X * (1 - maximizeAnim)), 0, math.round(position.Y * (1 - maximizeAnim)))
		end),
	}
	local _children_1 = {
		Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
	}
	local _length_1 = #_children_1
	local _children_2 = {}
	local _length_2 = #_children_2
	if children then
		for _k, _v in pairs(children) do
			if type(_k) == "number" then
				_children_2[_length_2 + _k] = _v
			else
				_children_2[_k] = _v
			end
		end
	end
	_children_1[_length_1 + 1] = Roact.createFragment(_children_2)
	_children[_length + 1] = Roact.createElement("Frame", _attributes_1, _children_1)
	return Roact.createElement(WindowContext.Provider, _attributes, _children)
end
local default = pure(Window)
return {
	default = default,
}
 end, _env("RemoteSpy.components.Window.Window"))() end)

_module("Window.story", "ModuleScript", "RemoteSpy.components.Window.Window.story", "RemoteSpy.components.Window", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local Root = TS.import(script, script.Parent.Parent, "Root").default
local Window = TS.import(script, script.Parent).default
return function(target)
	local handle = Roact.mount(Roact.createElement(Root, {}, {
		Roact.createElement(Window.Root, {
			initialSize = UDim2.new(0, 1080, 0, 700),
			initialPosition = UDim2.new(0.5, -1080 / 2, 0.5, -700 / 2),
		}, {
			Roact.createElement(Window.DropShadow),
			Roact.createElement(Window.Background),
			Roact.createElement(Window.TitleBar, {
				caption = '<font color="#E5E5E5">New window</font>',
				icon = "rbxassetid://9886981409",
			}),
			Roact.createElement(Window.Resize, {
				minSize = Vector2.new(350, 250),
			}),
		}),
	}), target, "App")
	return function()
		Roact.unmount(handle)
	end
end
 end, _env("RemoteSpy.components.Window.Window.story"))() end)

_module("WindowBackground", "ModuleScript", "RemoteSpy.components.Window.WindowBackground", "RemoteSpy.components.Window", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function WindowBackground(_param)
	local background = _param.background
	if background == nil then
		background = Color3.fromHex("#202020")
	end
	local transparency = _param.transparency
	if transparency == nil then
		transparency = 0.2
	end
	local children = _param[Roact.Children]
	local _attributes = {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = background,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
	}
	local _children = {
		Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
	}
	local _length = #_children
	if children then
		for _k, _v in pairs(children) do
			if type(_k) == "number" then
				_children[_length + _k] = _v
			else
				_children[_k] = _v
			end
		end
	end
	_length = #_children
	_children[_length + 1] = Roact.createElement(Container, {}, {
		Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Roact.createElement("UIStroke", {
			Color = Color3.fromHex("#606060"),
			Transparency = 0.5,
			Thickness = 1,
		}),
	})
	return Roact.createElement("Frame", _attributes, _children)
end
return {
	default = WindowBackground,
}
 end, _env("RemoteSpy.components.Window.WindowBackground"))() end)

_module("WindowDropShadow", "ModuleScript", "RemoteSpy.components.Window.WindowDropShadow", "RemoteSpy.components.Window", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local WindowAssets = TS.import(script, script.Parent, "assets").WindowAssets
local IMAGE_SIZE = Vector2.new(226, 226)
local function WindowDropShadow()
	return Roact.createElement("ImageLabel", {
		Image = WindowAssets.DropShadow,
		ScaleType = "Slice",
		SliceCenter = Rect.new(IMAGE_SIZE / 2, IMAGE_SIZE / 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 110, 1, 110),
		Position = UDim2.new(0.5, 0, 0.5, 24),
		BackgroundTransparency = 1,
	})
end
return {
	default = WindowDropShadow,
}
 end, _env("RemoteSpy.components.Window.WindowDropShadow"))() end)

_module("WindowResize", "ModuleScript", "RemoteSpy.components.Window.WindowResize", "RemoteSpy.components.Window", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Button = TS.import(script, script.Parent.Parent, "Button").default
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local UserInputService = TS.import(script, TS.getModule(script, "@rbxts", "services")).UserInputService
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useEffect = _roact_hooked.useEffect
local useState = _roact_hooked.useState
local useWindowContext = TS.import(script, script.Parent, "use-window-context").useWindowContext
local THICKNESS = 14
local Handle = function(props)
	return Roact.createElement(Button, {
		onPress = function(_, x, y)
			return props.dragStart(Vector2.new(x, y))
		end,
		anchorPoint = Vector2.new(0.5, 0.5),
		size = props.size,
		position = props.position,
		active = false,
	})
end
local function WindowResize(_param)
	local minSize = _param.minSize
	if minSize == nil then
		minSize = Vector2.new(250, 250)
	end
	local maxSize = _param.maxSize
	if maxSize == nil then
		maxSize = Vector2.new(2048, 2048)
	end
	local _binding = useWindowContext()
	local size = _binding.size
	local setSize = _binding.setSize
	local position = _binding.position
	local setPosition = _binding.setPosition
	local maximized = _binding.maximized
	local _binding_1 = useState()
	local dragStart = _binding_1[1]
	local setDragStart = _binding_1[2]
	useEffect(function()
		if not dragStart or maximized then
			return nil
		end
		local startPosition = position:getValue()
		local startSize = size:getValue()
		local inputBegan = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local current = UserInputService:GetMouseLocation()
				local _mouse = dragStart.mouse
				local delta = current - _mouse
				local _arg0 = dragStart.direction * delta
				local targetSize = startSize + _arg0
				local targetSizeClamped = Vector2.new(math.clamp(targetSize.X, minSize.X, maxSize.X), math.clamp(targetSize.Y, minSize.Y, maxSize.Y))
				setSize(targetSizeClamped)
				if dragStart.direction.X < 0 and dragStart.direction.Y < 0 then
					local _arg0_1 = startSize - targetSizeClamped
					setPosition(startPosition + _arg0_1)
				elseif dragStart.direction.X < 0 then
					setPosition(Vector2.new(startPosition.X + (startSize.X - targetSizeClamped.X), startPosition.Y))
				elseif dragStart.direction.Y < 0 then
					setPosition(Vector2.new(startPosition.X, startPosition.Y + (startSize.Y - targetSizeClamped.Y)))
				end
			end
		end)
		local inputEnded = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				setDragStart(nil)
			end
		end)
		return function()
			inputBegan:Disconnect()
			inputEnded:Disconnect()
		end
	end, { dragStart })
	return Roact.createElement(Container, {}, {
		Roact.createElement(Handle, {
			dragStart = function(mouse)
				return setDragStart({
					mouse = mouse,
					direction = Vector2.new(0, -1),
				})
			end,
			size = UDim2.new(1, -THICKNESS, 0, THICKNESS),
			position = UDim2.new(0.5, 0, 0, 0),
		}),
		Roact.createElement(Handle, {
			dragStart = function(mouse)
				return setDragStart({
					mouse = mouse,
					direction = Vector2.new(-1, 0),
				})
			end,
			size = UDim2.new(0, THICKNESS, 1, -THICKNESS),
			position = UDim2.new(0, 0, 0.5, 0),
		}),
		Roact.createElement(Handle, {
			dragStart = function(mouse)
				return setDragStart({
					mouse = mouse,
					direction = Vector2.new(1, 0),
				})
			end,
			size = UDim2.new(0, THICKNESS, 1, -THICKNESS),
			position = UDim2.new(1, 0, 0.5, 0),
		}),
		Roact.createElement(Handle, {
			dragStart = function(mouse)
				return setDragStart({
					mouse = mouse,
					direction = Vector2.new(0, 1),
				})
			end,
			size = UDim2.new(1, -THICKNESS, 0, THICKNESS),
			position = UDim2.new(0.5, 0, 1, 0),
		}),
		Roact.createElement(Handle, {
			dragStart = function(mouse)
				return setDragStart({
					mouse = mouse,
					direction = Vector2.new(-1, -1),
				})
			end,
			size = UDim2.new(0, THICKNESS, 0, THICKNESS),
			position = UDim2.new(0, 0, 0, 0),
		}),
		Roact.createElement(Handle, {
			dragStart = function(mouse)
				return setDragStart({
					mouse = mouse,
					direction = Vector2.new(1, -1),
				})
			end,
			size = UDim2.new(0, THICKNESS, 0, THICKNESS),
			position = UDim2.new(1, 0, 0, 0),
		}),
		Roact.createElement(Handle, {
			dragStart = function(mouse)
				return setDragStart({
					mouse = mouse,
					direction = Vector2.new(-1, 1),
				})
			end,
			size = UDim2.new(0, THICKNESS, 0, THICKNESS),
			position = UDim2.new(0, 0, 1, 0),
		}),
		Roact.createElement(Handle, {
			dragStart = function(mouse)
				return setDragStart({
					mouse = mouse,
					direction = Vector2.new(1, 1),
				})
			end,
			size = UDim2.new(0, THICKNESS, 0, THICKNESS),
			position = UDim2.new(1, 0, 1, 0),
		}),
	})
end
local default = pure(WindowResize)
return {
	default = default,
}
 end, _env("RemoteSpy.components.Window.WindowResize"))() end)

_module("WindowTitleBar", "ModuleScript", "RemoteSpy.components.Window.WindowTitleBar", "RemoteSpy.components.Window", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Button = TS.import(script, script.Parent.Parent, "Button").default
local Container = TS.import(script, script.Parent.Parent, "Container").default
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local Instant = _flipper.Instant
local Spring = _flipper.Spring
local TOPBAR_OFFSET = TS.import(script, script.Parent.Parent.Parent, "constants").TOPBAR_OFFSET
local UserInputService = TS.import(script, TS.getModule(script, "@rbxts", "services")).UserInputService
local WindowAssets = TS.import(script, script.Parent, "assets").WindowAssets
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local pure = _roact_hooked.pure
local useBinding = _roact_hooked.useBinding
local useEffect = _roact_hooked.useEffect
local useState = _roact_hooked.useState
local useSingleMotor = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked-plus").out).useSingleMotor
local useWindowContext = TS.import(script, script.Parent, "use-window-context").useWindowContext
local function WindowTitleBar(_param)
	local caption = _param.caption
	if caption == nil then
		caption = "New window"
	end
	local captionColor = _param.captionColor
	if captionColor == nil then
		captionColor = Color3.new(1, 1, 1)
	end
	local captionTransparency = _param.captionTransparency
	if captionTransparency == nil then
		captionTransparency = 0
	end
	local icon = _param.icon
	if icon == nil then
		icon = WindowAssets.DefaultWindowIcon
	end
	local height = _param.height
	if height == nil then
		height = 42
	end
	local onClose = _param.onClose
	local children = _param[Roact.Children]
	local _binding = useWindowContext()
	local size = _binding.size
	local maximized = _binding.maximized
	local setMaximized = _binding.setMaximized
	local setPosition = _binding.setPosition
	local _binding_1 = useSingleMotor(1)
	local closeTransparency = _binding_1[1]
	local setCloseTransparency = _binding_1[2]
	local _binding_2 = useSingleMotor(1)
	local minimizeTransparency = _binding_2[1]
	local setMinimizeTransparency = _binding_2[2]
	local _binding_3 = useSingleMotor(1)
	local maximizeTransparency = _binding_3[1]
	local setMaximizeTransparency = _binding_3[2]
	local _binding_4 = useBinding(Vector2.new())
	local startPosition = _binding_4[1]
	local setStartPosition = _binding_4[2]
	local _binding_5 = useState()
	local dragStart = _binding_5[1]
	local setDragStart = _binding_5[2]
	useEffect(function()
		if not dragStart then
			return nil
		end
		local startPos = startPosition:getValue()
		local shouldMinimize = maximized
		local mouseMoved = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local current = UserInputService:GetMouseLocation()
				local delta = current - dragStart
				setPosition(startPos + delta)
				if shouldMinimize then
					shouldMinimize = false
					setMaximized(false)
				end
			end
		end)
		local mouseUp = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				setDragStart(nil)
			end
		end)
		return function()
			mouseMoved:Disconnect()
			mouseUp:Disconnect()
		end
	end, { dragStart })
	local _attributes = {
		size = UDim2.new(1, 0, 0, height),
	}
	local _children = {
		Roact.createElement("ImageLabel", {
			Image = icon,
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0, 16, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}),
		Roact.createElement("TextLabel", {
			RichText = true,
			Text = caption,
			TextColor3 = captionColor,
			TextTransparency = captionTransparency,
			Font = "Gotham",
			TextSize = 11,
			TextXAlignment = "Left",
			TextYAlignment = "Center",
			Size = UDim2.new(1, -44, 1, 0),
			Position = UDim2.new(0, 44, 0, 0),
			BackgroundTransparency = 1,
		}),
		Roact.createElement(Button, {
			onPress = function(rbx, x, y)
				local mouse = Vector2.new(x, y)
				if maximized then
					local currentSize = Vector2.new(size:getValue().X - 46 * 3, height)
					setStartPosition(Vector2.new())
					local _absoluteSize = rbx.AbsoluteSize
					local _arg0 = currentSize / _absoluteSize
					setDragStart(mouse * _arg0)
				else
					setStartPosition(rbx.AbsolutePosition + TOPBAR_OFFSET)
					setDragStart(mouse)
				end
			end,
			active = false,
			size = UDim2.new(1, -46 * 3, 1, 0),
		}),
		Roact.createElement(Button, {
			onClick = function()
				setCloseTransparency(Spring.new(0, {
					frequency = 6,
				}))
				local _result = onClose
				if _result ~= nil then
					_result()
				end
			end,
			onPress = function()
				return setCloseTransparency(Instant.new(0.25))
			end,
			onHover = function()
				return setCloseTransparency(Spring.new(0, {
					frequency = 6,
				}))
			end,
			onHoverEnd = function()
				return setCloseTransparency(Spring.new(1, {
					frequency = 6,
				}))
			end,
			size = UDim2.new(0, 46, 1, 0),
			position = UDim2.new(1, 0, 0, 0),
			anchorPoint = Vector2.new(1, 0),
		}, {
			Roact.createElement("ImageLabel", {
				Image = WindowAssets.CloseButton,
				ImageTransparency = closeTransparency,
				ImageColor3 = Color3.fromHex("#C83D3D"),
				ScaleType = "Slice",
				SliceCenter = Rect.new(8, 8, 8, 8),
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
			}),
			Roact.createElement("ImageLabel", {
				Image = WindowAssets.Close,
				Size = UDim2.new(0, 16, 0, 16),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}),
		}),
		Roact.createElement(Button, {
			onClick = function()
				setMaximizeTransparency(Spring.new(0.94, {
					frequency = 6,
				}))
				setMaximized(not maximized)
			end,
			onPress = function()
				return setMaximizeTransparency(Instant.new(0.96))
			end,
			onHover = function()
				return setMaximizeTransparency(Spring.new(0.94, {
					frequency = 6,
				}))
			end,
			onHoverEnd = function()
				return setMaximizeTransparency(Spring.new(1, {
					frequency = 6,
				}))
			end,
			background = Color3.fromHex("#FFFFFF"),
			transparency = maximizeTransparency,
			size = UDim2.new(0, 46, 1, 0),
			position = UDim2.new(1, -46, 0, 0),
			anchorPoint = Vector2.new(1, 0),
		}, {
			Roact.createElement("ImageLabel", {
				Image = if maximized then WindowAssets.RestoreDown else WindowAssets.Maximize,
				Size = UDim2.new(0, 16, 0, 16),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}),
		}),
		Roact.createElement(Button, {
			onClick = function()
				local _viewportSize = game:GetService("Workspace").CurrentCamera
				if _viewportSize ~= nil then
					_viewportSize = _viewportSize.ViewportSize
				end
				local viewportSize = _viewportSize
				if viewportSize then
					local _vector2 = Vector2.new(42, height)
					setPosition(viewportSize - _vector2)
					if maximized then
						setMaximized(false)
					end
				end
				setMinimizeTransparency(Spring.new(0.94, {
					frequency = 6,
				}))
			end,
			onPress = function()
				return setMinimizeTransparency(Instant.new(0.96))
			end,
			onHover = function()
				return setMinimizeTransparency(Spring.new(0.94, {
					frequency = 6,
				}))
			end,
			onHoverEnd = function()
				return setMinimizeTransparency(Spring.new(1, {
					frequency = 6,
				}))
			end,
			background = Color3.fromHex("#FFFFFF"),
			transparency = minimizeTransparency,
			size = UDim2.new(0, 46, 1, 0),
			position = UDim2.new(1, -46 * 2, 0, 0),
			anchorPoint = Vector2.new(1, 0),
		}, {
			Roact.createElement("ImageLabel", {
				Image = WindowAssets.Minimize,
				Size = UDim2.new(0, 16, 0, 16),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}),
		}),
	}
	local _length = #_children
	if children then
		for _k, _v in pairs(children) do
			if type(_k) == "number" then
				_children[_length + _k] = _v
			else
				_children[_k] = _v
			end
		end
	end
	return Roact.createElement(Container, _attributes, _children)
end
local default = pure(WindowTitleBar)
return {
	default = default,
}
 end, _env("RemoteSpy.components.Window.WindowTitleBar"))() end)

_module("assets", "ModuleScript", "RemoteSpy.components.Window.assets", "RemoteSpy.components.Window", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local WindowAssets
do
	local _inverse = {}
	WindowAssets = setmetatable({}, {
		__index = _inverse,
	})
	WindowAssets.Close = "rbxassetid://9886659671"
	_inverse["rbxassetid://9886659671"] = "Close"
	WindowAssets.CloseButton = "rbxassetid://9887215356"
	_inverse["rbxassetid://9887215356"] = "CloseButton"
	WindowAssets.Maximize = "rbxassetid://9886659406"
	_inverse["rbxassetid://9886659406"] = "Maximize"
	WindowAssets.RestoreDown = "rbxassetid://9886659001"
	_inverse["rbxassetid://9886659001"] = "RestoreDown"
	WindowAssets.Minimize = "rbxassetid://9886659276"
	_inverse["rbxassetid://9886659276"] = "Minimize"
	WindowAssets.DefaultWindowIcon = "rbxassetid://9886659555"
	_inverse["rbxassetid://9886659555"] = "DefaultWindowIcon"
	WindowAssets.DropShadow = "rbxassetid://9886919127"
	_inverse["rbxassetid://9886919127"] = "DropShadow"
end
return {
	WindowAssets = WindowAssets,
}
 end, _env("RemoteSpy.components.Window.assets"))() end)

_module("use-window-context", "ModuleScript", "RemoteSpy.components.Window.use-window-context", "RemoteSpy.components.Window", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local useContext = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useContext
local WindowContext = Roact.createContext(nil)
local function useWindowContext()
	return useContext(WindowContext)
end
return {
	useWindowContext = useWindowContext,
	WindowContext = WindowContext,
}
 end, _env("RemoteSpy.components.Window.use-window-context"))() end)

_module("constants", "ModuleScript", "RemoteSpy.constants", "RemoteSpy", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local DISPLAY_ORDER = 6
local SIDE_PANEL_WIDTH = 280
local TOPBAR_OFFSET = (game:GetService("GuiService"):GetGuiInset())
local IS_LOADED = "__REMOTESPY_IS_LOADED__"
local IS_ELEVATED = loadstring ~= nil
local HAS_FILE_ACCESS = readfile ~= nil
local IS_ACRYLIC_ENABLED = true
return {
	DISPLAY_ORDER = DISPLAY_ORDER,
	SIDE_PANEL_WIDTH = SIDE_PANEL_WIDTH,
	TOPBAR_OFFSET = TOPBAR_OFFSET,
	IS_LOADED = IS_LOADED,
	IS_ELEVATED = IS_ELEVATED,
	HAS_FILE_ACCESS = HAS_FILE_ACCESS,
	IS_ACRYLIC_ENABLED = IS_ACRYLIC_ENABLED,
}
 end, _env("RemoteSpy.constants"))() end)

_instance("hooks", "Folder", "RemoteSpy.hooks", "RemoteSpy")

_module("use-action-effect", "ModuleScript", "RemoteSpy.hooks.use-action-effect", "RemoteSpy.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local _action_bar = TS.import(script, script.Parent.Parent, "reducers", "action-bar")
local deactivateAction = _action_bar.deactivateAction
local selectActionIsActive = _action_bar.selectActionIsActive
local useEffect = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useEffect
local _use_root_store = TS.import(script, script.Parent, "use-root-store")
local useRootDispatch = _use_root_store.useRootDispatch
local useRootSelector = _use_root_store.useRootSelector
local function useActionEffect(action, effect)
	local dispatch = useRootDispatch()
	local activated = useRootSelector(function(state)
		return selectActionIsActive(state, action)
	end)
	useEffect(function()
		if activated then
			task.spawn(effect)
			dispatch(deactivateAction(action))
		end
	end, { activated })
end
return {
	useActionEffect = useActionEffect,
}
 end, _env("RemoteSpy.hooks.use-action-effect"))() end)

_module("use-root-store", "ModuleScript", "RemoteSpy.hooks.use-root-store", "RemoteSpy.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local _roact_rodux_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-rodux-hooked").out)
local useDispatch = _roact_rodux_hooked.useDispatch
local useSelector = _roact_rodux_hooked.useSelector
local useStore = _roact_rodux_hooked.useStore
local useRootSelector = useSelector
local useRootDispatch = useDispatch
local useRootStore = useStore
return {
	useRootSelector = useRootSelector,
	useRootDispatch = useRootDispatch,
	useRootStore = useRootStore,
}
 end, _env("RemoteSpy.hooks.use-root-store"))() end)

_module("receiver", "LocalScript", "RemoteSpy.receiver", "RemoteSpy", function () return setfenv(function() local TS = require(script.Parent.include.RuntimeLib)
local logger = TS.import(script, script.Parent, "reducers", "remote-log")
local store = TS.import(script, script.Parent, "store")
local getFunctionScript = TS.import(script, script.Parent, "utils", "function-util").getFunctionScript
local getInstanceId = TS.import(script, script.Parent, "utils", "instance-util").getInstanceId
local makeSelectRemoteLog = TS.import(script, script.Parent, "reducers", "remote-log", "selectors").makeSelectRemoteLog

local CALLER_STACK_LEVEL = if KRNL_LOADED then 6 else 4

local FireServer = Instance.new("RemoteEvent").FireServer
local InvokeServer = Instance.new("RemoteFunction").InvokeServer
local IsA = game.IsA

local refs = {}
local selectRemoteLog = makeSelectRemoteLog()

if not hookfunction then
	return
end

if not getcallingscript then
	function getcallingscript()
		return nil
	end
end

local function onReceive(self, params, returns)
	local traceback = {}
	local callback = debug.info(CALLER_STACK_LEVEL, "f")

	local level, fn = 4, callback

	while fn do
		table.insert(traceback, fn)
		level = level + 1
		fn = debug.info(level, "f")
	end

	task.defer(function()
		local script = getcallingscript() or (callback and getFunctionScript(callback))
		local signal = logger.createOutgoingSignal(self, script, callback, traceback, params, returns)
		local remoteId = getInstanceId(self)

		if store.get(function(state)
			return selectRemoteLog(state, remoteId)
		end) then
			store.dispatch(logger.pushOutgoingSignal(remoteId, signal))
		else
			local remoteLog = logger.createRemoteLog(self, signal)
			store.dispatch(logger.pushRemoteLog(remoteLog))
		end
	end)
end

-- Hooks

refs.FireServer = hookfunction(FireServer, function(self, ...)
	if self and store.isActive() and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
		onReceive(self, { ... })
	end
	return refs.FireServer(self, ...)
end)

refs.InvokeServer = hookfunction(InvokeServer, function(self, ...)
	if self and store.isActive() and typeof(self) == "Instance" and self:IsA("RemoteFunction") then
		onReceive(self, { ... })
	end
	return refs.InvokeServer(self, ...)
end)

refs.__namecall = hookmetamethod(game, "__namecall", function(self, ...)
	local method = getnamecallmethod()

	if
		(store.isActive() and method == "FireServer" and IsA(self, "RemoteEvent")) or
		(store.isActive() and method == "InvokeServer" and IsA(self, "RemoteFunction"))
	then
		onReceive(self, { ... })
	end

	return refs.__namecall(self, ...)
end)
 end, _env("RemoteSpy.receiver"))() end)

_module("reducers", "ModuleScript", "RemoteSpy.reducers", "RemoteSpy", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.include.RuntimeLib)
local Rodux = TS.import(script, TS.getModule(script, "@rbxts", "rodux").src)
local actionBarReducer = TS.import(script, script, "action-bar").default
local remoteLogReducer = TS.import(script, script, "remote-log").default
local tabGroupReducer = TS.import(script, script, "tab-group").default
local tracebackReducer = TS.import(script, script, "traceback").default
local default = Rodux.combineReducers({
	actionBar = actionBarReducer,
	remoteLog = remoteLogReducer,
	tabGroup = tabGroupReducer,
	traceback = tracebackReducer,
})
return {
	default = default,
}
 end, _env("RemoteSpy.reducers"))() end)

_module("action-bar", "ModuleScript", "RemoteSpy.reducers.action-bar", "RemoteSpy.reducers", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
for _k, _v in pairs(TS.import(script, script, "actions") or {}) do
	exports[_k] = _v
end
for _k, _v in pairs(TS.import(script, script, "model") or {}) do
	exports[_k] = _v
end
exports.default = TS.import(script, script, "reducer").default
for _k, _v in pairs(TS.import(script, script, "selectors") or {}) do
	exports[_k] = _v
end
return exports
 end, _env("RemoteSpy.reducers.action-bar"))() end)

_module("actions", "ModuleScript", "RemoteSpy.reducers.action-bar.actions", "RemoteSpy.reducers.action-bar", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local function setActionEnabled(id, enabled)
	return {
		type = "SET_ACTION_ENABLED",
		id = id,
		enabled = enabled,
	}
end
local function activateAction(id)
	return {
		type = "ACTIVATE_ACTION",
		id = id,
	}
end
local function deactivateAction(id)
	return {
		type = "DEACTIVATE_ACTION",
		id = id,
	}
end
return {
	setActionEnabled = setActionEnabled,
	activateAction = activateAction,
	deactivateAction = deactivateAction,
}
 end, _env("RemoteSpy.reducers.action-bar.actions"))() end)

_module("model", "ModuleScript", "RemoteSpy.reducers.action-bar.model", "RemoteSpy.reducers.action-bar", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
return nil
 end, _env("RemoteSpy.reducers.action-bar.model"))() end)

_module("reducer", "ModuleScript", "RemoteSpy.reducers.action-bar.reducer", "RemoteSpy.reducers.action-bar", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local initialState = {
	actions = {
		close = {
			id = "close",
			disabled = false,
			active = false,
		},
		navigatePrevious = {
			id = "navigatePrevious",
			disabled = true,
			active = false,
		},
		navigateNext = {
			id = "navigateNext",
			disabled = false,
			active = false,
		},
		copy = {
			id = "copy",
			disabled = true,
			active = false,
		},
		save = {
			id = "save",
			disabled = true,
			active = false,
		},
		delete = {
			id = "delete",
			disabled = true,
			active = false,
		},
		traceback = {
			id = "traceback",
			disabled = false,
			active = false,
		},
		copyPath = {
			id = "copyPath",
			disabled = false,
			active = false,
		},
	},
}
local function actionBarReducer(state, action)
	if state == nil then
		state = initialState
	end
	local _exp = action.type
	repeat
		if _exp == "SET_ACTION_ENABLED" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			local _left = "actions"
			local _object_1 = {}
			for _k, _v in pairs(state.actions) do
				_object_1[_k] = _v
			end
			local _left_1 = action.id
			local _object_2 = {}
			for _k, _v in pairs(state.actions[action.id]) do
				_object_2[_k] = _v
			end
			_object_2.disabled = not action.enabled
			_object_1[_left_1] = _object_2
			_object[_left] = _object_1
			return _object
		end
		if _exp == "ACTIVATE_ACTION" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			local _left = "actions"
			local _object_1 = {}
			for _k, _v in pairs(state.actions) do
				_object_1[_k] = _v
			end
			local _left_1 = action.id
			local _object_2 = {}
			for _k, _v in pairs(state.actions[action.id]) do
				_object_2[_k] = _v
			end
			_object_2.active = true
			_object_1[_left_1] = _object_2
			_object[_left] = _object_1
			return _object
		end
		if _exp == "DEACTIVATE_ACTION" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			local _left = "actions"
			local _object_1 = {}
			for _k, _v in pairs(state.actions) do
				_object_1[_k] = _v
			end
			local _left_1 = action.id
			local _object_2 = {}
			for _k, _v in pairs(state.actions[action.id]) do
				_object_2[_k] = _v
			end
			_object_2.active = false
			_object_1[_left_1] = _object_2
			_object[_left] = _object_1
			return _object
		end
		return state
	until true
end
return {
	default = actionBarReducer,
}
 end, _env("RemoteSpy.reducers.action-bar.reducer"))() end)

_module("selectors", "ModuleScript", "RemoteSpy.reducers.action-bar.selectors", "RemoteSpy.reducers.action-bar", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local selectActionBarState = function(state)
	return state.actionBar.actions
end
local selectIsClosing = function(state)
	return state.actionBar.actions.close.active
end
local selectActionById = function(state, id)
	return state.actionBar.actions[id]
end
local selectActionIsActive = function(state, id)
	return state.actionBar.actions[id].active
end
local selectActionIsDisabled = function(state, id)
	return state.actionBar.actions[id].disabled
end
return {
	selectActionBarState = selectActionBarState,
	selectIsClosing = selectIsClosing,
	selectActionById = selectActionById,
	selectActionIsActive = selectActionIsActive,
	selectActionIsDisabled = selectActionIsDisabled,
}
 end, _env("RemoteSpy.reducers.action-bar.selectors"))() end)

_module("remote-log", "ModuleScript", "RemoteSpy.reducers.remote-log", "RemoteSpy.reducers", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
for _k, _v in pairs(TS.import(script, script, "actions") or {}) do
	exports[_k] = _v
end
for _k, _v in pairs(TS.import(script, script, "model") or {}) do
	exports[_k] = _v
end
exports.default = TS.import(script, script, "reducer").default
for _k, _v in pairs(TS.import(script, script, "utils") or {}) do
	exports[_k] = _v
end
for _k, _v in pairs(TS.import(script, script, "selectors") or {}) do
	exports[_k] = _v
end
return exports
 end, _env("RemoteSpy.reducers.remote-log"))() end)

_module("actions", "ModuleScript", "RemoteSpy.reducers.remote-log.actions", "RemoteSpy.reducers.remote-log", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local function pushRemoteLog(log)
	return {
		type = "PUSH_REMOTE_LOG",
		log = log,
	}
end
local function removeRemoteLog(id)
	return {
		type = "REMOVE_REMOTE_LOG",
		id = id,
	}
end
local function pushOutgoingSignal(id, signal)
	return {
		type = "PUSH_OUTGOING_SIGNAL",
		id = id,
		signal = signal,
	}
end
local function removeOutgoingSignal(id, signalId)
	return {
		type = "REMOVE_OUTGOING_SIGNAL",
		id = id,
		signalId = signalId,
	}
end
local function clearOutgoingSignals(id)
	return {
		type = "CLEAR_OUTGOING_SIGNALS",
		id = id,
	}
end
local function setRemoteSelected(id)
	return {
		type = "SET_REMOTE_SELECTED",
		id = id,
	}
end
local function setSignalSelected(remote, id)
	return {
		type = "SET_SIGNAL_SELECTED",
		remote = remote,
		id = id,
	}
end
local function toggleSignalSelected(remote, id)
	return {
		type = "TOGGLE_SIGNAL_SELECTED",
		remote = remote,
		id = id,
	}
end
return {
	pushRemoteLog = pushRemoteLog,
	removeRemoteLog = removeRemoteLog,
	pushOutgoingSignal = pushOutgoingSignal,
	removeOutgoingSignal = removeOutgoingSignal,
	clearOutgoingSignals = clearOutgoingSignals,
	setRemoteSelected = setRemoteSelected,
	setSignalSelected = setSignalSelected,
	toggleSignalSelected = toggleSignalSelected,
}
 end, _env("RemoteSpy.reducers.remote-log.actions"))() end)

_module("model", "ModuleScript", "RemoteSpy.reducers.remote-log.model", "RemoteSpy.reducers.remote-log", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
return nil
 end, _env("RemoteSpy.reducers.remote-log.model"))() end)

_module("reducer", "ModuleScript", "RemoteSpy.reducers.remote-log.reducer", "RemoteSpy.reducers.remote-log", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local initialState = {
	logs = {},
}
local function remoteLogReducer(state, action)
	if state == nil then
		state = initialState
	end
	local _exp = action.type
	repeat
		if _exp == "PUSH_REMOTE_LOG" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			local _left = "logs"
			local _array = {}
			local _length = #_array
			local _array_1 = state.logs
			local _Length = #_array_1
			table.move(_array_1, 1, _Length, _length + 1, _array)
			_length += _Length
			_array[_length + 1] = action.log
			_object[_left] = _array
			return _object
		end
		if _exp == "REMOVE_REMOTE_LOG" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			local _left = "logs"
			local _logs = state.logs
			local _arg0 = function(log)
				return log.id ~= action.id
			end
			-- ▼ ReadonlyArray.filter ▼
			local _newValue = {}
			local _length = 0
			for _k, _v in ipairs(_logs) do
				if _arg0(_v, _k - 1, _logs) == true then
					_length += 1
					_newValue[_length] = _v
				end
			end
			-- ▲ ReadonlyArray.filter ▲
			_object[_left] = _newValue
			return _object
		end
		if _exp == "PUSH_OUTGOING_SIGNAL" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			local _left = "logs"
			local _logs = state.logs
			local _arg0 = function(log)
				if log.id == action.id then
					local _array = { action.signal }
					local _length = #_array
					local _array_1 = log.outgoing
					table.move(_array_1, 1, #_array_1, _length + 1, _array)
					local outgoing = _array
					if #outgoing > 80 then
						outgoing[#outgoing] = nil
					end
					local _object_1 = {}
					for _k, _v in pairs(log) do
						_object_1[_k] = _v
					end
					_object_1.outgoing = outgoing
					return _object_1
				end
				return log
			end
			-- ▼ ReadonlyArray.map ▼
			local _newValue = table.create(#_logs)
			for _k, _v in ipairs(_logs) do
				_newValue[_k] = _arg0(_v, _k - 1, _logs)
			end
			-- ▲ ReadonlyArray.map ▲
			_object[_left] = _newValue
			return _object
		end
		if _exp == "REMOVE_OUTGOING_SIGNAL" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			local _left = "logs"
			local _logs = state.logs
			local _arg0 = function(log)
				if log.id == action.id then
					local _object_1 = {}
					for _k, _v in pairs(log) do
						_object_1[_k] = _v
					end
					local _left_1 = "outgoing"
					local _outgoing = log.outgoing
					local _arg0_1 = function(signal)
						return signal.id ~= action.signalId
					end
					-- ▼ ReadonlyArray.filter ▼
					local _newValue = {}
					local _length = 0
					for _k, _v in ipairs(_outgoing) do
						if _arg0_1(_v, _k - 1, _outgoing) == true then
							_length += 1
							_newValue[_length] = _v
						end
					end
					-- ▲ ReadonlyArray.filter ▲
					_object_1[_left_1] = _newValue
					return _object_1
				end
				return log
			end
			-- ▼ ReadonlyArray.map ▼
			local _newValue = table.create(#_logs)
			for _k, _v in ipairs(_logs) do
				_newValue[_k] = _arg0(_v, _k - 1, _logs)
			end
			-- ▲ ReadonlyArray.map ▲
			_object[_left] = _newValue
			return _object
		end
		if _exp == "CLEAR_OUTGOING_SIGNALS" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			local _left = "logs"
			local _logs = state.logs
			local _arg0 = function(log)
				if log.id == action.id then
					local _object_1 = {}
					for _k, _v in pairs(log) do
						_object_1[_k] = _v
					end
					_object_1.outgoing = {}
					return _object_1
				end
				return log
			end
			-- ▼ ReadonlyArray.map ▼
			local _newValue = table.create(#_logs)
			for _k, _v in ipairs(_logs) do
				_newValue[_k] = _arg0(_v, _k - 1, _logs)
			end
			-- ▲ ReadonlyArray.map ▲
			_object[_left] = _newValue
			return _object
		end
		if _exp == "SET_REMOTE_SELECTED" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			_object.remoteSelected = action.id
			return _object
		end
		if _exp == "SET_SIGNAL_SELECTED" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			_object.signalSelected = action.id
			_object.remoteForSignalSelected = if action.id ~= nil then action.remote else nil
			return _object
		end
		if _exp == "TOGGLE_SIGNAL_SELECTED" then
			local signalSelected = if state.signalSelected == action.id then nil else action.id
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			_object.signalSelected = signalSelected
			_object.remoteForSignalSelected = if signalSelected ~= nil then action.remote else nil
			return _object
		end
		return state
	until true
end
return {
	default = remoteLogReducer,
}
 end, _env("RemoteSpy.reducers.remote-log.reducer"))() end)

_module("selectors", "ModuleScript", "RemoteSpy.reducers.remote-log.selectors", "RemoteSpy.reducers.remote-log", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local createSelector = TS.import(script, TS.getModule(script, "@rbxts", "roselect").src).createSelector
local selectRemoteLogs = function(state)
	return state.remoteLog.logs
end
local selectRemoteLogIds = createSelector({ selectRemoteLogs }, function(logs)
	local _arg0 = function(log)
		return log.id
	end
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#logs)
	for _k, _v in ipairs(logs) do
		_newValue[_k] = _arg0(_v, _k - 1, logs)
	end
	-- ▲ ReadonlyArray.map ▲
	return _newValue
end)
local selectRemoteLogsOutgoing = function(state)
	local _logs = state.remoteLog.logs
	local _arg0 = function(log)
		return log.outgoing
	end
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#_logs)
	for _k, _v in ipairs(_logs) do
		_newValue[_k] = _arg0(_v, _k - 1, _logs)
	end
	-- ▲ ReadonlyArray.map ▲
	return _newValue
end
local selectRemoteIdSelected = function(state)
	return state.remoteLog.remoteSelected
end
local selectSignalIdSelected = function(state)
	return state.remoteLog.signalSelected
end
local selectSignalIdSelectedRemote = function(state)
	return state.remoteLog.remoteForSignalSelected
end
local makeSelectRemoteLog = function()
	return createSelector({ selectRemoteLogs, function(_, id)
		return id
	end }, function(logs, id)
		local _arg0 = function(log)
			return log.id == id
		end
		-- ▼ ReadonlyArray.find ▼
		local _result
		for _i, _v in ipairs(logs) do
			if _arg0(_v, _i - 1, logs) == true then
				_result = _v
				break
			end
		end
		-- ▲ ReadonlyArray.find ▲
		return _result
	end)
end
local makeSelectRemoteLogOutgoing = function()
	return createSelector({ makeSelectRemoteLog() }, function(log)
		local _result = log
		if _result ~= nil then
			_result = _result.outgoing
		end
		return _result
	end)
end
local makeSelectRemoteLogObject = function()
	return createSelector({ makeSelectRemoteLog() }, function(log)
		local _result = log
		if _result ~= nil then
			_result = _result.object
		end
		return _result
	end)
end
local makeSelectRemoteLogType = function()
	return createSelector({ makeSelectRemoteLog() }, function(log)
		local _result = log
		if _result ~= nil then
			_result = _result.type
		end
		return _result
	end)
end
local _selectOutgoing = makeSelectRemoteLogOutgoing()
local selectSignalSelected = createSelector({ function(state)
	local _condition = selectSignalIdSelectedRemote(state)
	if _condition == nil then
		_condition = ""
	end
	return _selectOutgoing(state, _condition)
end, selectSignalIdSelected }, function(outgoing, id)
	local _result
	if outgoing and id ~= nil then
		local _result_1 = outgoing
		if _result_1 ~= nil then
			local _arg0 = function(signal)
				return signal.id == id
			end
			-- ▼ ReadonlyArray.find ▼
			local _result_2
			for _i, _v in ipairs(_result_1) do
				if _arg0(_v, _i - 1, _result_1) == true then
					_result_2 = _v
					break
				end
			end
			-- ▲ ReadonlyArray.find ▲
			_result_1 = _result_2
		end
		_result = _result_1
	else
		_result = nil
	end
	return _result
end)
return {
	selectRemoteLogs = selectRemoteLogs,
	selectRemoteLogIds = selectRemoteLogIds,
	selectRemoteLogsOutgoing = selectRemoteLogsOutgoing,
	selectRemoteIdSelected = selectRemoteIdSelected,
	selectSignalIdSelected = selectSignalIdSelected,
	selectSignalIdSelectedRemote = selectSignalIdSelectedRemote,
	makeSelectRemoteLog = makeSelectRemoteLog,
	makeSelectRemoteLogOutgoing = makeSelectRemoteLogOutgoing,
	makeSelectRemoteLogObject = makeSelectRemoteLogObject,
	makeSelectRemoteLogType = makeSelectRemoteLogType,
	selectSignalSelected = selectSignalSelected,
}
 end, _env("RemoteSpy.reducers.remote-log.selectors"))() end)

_module("utils", "ModuleScript", "RemoteSpy.reducers.remote-log.utils", "RemoteSpy.reducers.remote-log", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local TabType = TS.import(script, script.Parent.Parent, "tab-group").TabType
local _instance_util = TS.import(script, script.Parent.Parent.Parent, "utils", "instance-util")
local getInstanceId = _instance_util.getInstanceId
local getInstancePath = _instance_util.getInstancePath
local stringifyFunctionSignature = TS.import(script, script.Parent.Parent.Parent, "utils", "function-util").stringifyFunctionSignature
local nextId = 0
local function createRemoteLog(object, signal)
	local id = getInstanceId(object)
	local remoteType = if object:IsA("RemoteEvent") then TabType.Event else TabType.Function
	return {
		id = id,
		object = object,
		type = remoteType,
		outgoing = if signal then { signal } else {},
	}
end
local function createOutgoingSignal(object, caller, callback, traceback, parameters, returns)
	local _object = {}
	local _left = "id"
	local _original = nextId
	nextId += 1
	_object[_left] = "signal-" .. tostring(_original)
	_object.remote = object
	_object.remoteId = getInstanceId(object)
	_object.name = object.Name
	_object.path = getInstancePath(object)
	_object.pathFmt = getInstancePath(object)
	_object.parameters = parameters
	_object.returns = returns
	_object.caller = caller
	_object.callback = callback
	_object.traceback = traceback
	return _object
end
local function stringifySignalTraceback(signal)
	local _exp = signal.traceback
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#_exp)
	for _k, _v in ipairs(_exp) do
		_newValue[_k] = stringifyFunctionSignature(_v, _k - 1, _exp)
	end
	-- ▲ ReadonlyArray.map ▲
	local mapped = _newValue
	local length = #mapped
	do
		local i = 0
		local _shouldIncrement = false
		while true do
			if _shouldIncrement then
				i += 1
			else
				_shouldIncrement = true
			end
			if not (i < length / 2) then
				break
			end
			local temp = mapped[i + 1]
			mapped[i + 1] = mapped[length - i - 1 + 1]
			mapped[length - i - 1 + 1] = temp
		end
	end
	mapped[length - 1 + 1] = "→ " .. (mapped[length - 1 + 1] .. " ←")
	return mapped
end
return {
	createRemoteLog = createRemoteLog,
	createOutgoingSignal = createOutgoingSignal,
	stringifySignalTraceback = stringifySignalTraceback,
}
 end, _env("RemoteSpy.reducers.remote-log.utils"))() end)

_module("tab-group", "ModuleScript", "RemoteSpy.reducers.tab-group", "RemoteSpy.reducers", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
for _k, _v in pairs(TS.import(script, script, "actions") or {}) do
	exports[_k] = _v
end
for _k, _v in pairs(TS.import(script, script, "model") or {}) do
	exports[_k] = _v
end
exports.default = TS.import(script, script, "reducer").default
for _k, _v in pairs(TS.import(script, script, "selectors") or {}) do
	exports[_k] = _v
end
for _k, _v in pairs(TS.import(script, script, "utils") or {}) do
	exports[_k] = _v
end
return exports
 end, _env("RemoteSpy.reducers.tab-group"))() end)

_module("actions", "ModuleScript", "RemoteSpy.reducers.tab-group.actions", "RemoteSpy.reducers.tab-group", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local function pushTab(tab)
	return {
		type = "PUSH_TAB",
		tab = tab,
	}
end
local function deleteTab(id)
	return {
		type = "DELETE_TAB",
		id = id,
	}
end
local function moveTab(id, to)
	return {
		type = "MOVE_TAB",
		id = id,
		to = to,
	}
end
local function setActiveTab(id)
	return {
		type = "SET_ACTIVE_TAB",
		id = id,
	}
end
return {
	pushTab = pushTab,
	deleteTab = deleteTab,
	moveTab = moveTab,
	setActiveTab = setActiveTab,
}
 end, _env("RemoteSpy.reducers.tab-group.actions"))() end)

_module("model", "ModuleScript", "RemoteSpy.reducers.tab-group.model", "RemoteSpy.reducers.tab-group", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TabType
do
	local _inverse = {}
	TabType = setmetatable({}, {
		__index = _inverse,
	})
	TabType.Home = "home"
	_inverse.home = "Home"
	TabType.Event = "event"
	_inverse.event = "Event"
	TabType.Function = "function"
	_inverse["function"] = "Function"
	TabType.Script = "script"
	_inverse.script = "Script"
end
return {
	TabType = TabType,
}
 end, _env("RemoteSpy.reducers.tab-group.model"))() end)

_module("reducer", "ModuleScript", "RemoteSpy.reducers.tab-group.reducer", "RemoteSpy.reducers.tab-group", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local TabType = TS.import(script, script.Parent, "model").TabType
local createTabColumn = TS.import(script, script.Parent, "utils").createTabColumn
local initialState = {
	tabs = { createTabColumn("home", "Home", TabType.Home, false) },
	activeTab = "home",
}
local function tabGroupReducer(state, action)
	if state == nil then
		state = initialState
	end
	local _exp = action.type
	repeat
		if _exp == "PUSH_TAB" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			local _left = "tabs"
			local _array = {}
			local _length = #_array
			local _array_1 = state.tabs
			local _Length = #_array_1
			table.move(_array_1, 1, _Length, _length + 1, _array)
			_length += _Length
			_array[_length + 1] = action.tab
			_object[_left] = _array
			return _object
		end
		if _exp == "DELETE_TAB" then
			local _tabs = state.tabs
			local _arg0 = function(tab)
				return tab.id == action.id
			end
			-- ▼ ReadonlyArray.findIndex ▼
			local _result = -1
			for _i, _v in ipairs(_tabs) do
				if _arg0(_v, _i - 1, _tabs) == true then
					_result = _i - 1
					break
				end
			end
			-- ▲ ReadonlyArray.findIndex ▲
			local index = _result
			local _object = {}
			local _left = "tabs"
			local _tabs_1 = state.tabs
			local _arg0_1 = function(tab)
				return tab.id ~= action.id
			end
			-- ▼ ReadonlyArray.filter ▼
			local _newValue = {}
			local _length = 0
			for _k, _v in ipairs(_tabs_1) do
				if _arg0_1(_v, _k - 1, _tabs_1) == true then
					_length += 1
					_newValue[_length] = _v
				end
			end
			-- ▲ ReadonlyArray.filter ▲
			_object[_left] = _newValue
			local _left_1 = "activeTab"
			local _result_1
			if state.activeTab == action.id then
				local _result_2 = state.tabs[index - 1 + 1]
				if _result_2 ~= nil then
					_result_2 = _result_2.id
				end
				local _condition = _result_2
				if _condition == nil then
					_condition = state.tabs[index + 1 + 1].id
				end
				_result_1 = _condition
			else
				_result_1 = state.activeTab
			end
			_object[_left_1] = _result_1
			return _object
		end
		if _exp == "MOVE_TAB" then
			local _tabs = state.tabs
			local _arg0 = function(tab)
				return tab.id == action.id
			end
			-- ▼ ReadonlyArray.find ▼
			local _result
			for _i, _v in ipairs(_tabs) do
				if _arg0(_v, _i - 1, _tabs) == true then
					_result = _v
					break
				end
			end
			-- ▲ ReadonlyArray.find ▲
			local tab = _result
			local from = (table.find(state.tabs, tab) or 0) - 1
			local tabs = table.clone(state.tabs)
			table.remove(tabs, from + 1)
			local _to = action.to
			table.insert(tabs, _to + 1, tab)
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			_object.tabs = tabs
			return _object
		end
		if _exp == "SET_ACTIVE_TAB" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			_object.activeTab = action.id
			return _object
		end
		return state
	until true
end
return {
	default = tabGroupReducer,
}
 end, _env("RemoteSpy.reducers.tab-group.reducer"))() end)

_module("selectors", "ModuleScript", "RemoteSpy.reducers.tab-group.selectors", "RemoteSpy.reducers.tab-group", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local createSelector = TS.import(script, TS.getModule(script, "@rbxts", "roselect").src).createSelector
local getTabOffset = TS.import(script, script.Parent, "utils").getTabOffset
local selectTabGroup = function(state)
	return state.tabGroup
end
local selectTabs = function(state)
	return state.tabGroup.tabs
end
local selectActiveTabId = function(state)
	return state.tabGroup.activeTab
end
local selectTabCount = function(state)
	return #state.tabGroup.tabs
end
local selectTab
local selectActiveTab = function(state)
	return selectTab(state, state.tabGroup.activeTab)
end
selectTab = function(state, id)
	local _tabs = state.tabGroup.tabs
	local _arg0 = function(tab)
		return tab.id == id
	end
	-- ▼ ReadonlyArray.find ▼
	local _result
	for _i, _v in ipairs(_tabs) do
		if _arg0(_v, _i - 1, _tabs) == true then
			_result = _v
			break
		end
	end
	-- ▲ ReadonlyArray.find ▲
	return _result
end
local selectTabOrder = function(state, id)
	local _tabs = state.tabGroup.tabs
	local _arg0 = function(tab)
		return tab.id == id
	end
	-- ▼ ReadonlyArray.findIndex ▼
	local _result = -1
	for _i, _v in ipairs(_tabs) do
		if _arg0(_v, _i - 1, _tabs) == true then
			_result = _i - 1
			break
		end
	end
	-- ▲ ReadonlyArray.findIndex ▲
	return _result
end
local selectActiveTabOrder = function(state)
	local _tabs = state.tabGroup.tabs
	local _arg0 = function(tab)
		return tab.id == state.tabGroup.activeTab
	end
	-- ▼ ReadonlyArray.findIndex ▼
	local _result = -1
	for _i, _v in ipairs(_tabs) do
		if _arg0(_v, _i - 1, _tabs) == true then
			_result = _i - 1
			break
		end
	end
	-- ▲ ReadonlyArray.findIndex ▲
	return _result
end
local selectTabIsActive = function(state, id)
	return state.tabGroup.activeTab == id
end
local selectTabType = function(state, id)
	local _result = selectTab(state, id)
	if _result ~= nil then
		_result = _result.type
	end
	return _result
end
local makeSelectTabsBefore = function()
	local selectTabsBefore = createSelector({ selectTabs, selectTabOrder }, function(tabs, order)
		local _arg0 = function(_, index)
			return index < order
		end
		-- ▼ ReadonlyArray.filter ▼
		local _newValue = {}
		local _length = 0
		for _k, _v in ipairs(tabs) do
			if _arg0(_v, _k - 1, tabs) == true then
				_length += 1
				_newValue[_length] = _v
			end
		end
		-- ▲ ReadonlyArray.filter ▲
		return _newValue
	end)
	return selectTabsBefore
end
local makeSelectTabOffset = function()
	local selectTabOffset = createSelector({ makeSelectTabsBefore(), selectTab }, function(tabs, tab)
		if not tab then
			return 0
		end
		return getTabOffset(tabs, tab)
	end)
	return selectTabOffset
end
return {
	selectTabGroup = selectTabGroup,
	selectTabs = selectTabs,
	selectActiveTabId = selectActiveTabId,
	selectTabCount = selectTabCount,
	selectActiveTab = selectActiveTab,
	selectTab = selectTab,
	selectTabOrder = selectTabOrder,
	selectActiveTabOrder = selectActiveTabOrder,
	selectTabIsActive = selectTabIsActive,
	selectTabType = selectTabType,
	makeSelectTabsBefore = makeSelectTabsBefore,
	makeSelectTabOffset = makeSelectTabOffset,
}
 end, _env("RemoteSpy.reducers.tab-group.selectors"))() end)

_module("utils", "ModuleScript", "RemoteSpy.reducers.tab-group.utils", "RemoteSpy.reducers.tab-group", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local TextService = TS.import(script, TS.getModule(script, "@rbxts", "services")).TextService
local MAX_TAB_CAPTION_WIDTH = 150
local function createTabColumn(id, caption, tabType, canClose)
	if canClose == nil then
		canClose = true
	end
	return {
		id = id,
		caption = caption,
		type = tabType,
		canClose = canClose,
	}
end
local function getTabCaptionWidth(tab)
	local textSize = TextService:GetTextSize(tab.caption, 11, "Gotham", Vector2.new(300, 0))
	return math.min(textSize.X, MAX_TAB_CAPTION_WIDTH)
end
local function getTabWidth(tab)
	local captionWidth = getTabCaptionWidth(tab)
	local iconWidth = 16 + 6
	local closeWidth = if tab.canClose then 16 + 6 else 3
	return 8 + iconWidth + captionWidth + closeWidth + 8
end
local function getTabOffset(tabs, tab)
	local offset = 0
	for _, t in ipairs(tabs) do
		if t == tab then
			break
		end
		offset += getTabWidth(t)
	end
	return offset
end
return {
	createTabColumn = createTabColumn,
	getTabCaptionWidth = getTabCaptionWidth,
	getTabWidth = getTabWidth,
	getTabOffset = getTabOffset,
	MAX_TAB_CAPTION_WIDTH = MAX_TAB_CAPTION_WIDTH,
}
 end, _env("RemoteSpy.reducers.tab-group.utils"))() end)

_module("traceback", "ModuleScript", "RemoteSpy.reducers.traceback", "RemoteSpy.reducers", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local exports = {}
for _k, _v in pairs(TS.import(script, script, "actions") or {}) do
	exports[_k] = _v
end
for _k, _v in pairs(TS.import(script, script, "model") or {}) do
	exports[_k] = _v
end
for _k, _v in pairs(TS.import(script, script, "selectors") or {}) do
	exports[_k] = _v
end
exports.default = TS.import(script, script, "reducer").default
return exports
 end, _env("RemoteSpy.reducers.traceback"))() end)

_module("actions", "ModuleScript", "RemoteSpy.reducers.traceback.actions", "RemoteSpy.reducers.traceback", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local function setTracebackCallStack(callStack)
	return {
		type = "SET_TRACEBACK_CALL_STACK",
		callStack = callStack,
	}
end
local function clearTraceback()
	return {
		type = "CLEAR_TRACEBACK",
	}
end
return {
	setTracebackCallStack = setTracebackCallStack,
	clearTraceback = clearTraceback,
}
 end, _env("RemoteSpy.reducers.traceback.actions"))() end)

_module("model", "ModuleScript", "RemoteSpy.reducers.traceback.model", "RemoteSpy.reducers.traceback", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
return nil
 end, _env("RemoteSpy.reducers.traceback.model"))() end)

_module("reducer", "ModuleScript", "RemoteSpy.reducers.traceback.reducer", "RemoteSpy.reducers.traceback", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local initialState = {
	callStack = {},
}
local function tracebackReducer(state, action)
	if state == nil then
		state = initialState
	end
	local _exp = action.type
	repeat
		if _exp == "SET_TRACEBACK_CALL_STACK" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			_object.callStack = action.callStack
			return _object
		end
		if _exp == "CLEAR_TRACEBACK" then
			local _object = {}
			for _k, _v in pairs(state) do
				_object[_k] = _v
			end
			_object.callStack = {}
			return _object
		end
		return state
	until true
end
return {
	default = tracebackReducer,
}
 end, _env("RemoteSpy.reducers.traceback.reducer"))() end)

_module("selectors", "ModuleScript", "RemoteSpy.reducers.traceback.selectors", "RemoteSpy.reducers.traceback", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.Parent.include.RuntimeLib)
local createSelector = TS.import(script, TS.getModule(script, "@rbxts", "roselect").src).createSelector
local _function_util = TS.import(script, script.Parent.Parent.Parent, "utils", "function-util")
local describeFunction = _function_util.describeFunction
local getFunctionScript = _function_util.getFunctionScript
local selectTracebackState = function(state)
	return state.traceback
end
local selectTracebackCallStack = function(state)
	return state.traceback.callStack
end
local selectTracebackByString = createSelector({ selectTracebackState, function(_, searchString)
	return searchString
end }, function(traceback, searchString)
	local _callStack = traceback.callStack
	local _arg0 = function(callback)
		local description = describeFunction(callback)
		local creator = getFunctionScript(callback)
		return (string.find(description.name, searchString)) ~= nil or (string.find(tostring(creator), searchString)) ~= nil
	end
	-- ▼ ReadonlyArray.filter ▼
	local _newValue = {}
	local _length = 0
	for _k, _v in ipairs(_callStack) do
		if _arg0(_v, _k - 1, _callStack) == true then
			_length += 1
			_newValue[_length] = _v
		end
	end
	-- ▲ ReadonlyArray.filter ▲
	return _newValue
end)
return {
	selectTracebackState = selectTracebackState,
	selectTracebackCallStack = selectTracebackCallStack,
	selectTracebackByString = selectTracebackByString,
}
 end, _env("RemoteSpy.reducers.traceback.selectors"))() end)

_module("store", "ModuleScript", "RemoteSpy.store", "RemoteSpy", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.include.RuntimeLib)
local Rodux = TS.import(script, TS.getModule(script, "@rbxts", "rodux").src)
local rootReducer = TS.import(script, script.Parent, "reducers").default
local store
local isDestructed = false
local function createStore()
	return Rodux.Store.new(rootReducer, nil)
end
local function configureStore()
	if store then
		return store
	end
	store = createStore()
	return store
end
local function destruct()
	if isDestructed then
		return nil
	end
	isDestructed = true
	store:destruct()
end
local function isActive()
	return store and not isDestructed
end
local function dispatch(action)
	if isDestructed then
		return nil
	end
	return configureStore():dispatch(action)
end
local function get(selector)
	if isDestructed then
		return nil
	end
	local store = configureStore()
	return if selector then selector(store:getState()) else store:getState()
end
local function changed(selector, callback)
	if isDestructed then
		return nil
	end
	local store = configureStore()
	local lastState = selector(store:getState())
	task.defer(callback, lastState)
	return store.changed:connect(function(state)
		local newState = selector(state)
		if lastState ~= newState then
			local _fn = task
			lastState = newState
			_fn.spawn(callback, lastState)
		end
	end)
end
return {
	configureStore = configureStore,
	destruct = destruct,
	isActive = isActive,
	dispatch = dispatch,
	get = get,
	changed = changed,
}
 end, _env("RemoteSpy.store"))() end)

_instance("utils", "Folder", "RemoteSpy.utils", "RemoteSpy")

_module("codify", "ModuleScript", "RemoteSpy.utils.codify", "RemoteSpy.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = require(script.Parent.Parent.include.RuntimeLib)
local getInstancePath = TS.import(script, script.Parent, "instance-util").getInstancePath
local codifyTableFlat, codifyTable, codify
local transformers = {
	table = function(value, level)
		return if level == -1 then codifyTableFlat(value) else codifyTable(value, level + 1)
	end,
	string = function(value)
		return string.format("%q", (string.gsub(value, "\n", "\\n")))
	end,
	number = function(value)
		return tostring(value)
	end,
	boolean = function(value)
		return tostring(value)
	end,
	Instance = function(value)
		return getInstancePath(value)
	end,
	BrickColor = function(value)
		return 'BrickColor.new("' .. (value.Name .. '")')
	end,
	Color3 = function(value)
		return "Color3.new(" .. (tostring(value.R) .. (", " .. (tostring(value.G) .. (", " .. (tostring(value.B) .. ")")))))
	end,
	ColorSequenceKeypoint = function(value)
		return "ColorSequenceKeypoint.new(" .. (tostring(value.Time) .. (", " .. (codify(value.Value) .. ")")))
	end,
	ColorSequence = function(value)
		return "ColorSequence.new(" .. (codify(value.Keypoints) .. ")")
	end,
	NumberRange = function(value)
		return "NumberRange.new(" .. (tostring(value.Min) .. (", " .. (tostring(value.Max) .. ")")))
	end,
	NumberSequenceKeypoint = function(value)
		return "NumberSequenceKeypoint.new(" .. (tostring(value.Time) .. (", " .. (codify(value.Value) .. ")")))
	end,
	NumberSequence = function(value)
		return "NumberSequence.new(" .. (codify(value.Keypoints) .. ")")
	end,
	Vector3 = function(value)
		return "Vector3.new(" .. (tostring(value.X) .. (", " .. (tostring(value.Y) .. (", " .. (tostring(value.Z) .. ")")))))
	end,
	Vector2 = function(value)
		return "Vector2.new(" .. (tostring(value.X) .. (", " .. (tostring(value.Y) .. ")")))
	end,
	UDim2 = function(value)
		return "UDim2.new(" .. (tostring(value.X.Scale) .. (", " .. (tostring(value.X.Offset) .. (", " .. (tostring(value.Y.Scale) .. (", " .. (tostring(value.Y.Offset) .. ")")))))))
	end,
	Ray = function(value)
		return "Ray.new(" .. (codify(value.Origin) .. (", " .. (codify(value.Direction) .. ")")))
	end,
	CFrame = function(value)
		return "CFrame.new(" .. (table.concat({ value:GetComponents() }, ", ") .. ")")
	end,
}
function codify(value, level)
	if level == nil then
		level = 0
	end
	local transformer = transformers[typeof(value)]
	if transformer then
		return transformer(value, level)
	else
		return tostring(value) .. (" --[[" .. (typeof(value) .. " not supported]]"))
	end
end
function codifyTable(object, level)
	if level == nil then
		level = 0
	end
	local lines = {}
	local indent = string.rep("	", level + 1)
	for key, value in pairs(object) do
		if type(value) == "function" or type(value) == "thread" then
			continue
		end
		local _arg0 = indent .. ("[" .. (codify(key, level) .. ("] = " .. codify(value, level))))
		table.insert(lines, _arg0)
	end
	if #lines == 0 then
		return "{}"
	end
	return "{\n" .. (table.concat(lines, ",\n") .. ("\n" .. (string.sub(indent, 1, -2) .. "}")))
end
function codifyTableFlat(object)
	local lines = {}
	for key, value in pairs(object) do
		if type(value) == "function" or type(value) == "thread" then
			continue
		end
		local _arg0 = "[" .. (codify(key, -1) .. ("] = " .. codify(value, -1)))
		table.insert(lines, _arg0)
	end
	if #lines == 0 then
		return "{}"
	end
	return "{ " .. (table.concat(lines, ", ") .. " }")
end
return {
	codify = codify,
	codifyTable = codifyTable,
	codifyTableFlat = codifyTableFlat,
}
 end, _env("RemoteSpy.utils.codify"))() end)

_module("format-escapes", "ModuleScript", "RemoteSpy.utils.format-escapes", "RemoteSpy.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local function formatEscapes(str)
	return (string.gsub(str, "[\n\r\t]+", " "))
end
return {
	formatEscapes = formatEscapes,
}
 end, _env("RemoteSpy.utils.format-escapes"))() end)

_module("function-util", "ModuleScript", "RemoteSpy.utils.function-util", "RemoteSpy.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local function describeFunction(fn)
	if debug.getinfo then
		local info = debug.getinfo(fn)
		local _object = {
			name = if info.name == "" or info.name == nil then "(anonymous)" else info.name,
			source = info.short_src,
		}
		local _left = "parameters"
		local _condition = info.numparams
		if _condition == nil then
			_condition = 0
		end
		_object[_left] = _condition
		_object.variadic = if info.is_vararg == 1 then true else false
		return _object
	end
	local name = debug.info(fn, "n")
	local source = debug.info(fn, "s")
	local parameters, variadic = debug.info(fn, "a")
	return {
		name = if name == "" or name == nil then "(anonymous)" else name,
		source = source,
		parameters = parameters,
		variadic = variadic,
	}
end
local function getFunctionScript(fn)
	return rawget(getfenv(fn), "script")
end
local function stringifyFunctionSignature(fn)
	local description = describeFunction(fn)
	local params = {}
	do
		local i = 0
		local _shouldIncrement = false
		while true do
			if _shouldIncrement then
				i += 1
			else
				_shouldIncrement = true
			end
			if not (i < description.parameters) then
				break
			end
			local _arg0 = string.char((string.byte("A")) + i)
			table.insert(params, _arg0)
		end
	end
	if description.variadic then
		table.insert(params, "...")
	end
	return description.name .. ("(" .. (table.concat(params, ", ") .. ")"))
end
return {
	describeFunction = describeFunction,
	getFunctionScript = getFunctionScript,
	stringifyFunctionSignature = stringifyFunctionSignature,
}
 end, _env("RemoteSpy.utils.function-util"))() end)

_module("global-util", "ModuleScript", "RemoteSpy.utils.global-util", "RemoteSpy.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local globals = if getgenv then getgenv() else {}
local function getGlobals()
	return globals
end
local function setGlobal(key, value)
	globals[key] = value
end
local function getGlobal(key)
	return globals[key]
end
local function hasGlobal(key)
	return globals[key] ~= nil
end
return {
	getGlobals = getGlobals,
	setGlobal = setGlobal,
	getGlobal = getGlobal,
	hasGlobal = hasGlobal,
}
 end, _env("RemoteSpy.utils.global-util"))() end)

_module("instance-util", "ModuleScript", "RemoteSpy.utils.instance-util", "RemoteSpy.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local idsByObject = {}
local objectsById = {}
local nextId = 0
local hasSpecialCharacters = function(str)
	return (string.match(str, "[a-zA-Z0-9_]+")) ~= str
end
local function getInstanceId(object)
	if not (idsByObject[object] ~= nil) then
		local _original = nextId
		nextId += 1
		local id = "instance-" .. tostring(_original)
		idsByObject[object] = id
		objectsById[id] = object
	end
	return idsByObject[object]
end
local function getInstanceFromId(id)
	return objectsById[id]
end
local function getInstancePath(object)
	local path = ""
	local current = object
	local isInDataModel = false
	repeat
		do
			if current == game then
				path = "game" .. path
				isInDataModel = true
			elseif current.Parent == game then
				path = ":GetService(" .. (string.format("%q", current.ClassName) .. (")" .. path))
			else
				path = if hasSpecialCharacters(current.Name) then "[" .. (string.format("%q", current.Name) .. ("]" .. path)) else "." .. (current.Name .. path)
			end
			current = current.Parent
		end
	until not current
	if not isInDataModel then
		path = "(nil)" .. path
	end
	path = string.gsub(path, '^game:GetService%("Workspace"%)', "workspace")
	return path
end
return {
	getInstanceId = getInstanceId,
	getInstanceFromId = getInstanceFromId,
	getInstancePath = getInstancePath,
}
 end, _env("RemoteSpy.utils.instance-util"))() end)

_module("number-util", "ModuleScript", "RemoteSpy.utils.number-util", "RemoteSpy.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local function map(n, min0, max0, min1, max1)
	return min1 + ((n - min0) * (max1 - min1)) / (max0 - min0)
end
local function mapStrict(n, min0, max0, min1, max1)
	return math.clamp(min1 + ((n - min0) * (max1 - min1)) / (max0 - min0), min1, max1)
end
local function lerp(a, b, t)
	return a + (b - a) * t
end
local function multiply(n, ...)
	local args = { ... }
	local _arg0 = function(a, b)
		return 1 - (1 - a) * (1 - b)
	end
	-- ▼ ReadonlyArray.reduce ▼
	local _result = n
	local _callback = _arg0
	for _i = 1, #args do
		_result = _callback(_result, args[_i], _i - 1, args)
	end
	-- ▲ ReadonlyArray.reduce ▲
	return _result
end
return {
	map = map,
	mapStrict = mapStrict,
	lerp = lerp,
	multiply = multiply,
}
 end, _env("RemoteSpy.utils.number-util"))() end)

_instance("include", "Folder", "RemoteSpy.include", "RemoteSpy")

_module("Promise", "ModuleScript", "RemoteSpy.include.Promise", "RemoteSpy.include", function () return setfenv(function() --[[
	An implementation of Promises similar to Promise/A+.
]]

local ERROR_NON_PROMISE_IN_LIST = "Non-promise value passed into %s at index %s"
local ERROR_NON_LIST = "Please pass a list of promises to %s"
local ERROR_NON_FUNCTION = "Please pass a handler function to %s!"
local MODE_KEY_METATABLE = { __mode = "k" }

local function isCallable(value)
	if type(value) == "function" then
		return true
	end

	if type(value) == "table" then
		local metatable = getmetatable(value)
		if metatable and type(rawget(metatable, "__call")) == "function" then
			return true
		end
	end

	return false
end

--[[
	Creates an enum dictionary with some metamethods to prevent common mistakes.
]]
local function makeEnum(enumName, members)
	local enum = {}

	for _, memberName in ipairs(members) do
		enum[memberName] = memberName
	end

	return setmetatable(enum, {
		__index = function(_, k)
			error(string.format("%s is not in %s!", k, enumName), 2)
		end,
		__newindex = function()
			error(string.format("Creating new members in %s is not allowed!", enumName), 2)
		end,
	})
end

--[=[
	An object to represent runtime errors that occur during execution.
	Promises that experience an error like this will be rejected with
	an instance of this object.

	@class Error
]=]
local Error
do
	Error = {
		Kind = makeEnum("Promise.Error.Kind", {
			"ExecutionError",
			"AlreadyCancelled",
			"NotResolvedInTime",
			"TimedOut",
		}),
	}
	Error.__index = Error

	function Error.new(options, parent)
		options = options or {}
		return setmetatable({
			error = tostring(options.error) or "[This error has no error text.]",
			trace = options.trace,
			context = options.context,
			kind = options.kind,
			parent = parent,
			createdTick = os.clock(),
			createdTrace = debug.traceback(),
		}, Error)
	end

	function Error.is(anything)
		if type(anything) == "table" then
			local metatable = getmetatable(anything)

			if type(metatable) == "table" then
				return rawget(anything, "error") ~= nil and type(rawget(metatable, "extend")) == "function"
			end
		end

		return false
	end

	function Error.isKind(anything, kind)
		assert(kind ~= nil, "Argument #2 to Promise.Error.isKind must not be nil")

		return Error.is(anything) and anything.kind == kind
	end

	function Error:extend(options)
		options = options or {}

		options.kind = options.kind or self.kind

		return Error.new(options, self)
	end

	function Error:getErrorChain()
		local runtimeErrors = { self }

		while runtimeErrors[#runtimeErrors].parent do
			table.insert(runtimeErrors, runtimeErrors[#runtimeErrors].parent)
		end

		return runtimeErrors
	end

	function Error:__tostring()
		local errorStrings = {
			string.format("-- Promise.Error(%s) --", self.kind or "?"),
		}

		for _, runtimeError in ipairs(self:getErrorChain()) do
			table.insert(
				errorStrings,
				table.concat({
					runtimeError.trace or runtimeError.error,
					runtimeError.context,
				}, "\n")
			)
		end

		return table.concat(errorStrings, "\n")
	end
end

--[[
	Packs a number of arguments into a table and returns its length.

	Used to cajole varargs without dropping sparse values.
]]
local function pack(...)
	return select("#", ...), { ... }
end

--[[
	Returns first value (success), and packs all following values.
]]
local function packResult(success, ...)
	return success, select("#", ...), { ... }
end

local function makeErrorHandler(traceback)
	assert(traceback ~= nil, "traceback is nil")

	return function(err)
		-- If the error object is already a table, forward it directly.
		-- Should we extend the error here and add our own trace?

		if type(err) == "table" then
			return err
		end

		return Error.new({
			error = err,
			kind = Error.Kind.ExecutionError,
			trace = debug.traceback(tostring(err), 2),
			context = "Promise created at:\n\n" .. traceback,
		})
	end
end

--[[
	Calls a Promise executor with error handling.
]]
local function runExecutor(traceback, callback, ...)
	return packResult(xpcall(callback, makeErrorHandler(traceback), ...))
end

--[[
	Creates a function that invokes a callback with correct error handling and
	resolution mechanisms.
]]
local function createAdvancer(traceback, callback, resolve, reject)
	return function(...)
		local ok, resultLength, result = runExecutor(traceback, callback, ...)

		if ok then
			resolve(unpack(result, 1, resultLength))
		else
			reject(result[1])
		end
	end
end

local function isEmpty(t)
	return next(t) == nil
end

--[=[
	An enum value used to represent the Promise's status.
	@interface Status
	@tag enum
	@within Promise
	.Started "Started" -- The Promise is executing, and not settled yet.
	.Resolved "Resolved" -- The Promise finished successfully.
	.Rejected "Rejected" -- The Promise was rejected.
	.Cancelled "Cancelled" -- The Promise was cancelled before it finished.
]=]
--[=[
	@prop Status Status
	@within Promise
	@readonly
	@tag enums
	A table containing all members of the `Status` enum, e.g., `Promise.Status.Resolved`.
]=]
--[=[
	A Promise is an object that represents a value that will exist in the future, but doesn't right now.
	Promises allow you to then attach callbacks that can run once the value becomes available (known as *resolving*),
	or if an error has occurred (known as *rejecting*).

	@class Promise
	@__index prototype
]=]
local Promise = {
	Error = Error,
	Status = makeEnum("Promise.Status", { "Started", "Resolved", "Rejected", "Cancelled" }),
	_getTime = os.clock,
	_timeEvent = game:GetService("RunService").Heartbeat,
	_unhandledRejectionCallbacks = {},
}
Promise.prototype = {}
Promise.__index = Promise.prototype

function Promise._new(traceback, callback, parent)
	if parent ~= nil and not Promise.is(parent) then
		error("Argument #2 to Promise.new must be a promise or nil", 2)
	end

	local self = {
		-- Used to locate where a promise was created
		_source = traceback,

		_status = Promise.Status.Started,

		-- A table containing a list of all results, whether success or failure.
		-- Only valid if _status is set to something besides Started
		_values = nil,

		-- Lua doesn't like sparse arrays very much, so we explicitly store the
		-- length of _values to handle middle nils.
		_valuesLength = -1,

		-- Tracks if this Promise has no error observers..
		_unhandledRejection = true,

		-- Queues representing functions we should invoke when we update!
		_queuedResolve = {},
		_queuedReject = {},
		_queuedFinally = {},

		-- The function to run when/if this promise is cancelled.
		_cancellationHook = nil,

		-- The "parent" of this promise in a promise chain. Required for
		-- cancellation propagation upstream.
		_parent = parent,

		-- Consumers are Promises that have chained onto this one.
		-- We track them for cancellation propagation downstream.
		_consumers = setmetatable({}, MODE_KEY_METATABLE),
	}

	if parent and parent._status == Promise.Status.Started then
		parent._consumers[self] = true
	end

	setmetatable(self, Promise)

	local function resolve(...)
		self:_resolve(...)
	end

	local function reject(...)
		self:_reject(...)
	end

	local function onCancel(cancellationHook)
		if cancellationHook then
			if self._status == Promise.Status.Cancelled then
				cancellationHook()
			else
				self._cancellationHook = cancellationHook
			end
		end

		return self._status == Promise.Status.Cancelled
	end

	coroutine.wrap(function()
		local ok, _, result = runExecutor(self._source, callback, resolve, reject, onCancel)

		if not ok then
			reject(result[1])
		end
	end)()

	return self
end

--[=[
	Construct a new Promise that will be resolved or rejected with the given callbacks.

	If you `resolve` with a Promise, it will be chained onto.

	You can safely yield within the executor function and it will not block the creating thread.

	```lua
	local myFunction()
		return Promise.new(function(resolve, reject, onCancel)
			wait(1)
			resolve("Hello world!")
		end)
	end

	myFunction():andThen(print)
	```

	You do not need to use `pcall` within a Promise. Errors that occur during execution will be caught and turned into a rejection automatically. If `error()` is called with a table, that table will be the rejection value. Otherwise, string errors will be converted into `Promise.Error(Promise.Error.Kind.ExecutionError)` objects for tracking debug information.

	You may register an optional cancellation hook by using the `onCancel` argument:

	* This should be used to abort any ongoing operations leading up to the promise being settled.
	* Call the `onCancel` function with a function callback as its only argument to set a hook which will in turn be called when/if the promise is cancelled.
	* `onCancel` returns `true` if the Promise was already cancelled when you called `onCancel`.
	* Calling `onCancel` with no argument will not override a previously set cancellation hook, but it will still return `true` if the Promise is currently cancelled.
	* You can set the cancellation hook at any time before resolving.
	* When a promise is cancelled, calls to `resolve` or `reject` will be ignored, regardless of if you set a cancellation hook or not.

	@param executor (resolve: (...: any) -> (), reject: (...: any) -> (), onCancel: (abortHandler?: () -> ()) -> boolean) -> ()
	@return Promise
]=]
function Promise.new(executor)
	return Promise._new(debug.traceback(nil, 2), executor)
end

function Promise:__tostring()
	return string.format("Promise(%s)", self._status)
end

--[=[
	The same as [Promise.new](/api/Promise#new), except execution begins after the next `Heartbeat` event.

	This is a spiritual replacement for `spawn`, but it does not suffer from the same [issues](https://eryn.io/gist/3db84579866c099cdd5bb2ff37947cec) as `spawn`.

	```lua
	local function waitForChild(instance, childName, timeout)
	  return Promise.defer(function(resolve, reject)
		local child = instance:WaitForChild(childName, timeout)

		;(child and resolve or reject)(child)
	  end)
	end
	```

	@param executor (resolve: (...: any) -> (), reject: (...: any) -> (), onCancel: (abortHandler?: () -> ()) -> boolean) -> ()
	@return Promise
]=]
function Promise.defer(executor)
	local traceback = debug.traceback(nil, 2)
	local promise
	promise = Promise._new(traceback, function(resolve, reject, onCancel)
		local connection
		connection = Promise._timeEvent:Connect(function()
			connection:Disconnect()
			local ok, _, result = runExecutor(traceback, executor, resolve, reject, onCancel)

			if not ok then
				reject(result[1])
			end
		end)
	end)

	return promise
end

-- Backwards compatibility
Promise.async = Promise.defer

--[=[
	Creates an immediately resolved Promise with the given value.

	```lua
	-- Example using Promise.resolve to deliver cached values:
	function getSomething(name)
		if cache[name] then
			return Promise.resolve(cache[name])
		else
			return Promise.new(function(resolve, reject)
				local thing = getTheThing()
				cache[name] = thing

				resolve(thing)
			end)
		end
	end
	```

	@param ... any
	@return Promise<...any>
]=]
function Promise.resolve(...)
	local length, values = pack(...)
	return Promise._new(debug.traceback(nil, 2), function(resolve)
		resolve(unpack(values, 1, length))
	end)
end

--[=[
	Creates an immediately rejected Promise with the given value.

	:::caution
	Something needs to consume this rejection (i.e. `:catch()` it), otherwise it will emit an unhandled Promise rejection warning on the next frame. Thus, you should not create and store rejected Promises for later use. Only create them on-demand as needed.
	:::

	@param ... any
	@return Promise<...any>
]=]
function Promise.reject(...)
	local length, values = pack(...)
	return Promise._new(debug.traceback(nil, 2), function(_, reject)
		reject(unpack(values, 1, length))
	end)
end

--[[
	Runs a non-promise-returning function as a Promise with the
  given arguments.
]]
function Promise._try(traceback, callback, ...)
	local valuesLength, values = pack(...)

	return Promise._new(traceback, function(resolve)
		resolve(callback(unpack(values, 1, valuesLength)))
	end)
end

--[=[
	Begins a Promise chain, calling a function and returning a Promise resolving with its return value. If the function errors, the returned Promise will be rejected with the error. You can safely yield within the Promise.try callback.

	:::info
	`Promise.try` is similar to [Promise.promisify](#promisify), except the callback is invoked immediately instead of returning a new function.
	:::

	```lua
	Promise.try(function()
		return math.random(1, 2) == 1 and "ok" or error("Oh an error!")
	end)
		:andThen(function(text)
			print(text)
		end)
		:catch(function(err)
			warn("Something went wrong")
		end)
	```

	@param callback (...: T...) -> ...any
	@param ... T... -- Additional arguments passed to `callback`
	@return Promise
]=]
function Promise.try(callback, ...)
	return Promise._try(debug.traceback(nil, 2), callback, ...)
end

--[[
	Returns a new promise that:
		* is resolved when all input promises resolve
		* is rejected if ANY input promises reject
]]
function Promise._all(traceback, promises, amount)
	if type(promises) ~= "table" then
		error(string.format(ERROR_NON_LIST, "Promise.all"), 3)
	end

	-- We need to check that each value is a promise here so that we can produce
	-- a proper error rather than a rejected promise with our error.
	for i, promise in pairs(promises) do
		if not Promise.is(promise) then
			error(string.format(ERROR_NON_PROMISE_IN_LIST, "Promise.all", tostring(i)), 3)
		end
	end

	-- If there are no values then return an already resolved promise.
	if #promises == 0 or amount == 0 then
		return Promise.resolve({})
	end

	return Promise._new(traceback, function(resolve, reject, onCancel)
		-- An array to contain our resolved values from the given promises.
		local resolvedValues = {}
		local newPromises = {}

		-- Keep a count of resolved promises because just checking the resolved
		-- values length wouldn't account for promises that resolve with nil.
		local resolvedCount = 0
		local rejectedCount = 0
		local done = false

		local function cancel()
			for _, promise in ipairs(newPromises) do
				promise:cancel()
			end
		end

		-- Called when a single value is resolved and resolves if all are done.
		local function resolveOne(i, ...)
			if done then
				return
			end

			resolvedCount = resolvedCount + 1

			if amount == nil then
				resolvedValues[i] = ...
			else
				resolvedValues[resolvedCount] = ...
			end

			if resolvedCount >= (amount or #promises) then
				done = true
				resolve(resolvedValues)
				cancel()
			end
		end

		onCancel(cancel)

		-- We can assume the values inside `promises` are all promises since we
		-- checked above.
		for i, promise in ipairs(promises) do
			newPromises[i] = promise:andThen(function(...)
				resolveOne(i, ...)
			end, function(...)
				rejectedCount = rejectedCount + 1

				if amount == nil or #promises - rejectedCount < amount then
					cancel()
					done = true

					reject(...)
				end
			end)
		end

		if done then
			cancel()
		end
	end)
end

--[=[
	Accepts an array of Promises and returns a new promise that:
	* is resolved after all input promises resolve.
	* is rejected if *any* input promises reject.

	:::info
	Only the first return value from each promise will be present in the resulting array.
	:::

	After any input Promise rejects, all other input Promises that are still pending will be cancelled if they have no other consumers.

	```lua
	local promises = {
		returnsAPromise("example 1"),
		returnsAPromise("example 2"),
		returnsAPromise("example 3"),
	}

	return Promise.all(promises)
	```

	@param promises {Promise<T>}
	@return Promise<{T}>
]=]
function Promise.all(promises)
	return Promise._all(debug.traceback(nil, 2), promises)
end

--[=[
	Folds an array of values or promises into a single value. The array is traversed sequentially.

	The reducer function can return a promise or value directly. Each iteration receives the resolved value from the previous, and the first receives your defined initial value.

	The folding will stop at the first rejection encountered.
	```lua
	local basket = {"blueberry", "melon", "pear", "melon"}
	Promise.fold(basket, function(cost, fruit)
		if fruit == "blueberry" then
			return cost -- blueberries are free!
		else
			-- call a function that returns a promise with the fruit price
			return fetchPrice(fruit):andThen(function(fruitCost)
				return cost + fruitCost
			end)
		end
	end, 0)
	```

	@since v3.1.0
	@param list {T | Promise<T>}
	@param reducer (accumulator: U, value: T, index: number) -> U | Promise<U>
	@param initialValue U
]=]
function Promise.fold(list, reducer, initialValue)
	assert(type(list) == "table", "Bad argument #1 to Promise.fold: must be a table")
	assert(isCallable(reducer), "Bad argument #2 to Promise.fold: must be a function")

	local accumulator = Promise.resolve(initialValue)
	return Promise.each(list, function(resolvedElement, i)
		accumulator = accumulator:andThen(function(previousValueResolved)
			return reducer(previousValueResolved, resolvedElement, i)
		end)
	end):andThen(function()
		return accumulator
	end)
end

--[=[
	Accepts an array of Promises and returns a Promise that is resolved as soon as `count` Promises are resolved from the input array. The resolved array values are in the order that the Promises resolved in. When this Promise resolves, all other pending Promises are cancelled if they have no other consumers.

	`count` 0 results in an empty array. The resultant array will never have more than `count` elements.

	```lua
	local promises = {
		returnsAPromise("example 1"),
		returnsAPromise("example 2"),
		returnsAPromise("example 3"),
	}

	return Promise.some(promises, 2) -- Only resolves with first 2 promises to resolve
	```

	@param promises {Promise<T>}
	@param count number
	@return Promise<{T}>
]=]
function Promise.some(promises, count)
	assert(type(count) == "number", "Bad argument #2 to Promise.some: must be a number")

	return Promise._all(debug.traceback(nil, 2), promises, count)
end

--[=[
	Accepts an array of Promises and returns a Promise that is resolved as soon as *any* of the input Promises resolves. It will reject only if *all* input Promises reject. As soon as one Promises resolves, all other pending Promises are cancelled if they have no other consumers.

	Resolves directly with the value of the first resolved Promise. This is essentially [[Promise.some]] with `1` count, except the Promise resolves with the value directly instead of an array with one element.

	```lua
	local promises = {
		returnsAPromise("example 1"),
		returnsAPromise("example 2"),
		returnsAPromise("example 3"),
	}

	return Promise.any(promises) -- Resolves with first value to resolve (only rejects if all 3 rejected)
	```

	@param promises {Promise<T>}
	@return Promise<T>
]=]
function Promise.any(promises)
	return Promise._all(debug.traceback(nil, 2), promises, 1):andThen(function(values)
		return values[1]
	end)
end

--[=[
	Accepts an array of Promises and returns a new Promise that resolves with an array of in-place Statuses when all input Promises have settled. This is equivalent to mapping `promise:finally` over the array of Promises.

	```lua
	local promises = {
		returnsAPromise("example 1"),
		returnsAPromise("example 2"),
		returnsAPromise("example 3"),
	}

	return Promise.allSettled(promises)
	```

	@param promises {Promise<T>}
	@return Promise<{Status}>
]=]
function Promise.allSettled(promises)
	if type(promises) ~= "table" then
		error(string.format(ERROR_NON_LIST, "Promise.allSettled"), 2)
	end

	-- We need to check that each value is a promise here so that we can produce
	-- a proper error rather than a rejected promise with our error.
	for i, promise in pairs(promises) do
		if not Promise.is(promise) then
			error(string.format(ERROR_NON_PROMISE_IN_LIST, "Promise.allSettled", tostring(i)), 2)
		end
	end

	-- If there are no values then return an already resolved promise.
	if #promises == 0 then
		return Promise.resolve({})
	end

	return Promise._new(debug.traceback(nil, 2), function(resolve, _, onCancel)
		-- An array to contain our resolved values from the given promises.
		local fates = {}
		local newPromises = {}

		-- Keep a count of resolved promises because just checking the resolved
		-- values length wouldn't account for promises that resolve with nil.
		local finishedCount = 0

		-- Called when a single value is resolved and resolves if all are done.
		local function resolveOne(i, ...)
			finishedCount = finishedCount + 1

			fates[i] = ...

			if finishedCount >= #promises then
				resolve(fates)
			end
		end

		onCancel(function()
			for _, promise in ipairs(newPromises) do
				promise:cancel()
			end
		end)

		-- We can assume the values inside `promises` are all promises since we
		-- checked above.
		for i, promise in ipairs(promises) do
			newPromises[i] = promise:finally(function(...)
				resolveOne(i, ...)
			end)
		end
	end)
end

--[=[
	Accepts an array of Promises and returns a new promise that is resolved or rejected as soon as any Promise in the array resolves or rejects.

	:::warning
	If the first Promise to settle from the array settles with a rejection, the resulting Promise from `race` will reject.

	If you instead want to tolerate rejections, and only care about at least one Promise resolving, you should use [Promise.any](#any) or [Promise.some](#some) instead.
	:::

	All other Promises that don't win the race will be cancelled if they have no other consumers.

	```lua
	local promises = {
		returnsAPromise("example 1"),
		returnsAPromise("example 2"),
		returnsAPromise("example 3"),
	}

	return Promise.race(promises) -- Only returns 1st value to resolve or reject
	```

	@param promises {Promise<T>}
	@return Promise<T>
]=]
function Promise.race(promises)
	assert(type(promises) == "table", string.format(ERROR_NON_LIST, "Promise.race"))

	for i, promise in pairs(promises) do
		assert(Promise.is(promise), string.format(ERROR_NON_PROMISE_IN_LIST, "Promise.race", tostring(i)))
	end

	return Promise._new(debug.traceback(nil, 2), function(resolve, reject, onCancel)
		local newPromises = {}
		local finished = false

		local function cancel()
			for _, promise in ipairs(newPromises) do
				promise:cancel()
			end
		end

		local function finalize(callback)
			return function(...)
				cancel()
				finished = true
				return callback(...)
			end
		end

		if onCancel(finalize(reject)) then
			return
		end

		for i, promise in ipairs(promises) do
			newPromises[i] = promise:andThen(finalize(resolve), finalize(reject))
		end

		if finished then
			cancel()
		end
	end)
end

--[=[
	Iterates serially over the given an array of values, calling the predicate callback on each value before continuing.

	If the predicate returns a Promise, we wait for that Promise to resolve before moving on to the next item
	in the array.

	:::info
	`Promise.each` is similar to `Promise.all`, except the Promises are ran in order instead of all at once.

	But because Promises are eager, by the time they are created, they're already running. Thus, we need a way to defer creation of each Promise until a later time.

	The predicate function exists as a way for us to operate on our data instead of creating a new closure for each Promise. If you would prefer, you can pass in an array of functions, and in the predicate, call the function and return its return value.
	:::

	```lua
	Promise.each({
		"foo",
		"bar",
		"baz",
		"qux"
	}, function(value, index)
		return Promise.delay(1):andThen(function()
		print(("%d) Got %s!"):format(index, value))
		end)
	end)

	--[[
		(1 second passes)
		> 1) Got foo!
		(1 second passes)
		> 2) Got bar!
		(1 second passes)
		> 3) Got baz!
		(1 second passes)
		> 4) Got qux!
	]]
	```

	If the Promise a predicate returns rejects, the Promise from `Promise.each` is also rejected with the same value.

	If the array of values contains a Promise, when we get to that point in the list, we wait for the Promise to resolve before calling the predicate with the value.

	If a Promise in the array of values is already Rejected when `Promise.each` is called, `Promise.each` rejects with that value immediately (the predicate callback will never be called even once). If a Promise in the list is already Cancelled when `Promise.each` is called, `Promise.each` rejects with `Promise.Error(Promise.Error.Kind.AlreadyCancelled`). If a Promise in the array of values is Started at first, but later rejects, `Promise.each` will reject with that value and iteration will not continue once iteration encounters that value.

	Returns a Promise containing an array of the returned/resolved values from the predicate for each item in the array of values.

	If this Promise returned from `Promise.each` rejects or is cancelled for any reason, the following are true:
	- Iteration will not continue.
	- Any Promises within the array of values will now be cancelled if they have no other consumers.
	- The Promise returned from the currently active predicate will be cancelled if it hasn't resolved yet.

	@since 3.0.0
	@param list {T | Promise<T>}
	@param predicate (value: T, index: number) -> U | Promise<U>
	@return Promise<{U}>
]=]
function Promise.each(list, predicate)
	assert(type(list) == "table", string.format(ERROR_NON_LIST, "Promise.each"))
	assert(isCallable(predicate), string.format(ERROR_NON_FUNCTION, "Promise.each"))

	return Promise._new(debug.traceback(nil, 2), function(resolve, reject, onCancel)
		local results = {}
		local promisesToCancel = {}

		local cancelled = false

		local function cancel()
			for _, promiseToCancel in ipairs(promisesToCancel) do
				promiseToCancel:cancel()
			end
		end

		onCancel(function()
			cancelled = true

			cancel()
		end)

		-- We need to preprocess the list of values and look for Promises.
		-- If we find some, we must register our andThen calls now, so that those Promises have a consumer
		-- from us registered. If we don't do this, those Promises might get cancelled by something else
		-- before we get to them in the series because it's not possible to tell that we plan to use it
		-- unless we indicate it here.

		local preprocessedList = {}

		for index, value in ipairs(list) do
			if Promise.is(value) then
				if value:getStatus() == Promise.Status.Cancelled then
					cancel()
					return reject(Error.new({
						error = "Promise is cancelled",
						kind = Error.Kind.AlreadyCancelled,
						context = string.format(
							"The Promise that was part of the array at index %d passed into Promise.each was already cancelled when Promise.each began.\n\nThat Promise was created at:\n\n%s",
							index,
							value._source
						),
					}))
				elseif value:getStatus() == Promise.Status.Rejected then
					cancel()
					return reject(select(2, value:await()))
				end

				-- Chain a new Promise from this one so we only cancel ours
				local ourPromise = value:andThen(function(...)
					return ...
				end)

				table.insert(promisesToCancel, ourPromise)
				preprocessedList[index] = ourPromise
			else
				preprocessedList[index] = value
			end
		end

		for index, value in ipairs(preprocessedList) do
			if Promise.is(value) then
				local success
				success, value = value:await()

				if not success then
					cancel()
					return reject(value)
				end
			end

			if cancelled then
				return
			end

			local predicatePromise = Promise.resolve(predicate(value, index))

			table.insert(promisesToCancel, predicatePromise)

			local success, result = predicatePromise:await()

			if not success then
				cancel()
				return reject(result)
			end

			results[index] = result
		end

		resolve(results)
	end)
end

--[=[
	Checks whether the given object is a Promise via duck typing. This only checks if the object is a table and has an `andThen` method.

	@param object any
	@return boolean -- `true` if the given `object` is a Promise.
]=]
function Promise.is(object)
	if type(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	if objectMetatable == Promise then
		-- The Promise came from this library.
		return true
	elseif objectMetatable == nil then
		-- No metatable, but we should still chain onto tables with andThen methods
		return isCallable(object.andThen)
	elseif
		type(objectMetatable) == "table"
		and type(rawget(objectMetatable, "__index")) == "table"
		and isCallable(rawget(rawget(objectMetatable, "__index"), "andThen"))
	then
		-- Maybe this came from a different or older Promise library.
		return true
	end

	return false
end

--[=[
	Wraps a function that yields into one that returns a Promise.

	Any errors that occur while executing the function will be turned into rejections.

	:::info
	`Promise.promisify` is similar to [Promise.try](#try), except the callback is returned as a callable function instead of being invoked immediately.
	:::

	```lua
	local sleep = Promise.promisify(wait)

	sleep(1):andThen(print)
	```

	```lua
	local isPlayerInGroup = Promise.promisify(function(player, groupId)
		return player:IsInGroup(groupId)
	end)
	```

	@param callback (...: any) -> ...any
	@return (...: any) -> Promise
]=]
function Promise.promisify(callback)
	return function(...)
		return Promise._try(debug.traceback(nil, 2), callback, ...)
	end
end

--[=[
	Returns a Promise that resolves after `seconds` seconds have passed. The Promise resolves with the actual amount of time that was waited.

	This function is **not** a wrapper around `wait`. `Promise.delay` uses a custom scheduler which provides more accurate timing. As an optimization, cancelling this Promise instantly removes the task from the scheduler.

	:::warning
	Passing `NaN`, infinity, or a number less than 1/60 is equivalent to passing 1/60.
	:::

	```lua
		Promise.delay(5):andThenCall(print, "This prints after 5 seconds")
	```

	@function delay
	@within Promise
	@param seconds number
	@return Promise<number>
]=]
do
	-- uses a sorted doubly linked list (queue) to achieve O(1) remove operations and O(n) for insert

	-- the initial node in the linked list
	local first
	local connection

	function Promise.delay(seconds)
		assert(type(seconds) == "number", "Bad argument #1 to Promise.delay, must be a number.")
		-- If seconds is -INF, INF, NaN, or less than 1 / 60, assume seconds is 1 / 60.
		-- This mirrors the behavior of wait()
		if not (seconds >= 1 / 60) or seconds == math.huge then
			seconds = 1 / 60
		end

		return Promise._new(debug.traceback(nil, 2), function(resolve, _, onCancel)
			local startTime = Promise._getTime()
			local endTime = startTime + seconds

			local node = {
				resolve = resolve,
				startTime = startTime,
				endTime = endTime,
			}

			if connection == nil then -- first is nil when connection is nil
				first = node
				connection = Promise._timeEvent:Connect(function()
					local threadStart = Promise._getTime()

					while first ~= nil and first.endTime < threadStart do
						local current = first
						first = current.next

						if first == nil then
							connection:Disconnect()
							connection = nil
						else
							first.previous = nil
						end

						current.resolve(Promise._getTime() - current.startTime)
					end
				end)
			else -- first is non-nil
				if first.endTime < endTime then -- if `node` should be placed after `first`
					-- we will insert `node` between `current` and `next`
					-- (i.e. after `current` if `next` is nil)
					local current = first
					local next = current.next

					while next ~= nil and next.endTime < endTime do
						current = next
						next = current.next
					end

					-- `current` must be non-nil, but `next` could be `nil` (i.e. last item in list)
					current.next = node
					node.previous = current

					if next ~= nil then
						node.next = next
						next.previous = node
					end
				else
					-- set `node` to `first`
					node.next = first
					first.previous = node
					first = node
				end
			end

			onCancel(function()
				-- remove node from queue
				local next = node.next

				if first == node then
					if next == nil then -- if `node` is the first and last
						connection:Disconnect()
						connection = nil
					else -- if `node` is `first` and not the last
						next.previous = nil
					end
					first = next
				else
					local previous = node.previous
					-- since `node` is not `first`, then we know `previous` is non-nil
					previous.next = next

					if next ~= nil then
						next.previous = previous
					end
				end
			end)
		end)
	end
end

--[=[
	Returns a new Promise that resolves if the chained Promise resolves within `seconds` seconds, or rejects if execution time exceeds `seconds`. The chained Promise will be cancelled if the timeout is reached.

	Rejects with `rejectionValue` if it is non-nil. If a `rejectionValue` is not given, it will reject with a `Promise.Error(Promise.Error.Kind.TimedOut)`. This can be checked with [[Error.isKind]].

	```lua
	getSomething():timeout(5):andThen(function(something)
		-- got something and it only took at max 5 seconds
	end):catch(function(e)
		-- Either getting something failed or the time was exceeded.

		if Promise.Error.isKind(e, Promise.Error.Kind.TimedOut) then
			warn("Operation timed out!")
		else
			warn("Operation encountered an error!")
		end
	end)
	```

	Sugar for:

	```lua
	Promise.race({
		Promise.delay(seconds):andThen(function()
			return Promise.reject(
				rejectionValue == nil
				and Promise.Error.new({ kind = Promise.Error.Kind.TimedOut })
				or rejectionValue
			)
		end),
		promise
	})
	```

	@param seconds number
	@param rejectionValue? any -- The value to reject with if the timeout is reached
	@return Promise
]=]
function Promise.prototype:timeout(seconds, rejectionValue)
	local traceback = debug.traceback(nil, 2)

	return Promise.race({
		Promise.delay(seconds):andThen(function()
			return Promise.reject(rejectionValue == nil and Error.new({
				kind = Error.Kind.TimedOut,
				error = "Timed out",
				context = string.format(
					"Timeout of %d seconds exceeded.\n:timeout() called at:\n\n%s",
					seconds,
					traceback
				),
			}) or rejectionValue)
		end),
		self,
	})
end

--[=[
	Returns the current Promise status.

	@return Status
]=]
function Promise.prototype:getStatus()
	return self._status
end

--[[
	Creates a new promise that receives the result of this promise.

	The given callbacks are invoked depending on that result.
]]
function Promise.prototype:_andThen(traceback, successHandler, failureHandler)
	self._unhandledRejection = false

	-- Create a new promise to follow this part of the chain
	return Promise._new(traceback, function(resolve, reject)
		-- Our default callbacks just pass values onto the next promise.
		-- This lets success and failure cascade correctly!

		local successCallback = resolve
		if successHandler then
			successCallback = createAdvancer(traceback, successHandler, resolve, reject)
		end

		local failureCallback = reject
		if failureHandler then
			failureCallback = createAdvancer(traceback, failureHandler, resolve, reject)
		end

		if self._status == Promise.Status.Started then
			-- If we haven't resolved yet, put ourselves into the queue
			table.insert(self._queuedResolve, successCallback)
			table.insert(self._queuedReject, failureCallback)
		elseif self._status == Promise.Status.Resolved then
			-- This promise has already resolved! Trigger success immediately.
			successCallback(unpack(self._values, 1, self._valuesLength))
		elseif self._status == Promise.Status.Rejected then
			-- This promise died a terrible death! Trigger failure immediately.
			failureCallback(unpack(self._values, 1, self._valuesLength))
		elseif self._status == Promise.Status.Cancelled then
			-- We don't want to call the success handler or the failure handler,
			-- we just reject this promise outright.
			reject(Error.new({
				error = "Promise is cancelled",
				kind = Error.Kind.AlreadyCancelled,
				context = "Promise created at\n\n" .. traceback,
			}))
		end
	end, self)
end

--[=[
	Chains onto an existing Promise and returns a new Promise.

	:::warning
	Within the failure handler, you should never assume that the rejection value is a string. Some rejections within the Promise library are represented by [[Error]] objects. If you want to treat it as a string for debugging, you should call `tostring` on it first.
	:::

	Return a Promise from the success or failure handler and it will be chained onto.

	@param successHandler (...: any) -> ...any
	@param failureHandler? (...: any) -> ...any
	@return Promise<...any>
]=]
function Promise.prototype:andThen(successHandler, failureHandler)
	assert(successHandler == nil or isCallable(successHandler), string.format(ERROR_NON_FUNCTION, "Promise:andThen"))
	assert(failureHandler == nil or isCallable(failureHandler), string.format(ERROR_NON_FUNCTION, "Promise:andThen"))

	return self:_andThen(debug.traceback(nil, 2), successHandler, failureHandler)
end

--[=[
	Shorthand for `Promise:andThen(nil, failureHandler)`.

	Returns a Promise that resolves if the `failureHandler` worked without encountering an additional error.

	:::warning
	Within the failure handler, you should never assume that the rejection value is a string. Some rejections within the Promise library are represented by [[Error]] objects. If you want to treat it as a string for debugging, you should call `tostring` on it first.
	:::


	@param failureHandler (...: any) -> ...any
	@return Promise<...any>
]=]
function Promise.prototype:catch(failureHandler)
	assert(failureHandler == nil or isCallable(failureHandler), string.format(ERROR_NON_FUNCTION, "Promise:catch"))
	return self:_andThen(debug.traceback(nil, 2), nil, failureHandler)
end

--[=[
	Similar to [Promise.andThen](#andThen), except the return value is the same as the value passed to the handler. In other words, you can insert a `:tap` into a Promise chain without affecting the value that downstream Promises receive.

	```lua
		getTheValue()
		:tap(print)
		:andThen(function(theValue)
			print("Got", theValue, "even though print returns nil!")
		end)
	```

	If you return a Promise from the tap handler callback, its value will be discarded but `tap` will still wait until it resolves before passing the original value through.

	@param tapHandler (...: any) -> ...any
	@return Promise<...any>
]=]
function Promise.prototype:tap(tapHandler)
	assert(isCallable(tapHandler), string.format(ERROR_NON_FUNCTION, "Promise:tap"))
	return self:_andThen(debug.traceback(nil, 2), function(...)
		local callbackReturn = tapHandler(...)

		if Promise.is(callbackReturn) then
			local length, values = pack(...)
			return callbackReturn:andThen(function()
				return unpack(values, 1, length)
			end)
		end

		return ...
	end)
end

--[=[
	Attaches an `andThen` handler to this Promise that calls the given callback with the predefined arguments. The resolved value is discarded.

	```lua
		promise:andThenCall(someFunction, "some", "arguments")
	```

	This is sugar for

	```lua
		promise:andThen(function()
		return someFunction("some", "arguments")
		end)
	```

	@param callback (...: any) -> any
	@param ...? any -- Additional arguments which will be passed to `callback`
	@return Promise
]=]
function Promise.prototype:andThenCall(callback, ...)
	assert(isCallable(callback), string.format(ERROR_NON_FUNCTION, "Promise:andThenCall"))
	local length, values = pack(...)
	return self:_andThen(debug.traceback(nil, 2), function()
		return callback(unpack(values, 1, length))
	end)
end

--[=[
	Attaches an `andThen` handler to this Promise that discards the resolved value and returns the given value from it.

	```lua
		promise:andThenReturn("some", "values")
	```

	This is sugar for

	```lua
		promise:andThen(function()
			return "some", "values"
		end)
	```

	:::caution
	Promises are eager, so if you pass a Promise to `andThenReturn`, it will begin executing before `andThenReturn` is reached in the chain. Likewise, if you pass a Promise created from [[Promise.reject]] into `andThenReturn`, it's possible that this will trigger the unhandled rejection warning. If you need to return a Promise, it's usually best practice to use [[Promise.andThen]].
	:::

	@param ... any -- Values to return from the function
	@return Promise
]=]
function Promise.prototype:andThenReturn(...)
	local length, values = pack(...)
	return self:_andThen(debug.traceback(nil, 2), function()
		return unpack(values, 1, length)
	end)
end

--[=[
	Cancels this promise, preventing the promise from resolving or rejecting. Does not do anything if the promise is already settled.

	Cancellations will propagate upwards and downwards through chained promises.

	Promises will only be cancelled if all of their consumers are also cancelled. This is to say that if you call `andThen` twice on the same promise, and you cancel only one of the child promises, it will not cancel the parent promise until the other child promise is also cancelled.

	```lua
		promise:cancel()
	```
]=]
function Promise.prototype:cancel()
	if self._status ~= Promise.Status.Started then
		return
	end

	self._status = Promise.Status.Cancelled

	if self._cancellationHook then
		self._cancellationHook()
	end

	if self._parent then
		self._parent:_consumerCancelled(self)
	end

	for child in pairs(self._consumers) do
		child:cancel()
	end

	self:_finalize()
end

--[[
	Used to decrease the number of consumers by 1, and if there are no more,
	cancel this promise.
]]
function Promise.prototype:_consumerCancelled(consumer)
	if self._status ~= Promise.Status.Started then
		return
	end

	self._consumers[consumer] = nil

	if next(self._consumers) == nil then
		self:cancel()
	end
end

--[[
	Used to set a handler for when the promise resolves, rejects, or is
	cancelled. Returns a new promise chained from this promise.
]]
function Promise.prototype:_finally(traceback, finallyHandler, onlyOk)
	if not onlyOk then
		self._unhandledRejection = false
	end

	-- Return a promise chained off of this promise
	return Promise._new(traceback, function(resolve, reject)
		local finallyCallback = resolve
		if finallyHandler then
			finallyCallback = createAdvancer(traceback, finallyHandler, resolve, reject)
		end

		if onlyOk then
			local callback = finallyCallback
			finallyCallback = function(...)
				if self._status == Promise.Status.Rejected then
					return resolve(self)
				end

				return callback(...)
			end
		end

		if self._status == Promise.Status.Started then
			-- The promise is not settled, so queue this.
			table.insert(self._queuedFinally, finallyCallback)
		else
			-- The promise already settled or was cancelled, run the callback now.
			finallyCallback(self._status)
		end
	end, self)
end

--[=[
	Set a handler that will be called regardless of the promise's fate. The handler is called when the promise is resolved, rejected, *or* cancelled.

	Returns a new promise chained from this promise.

	:::caution
	If the Promise is cancelled, any Promises chained off of it with `andThen` won't run. Only Promises chained with `finally` or `done` will run in the case of cancellation.
	:::

	```lua
	local thing = createSomething()

	doSomethingWith(thing)
		:andThen(function()
			print("It worked!")
			-- do something..
		end)
		:catch(function()
			warn("Oh no it failed!")
		end)
		:finally(function()
			-- either way, destroy thing

			thing:Destroy()
		end)

	```

	@param finallyHandler (status: Status) -> ...any
	@return Promise<...any>
]=]
function Promise.prototype:finally(finallyHandler)
	assert(finallyHandler == nil or isCallable(finallyHandler), string.format(ERROR_NON_FUNCTION, "Promise:finally"))
	return self:_finally(debug.traceback(nil, 2), finallyHandler)
end

--[=[
	Same as `andThenCall`, except for `finally`.

	Attaches a `finally` handler to this Promise that calls the given callback with the predefined arguments.

	@param callback (...: any) -> any
	@param ...? any -- Additional arguments which will be passed to `callback`
	@return Promise
]=]
function Promise.prototype:finallyCall(callback, ...)
	assert(isCallable(callback), string.format(ERROR_NON_FUNCTION, "Promise:finallyCall"))
	local length, values = pack(...)
	return self:_finally(debug.traceback(nil, 2), function()
		return callback(unpack(values, 1, length))
	end)
end

--[=[
	Attaches a `finally` handler to this Promise that discards the resolved value and returns the given value from it.

	```lua
		promise:finallyReturn("some", "values")
	```

	This is sugar for

	```lua
		promise:finally(function()
			return "some", "values"
		end)
	```

	@param ... any -- Values to return from the function
	@return Promise
]=]
function Promise.prototype:finallyReturn(...)
	local length, values = pack(...)
	return self:_finally(debug.traceback(nil, 2), function()
		return unpack(values, 1, length)
	end)
end

--[=[
	Set a handler that will be called only if the Promise resolves or is cancelled. This method is similar to `finally`, except it doesn't catch rejections.

	:::caution
	`done` should be reserved specifically when you want to perform some operation after the Promise is finished (like `finally`), but you don't want to consume rejections (like in <a href="/roblox-lua-promise/lib/Examples.html#cancellable-animation-sequence">this example</a>). You should use `andThen` instead if you only care about the Resolved case.
	:::

	:::warning
	Like `finally`, if the Promise is cancelled, any Promises chained off of it with `andThen` won't run. Only Promises chained with `done` and `finally` will run in the case of cancellation.
	:::

	Returns a new promise chained from this promise.

	@param doneHandler (status: Status) -> ...any
	@return Promise<...any>
]=]
function Promise.prototype:done(doneHandler)
	assert(doneHandler == nil or isCallable(doneHandler), string.format(ERROR_NON_FUNCTION, "Promise:done"))
	return self:_finally(debug.traceback(nil, 2), doneHandler, true)
end

--[=[
	Same as `andThenCall`, except for `done`.

	Attaches a `done` handler to this Promise that calls the given callback with the predefined arguments.

	@param callback (...: any) -> any
	@param ...? any -- Additional arguments which will be passed to `callback`
	@return Promise
]=]
function Promise.prototype:doneCall(callback, ...)
	assert(isCallable(callback), string.format(ERROR_NON_FUNCTION, "Promise:doneCall"))
	local length, values = pack(...)
	return self:_finally(debug.traceback(nil, 2), function()
		return callback(unpack(values, 1, length))
	end, true)
end

--[=[
	Attaches a `done` handler to this Promise that discards the resolved value and returns the given value from it.

	```lua
		promise:doneReturn("some", "values")
	```

	This is sugar for

	```lua
		promise:done(function()
			return "some", "values"
		end)
	```

	@param ... any -- Values to return from the function
	@return Promise
]=]
function Promise.prototype:doneReturn(...)
	local length, values = pack(...)
	return self:_finally(debug.traceback(nil, 2), function()
		return unpack(values, 1, length)
	end, true)
end

--[=[
	Yields the current thread until the given Promise completes. Returns the Promise's status, followed by the values that the promise resolved or rejected with.

	@yields
	@return Status -- The Status representing the fate of the Promise
	@return ...any -- The values the Promise resolved or rejected with.
]=]
function Promise.prototype:awaitStatus()
	self._unhandledRejection = false

	if self._status == Promise.Status.Started then
		local bindable = Instance.new("BindableEvent")

		self:finally(function()
			bindable:Fire()
		end)

		bindable.Event:Wait()
		bindable:Destroy()
	end

	if self._status == Promise.Status.Resolved then
		return self._status, unpack(self._values, 1, self._valuesLength)
	elseif self._status == Promise.Status.Rejected then
		return self._status, unpack(self._values, 1, self._valuesLength)
	end

	return self._status
end

local function awaitHelper(status, ...)
	return status == Promise.Status.Resolved, ...
end

--[=[
	Yields the current thread until the given Promise completes. Returns true if the Promise resolved, followed by the values that the promise resolved or rejected with.

	:::caution
	If the Promise gets cancelled, this function will return `false`, which is indistinguishable from a rejection. If you need to differentiate, you should use [[Promise.awaitStatus]] instead.
	:::

	```lua
		local worked, value = getTheValue():await()

	if worked then
		print("got", value)
	else
		warn("it failed")
	end
	```

	@yields
	@return boolean -- `true` if the Promise successfully resolved
	@return ...any -- The values the Promise resolved or rejected with.
]=]
function Promise.prototype:await()
	return awaitHelper(self:awaitStatus())
end

local function expectHelper(status, ...)
	if status ~= Promise.Status.Resolved then
		error((...) == nil and "Expected Promise rejected with no value." or (...), 3)
	end

	return ...
end

--[=[
	Yields the current thread until the given Promise completes. Returns the values that the promise resolved with.

	```lua
	local worked = pcall(function()
		print("got", getTheValue():expect())
	end)

	if not worked then
		warn("it failed")
	end
	```

	This is essentially sugar for:

	```lua
	select(2, assert(promise:await()))
	```

	**Errors** if the Promise rejects or gets cancelled.

	@error any -- Errors with the rejection value if this Promise rejects or gets cancelled.
	@yields
	@return ...any -- The values the Promise resolved with.
]=]
function Promise.prototype:expect()
	return expectHelper(self:awaitStatus())
end

-- Backwards compatibility
Promise.prototype.awaitValue = Promise.prototype.expect

--[[
	Intended for use in tests.

	Similar to await(), but instead of yielding if the promise is unresolved,
	_unwrap will throw. This indicates an assumption that a promise has
	resolved.
]]
function Promise.prototype:_unwrap()
	if self._status == Promise.Status.Started then
		error("Promise has not resolved or rejected.", 2)
	end

	local success = self._status == Promise.Status.Resolved

	return success, unpack(self._values, 1, self._valuesLength)
end

function Promise.prototype:_resolve(...)
	if self._status ~= Promise.Status.Started then
		if Promise.is((...)) then
			(...):_consumerCancelled(self)
		end
		return
	end

	-- If the resolved value was a Promise, we chain onto it!
	if Promise.is((...)) then
		-- Without this warning, arguments sometimes mysteriously disappear
		if select("#", ...) > 1 then
			local message = string.format(
				"When returning a Promise from andThen, extra arguments are " .. "discarded! See:\n\n%s",
				self._source
			)
			warn(message)
		end

		local chainedPromise = ...

		local promise = chainedPromise:andThen(function(...)
			self:_resolve(...)
		end, function(...)
			local maybeRuntimeError = chainedPromise._values[1]

			-- Backwards compatibility < v2
			if chainedPromise._error then
				maybeRuntimeError = Error.new({
					error = chainedPromise._error,
					kind = Error.Kind.ExecutionError,
					context = "[No stack trace available as this Promise originated from an older version of the Promise library (< v2)]",
				})
			end

			if Error.isKind(maybeRuntimeError, Error.Kind.ExecutionError) then
				return self:_reject(maybeRuntimeError:extend({
					error = "This Promise was chained to a Promise that errored.",
					trace = "",
					context = string.format(
						"The Promise at:\n\n%s\n...Rejected because it was chained to the following Promise, which encountered an error:\n",
						self._source
					),
				}))
			end

			self:_reject(...)
		end)

		if promise._status == Promise.Status.Cancelled then
			self:cancel()
		elseif promise._status == Promise.Status.Started then
			-- Adopt ourselves into promise for cancellation propagation.
			self._parent = promise
			promise._consumers[self] = true
		end

		return
	end

	self._status = Promise.Status.Resolved
	self._valuesLength, self._values = pack(...)

	-- We assume that these callbacks will not throw errors.
	for _, callback in ipairs(self._queuedResolve) do
		coroutine.wrap(callback)(...)
	end

	self:_finalize()
end

function Promise.prototype:_reject(...)
	if self._status ~= Promise.Status.Started then
		return
	end

	self._status = Promise.Status.Rejected
	self._valuesLength, self._values = pack(...)

	-- If there are any rejection handlers, call those!
	if not isEmpty(self._queuedReject) then
		-- We assume that these callbacks will not throw errors.
		for _, callback in ipairs(self._queuedReject) do
			coroutine.wrap(callback)(...)
		end
	else
		-- At this point, no one was able to observe the error.
		-- An error handler might still be attached if the error occurred
		-- synchronously. We'll wait one tick, and if there are still no
		-- observers, then we should put a message in the console.

		local err = tostring((...))

		coroutine.wrap(function()
			Promise._timeEvent:Wait()

			-- Someone observed the error, hooray!
			if not self._unhandledRejection then
				return
			end

			-- Build a reasonable message
			local message = string.format("Unhandled Promise rejection:\n\n%s\n\n%s", err, self._source)

			for _, callback in ipairs(Promise._unhandledRejectionCallbacks) do
				task.spawn(callback, self, unpack(self._values, 1, self._valuesLength))
			end

			if Promise.TEST then
				-- Don't spam output when we're running tests.
				return
			end

			warn(message)
		end)()
	end

	self:_finalize()
end

--[[
	Calls any :finally handlers. We need this to be a separate method and
	queue because we must call all of the finally callbacks upon a success,
	failure, *and* cancellation.
]]
function Promise.prototype:_finalize()
	for _, callback in ipairs(self._queuedFinally) do
		-- Purposefully not passing values to callbacks here, as it could be the
		-- resolved values, or rejected errors. If the developer needs the values,
		-- they should use :andThen or :catch explicitly.
		coroutine.wrap(callback)(self._status)
	end

	self._queuedFinally = nil
	self._queuedReject = nil
	self._queuedResolve = nil

	-- Clear references to other Promises to allow gc
	if not Promise.TEST then
		self._parent = nil
		self._consumers = nil
	end
end

--[=[
	Chains a Promise from this one that is resolved if this Promise is already resolved, and rejected if it is not resolved at the time of calling `:now()`. This can be used to ensure your `andThen` handler occurs on the same frame as the root Promise execution.

	```lua
	doSomething()
		:now()
		:andThen(function(value)
			print("Got", value, "synchronously.")
		end)
	```

	If this Promise is still running, Rejected, or Cancelled, the Promise returned from `:now()` will reject with the `rejectionValue` if passed, otherwise with a `Promise.Error(Promise.Error.Kind.NotResolvedInTime)`. This can be checked with [[Error.isKind]].

	@param rejectionValue? any -- The value to reject with if the Promise isn't resolved
	@return Promise
]=]
function Promise.prototype:now(rejectionValue)
	local traceback = debug.traceback(nil, 2)
	if self._status == Promise.Status.Resolved then
		return self:_andThen(traceback, function(...)
			return ...
		end)
	else
		return Promise.reject(rejectionValue == nil and Error.new({
			kind = Error.Kind.NotResolvedInTime,
			error = "This Promise was not resolved in time for :now()",
			context = ":now() was called at:\n\n" .. traceback,
		}) or rejectionValue)
	end
end

--[=[
	Repeatedly calls a Promise-returning function up to `times` number of times, until the returned Promise resolves.

	If the amount of retries is exceeded, the function will return the latest rejected Promise.

	```lua
	local function canFail(a, b, c)
		return Promise.new(function(resolve, reject)
			-- do something that can fail

			local failed, thing = doSomethingThatCanFail(a, b, c)

			if failed then
				reject("it failed")
			else
				resolve(thing)
			end
		end)
	end

	local MAX_RETRIES = 10
	local value = Promise.retry(canFail, MAX_RETRIES, "foo", "bar", "baz") -- args to send to canFail
	```

	@since 3.0.0
	@param callback (...: P) -> Promise<T>
	@param times number
	@param ...? P
]=]
function Promise.retry(callback, times, ...)
	assert(isCallable(callback), "Parameter #1 to Promise.retry must be a function")
	assert(type(times) == "number", "Parameter #2 to Promise.retry must be a number")

	local args, length = { ... }, select("#", ...)

	return Promise.resolve(callback(...)):catch(function(...)
		if times > 0 then
			return Promise.retry(callback, times - 1, unpack(args, 1, length))
		else
			return Promise.reject(...)
		end
	end)
end

--[=[
	Repeatedly calls a Promise-returning function up to `times` number of times, waiting `seconds` seconds between each
	retry, until the returned Promise resolves.

	If the amount of retries is exceeded, the function will return the latest rejected Promise.

	@since v3.2.0
	@param callback (...: P) -> Promise<T>
	@param times number
	@param seconds number
	@param ...? P
]=]
function Promise.retryWithDelay(callback, times, seconds, ...)
	assert(isCallable(callback), "Parameter #1 to Promise.retry must be a function")
	assert(type(times) == "number", "Parameter #2 (times) to Promise.retry must be a number")
	assert(type(seconds) == "number", "Parameter #3 (seconds) to Promise.retry must be a number")

	local args, length = { ... }, select("#", ...)

	return Promise.resolve(callback(...)):catch(function(...)
		if times > 0 then
			Promise.delay(seconds):await()

			return Promise.retryWithDelay(callback, times - 1, seconds, unpack(args, 1, length))
		else
			return Promise.reject(...)
		end
	end)
end

--[=[
	Converts an event into a Promise which resolves the next time the event fires.

	The optional `predicate` callback, if passed, will receive the event arguments and should return `true` or `false`, based on if this fired event should resolve the Promise or not. If `true`, the Promise resolves. If `false`, nothing happens and the predicate will be rerun the next time the event fires.

	The Promise will resolve with the event arguments.

	:::tip
	This function will work given any object with a `Connect` method. This includes all Roblox events.
	:::

	```lua
	-- Creates a Promise which only resolves when `somePart` is touched
	-- by a part named `"Something specific"`.
	return Promise.fromEvent(somePart.Touched, function(part)
		return part.Name == "Something specific"
	end)
	```

	@since 3.0.0
	@param event Event -- Any object with a `Connect` method. This includes all Roblox events.
	@param predicate? (...: P) -> boolean -- A function which determines if the Promise should resolve with the given value, or wait for the next event to check again.
	@return Promise<P>
]=]
function Promise.fromEvent(event, predicate)
	predicate = predicate or function()
		return true
	end

	return Promise._new(debug.traceback(nil, 2), function(resolve, _, onCancel)
		local connection
		local shouldDisconnect = false

		local function disconnect()
			connection:Disconnect()
			connection = nil
		end

		-- We use shouldDisconnect because if the callback given to Connect is called before
		-- Connect returns, connection will still be nil. This happens with events that queue up
		-- events when there's nothing connected, such as RemoteEvents

		connection = event:Connect(function(...)
			local callbackValue = predicate(...)

			if callbackValue == true then
				resolve(...)

				if connection then
					disconnect()
				else
					shouldDisconnect = true
				end
			elseif type(callbackValue) ~= "boolean" then
				error("Promise.fromEvent predicate should always return a boolean")
			end
		end)

		if shouldDisconnect and connection then
			return disconnect()
		end

		onCancel(disconnect)
	end)
end

--[=[
	Registers a callback that runs when an unhandled rejection happens. An unhandled rejection happens when a Promise
	is rejected, and the rejection is not observed with `:catch`.

	The callback is called with the actual promise that rejected, followed by the rejection values.

	@since v3.2.0
	@param callback (promise: Promise, ...: any) -- A callback that runs when an unhandled rejection happens.
	@return () -> () -- Function that unregisters the `callback` when called
]=]
function Promise.onUnhandledRejection(callback)
	table.insert(Promise._unhandledRejectionCallbacks, callback)

	return function()
		local index = table.find(Promise._unhandledRejectionCallbacks, callback)

		if index then
			table.remove(Promise._unhandledRejectionCallbacks, index)
		end
	end
end

return Promise
 end, _env("RemoteSpy.include.Promise"))() end)

_module("RuntimeLib", "ModuleScript", "RemoteSpy.include.RuntimeLib", "RemoteSpy.include", function () return setfenv(function() local Promise = require(script.Parent.Promise)

local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local TS = {}

TS.Promise = Promise

local function isPlugin(object)
	return RunService:IsStudio() and object:FindFirstAncestorWhichIsA("Plugin") ~= nil
end

function TS.getModule(object, scope, moduleName)
	if moduleName == nil then
		moduleName = scope
		scope = "@rbxts"
	end

	if RunService:IsRunning() and object:IsDescendantOf(ReplicatedFirst) then
		warn("roblox-ts packages should not be used from ReplicatedFirst!")
	end

	-- ensure modules have fully replicated
	if RunService:IsRunning() and RunService:IsClient() and not isPlugin(object) and not game:IsLoaded() then
		game.Loaded:Wait()
	end

	local globalModules = script.Parent:FindFirstChild("node_modules")
	if not globalModules then
		error("Could not find any modules!", 2)
	end

	repeat
		local modules = object:FindFirstChild("node_modules")
		if modules and modules ~= globalModules then
			modules = modules:FindFirstChild("@rbxts")
		end
		if modules then
			local module = modules:FindFirstChild(moduleName)
			if module then
				return module
			end
		end
		object = object.Parent
	until object == nil or object == globalModules

	local scopedModules = globalModules:FindFirstChild(scope or "@rbxts");
	return (scopedModules or globalModules):FindFirstChild(moduleName) or error("Could not find module: " .. moduleName, 2)
end

-- This is a hash which TS.import uses as a kind of linked-list-like history of [Script who Loaded] -> Library
local currentlyLoading = {}
local registeredLibraries = {}

function TS.import(caller, module, ...)
	for i = 1, select("#", ...) do
		module = module:WaitForChild((select(i, ...)))
	end

	if module.ClassName ~= "ModuleScript" then
		error("Failed to import! Expected ModuleScript, got " .. module.ClassName, 2)
	end

	currentlyLoading[caller] = module

	-- Check to see if a case like this occurs:
	-- module -> Module1 -> Module2 -> module

	-- WHERE currentlyLoading[module] is Module1
	-- and currentlyLoading[Module1] is Module2
	-- and currentlyLoading[Module2] is module

	local currentModule = module
	local depth = 0

	while currentModule do
		depth = depth + 1
		currentModule = currentlyLoading[currentModule]

		if currentModule == module then
			local str = currentModule.Name -- Get the string traceback

			for _ = 1, depth do
				currentModule = currentlyLoading[currentModule]
				str = str .. "  ⇒ " .. currentModule.Name
			end

			error("Failed to import! Detected a circular dependency chain: " .. str, 2)
		end
	end

	if not registeredLibraries[module] then
		if _G[module] then
			error(
				"Invalid module access! Do you have two TS runtimes trying to import this? " .. module:GetFullName(),
				2
			)
		end

		_G[module] = TS
		registeredLibraries[module] = true -- register as already loaded for subsequent calls
	end

	local data = require(module)

	if currentlyLoading[caller] == module then -- Thread-safe cleanup!
		currentlyLoading[caller] = nil
	end

	return data
end

function TS.instanceof(obj, class)
	-- custom Class.instanceof() check
	if type(class) == "table" and type(class.instanceof) == "function" then
		return class.instanceof(obj)
	end

	-- metatable check
	if type(obj) == "table" then
		obj = getmetatable(obj)
		while obj ~= nil do
			if obj == class then
				return true
			end
			local mt = getmetatable(obj)
			if mt then
				obj = mt.__index
			else
				obj = nil
			end
		end
	end

	return false
end

function TS.async(callback)
	return function(...)
		local n = select("#", ...)
		local args = { ... }
		return Promise.new(function(resolve, reject)
			coroutine.wrap(function()
				local ok, result = pcall(callback, unpack(args, 1, n))
				if ok then
					resolve(result)
				else
					reject(result)
				end
			end)()
		end)
	end
end

function TS.await(promise)
	if not Promise.is(promise) then
		return promise
	end

	local status, value = promise:awaitStatus()
	if status == Promise.Status.Resolved then
		return value
	elseif status == Promise.Status.Rejected then
		error(value, 2)
	else
		error("The awaited Promise was cancelled", 2)
	end
end

function TS.bit_lrsh(a, b)
	local absA = math.abs(a)
	local result = bit32.rshift(absA, b)
	if a == absA then
		return result
	else
		return -result - 1
	end
end

TS.TRY_RETURN = 1
TS.TRY_BREAK = 2
TS.TRY_CONTINUE = 3

function TS.try(func, catch, finally)
	local err, traceback
	local success, exitType, returns = xpcall(
		func,
		function(errInner)
			err = errInner
			traceback = debug.traceback()
		end
	)
	if not success and catch then
		local newExitType, newReturns = catch(err, traceback)
		if newExitType then
			exitType, returns = newExitType, newReturns
		end
	end
	if finally then
		local newExitType, newReturns = finally()
		if newExitType then
			exitType, returns = newExitType, newReturns
		end
	end
	return exitType, returns
end

function TS.generator(callback)
	local co = coroutine.create(callback)
	return {
		next = function(...)
			if coroutine.status(co) == "dead" then
				return { done = true }
			else
				local success, value = coroutine.resume(co, ...)
				if success == false then
					error(value, 2)
				end
				return {
					value = value,
					done = coroutine.status(co) == "dead",
				}
			end
		end,
	}
end

return TS
 end, _env("RemoteSpy.include.RuntimeLib"))() end)

_instance("node_modules", "Folder", "RemoteSpy.include.node_modules", "RemoteSpy.include")

_instance("bin", "Folder", "RemoteSpy.include.node_modules.bin", "RemoteSpy.include.node_modules")

_module("out", "ModuleScript", "RemoteSpy.include.node_modules.bin.out", "RemoteSpy.include.node_modules.bin", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
--[[
	*
	* Tracks connections, instances, functions, and objects to be later destroyed.
]]
local Bin
do
	Bin = setmetatable({}, {
		__tostring = function()
			return "Bin"
		end,
	})
	Bin.__index = Bin
	function Bin.new(...)
		local self = setmetatable({}, Bin)
		return self:constructor(...) or self
	end
	function Bin:constructor()
	end
	function Bin:add(item)
		local node = {
			item = item,
		}
		if self.head == nil then
			self.head = node
		end
		if self.tail then
			self.tail.next = node
		end
		self.tail = node
		return item
	end
	function Bin:destroy()
		while self.head do
			local item = self.head.item
			if type(item) == "function" then
				item()
			elseif typeof(item) == "RBXScriptConnection" then
				item:Disconnect()
			elseif item.destroy ~= nil then
				item:destroy()
			elseif item.Destroy ~= nil then
				item:Destroy()
			end
			self.head = self.head.next
		end
	end
	function Bin:isEmpty()
		return self.head == nil
	end
end
return {
	Bin = Bin,
}
 end, _env("RemoteSpy.include.node_modules.bin.out"))() end)

_instance("compiler-types", "Folder", "RemoteSpy.include.node_modules.compiler-types", "RemoteSpy.include.node_modules")

_instance("types", "Folder", "RemoteSpy.include.node_modules.compiler-types.types", "RemoteSpy.include.node_modules.compiler-types")

_instance("flipper", "Folder", "RemoteSpy.include.node_modules.flipper", "RemoteSpy.include.node_modules")

_module("src", "ModuleScript", "RemoteSpy.include.node_modules.flipper.src", "RemoteSpy.include.node_modules.flipper", function () return setfenv(function() local Flipper = {
	SingleMotor = require(script.SingleMotor),
	GroupMotor = require(script.GroupMotor),

	Instant = require(script.Instant),
	Linear = require(script.Linear),
	Spring = require(script.Spring),
	
	isMotor = require(script.isMotor),
}

return Flipper end, _env("RemoteSpy.include.node_modules.flipper.src"))() end)

_module("BaseMotor", "ModuleScript", "RemoteSpy.include.node_modules.flipper.src.BaseMotor", "RemoteSpy.include.node_modules.flipper.src", function () return setfenv(function() local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)

local noop = function() end

local BaseMotor = {}
BaseMotor.__index = BaseMotor

function BaseMotor.new()
	return setmetatable({
		_onStep = Signal.new(),
		_onStart = Signal.new(),
		_onComplete = Signal.new(),
	}, BaseMotor)
end

function BaseMotor:onStep(handler)
	return self._onStep:connect(handler)
end

function BaseMotor:onStart(handler)
	return self._onStart:connect(handler)
end

function BaseMotor:onComplete(handler)
	return self._onComplete:connect(handler)
end

function BaseMotor:start()
	if not self._connection then
		self._connection = RunService.RenderStepped:Connect(function(deltaTime)
			self:step(deltaTime)
		end)
	end
end

function BaseMotor:stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

BaseMotor.destroy = BaseMotor.stop

BaseMotor.step = noop
BaseMotor.getValue = noop
BaseMotor.setGoal = noop

function BaseMotor:__tostring()
	return "Motor"
end

return BaseMotor
 end, _env("RemoteSpy.include.node_modules.flipper.src.BaseMotor"))() end)

_module("GroupMotor", "ModuleScript", "RemoteSpy.include.node_modules.flipper.src.GroupMotor", "RemoteSpy.include.node_modules.flipper.src", function () return setfenv(function() local BaseMotor = require(script.Parent.BaseMotor)
local SingleMotor = require(script.Parent.SingleMotor)

local isMotor = require(script.Parent.isMotor)

local GroupMotor = setmetatable({}, BaseMotor)
GroupMotor.__index = GroupMotor

local function toMotor(value)
	if isMotor(value) then
		return value
	end

	local valueType = typeof(value)

	if valueType == "number" then
		return SingleMotor.new(value, false)
	elseif valueType == "table" then
		return GroupMotor.new(value, false)
	end

	error(("Unable to convert %q to motor; type %s is unsupported"):format(value, valueType), 2)
end

function GroupMotor.new(initialValues, useImplicitConnections)
	assert(initialValues, "Missing argument #1: initialValues")
	assert(typeof(initialValues) == "table", "initialValues must be a table!")
	assert(not initialValues.step, "initialValues contains disallowed property \"step\". Did you mean to put a table of values here?")

	local self = setmetatable(BaseMotor.new(), GroupMotor)

	if useImplicitConnections ~= nil then
		self._useImplicitConnections = useImplicitConnections
	else
		self._useImplicitConnections = true
	end

	self._complete = true
	self._motors = {}

	for key, value in pairs(initialValues) do
		self._motors[key] = toMotor(value)
	end

	return self
end

function GroupMotor:step(deltaTime)
	if self._complete then
		return true
	end

	local allMotorsComplete = true

	for _, motor in pairs(self._motors) do
		local complete = motor:step(deltaTime)
		if not complete then
			-- If any of the sub-motors are incomplete, the group motor will not be complete either
			allMotorsComplete = false
		end
	end

	self._onStep:fire(self:getValue())

	if allMotorsComplete then
		if self._useImplicitConnections then
			self:stop()
		end

		self._complete = true
		self._onComplete:fire()
	end

	return allMotorsComplete
end

function GroupMotor:setGoal(goals)
	assert(not goals.step, "goals contains disallowed property \"step\". Did you mean to put a table of goals here?")

	self._complete = false
	self._onStart:fire()

	for key, goal in pairs(goals) do
		local motor = assert(self._motors[key], ("Unknown motor for key %s"):format(key))
		motor:setGoal(goal)
	end

	if self._useImplicitConnections then
		self:start()
	end
end

function GroupMotor:getValue()
	local values = {}

	for key, motor in pairs(self._motors) do
		values[key] = motor:getValue()
	end

	return values
end

function GroupMotor:__tostring()
	return "Motor(Group)"
end

return GroupMotor
 end, _env("RemoteSpy.include.node_modules.flipper.src.GroupMotor"))() end)

_module("Instant", "ModuleScript", "RemoteSpy.include.node_modules.flipper.src.Instant", "RemoteSpy.include.node_modules.flipper.src", function () return setfenv(function() local Instant = {}
Instant.__index = Instant

function Instant.new(targetValue)
	return setmetatable({
		_targetValue = targetValue,
	}, Instant)
end

function Instant:step()
	return {
		complete = true,
		value = self._targetValue,
	}
end

return Instant end, _env("RemoteSpy.include.node_modules.flipper.src.Instant"))() end)

_module("Linear", "ModuleScript", "RemoteSpy.include.node_modules.flipper.src.Linear", "RemoteSpy.include.node_modules.flipper.src", function () return setfenv(function() local Linear = {}
Linear.__index = Linear

function Linear.new(targetValue, options)
	assert(targetValue, "Missing argument #1: targetValue")
	
	options = options or {}

	return setmetatable({
		_targetValue = targetValue,
		_velocity = options.velocity or 1,
	}, Linear)
end

function Linear:step(state, dt)
	local position = state.value
	local velocity = self._velocity -- Linear motion ignores the state's velocity
	local goal = self._targetValue

	local dPos = dt * velocity

	local complete = dPos >= math.abs(goal - position)
	position = position + dPos * (goal > position and 1 or -1)
	if complete then
		position = self._targetValue
		velocity = 0
	end
	
	return {
		complete = complete,
		value = position,
		velocity = velocity,
	}
end

return Linear end, _env("RemoteSpy.include.node_modules.flipper.src.Linear"))() end)

_module("Signal", "ModuleScript", "RemoteSpy.include.node_modules.flipper.src.Signal", "RemoteSpy.include.node_modules.flipper.src", function () return setfenv(function() local Connection = {}
Connection.__index = Connection

function Connection.new(signal, handler)
	return setmetatable({
		signal = signal,
		connected = true,
		_handler = handler,
	}, Connection)
end

function Connection:disconnect()
	if self.connected then
		self.connected = false

		for index, connection in pairs(self.signal._connections) do
			if connection == self then
				table.remove(self.signal._connections, index)
				return
			end
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_connections = {},
		_threads = {},
	}, Signal)
end

function Signal:fire(...)
	for _, connection in pairs(self._connections) do
		connection._handler(...)
	end

	for _, thread in pairs(self._threads) do
		coroutine.resume(thread, ...)
	end
	
	self._threads = {}
end

function Signal:connect(handler)
	local connection = Connection.new(self, handler)
	table.insert(self._connections, connection)
	return connection
end

function Signal:wait()
	table.insert(self._threads, coroutine.running())
	return coroutine.yield()
end

return Signal end, _env("RemoteSpy.include.node_modules.flipper.src.Signal"))() end)

_module("SingleMotor", "ModuleScript", "RemoteSpy.include.node_modules.flipper.src.SingleMotor", "RemoteSpy.include.node_modules.flipper.src", function () return setfenv(function() local BaseMotor = require(script.Parent.BaseMotor)

local SingleMotor = setmetatable({}, BaseMotor)
SingleMotor.__index = SingleMotor

function SingleMotor.new(initialValue, useImplicitConnections)
	assert(initialValue, "Missing argument #1: initialValue")
	assert(typeof(initialValue) == "number", "initialValue must be a number!")

	local self = setmetatable(BaseMotor.new(), SingleMotor)

	if useImplicitConnections ~= nil then
		self._useImplicitConnections = useImplicitConnections
	else
		self._useImplicitConnections = true
	end

	self._goal = nil
	self._state = {
		complete = true,
		value = initialValue,
	}

	return self
end

function SingleMotor:step(deltaTime)
	if self._state.complete then
		return true
	end

	local newState = self._goal:step(self._state, deltaTime)

	self._state = newState
	self._onStep:fire(newState.value)

	if newState.complete then
		if self._useImplicitConnections then
			self:stop()
		end

		self._onComplete:fire()
	end

	return newState.complete
end

function SingleMotor:getValue()
	return self._state.value
end

function SingleMotor:setGoal(goal)
	self._state.complete = false
	self._goal = goal

	self._onStart:fire()

	if self._useImplicitConnections then
		self:start()
	end
end

function SingleMotor:__tostring()
	return "Motor(Single)"
end

return SingleMotor
 end, _env("RemoteSpy.include.node_modules.flipper.src.SingleMotor"))() end)

_module("Spring", "ModuleScript", "RemoteSpy.include.node_modules.flipper.src.Spring", "RemoteSpy.include.node_modules.flipper.src", function () return setfenv(function() local VELOCITY_THRESHOLD = 0.001
local POSITION_THRESHOLD = 0.001

local EPS = 0.0001

local Spring = {}
Spring.__index = Spring

function Spring.new(targetValue, options)
	assert(targetValue, "Missing argument #1: targetValue")
	options = options or {}

	return setmetatable({
		_targetValue = targetValue,
		_frequency = options.frequency or 4,
		_dampingRatio = options.dampingRatio or 1,
	}, Spring)
end

function Spring:step(state, dt)
	-- Copyright 2018 Parker Stebbins (parker@fractality.io)
	-- github.com/Fraktality/Spring
	-- Distributed under the MIT license

	local d = self._dampingRatio
	local f = self._frequency*2*math.pi
	local g = self._targetValue
	local p0 = state.value
	local v0 = state.velocity or 0

	local offset = p0 - g
	local decay = math.exp(-d*f*dt)

	local p1, v1

	if d == 1 then -- Critically damped
		p1 = (offset*(1 + f*dt) + v0*dt)*decay + g
		v1 = (v0*(1 - f*dt) - offset*(f*f*dt))*decay
	elseif d < 1 then -- Underdamped
		local c = math.sqrt(1 - d*d)

		local i = math.cos(f*c*dt)
		local j = math.sin(f*c*dt)

		-- Damping ratios approaching 1 can cause division by small numbers.
		-- To fix that, group terms around z=j/c and find an approximation for z.
		-- Start with the definition of z:
		--    z = sin(dt*f*c)/c
		-- Substitute a=dt*f:
		--    z = sin(a*c)/c
		-- Take the Maclaurin expansion of z with respect to c:
		--    z = a - (a^3*c^2)/6 + (a^5*c^4)/120 + O(c^6)
		--    z ≈ a - (a^3*c^2)/6 + (a^5*c^4)/120
		-- Rewrite in Horner form:
		--    z ≈ a + ((a*a)*(c*c)*(c*c)/20 - c*c)*(a*a*a)/6

		local z
		if c > EPS then
			z = j/c
		else
			local a = dt*f
			z = a + ((a*a)*(c*c)*(c*c)/20 - c*c)*(a*a*a)/6
		end

		-- Frequencies approaching 0 present a similar problem.
		-- We want an approximation for y as f approaches 0, where:
		--    y = sin(dt*f*c)/(f*c)
		-- Substitute b=dt*c:
		--    y = sin(b*c)/b
		-- Now reapply the process from z.

		local y
		if f*c > EPS then
			y = j/(f*c)
		else
			local b = f*c
			y = dt + ((dt*dt)*(b*b)*(b*b)/20 - b*b)*(dt*dt*dt)/6
		end

		p1 = (offset*(i + d*z) + v0*y)*decay + g
		v1 = (v0*(i - z*d) - offset*(z*f))*decay

	else -- Overdamped
		local c = math.sqrt(d*d - 1)

		local r1 = -f*(d - c)
		local r2 = -f*(d + c)

		local co2 = (v0 - offset*r1)/(2*f*c)
		local co1 = offset - co2

		local e1 = co1*math.exp(r1*dt)
		local e2 = co2*math.exp(r2*dt)

		p1 = e1 + e2 + g
		v1 = e1*r1 + e2*r2
	end

	local complete = math.abs(v1) < VELOCITY_THRESHOLD and math.abs(p1 - g) < POSITION_THRESHOLD
	
	return {
		complete = complete,
		value = complete and g or p1,
		velocity = v1,
	}
end

return Spring end, _env("RemoteSpy.include.node_modules.flipper.src.Spring"))() end)

_module("isMotor", "ModuleScript", "RemoteSpy.include.node_modules.flipper.src.isMotor", "RemoteSpy.include.node_modules.flipper.src", function () return setfenv(function() local function isMotor(value)
	local motorType = tostring(value):match("^Motor%((.+)%)$")

	if motorType then
		return true, motorType
	else
		return false
	end
end

return isMotor end, _env("RemoteSpy.include.node_modules.flipper.src.isMotor"))() end)

_instance("typings", "Folder", "RemoteSpy.include.node_modules.flipper.typings", "RemoteSpy.include.node_modules.flipper")

_instance("hax", "Folder", "RemoteSpy.include.node_modules.hax", "RemoteSpy.include.node_modules")

_instance("types", "Folder", "RemoteSpy.include.node_modules.hax.types", "RemoteSpy.include.node_modules.hax")

_module("make", "ModuleScript", "RemoteSpy.include.node_modules.make", "RemoteSpy.include.node_modules", function () return setfenv(function() -- Compiled with roblox-ts v1.2.3
--[[
	*
	* Returns a table wherein an object's writable properties can be specified,
	* while also allowing functions to be passed in which can be bound to a RBXScriptSignal.
]]
--[[
	*
	* Instantiates a new Instance of `className` with given `settings`,
	* where `settings` is an object of the form { [K: propertyName]: value }.
	*
	* `settings.Children` is an array of child objects to be parented to the generated Instance.
	*
	* Events can be set to a callback function, which will be connected.
	*
	* `settings.Parent` is always set last.
]]
local function Make(className, settings)
	local _binding = settings
	local children = _binding.Children
	local parent = _binding.Parent
	local instance = Instance.new(className)
	for setting, value in pairs(settings) do
		if setting ~= "Children" and setting ~= "Parent" then
			local _binding_1 = instance
			local prop = _binding_1[setting]
			if typeof(prop) == "RBXScriptSignal" then
				prop:Connect(value)
			else
				instance[setting] = value
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	instance.Parent = parent
	return instance
end
return Make
 end, _env("RemoteSpy.include.node_modules.make"))() end)

_instance("node_modules", "Folder", "RemoteSpy.include.node_modules.make.node_modules", "RemoteSpy.include.node_modules.make")

_instance("@rbxts", "Folder", "RemoteSpy.include.node_modules.make.node_modules.@rbxts", "RemoteSpy.include.node_modules.make.node_modules")

_instance("compiler-types", "Folder", "RemoteSpy.include.node_modules.make.node_modules.@rbxts.compiler-types", "RemoteSpy.include.node_modules.make.node_modules.@rbxts")

_instance("types", "Folder", "RemoteSpy.include.node_modules.make.node_modules.@rbxts.compiler-types.types", "RemoteSpy.include.node_modules.make.node_modules.@rbxts.compiler-types")

_module("object-utils", "ModuleScript", "RemoteSpy.include.node_modules.object-utils", "RemoteSpy.include.node_modules", function () return setfenv(function() local HttpService = game:GetService("HttpService")

local Object = {}

function Object.keys(object)
	local result = table.create(#object)
	for key in pairs(object) do
		result[#result + 1] = key
	end
	return result
end

function Object.values(object)
	local result = table.create(#object)
	for _, value in pairs(object) do
		result[#result + 1] = value
	end
	return result
end

function Object.entries(object)
	local result = table.create(#object)
	for key, value in pairs(object) do
		result[#result + 1] = { key, value }
	end
	return result
end

function Object.assign(toObj, ...)
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if type(arg) == "table" then
			for key, value in pairs(arg) do
				toObj[key] = value
			end
		end
	end
	return toObj
end

function Object.copy(object)
	local result = table.create(#object)
	for k, v in pairs(object) do
		result[k] = v
	end
	return result
end

local function deepCopyHelper(object, encountered)
	local result = table.create(#object)
	encountered[object] = result

	for k, v in pairs(object) do
		if type(k) == "table" then
			k = encountered[k] or deepCopyHelper(k, encountered)
		end

		if type(v) == "table" then
			v = encountered[v] or deepCopyHelper(v, encountered)
		end

		result[k] = v
	end

	return result
end

function Object.deepCopy(object)
	return deepCopyHelper(object, {})
end

function Object.deepEquals(a, b)
	-- a[k] == b[k]
	for k in pairs(a) do
		local av = a[k]
		local bv = b[k]
		if type(av) == "table" and type(bv) == "table" then
			local result = Object.deepEquals(av, bv)
			if not result then
				return false
			end
		elseif av ~= bv then
			return false
		end
	end

	-- extra keys in b
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end

	return true
end

function Object.toString(data)
	return HttpService:JSONEncode(data)
end

function Object.isEmpty(object)
	return next(object) == nil
end

function Object.fromEntries(entries)
	local entriesLen = #entries

	local result = table.create(entriesLen)
	if entries then
		for i = 1, entriesLen do
			local pair = entries[i]
			result[pair[1]] = pair[2]
		end
	end
	return result
end

return Object
 end, _env("RemoteSpy.include.node_modules.object-utils"))() end)

_instance("roact", "Folder", "RemoteSpy.include.node_modules.roact", "RemoteSpy.include.node_modules")

_module("src", "ModuleScript", "RemoteSpy.include.node_modules.roact.src", "RemoteSpy.include.node_modules.roact", function () return setfenv(function() --[[
	Packages up the internals of Roact and exposes a public API for it.
]]

local GlobalConfig = require(script.GlobalConfig)
local createReconciler = require(script.createReconciler)
local createReconcilerCompat = require(script.createReconcilerCompat)
local RobloxRenderer = require(script.RobloxRenderer)
local strict = require(script.strict)
local Binding = require(script.Binding)

local robloxReconciler = createReconciler(RobloxRenderer)
local reconcilerCompat = createReconcilerCompat(robloxReconciler)

local Roact = strict {
	Component = require(script.Component),
	createElement = require(script.createElement),
	createFragment = require(script.createFragment),
	oneChild = require(script.oneChild),
	PureComponent = require(script.PureComponent),
	None = require(script.None),
	Portal = require(script.Portal),
	createRef = require(script.createRef),
	forwardRef = require(script.forwardRef),
	createBinding = Binding.create,
	joinBindings = Binding.join,
	createContext = require(script.createContext),

	Change = require(script.PropMarkers.Change),
	Children = require(script.PropMarkers.Children),
	Event = require(script.PropMarkers.Event),
	Ref = require(script.PropMarkers.Ref),

	mount = robloxReconciler.mountVirtualTree,
	unmount = robloxReconciler.unmountVirtualTree,
	update = robloxReconciler.updateVirtualTree,

	reify = reconcilerCompat.reify,
	teardown = reconcilerCompat.teardown,
	reconcile = reconcilerCompat.reconcile,

	setGlobalConfig = GlobalConfig.set,

	-- APIs that may change in the future without warning
	UNSTABLE = {
	},
}

return Roact end, _env("RemoteSpy.include.node_modules.roact.src"))() end)

_module("Binding", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.Binding", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local createSignal = require(script.Parent.createSignal)
local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local config = require(script.Parent.GlobalConfig).get()

local BindingImpl = Symbol.named("BindingImpl")

local BindingInternalApi = {}

local bindingPrototype = {}

function bindingPrototype:getValue()
	return BindingInternalApi.getValue(self)
end

function bindingPrototype:map(predicate)
	return BindingInternalApi.map(self, predicate)
end

local BindingPublicMeta = {
	__index = bindingPrototype,
	__tostring = function(self)
		return string.format("RoactBinding(%s)", tostring(self:getValue()))
	end,
}

function BindingInternalApi.update(binding, newValue)
	return binding[BindingImpl].update(newValue)
end

function BindingInternalApi.subscribe(binding, callback)
	return binding[BindingImpl].subscribe(callback)
end

function BindingInternalApi.getValue(binding)
	return binding[BindingImpl].getValue()
end

function BindingInternalApi.create(initialValue)
	local impl = {
		value = initialValue,
		changeSignal = createSignal(),
	}

	function impl.subscribe(callback)
		return impl.changeSignal:subscribe(callback)
	end

	function impl.update(newValue)
		impl.value = newValue
		impl.changeSignal:fire(newValue)
	end

	function impl.getValue()
		return impl.value
	end

	return setmetatable({
		[Type] = Type.Binding,
		[BindingImpl] = impl,
	}, BindingPublicMeta), impl.update
end

function BindingInternalApi.map(upstreamBinding, predicate)
	if config.typeChecks then
		assert(Type.of(upstreamBinding) == Type.Binding, "Expected arg #1 to be a binding")
		assert(typeof(predicate) == "function", "Expected arg #1 to be a function")
	end

	local impl = {}

	function impl.subscribe(callback)
		return BindingInternalApi.subscribe(upstreamBinding, function(newValue)
			callback(predicate(newValue))
		end)
	end

	function impl.update(newValue)
		error("Bindings created by Binding:map(fn) cannot be updated directly", 2)
	end

	function impl.getValue()
		return predicate(upstreamBinding:getValue())
	end

	return setmetatable({
		[Type] = Type.Binding,
		[BindingImpl] = impl,
	}, BindingPublicMeta)
end

function BindingInternalApi.join(upstreamBindings)
	if config.typeChecks then
		assert(typeof(upstreamBindings) == "table", "Expected arg #1 to be of type table")

		for key, value in pairs(upstreamBindings) do
			if Type.of(value) ~= Type.Binding then
				local message = (
					"Expected arg #1 to contain only bindings, but key %q had a non-binding value"
				):format(
					tostring(key)
				)
				error(message, 2)
			end
		end
	end

	local impl = {}

	local function getValue()
		local value = {}

		for key, upstream in pairs(upstreamBindings) do
			value[key] = upstream:getValue()
		end

		return value
	end

	function impl.subscribe(callback)
		local disconnects = {}

		for key, upstream in pairs(upstreamBindings) do
			disconnects[key] = BindingInternalApi.subscribe(upstream, function(newValue)
				callback(getValue())
			end)
		end

		return function()
			if disconnects == nil then
				return
			end

			for _, disconnect in pairs(disconnects) do
				disconnect()
			end

			disconnects = nil
		end
	end

	function impl.update(newValue)
		error("Bindings created by joinBindings(...) cannot be updated directly", 2)
	end

	function impl.getValue()
		return getValue()
	end

	return setmetatable({
		[Type] = Type.Binding,
		[BindingImpl] = impl,
	}, BindingPublicMeta)
end

return BindingInternalApi end, _env("RemoteSpy.include.node_modules.roact.src.Binding"))() end)

_module("Component", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.Component", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local assign = require(script.Parent.assign)
local ComponentLifecyclePhase = require(script.Parent.ComponentLifecyclePhase)
local Type = require(script.Parent.Type)
local Symbol = require(script.Parent.Symbol)
local invalidSetStateMessages = require(script.Parent.invalidSetStateMessages)
local internalAssert = require(script.Parent.internalAssert)

local config = require(script.Parent.GlobalConfig).get()

--[[
	Calling setState during certain lifecycle allowed methods has the potential
	to create an infinitely updating component. Rather than time out, we exit
	with an error if an unreasonable number of self-triggering updates occur
]]
local MAX_PENDING_UPDATES = 100

local InternalData = Symbol.named("InternalData")

local componentMissingRenderMessage = [[
The component %q is missing the `render` method.
`render` must be defined when creating a Roact component!]]

local tooManyUpdatesMessage = [[
The component %q has reached the setState update recursion limit.
When using `setState` in `didUpdate`, make sure that it won't repeat infinitely!]]

local componentClassMetatable = {}

function componentClassMetatable:__tostring()
	return self.__componentName
end

local Component = {}
setmetatable(Component, componentClassMetatable)

Component[Type] = Type.StatefulComponentClass
Component.__index = Component
Component.__componentName = "Component"

--[[
	A method called by consumers of Roact to create a new component class.
	Components can not be extended beyond this point, with the exception of
	PureComponent.
]]
function Component:extend(name)
	if config.typeChecks then
		assert(Type.of(self) == Type.StatefulComponentClass, "Invalid `self` argument to `extend`.")
		assert(typeof(name) == "string", "Component class name must be a string")
	end

	local class = {}

	for key, value in pairs(self) do
		-- Roact opts to make consumers use composition over inheritance, which
		-- lines up with React.
		-- https://reactjs.org/docs/composition-vs-inheritance.html
		if key ~= "extend" then
			class[key] = value
		end
	end

	class[Type] = Type.StatefulComponentClass
	class.__index = class
	class.__componentName = name

	setmetatable(class, componentClassMetatable)

	return class
end

function Component:__getDerivedState(incomingProps, incomingState)
	if config.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentInstance, "Invalid use of `__getDerivedState`")
	end

	local internalData = self[InternalData]
	local componentClass = internalData.componentClass

	if componentClass.getDerivedStateFromProps ~= nil then
		local derivedState = componentClass.getDerivedStateFromProps(incomingProps, incomingState)

		if derivedState ~= nil then
			if config.typeChecks then
				assert(typeof(derivedState) == "table", "getDerivedStateFromProps must return a table!")
			end

			return derivedState
		end
	end

	return nil
end

function Component:setState(mapState)
	if config.typeChecks then
		assert(Type.of(self) == Type.StatefulComponentInstance, "Invalid `self` argument to `extend`.")
	end

	local internalData = self[InternalData]
	local lifecyclePhase = internalData.lifecyclePhase

	--[[
		When preparing to update, rendering, or unmounting, it is not safe
		to call `setState` as it will interfere with in-flight updates. It's
		also disallowed during unmounting
	]]
	if lifecyclePhase == ComponentLifecyclePhase.ShouldUpdate or
		lifecyclePhase == ComponentLifecyclePhase.WillUpdate or
		lifecyclePhase == ComponentLifecyclePhase.Render or
		lifecyclePhase == ComponentLifecyclePhase.WillUnmount
	then
		local messageTemplate = invalidSetStateMessages[internalData.lifecyclePhase]

		local message = messageTemplate:format(tostring(internalData.componentClass))

		error(message, 2)
	end

	local pendingState = internalData.pendingState

	local partialState
	if typeof(mapState) == "function" then
		partialState = mapState(pendingState or self.state, self.props)

		-- Abort the state update if the given state updater function returns nil
		if partialState == nil then
			return
		end
	elseif typeof(mapState) == "table" then
		partialState = mapState
	else
		error("Invalid argument to setState, expected function or table", 2)
	end

	local newState
	if pendingState ~= nil then
		newState = assign(pendingState, partialState)
	else
		newState = assign({}, self.state, partialState)
	end

	if lifecyclePhase == ComponentLifecyclePhase.Init then
		-- If `setState` is called in `init`, we can skip triggering an update!
		local derivedState = self:__getDerivedState(self.props, newState)
		self.state = assign(newState, derivedState)

	elseif lifecyclePhase == ComponentLifecyclePhase.DidMount or
		lifecyclePhase == ComponentLifecyclePhase.DidUpdate or
		lifecyclePhase == ComponentLifecyclePhase.ReconcileChildren
	then
		--[[
			During certain phases of the component lifecycle, it's acceptable to
			allow `setState` but defer the update until we're done with ones in flight.
			We do this by collapsing it into any pending updates we have.
		]]
		local derivedState = self:__getDerivedState(self.props, newState)
		internalData.pendingState = assign(newState, derivedState)

	elseif lifecyclePhase == ComponentLifecyclePhase.Idle then
		-- Pause parent events when we are updated outside of our lifecycle
		-- If these events are not paused, our setState can cause a component higher up the
		-- tree to rerender based on events caused by our component while this reconciliation is happening.
		-- This could cause the tree to become invalid.
		local virtualNode = internalData.virtualNode
		local reconciler = internalData.reconciler
		if config.tempFixUpdateChildrenReEntrancy then
			reconciler.suspendParentEvents(virtualNode)
		end

		-- Outside of our lifecycle, the state update is safe to make immediately
		self:__update(nil, newState)

		if config.tempFixUpdateChildrenReEntrancy then
			reconciler.resumeParentEvents(virtualNode)
		end
	else
		local messageTemplate = invalidSetStateMessages.default

		local message = messageTemplate:format(tostring(internalData.componentClass))

		error(message, 2)
	end
end

--[[
	Returns the stack trace of where the element was created that this component
	instance's properties are based on.

	Intended to be used primarily by diagnostic tools.
]]
function Component:getElementTraceback()
	return self[InternalData].virtualNode.currentElement.source
end

--[[
	Returns a snapshot of this component given the current props and state. Must
	be overridden by consumers of Roact and should be a pure function with
	regards to props and state.

	TODO (#199): Accept props and state as arguments.
]]
function Component:render()
	local internalData = self[InternalData]

	local message = componentMissingRenderMessage:format(
		tostring(internalData.componentClass)
	)

	error(message, 0)
end

--[[
	Retrieves the context value corresponding to the given key. Can return nil
	if a requested context key is not present
]]
function Component:__getContext(key)
	if config.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentInstance, "Invalid use of `__getContext`")
		internalAssert(key ~= nil, "Context key cannot be nil")
	end

	local virtualNode = self[InternalData].virtualNode
	local context = virtualNode.context

	return context[key]
end

--[[
	Adds a new context entry to this component's context table (which will be
	passed down to child components).
]]
function Component:__addContext(key, value)
	if config.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentInstance, "Invalid use of `__addContext`")
	end
	local virtualNode = self[InternalData].virtualNode

	-- Make sure we store a reference to the component's original, unmodified
	-- context the virtual node. In the reconciler, we'll restore the original
	-- context if we need to replace the node (this happens when a node gets
	-- re-rendered as a different component)
	if virtualNode.originalContext == nil then
		virtualNode.originalContext = virtualNode.context
	end

	-- Build a new context table on top of the existing one, then apply it to
	-- our virtualNode
	local existing = virtualNode.context
	virtualNode.context = assign({}, existing, { [key] = value })
end

--[[
	Performs property validation if the static method validateProps is declared.
	validateProps should follow assert's expected arguments:
	(false, message: string) | true. The function may return a message in the
	true case; it will be ignored. If this fails, the function will throw the
	error.
]]
function Component:__validateProps(props)
	if not config.propValidation then
		return
	end

	local validator = self[InternalData].componentClass.validateProps

	if validator == nil then
		return
	end

	if typeof(validator) ~= "function" then
		error(("validateProps must be a function, but it is a %s.\nCheck the definition of the component %q."):format(
			typeof(validator),
			self.__componentName
		))
	end

	local success, failureReason = validator(props)

	if not success then
		failureReason = failureReason or "<Validator function did not supply a message>"
		error(("Property validation failed in %s: %s\n\n%s"):format(
			self.__componentName,
			tostring(failureReason),
			self:getElementTraceback() or "<enable element tracebacks>"),
		0)
	end
end

--[[
	An internal method used by the reconciler to construct a new component
	instance and attach it to the given virtualNode.
]]
function Component:__mount(reconciler, virtualNode)
	if config.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentClass, "Invalid use of `__mount`")
		internalAssert(Type.of(virtualNode) == Type.VirtualNode, "Expected arg #2 to be of type VirtualNode")
	end

	local currentElement = virtualNode.currentElement
	local hostParent = virtualNode.hostParent

	-- Contains all the information that we want to keep from consumers of
	-- Roact, or even other parts of the codebase like the reconciler.
	local internalData = {
		reconciler = reconciler,
		virtualNode = virtualNode,
		componentClass = self,
		lifecyclePhase = ComponentLifecyclePhase.Init,
	}

	local instance = {
		[Type] = Type.StatefulComponentInstance,
		[InternalData] = internalData,
	}

	setmetatable(instance, self)

	virtualNode.instance = instance

	local props = currentElement.props

	if self.defaultProps ~= nil then
		props = assign({}, self.defaultProps, props)
	end

	instance:__validateProps(props)

	instance.props = props

	local newContext = assign({}, virtualNode.legacyContext)
	instance._context = newContext

	instance.state = assign({}, instance:__getDerivedState(instance.props, {}))

	if instance.init ~= nil then
		instance:init(instance.props)
		assign(instance.state, instance:__getDerivedState(instance.props, instance.state))
	end

	-- It's possible for init() to redefine _context!
	virtualNode.legacyContext = instance._context

	internalData.lifecyclePhase = ComponentLifecyclePhase.Render
	local renderResult = instance:render()

	internalData.lifecyclePhase = ComponentLifecyclePhase.ReconcileChildren
	reconciler.updateVirtualNodeWithRenderResult(virtualNode, hostParent, renderResult)

	if instance.didMount ~= nil then
		internalData.lifecyclePhase = ComponentLifecyclePhase.DidMount
		instance:didMount()
	end

	if internalData.pendingState ~= nil then
		-- __update will handle pendingState, so we don't pass any new element or state
		instance:__update(nil, nil)
	end

	internalData.lifecyclePhase = ComponentLifecyclePhase.Idle
end

--[[
	Internal method used by the reconciler to clean up any resources held by
	this component instance.
]]
function Component:__unmount()
	if config.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentInstance, "Invalid use of `__unmount`")
	end

	local internalData = self[InternalData]
	local virtualNode = internalData.virtualNode
	local reconciler = internalData.reconciler

	if self.willUnmount ~= nil then
		internalData.lifecyclePhase = ComponentLifecyclePhase.WillUnmount
		self:willUnmount()
	end

	for _, childNode in pairs(virtualNode.children) do
		reconciler.unmountVirtualNode(childNode)
	end
end

--[[
	Internal method used by setState (to trigger updates based on state) and by
	the reconciler (to trigger updates based on props)

	Returns true if the update was completed, false if it was cancelled by shouldUpdate
]]
function Component:__update(updatedElement, updatedState)
	if config.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentInstance, "Invalid use of `__update`")
		internalAssert(
			Type.of(updatedElement) == Type.Element or updatedElement == nil,
			"Expected arg #1 to be of type Element or nil"
		)
		internalAssert(
			typeof(updatedState) == "table" or updatedState == nil,
			"Expected arg #2 to be of type table or nil"
		)
	end

	local internalData = self[InternalData]
	local componentClass = internalData.componentClass

	local newProps = self.props
	if updatedElement ~= nil then
		newProps = updatedElement.props

		if componentClass.defaultProps ~= nil then
			newProps = assign({}, componentClass.defaultProps, newProps)
		end

		self:__validateProps(newProps)
	end

	local updateCount = 0
	repeat
		local finalState
		local pendingState = nil

		-- Consume any pending state we might have
		if internalData.pendingState ~= nil then
			pendingState = internalData.pendingState
			internalData.pendingState = nil
		end

		-- Consume a standard update to state or props
		if updatedState ~= nil or newProps ~= self.props then
			if pendingState == nil then
				finalState = updatedState or self.state
			else
				finalState = assign(pendingState, updatedState)
			end

			local derivedState = self:__getDerivedState(newProps, finalState)

			if derivedState ~= nil then
				finalState = assign({}, finalState, derivedState)
			end

			updatedState = nil
		else
			finalState = pendingState
		end

		if not self:__resolveUpdate(newProps, finalState) then
			-- If the update was short-circuited, bubble the result up to the caller
			return false
		end

		updateCount = updateCount + 1

		if updateCount > MAX_PENDING_UPDATES then
			error(tooManyUpdatesMessage:format(tostring(internalData.componentClass)), 3)
		end
	until internalData.pendingState == nil

	return true
end

--[[
	Internal method used by __update to apply new props and state

	Returns true if the update was completed, false if it was cancelled by shouldUpdate
]]
function Component:__resolveUpdate(incomingProps, incomingState)
	if config.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentInstance, "Invalid use of `__resolveUpdate`")
	end

	local internalData = self[InternalData]
	local virtualNode = internalData.virtualNode
	local reconciler = internalData.reconciler

	local oldProps = self.props
	local oldState = self.state

	if incomingProps == nil then
		incomingProps = oldProps
	end
	if incomingState == nil then
		incomingState = oldState
	end

	if self.shouldUpdate ~= nil then
		internalData.lifecyclePhase = ComponentLifecyclePhase.ShouldUpdate
		local continueWithUpdate = self:shouldUpdate(incomingProps, incomingState)

		if not continueWithUpdate then
			internalData.lifecyclePhase = ComponentLifecyclePhase.Idle
			return false
		end
	end

	if self.willUpdate ~= nil then
		internalData.lifecyclePhase = ComponentLifecyclePhase.WillUpdate
		self:willUpdate(incomingProps, incomingState)
	end

	internalData.lifecyclePhase = ComponentLifecyclePhase.Render

	self.props = incomingProps
	self.state = incomingState

	local renderResult = virtualNode.instance:render()

	internalData.lifecyclePhase = ComponentLifecyclePhase.ReconcileChildren
	reconciler.updateVirtualNodeWithRenderResult(virtualNode, virtualNode.hostParent, renderResult)

	if self.didUpdate ~= nil then
		internalData.lifecyclePhase = ComponentLifecyclePhase.DidUpdate
		self:didUpdate(oldProps, oldState)
	end

	internalData.lifecyclePhase = ComponentLifecyclePhase.Idle
	return true
end

return Component end, _env("RemoteSpy.include.node_modules.roact.src.Component"))() end)

_module("ComponentLifecyclePhase", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.ComponentLifecyclePhase", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)

local ComponentLifecyclePhase = strict({
	-- Component methods
	Init = Symbol.named("init"),
	Render = Symbol.named("render"),
	ShouldUpdate = Symbol.named("shouldUpdate"),
	WillUpdate = Symbol.named("willUpdate"),
	DidMount = Symbol.named("didMount"),
	DidUpdate = Symbol.named("didUpdate"),
	WillUnmount = Symbol.named("willUnmount"),

	-- Phases describing reconciliation status
	ReconcileChildren = Symbol.named("reconcileChildren"),
	Idle = Symbol.named("idle"),
}, "ComponentLifecyclePhase")

return ComponentLifecyclePhase end, _env("RemoteSpy.include.node_modules.roact.src.ComponentLifecyclePhase"))() end)

_module("Config", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.Config", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Exposes an interface to set global configuration values for Roact.

	Configuration can only occur once, and should only be done by an application
	using Roact, not a library.

	Any keys that aren't recognized will cause errors. Configuration is only
	intended for configuring Roact itself, not extensions or libraries.

	Configuration is expected to be set immediately after loading Roact. Setting
	configuration values after an application starts may produce unpredictable
	behavior.
]]

-- Every valid configuration value should be non-nil in this table.
local defaultConfig = {
	-- Enables asserts for internal Roact APIs. Useful for debugging Roact itself.
	["internalTypeChecks"] = false,
	-- Enables stricter type asserts for Roact's public API.
	["typeChecks"] = false,
	-- Enables storage of `debug.traceback()` values on elements for debugging.
	["elementTracing"] = false,
	-- Enables validation of component props in stateful components.
	["propValidation"] = false,

	-- Temporary config for enabling a bug fix for processing events based on updates to child instances
	-- outside of the standard lifecycle.
	["tempFixUpdateChildrenReEntrancy"] = false,
}

-- Build a list of valid configuration values up for debug messages.
local defaultConfigKeys = {}
for key in pairs(defaultConfig) do
	table.insert(defaultConfigKeys, key)
end

local Config = {}

function Config.new()
	local self = {}

	self._currentConfig = setmetatable({}, {
		__index = function(_, key)
			local message = (
				"Invalid global configuration key %q. Valid configuration keys are: %s"
			):format(
				tostring(key),
				table.concat(defaultConfigKeys, ", ")
			)

			error(message, 3)
		end
	})

	-- We manually bind these methods here so that the Config's methods can be
	-- used without passing in self, since they eventually get exposed on the
	-- root Roact object.
	self.set = function(...)
		return Config.set(self, ...)
	end

	self.get = function(...)
		return Config.get(self, ...)
	end

	self.scoped = function(...)
		return Config.scoped(self, ...)
	end

	self.set(defaultConfig)

	return self
end

function Config:set(configValues)
	-- Validate values without changing any configuration.
	-- We only want to apply this configuration if it's valid!
	for key, value in pairs(configValues) do
		if defaultConfig[key] == nil then
			local message = (
				"Invalid global configuration key %q (type %s). Valid configuration keys are: %s"
			):format(
				tostring(key),
				typeof(key),
				table.concat(defaultConfigKeys, ", ")
			)

			error(message, 3)
		end

		-- Right now, all configuration values must be boolean.
		if typeof(value) ~= "boolean" then
			local message = (
				"Invalid value %q (type %s) for global configuration key %q. Valid values are: true, false"
			):format(
				tostring(value),
				typeof(value),
				tostring(key)
			)

			error(message, 3)
		end

		self._currentConfig[key] = value
	end
end

function Config:get()
	return self._currentConfig
end

function Config:scoped(configValues, callback)
	local previousValues = {}
	for key, value in pairs(self._currentConfig) do
		previousValues[key] = value
	end

	self.set(configValues)

	local success, result = pcall(callback)

	self.set(previousValues)

	assert(success, result)
end

return Config end, _env("RemoteSpy.include.node_modules.roact.src.Config"))() end)

_module("ElementKind", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.ElementKind", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Contains markers for annotating the type of an element.

	Use `ElementKind` as a key, and values from it as the value.

		local element = {
			[ElementKind] = ElementKind.Host,
		}
]]

local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)
local Portal = require(script.Parent.Portal)

local ElementKind = newproxy(true)

local ElementKindInternal = {
	Portal = Symbol.named("Portal"),
	Host = Symbol.named("Host"),
	Function = Symbol.named("Function"),
	Stateful = Symbol.named("Stateful"),
	Fragment = Symbol.named("Fragment"),
}

function ElementKindInternal.of(value)
	if typeof(value) ~= "table" then
		return nil
	end

	return value[ElementKind]
end

local componentTypesToKinds = {
	["string"] = ElementKindInternal.Host,
	["function"] = ElementKindInternal.Function,
	["table"] = ElementKindInternal.Stateful,
}

function ElementKindInternal.fromComponent(component)
	if component == Portal then
		return ElementKind.Portal
	else
		return componentTypesToKinds[typeof(component)]
	end
end

getmetatable(ElementKind).__index = ElementKindInternal

strict(ElementKindInternal, "ElementKind")

return ElementKind end, _env("RemoteSpy.include.node_modules.roact.src.ElementKind"))() end)

_module("ElementUtils", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.ElementUtils", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local Type = require(script.Parent.Type)
local Symbol = require(script.Parent.Symbol)

local function noop()
	return nil
end

local ElementUtils = {}

--[[
	A signal value indicating that a child should use its parent's key, because
	it has no key of its own.

	This occurs when you return only one element from a function component or
	stateful render function.
]]
ElementUtils.UseParentKey = Symbol.named("UseParentKey")

--[[
	Returns an iterator over the children of an element.
	`elementOrElements` may be one of:
	* a boolean
	* nil
	* a single element
	* a fragment
	* a table of elements

	If `elementOrElements` is a boolean or nil, this will return an iterator with
	zero elements.

	If `elementOrElements` is a single element, this will return an iterator with
	one element: a tuple where the first value is ElementUtils.UseParentKey, and
	the second is the value of `elementOrElements`.

	If `elementOrElements` is a fragment or a table, this will return an iterator
	over all the elements of the array.

	If `elementOrElements` is none of the above, this function will throw.
]]
function ElementUtils.iterateElements(elementOrElements)
	local richType = Type.of(elementOrElements)

	-- Single child
	if richType == Type.Element then
		local called = false

		return function()
			if called then
				return nil
			else
				called = true
				return ElementUtils.UseParentKey, elementOrElements
			end
		end
	end

	local regularType = typeof(elementOrElements)

	if elementOrElements == nil or regularType == "boolean" then
		return noop
	end

	if regularType == "table" then
		return pairs(elementOrElements)
	end

	error("Invalid elements")
end

--[[
	Gets the child corresponding to a given key, respecting Roact's rules for
	children. Specifically:
	* If `elements` is nil or a boolean, this will return `nil`, regardless of
		the key given.
	* If `elements` is a single element, this will return `nil`, unless the key
		is ElementUtils.UseParentKey.
	* If `elements` is a table of elements, this will return `elements[key]`.
]]
function ElementUtils.getElementByKey(elements, hostKey)
	if elements == nil or typeof(elements) == "boolean" then
		return nil
	end

	if Type.of(elements) == Type.Element then
		if hostKey == ElementUtils.UseParentKey then
			return elements
		end

		return nil
	end

	if typeof(elements) == "table" then
		return elements[hostKey]
	end

	error("Invalid elements")
end

return ElementUtils end, _env("RemoteSpy.include.node_modules.roact.src.ElementUtils"))() end)

_module("GlobalConfig", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.GlobalConfig", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Exposes a single instance of a configuration as Roact's GlobalConfig.
]]

local Config = require(script.Parent.Config)

return Config.new() end, _env("RemoteSpy.include.node_modules.roact.src.GlobalConfig"))() end)

_module("Logging", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.Logging", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Centralized place to handle logging. Lets us:
	- Unit test log output via `Logging.capture`
	- Disable verbose log messages when not debugging Roact

	This should be broken out into a separate library with the addition of
	scoping and logging configuration.
]]

-- Determines whether log messages will go to stdout/stderr
local outputEnabled = true

-- A set of LogInfo objects that should have messages inserted into them.
-- This is a set so that nested calls to Logging.capture will behave.
local collectors = {}

-- A set of all stack traces that have called warnOnce.
local onceUsedLocations = {}

--[[
	Indent a potentially multi-line string with the given number of tabs, in
	addition to any indentation the string already has.
]]
local function indent(source, indentLevel)
	local indentString = ("\t"):rep(indentLevel)

	return indentString .. source:gsub("\n", "\n" .. indentString)
end

--[[
	Indents a list of strings and then concatenates them together with newlines
	into a single string.
]]
local function indentLines(lines, indentLevel)
	local outputBuffer = {}

	for _, line in ipairs(lines) do
		table.insert(outputBuffer, indent(line, indentLevel))
	end

	return table.concat(outputBuffer, "\n")
end

local logInfoMetatable = {}

--[[
	Automatic coercion to strings for LogInfo objects to enable debugging them
	more easily.
]]
function logInfoMetatable:__tostring()
	local outputBuffer = {"LogInfo {"}

	local errorCount = #self.errors
	local warningCount = #self.warnings
	local infosCount = #self.infos

	if errorCount + warningCount + infosCount == 0 then
		table.insert(outputBuffer, "\t(no messages)")
	end

	if errorCount > 0 then
		table.insert(outputBuffer, ("\tErrors (%d) {"):format(errorCount))
		table.insert(outputBuffer, indentLines(self.errors, 2))
		table.insert(outputBuffer, "\t}")
	end

	if warningCount > 0 then
		table.insert(outputBuffer, ("\tWarnings (%d) {"):format(warningCount))
		table.insert(outputBuffer, indentLines(self.warnings, 2))
		table.insert(outputBuffer, "\t}")
	end

	if infosCount > 0 then
		table.insert(outputBuffer, ("\tInfos (%d) {"):format(infosCount))
		table.insert(outputBuffer, indentLines(self.infos, 2))
		table.insert(outputBuffer, "\t}")
	end

	table.insert(outputBuffer, "}")

	return table.concat(outputBuffer, "\n")
end

local function createLogInfo()
	local logInfo = {
		errors = {},
		warnings = {},
		infos = {},
	}

	setmetatable(logInfo, logInfoMetatable)

	return logInfo
end

local Logging = {}

--[[
	Invokes `callback`, capturing all output that happens during its execution.

	Output will not go to stdout or stderr and will instead be put into a
	LogInfo object that is returned. If `callback` throws, the error will be
	bubbled up to the caller of `Logging.capture`.
]]
function Logging.capture(callback)
	local collector = createLogInfo()

	local wasOutputEnabled = outputEnabled
	outputEnabled = false
	collectors[collector] = true

	local success, result = pcall(callback)

	collectors[collector] = nil
	outputEnabled = wasOutputEnabled

	assert(success, result)

	return collector
end

--[[
	Issues a warning with an automatically attached stack trace.
]]
function Logging.warn(messageTemplate, ...)
	local message = messageTemplate:format(...)

	for collector in pairs(collectors) do
		table.insert(collector.warnings, message)
	end

	-- debug.traceback inserts a leading newline, so we trim it here
	local trace = debug.traceback("", 2):sub(2)
	local fullMessage = ("%s\n%s"):format(message, indent(trace, 1))

	if outputEnabled then
		warn(fullMessage)
	end
end

--[[
	Issues a warning like `Logging.warn`, but only outputs once per call site.

	This is useful for marking deprecated functions that might be called a lot;
	using `warnOnce` instead of `warn` will reduce output noise while still
	correctly marking all call sites.
]]
function Logging.warnOnce(messageTemplate, ...)
	local trace = debug.traceback()

	if onceUsedLocations[trace] then
		return
	end

	onceUsedLocations[trace] = true
	Logging.warn(messageTemplate, ...)
end

return Logging end, _env("RemoteSpy.include.node_modules.roact.src.Logging"))() end)

_module("None", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.None", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local Symbol = require(script.Parent.Symbol)

-- Marker used to specify that the value is nothing, because nil cannot be
-- stored in tables.
local None = Symbol.named("None")

return None end, _env("RemoteSpy.include.node_modules.roact.src.None"))() end)

_module("NoopRenderer", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.NoopRenderer", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Reference renderer intended for use in tests as well as for documenting the
	minimum required interface for a Roact renderer.
]]

local NoopRenderer = {}

function NoopRenderer.isHostObject(target)
	-- Attempting to use NoopRenderer to target a Roblox instance is almost
	-- certainly a mistake.
	return target == nil
end

function NoopRenderer.mountHostNode(reconciler, node)
end

function NoopRenderer.unmountHostNode(reconciler, node)
end

function NoopRenderer.updateHostNode(reconciler, node, newElement)
	return node
end

return NoopRenderer end, _env("RemoteSpy.include.node_modules.roact.src.NoopRenderer"))() end)

_module("Portal", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.Portal", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local Symbol = require(script.Parent.Symbol)

local Portal = Symbol.named("Portal")

return Portal end, _env("RemoteSpy.include.node_modules.roact.src.Portal"))() end)

_instance("PropMarkers", "Folder", "RemoteSpy.include.node_modules.roact.src.PropMarkers", "RemoteSpy.include.node_modules.roact.src")

_module("Change", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.PropMarkers.Change", "RemoteSpy.include.node_modules.roact.src.PropMarkers", function () return setfenv(function() --[[
	Change is used to generate special prop keys that can be used to connect to
	GetPropertyChangedSignal.

	Generally, Change is indexed by a Roblox property name:

		Roact.createElement("TextBox", {
			[Roact.Change.Text] = function(rbx)
				print("The TextBox", rbx, "changed text to", rbx.Text)
			end,
		})
]]

local Type = require(script.Parent.Parent.Type)

local Change = {}

local changeMetatable = {
	__tostring = function(self)
		return ("RoactHostChangeEvent(%s)"):format(self.name)
	end,
}

setmetatable(Change, {
	__index = function(self, propertyName)
		local changeListener = {
			[Type] = Type.HostChangeEvent,
			name = propertyName,
		}

		setmetatable(changeListener, changeMetatable)
		Change[propertyName] = changeListener

		return changeListener
	end,
})

return Change
 end, _env("RemoteSpy.include.node_modules.roact.src.PropMarkers.Change"))() end)

_module("Children", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.PropMarkers.Children", "RemoteSpy.include.node_modules.roact.src.PropMarkers", function () return setfenv(function() local Symbol = require(script.Parent.Parent.Symbol)

local Children = Symbol.named("Children")

return Children end, _env("RemoteSpy.include.node_modules.roact.src.PropMarkers.Children"))() end)

_module("Event", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.PropMarkers.Event", "RemoteSpy.include.node_modules.roact.src.PropMarkers", function () return setfenv(function() --[[
	Index into `Event` to get a prop key for attaching to an event on a Roblox
	Instance.

	Example:

		Roact.createElement("TextButton", {
			Text = "Hello, world!",

			[Roact.Event.MouseButton1Click] = function(rbx)
				print("Clicked", rbx)
			end
		})
]]

local Type = require(script.Parent.Parent.Type)

local Event = {}

local eventMetatable = {
	__tostring = function(self)
		return ("RoactHostEvent(%s)"):format(self.name)
	end,
}

setmetatable(Event, {
	__index = function(self, eventName)
		local event = {
			[Type] = Type.HostEvent,
			name = eventName,
		}

		setmetatable(event, eventMetatable)

		Event[eventName] = event

		return event
	end,
})

return Event
 end, _env("RemoteSpy.include.node_modules.roact.src.PropMarkers.Event"))() end)

_module("Ref", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.PropMarkers.Ref", "RemoteSpy.include.node_modules.roact.src.PropMarkers", function () return setfenv(function() local Symbol = require(script.Parent.Parent.Symbol)

local Ref = Symbol.named("Ref")

return Ref end, _env("RemoteSpy.include.node_modules.roact.src.PropMarkers.Ref"))() end)

_module("PureComponent", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.PureComponent", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	A version of Component with a `shouldUpdate` method that forces the
	resulting component to be pure.
]]

local Component = require(script.Parent.Component)

local PureComponent = Component:extend("PureComponent")

-- When extend()ing a component, you don't get an extend method.
-- This is to promote composition over inheritance.
-- PureComponent is an exception to this rule.
PureComponent.extend = Component.extend

function PureComponent:shouldUpdate(newProps, newState)
	-- In a vast majority of cases, if state updated, something has updated.
	-- We don't bother checking in this case.
	if newState ~= self.state then
		return true
	end

	if newProps == self.props then
		return false
	end

	for key, value in pairs(newProps) do
		if self.props[key] ~= value then
			return true
		end
	end

	for key, value in pairs(self.props) do
		if newProps[key] ~= value then
			return true
		end
	end

	return false
end

return PureComponent end, _env("RemoteSpy.include.node_modules.roact.src.PureComponent"))() end)

_module("RobloxRenderer", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.RobloxRenderer", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Renderer that deals in terms of Roblox Instances. This is the most
	well-supported renderer after NoopRenderer and is currently the only
	renderer that does anything.
]]

local Binding = require(script.Parent.Binding)
local Children = require(script.Parent.PropMarkers.Children)
local ElementKind = require(script.Parent.ElementKind)
local SingleEventManager = require(script.Parent.SingleEventManager)
local getDefaultInstanceProperty = require(script.Parent.getDefaultInstanceProperty)
local Ref = require(script.Parent.PropMarkers.Ref)
local Type = require(script.Parent.Type)
local internalAssert = require(script.Parent.internalAssert)

local config = require(script.Parent.GlobalConfig).get()

local applyPropsError = [[
Error applying props:
	%s
In element:
%s
]]

local updatePropsError = [[
Error updating props:
	%s
In element:
%s
]]

local function identity(...)
	return ...
end

local function applyRef(ref, newHostObject)
	if ref == nil then
		return
	end

	if typeof(ref) == "function" then
		ref(newHostObject)
	elseif Type.of(ref) == Type.Binding then
		Binding.update(ref, newHostObject)
	else
		-- TODO (#197): Better error message
		error(("Invalid ref: Expected type Binding but got %s"):format(
			typeof(ref)
		))
	end
end

local function setRobloxInstanceProperty(hostObject, key, newValue)
	if newValue == nil then
		local hostClass = hostObject.ClassName
		local _, defaultValue = getDefaultInstanceProperty(hostClass, key)
		newValue = defaultValue
	end

	-- Assign the new value to the object
	hostObject[key] = newValue

	return
end

local function removeBinding(virtualNode, key)
	local disconnect = virtualNode.bindings[key]
	disconnect()
	virtualNode.bindings[key] = nil
end

local function attachBinding(virtualNode, key, newBinding)
	local function updateBoundProperty(newValue)
		local success, errorMessage = xpcall(function()
			setRobloxInstanceProperty(virtualNode.hostObject, key, newValue)
		end, identity)

		if not success then
			local source = virtualNode.currentElement.source

			if source == nil then
				source = "<enable element tracebacks>"
			end

			local fullMessage = updatePropsError:format(errorMessage, source)
			error(fullMessage, 0)
		end
	end

	if virtualNode.bindings == nil then
		virtualNode.bindings = {}
	end

	virtualNode.bindings[key] = Binding.subscribe(newBinding, updateBoundProperty)

	updateBoundProperty(newBinding:getValue())
end

local function detachAllBindings(virtualNode)
	if virtualNode.bindings ~= nil then
		for _, disconnect in pairs(virtualNode.bindings) do
			disconnect()
		end
	end
end

local function applyProp(virtualNode, key, newValue, oldValue)
	if newValue == oldValue then
		return
	end

	if key == Ref or key == Children then
		-- Refs and children are handled in a separate pass
		return
	end

	local internalKeyType = Type.of(key)

	if internalKeyType == Type.HostEvent or internalKeyType == Type.HostChangeEvent then
		if virtualNode.eventManager == nil then
			virtualNode.eventManager = SingleEventManager.new(virtualNode.hostObject)
		end

		local eventName = key.name

		if internalKeyType == Type.HostChangeEvent then
			virtualNode.eventManager:connectPropertyChange(eventName, newValue)
		else
			virtualNode.eventManager:connectEvent(eventName, newValue)
		end

		return
	end

	local newIsBinding = Type.of(newValue) == Type.Binding
	local oldIsBinding = Type.of(oldValue) == Type.Binding

	if oldIsBinding then
		removeBinding(virtualNode, key)
	end

	if newIsBinding then
		attachBinding(virtualNode, key, newValue)
	else
		setRobloxInstanceProperty(virtualNode.hostObject, key, newValue)
	end
end

local function applyProps(virtualNode, props)
	for propKey, value in pairs(props) do
		applyProp(virtualNode, propKey, value, nil)
	end
end

local function updateProps(virtualNode, oldProps, newProps)
	-- Apply props that were added or updated
	for propKey, newValue in pairs(newProps) do
		local oldValue = oldProps[propKey]

		applyProp(virtualNode, propKey, newValue, oldValue)
	end

	-- Clean up props that were removed
	for propKey, oldValue in pairs(oldProps) do
		local newValue = newProps[propKey]

		if newValue == nil then
			applyProp(virtualNode, propKey, nil, oldValue)
		end
	end
end

local RobloxRenderer = {}

function RobloxRenderer.isHostObject(target)
	return typeof(target) == "Instance"
end

function RobloxRenderer.mountHostNode(reconciler, virtualNode)
	local element = virtualNode.currentElement
	local hostParent = virtualNode.hostParent
	local hostKey = virtualNode.hostKey

	if config.internalTypeChecks then
		internalAssert(ElementKind.of(element) == ElementKind.Host, "Element at given node is not a host Element")
	end
	if config.typeChecks then
		assert(element.props.Name == nil, "Name can not be specified as a prop to a host component in Roact.")
		assert(element.props.Parent == nil, "Parent can not be specified as a prop to a host component in Roact.")
	end

	local instance = Instance.new(element.component)
	virtualNode.hostObject = instance

	local success, errorMessage = xpcall(function()
		applyProps(virtualNode, element.props)
	end, identity)

	if not success then
		local source = element.source

		if source == nil then
			source = "<enable element tracebacks>"
		end

		local fullMessage = applyPropsError:format(errorMessage, source)
		error(fullMessage, 0)
	end

	instance.Name = tostring(hostKey)

	local children = element.props[Children]

	if children ~= nil then
		reconciler.updateVirtualNodeWithChildren(virtualNode, virtualNode.hostObject, children)
	end

	instance.Parent = hostParent
	virtualNode.hostObject = instance

	applyRef(element.props[Ref], instance)

	if virtualNode.eventManager ~= nil then
		virtualNode.eventManager:resume()
	end
end

function RobloxRenderer.unmountHostNode(reconciler, virtualNode)
	local element = virtualNode.currentElement

	applyRef(element.props[Ref], nil)

	for _, childNode in pairs(virtualNode.children) do
		reconciler.unmountVirtualNode(childNode)
	end

	detachAllBindings(virtualNode)

	virtualNode.hostObject:Destroy()
end

function RobloxRenderer.updateHostNode(reconciler, virtualNode, newElement)
	local oldProps = virtualNode.currentElement.props
	local newProps = newElement.props

	if virtualNode.eventManager ~= nil then
		virtualNode.eventManager:suspend()
	end

	-- If refs changed, detach the old ref and attach the new one
	if oldProps[Ref] ~= newProps[Ref] then
		applyRef(oldProps[Ref], nil)
		applyRef(newProps[Ref], virtualNode.hostObject)
	end

	local success, errorMessage = xpcall(function()
		updateProps(virtualNode, oldProps, newProps)
	end, identity)

	if not success then
		local source = newElement.source

		if source == nil then
			source = "<enable element tracebacks>"
		end

		local fullMessage = updatePropsError:format(errorMessage, source)
		error(fullMessage, 0)
	end

	local children = newElement.props[Children]
	if children ~= nil or oldProps[Children] ~= nil then
		reconciler.updateVirtualNodeWithChildren(virtualNode, virtualNode.hostObject, children)
	end

	if virtualNode.eventManager ~= nil then
		virtualNode.eventManager:resume()
	end

	return virtualNode
end

return RobloxRenderer
 end, _env("RemoteSpy.include.node_modules.roact.src.RobloxRenderer"))() end)

_module("SingleEventManager", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.SingleEventManager", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	A manager for a single host virtual node's connected events.
]]

local Logging = require(script.Parent.Logging)

local CHANGE_PREFIX = "Change."

local EventStatus = {
	-- No events are processed at all; they're silently discarded
	Disabled = "Disabled",

	-- Events are stored in a queue; listeners are invoked when the manager is resumed
	Suspended = "Suspended",

	-- Event listeners are invoked as the events fire
	Enabled = "Enabled",
}

local SingleEventManager = {}
SingleEventManager.__index = SingleEventManager

function SingleEventManager.new(instance)
	local self = setmetatable({
		-- The queue of suspended events
		_suspendedEventQueue = {},

		-- All the event connections being managed
		-- Events are indexed by a string key
		_connections = {},

		-- All the listeners being managed
		-- These are stored distinctly from the connections
		-- Connections can have their listeners replaced at runtime
		_listeners = {},

		-- The suspension status of the manager
		-- Managers start disabled and are "resumed" after the initial render
		_status = EventStatus.Disabled,

		-- If true, the manager is processing queued events right now.
		_isResuming = false,

		-- The Roblox instance the manager is managing
		_instance = instance,
	}, SingleEventManager)

	return self
end

function SingleEventManager:connectEvent(key, listener)
	self:_connect(key, self._instance[key], listener)
end

function SingleEventManager:connectPropertyChange(key, listener)
	local success, event = pcall(function()
		return self._instance:GetPropertyChangedSignal(key)
	end)

	if not success then
		error(("Cannot get changed signal on property %q: %s"):format(
			tostring(key),
			event
		), 0)
	end

	self:_connect(CHANGE_PREFIX .. key, event, listener)
end

function SingleEventManager:_connect(eventKey, event, listener)
	-- If the listener doesn't exist we can just disconnect the existing connection
	if listener == nil then
		if self._connections[eventKey] ~= nil then
			self._connections[eventKey]:Disconnect()
			self._connections[eventKey] = nil
		end

		self._listeners[eventKey] = nil
	else
		if self._connections[eventKey] == nil then
			self._connections[eventKey] = event:Connect(function(...)
				if self._status == EventStatus.Enabled then
					self._listeners[eventKey](self._instance, ...)
				elseif self._status == EventStatus.Suspended then
					-- Store this event invocation to be fired when resume is
					-- called.

					local argumentCount = select("#", ...)
					table.insert(self._suspendedEventQueue, { eventKey, argumentCount, ... })
				end
			end)
		end

		self._listeners[eventKey] = listener
	end
end

function SingleEventManager:suspend()
	self._status = EventStatus.Suspended
end

function SingleEventManager:resume()
	-- If we're already resuming events for this instance, trying to resume
	-- again would cause a disaster.
	if self._isResuming then
		return
	end

	self._isResuming = true

	local index = 1

	-- More events might be added to the queue when evaluating events, so we
	-- need to be careful in order to preserve correct evaluation order.
	while index <= #self._suspendedEventQueue do
		local eventInvocation = self._suspendedEventQueue[index]
		local listener = self._listeners[eventInvocation[1]]
		local argumentCount = eventInvocation[2]

		-- The event might have been disconnected since suspension started; in
		-- this case, we drop the event.
		if listener ~= nil then
			-- Wrap the listener in a coroutine to catch errors and handle
			-- yielding correctly.
			local listenerCo = coroutine.create(listener)
			local success, result = coroutine.resume(
				listenerCo,
				self._instance,
				unpack(eventInvocation, 3, 2 + argumentCount))

			-- If the listener threw an error, we log it as a warning, since
			-- there's no way to write error text in Roblox Lua without killing
			-- our thread!
			if not success then
				Logging.warn("%s", result)
			end
		end

		index = index + 1
	end

	self._isResuming = false
	self._status = EventStatus.Enabled
	self._suspendedEventQueue = {}
end

return SingleEventManager end, _env("RemoteSpy.include.node_modules.roact.src.SingleEventManager"))() end)

_module("Symbol", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.Symbol", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	A 'Symbol' is an opaque marker type.

	Symbols have the type 'userdata', but when printed to the console, the name
	of the symbol is shown.
]]

local Symbol = {}

--[[
	Creates a Symbol with the given name.

	When printed or coerced to a string, the symbol will turn into the string
	given as its name.
]]
function Symbol.named(name)
	assert(type(name) == "string", "Symbols must be created using a string name!")

	local self = newproxy(true)

	local wrappedName = ("Symbol(%s)"):format(name)

	getmetatable(self).__tostring = function()
		return wrappedName
	end

	return self
end

return Symbol end, _env("RemoteSpy.include.node_modules.roact.src.Symbol"))() end)

_module("Type", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.Type", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Contains markers for annotating objects with types.

	To set the type of an object, use `Type` as a key and the actual marker as
	the value:

		local foo = {
			[Type] = Type.Foo,
		}
]]

local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)

local Type = newproxy(true)

local TypeInternal = {}

local function addType(name)
	TypeInternal[name] = Symbol.named("Roact" .. name)
end

addType("Binding")
addType("Element")
addType("HostChangeEvent")
addType("HostEvent")
addType("StatefulComponentClass")
addType("StatefulComponentInstance")
addType("VirtualNode")
addType("VirtualTree")

function TypeInternal.of(value)
	if typeof(value) ~= "table" then
		return nil
	end

	return value[Type]
end

getmetatable(Type).__index = TypeInternal

getmetatable(Type).__tostring = function()
	return "RoactType"
end

strict(TypeInternal, "Type")

return Type end, _env("RemoteSpy.include.node_modules.roact.src.Type"))() end)

_module("assertDeepEqual", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.assertDeepEqual", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	A utility used to assert that two objects are value-equal recursively. It
	outputs fairly nicely formatted messages to help diagnose why two objects
	would be different.

	This should only be used in tests.
]]

local function deepEqual(a, b)
	if typeof(a) ~= typeof(b) then
		local message = ("{1} is of type %s, but {2} is of type %s"):format(
			typeof(a),
			typeof(b)
		)
		return false, message
	end

	if typeof(a) == "table" then
		local visitedKeys = {}

		for key, value in pairs(a) do
			visitedKeys[key] = true

			local success, innerMessage = deepEqual(value, b[key])
			if not success then
				local message = innerMessage
					:gsub("{1}", ("{1}[%s]"):format(tostring(key)))
					:gsub("{2}", ("{2}[%s]"):format(tostring(key)))

				return false, message
			end
		end

		for key, value in pairs(b) do
			if not visitedKeys[key] then
				local success, innerMessage = deepEqual(value, a[key])

				if not success then
					local message = innerMessage
						:gsub("{1}", ("{1}[%s]"):format(tostring(key)))
						:gsub("{2}", ("{2}[%s]"):format(tostring(key)))

					return false, message
				end
			end
		end

		return true
	end

	if a == b then
		return true
	end

	local message = "{1} ~= {2}"
	return false, message
end

local function assertDeepEqual(a, b)
	local success, innerMessageTemplate = deepEqual(a, b)

	if not success then
		local innerMessage = innerMessageTemplate
			:gsub("{1}", "first")
			:gsub("{2}", "second")

		local message = ("Values were not deep-equal.\n%s"):format(innerMessage)

		error(message, 2)
	end
end

return assertDeepEqual end, _env("RemoteSpy.include.node_modules.roact.src.assertDeepEqual"))() end)

_module("assign", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.assign", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local None = require(script.Parent.None)

--[[
	Merges values from zero or more tables onto a target table. If a value is
	set to None, it will instead be removed from the table.

	This function is identical in functionality to JavaScript's Object.assign.
]]
local function assign(target, ...)
	for index = 1, select("#", ...) do
		local source = select(index, ...)

		if source ~= nil then
			for key, value in pairs(source) do
				if value == None then
					target[key] = nil
				else
					target[key] = value
				end
			end
		end
	end

	return target
end

return assign end, _env("RemoteSpy.include.node_modules.roact.src.assign"))() end)

_module("createContext", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.createContext", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local Symbol = require(script.Parent.Symbol)
local createFragment = require(script.Parent.createFragment)
local createSignal = require(script.Parent.createSignal)
local Children = require(script.Parent.PropMarkers.Children)
local Component = require(script.Parent.Component)

--[[
	Construct the value that is assigned to Roact's context storage.
]]
local function createContextEntry(currentValue)
	return {
		value = currentValue,
		onUpdate = createSignal(),
	}
end

local function createProvider(context)
	local Provider = Component:extend("Provider")

	function Provider:init(props)
		self.contextEntry = createContextEntry(props.value)
		self:__addContext(context.key, self.contextEntry)
	end

	function Provider:willUpdate(nextProps)
		-- If the provided value changed, immediately update the context entry.
		--
		-- During this update, any components that are reachable will receive
		-- this updated value at the same time as any props and state updates
		-- that are being applied.
		if nextProps.value ~= self.props.value then
			self.contextEntry.value = nextProps.value
		end
	end

	function Provider:didUpdate(prevProps)
		-- If the provided value changed, after we've updated every reachable
		-- component, fire a signal to update the rest.
		--
		-- This signal will notify all context consumers. It's expected that
		-- they will compare the last context value they updated with and only
		-- trigger an update on themselves if this value is different.
		--
		-- This codepath will generally only update consumer components that has
		-- a component implementing shouldUpdate between them and the provider.
		if prevProps.value ~= self.props.value then
			self.contextEntry.onUpdate:fire(self.props.value)
		end
	end

	function Provider:render()
		return createFragment(self.props[Children])
	end

	return Provider
end

local function createConsumer(context)
	local Consumer = Component:extend("Consumer")

	function Consumer.validateProps(props)
		if type(props.render) ~= "function" then
			return false, "Consumer expects a `render` function"
		else
			return true
		end
	end

	function Consumer:init(props)
		-- This value may be nil, which indicates that our consumer is not a
		-- descendant of a provider for this context item.
		self.contextEntry = self:__getContext(context.key)
	end

	function Consumer:render()
		-- Render using the latest available for this context item.
		--
		-- We don't store this value in state in order to have more fine-grained
		-- control over our update behavior.
		local value
		if self.contextEntry ~= nil then
			value = self.contextEntry.value
		else
			value = context.defaultValue
		end

		return self.props.render(value)
	end

	function Consumer:didUpdate()
		-- Store the value that we most recently updated with.
		--
		-- This value is compared in the contextEntry onUpdate hook below.
		if self.contextEntry ~= nil then
			self.lastValue = self.contextEntry.value
		end
	end

	function Consumer:didMount()
		if self.contextEntry ~= nil then
			-- When onUpdate is fired, a new value has been made available in
			-- this context entry, but we may have already updated in the same
			-- update cycle.
			--
			-- To avoid sending a redundant update, we compare the new value
			-- with the last value that we updated with (set in didUpdate) and
			-- only update if they differ. This may happen when an update from a
			-- provider was blocked by an intermediate component that returned
			-- false from shouldUpdate.
			self.disconnect = self.contextEntry.onUpdate:subscribe(function(newValue)
				if newValue ~= self.lastValue then
					-- Trigger a dummy state update.
					self:setState({})
				end
			end)
		end
	end

	function Consumer:willUnmount()
		if self.disconnect ~= nil then
			self.disconnect()
		end
	end

	return Consumer
end

local Context = {}
Context.__index = Context

function Context.new(defaultValue)
	return setmetatable({
		defaultValue = defaultValue,
		key = Symbol.named("ContextKey"),
	}, Context)
end

function Context:__tostring()
	return "RoactContext"
end

local function createContext(defaultValue)
	local context = Context.new(defaultValue)

	return {
		Provider = createProvider(context),
		Consumer = createConsumer(context),
	}
end

return createContext
 end, _env("RemoteSpy.include.node_modules.roact.src.createContext"))() end)

_module("createElement", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.createElement", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local Children = require(script.Parent.PropMarkers.Children)
local ElementKind = require(script.Parent.ElementKind)
local Logging = require(script.Parent.Logging)
local Type = require(script.Parent.Type)

local config = require(script.Parent.GlobalConfig).get()

local multipleChildrenMessage = [[
The prop `Roact.Children` was defined but was overriden by the third parameter to createElement!
This can happen when a component passes props through to a child element but also uses the `children` argument:

	Roact.createElement("Frame", passedProps, {
		child = ...
	})

Instead, consider using a utility function to merge tables of children together:

	local children = mergeTables(passedProps[Roact.Children], {
		child = ...
	})

	local fullProps = mergeTables(passedProps, {
		[Roact.Children] = children
	})

	Roact.createElement("Frame", fullProps)]]

--[[
	Creates a new element representing the given component.

	Elements are lightweight representations of what a component instance should
	look like.

	Children is a shorthand for specifying `Roact.Children` as a key inside
	props. If specified, the passed `props` table is mutated!
]]
local function createElement(component, props, children)
	if config.typeChecks then
		assert(component ~= nil, "`component` is required")
		assert(typeof(props) == "table" or props == nil, "`props` must be a table or nil")
		assert(typeof(children) == "table" or children == nil, "`children` must be a table or nil")
	end

	if props == nil then
		props = {}
	end

	if children ~= nil then
		if props[Children] ~= nil then
			Logging.warnOnce(multipleChildrenMessage)
		end

		props[Children] = children
	end

	local elementKind = ElementKind.fromComponent(component)

	local element = {
		[Type] = Type.Element,
		[ElementKind] = elementKind,
		component = component,
		props = props,
	}

	if config.elementTracing then
		-- We trim out the leading newline since there's no way to specify the
		-- trace level without also specifying a message.
		element.source = debug.traceback("", 2):sub(2)
	end

	return element
end

return createElement end, _env("RemoteSpy.include.node_modules.roact.src.createElement"))() end)

_module("createFragment", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.createFragment", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local ElementKind = require(script.Parent.ElementKind)
local Type = require(script.Parent.Type)

local function createFragment(elements)
	return {
		[Type] = Type.Element,
		[ElementKind] = ElementKind.Fragment,
		elements = elements,
	}
end

return createFragment end, _env("RemoteSpy.include.node_modules.roact.src.createFragment"))() end)

_module("createReconciler", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.createReconciler", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local Type = require(script.Parent.Type)
local ElementKind = require(script.Parent.ElementKind)
local ElementUtils = require(script.Parent.ElementUtils)
local Children = require(script.Parent.PropMarkers.Children)
local Symbol = require(script.Parent.Symbol)
local internalAssert = require(script.Parent.internalAssert)

local config = require(script.Parent.GlobalConfig).get()

local InternalData = Symbol.named("InternalData")

--[[
	The reconciler is the mechanism in Roact that constructs the virtual tree
	that later gets turned into concrete objects by the renderer.

	Roact's reconciler is constructed with the renderer as an argument, which
	enables switching to different renderers for different platforms or
	scenarios.

	When testing the reconciler itself, it's common to use `NoopRenderer` with
	spies replacing some methods. The default (and only) reconciler interface
	exposed by Roact right now uses `RobloxRenderer`.
]]
local function createReconciler(renderer)
	local reconciler
	local mountVirtualNode
	local updateVirtualNode
	local unmountVirtualNode

	--[[
		Unmount the given virtualNode, replacing it with a new node described by
		the given element.

		Preserves host properties, depth, and legacyContext from parent.
	]]
	local function replaceVirtualNode(virtualNode, newElement)
		local hostParent = virtualNode.hostParent
		local hostKey = virtualNode.hostKey
		local depth = virtualNode.depth
		local parent = virtualNode.parent

		-- If the node that is being replaced has modified context, we need to
		-- use the original *unmodified* context for the new node
		-- The `originalContext` field will be nil if the context was unchanged
		local context = virtualNode.originalContext or virtualNode.context
		local parentLegacyContext = virtualNode.parentLegacyContext

		unmountVirtualNode(virtualNode)
		local newNode = mountVirtualNode(newElement, hostParent, hostKey, context, parentLegacyContext)

		-- mountVirtualNode can return nil if the element is a boolean
		if newNode ~= nil then
			newNode.depth = depth
			newNode.parent = parent
		end

		return newNode
	end

	--[[
		Utility to update the children of a virtual node based on zero or more
		updated children given as elements.
	]]
	local function updateChildren(virtualNode, hostParent, newChildElements)
		if config.internalTypeChecks then
			internalAssert(Type.of(virtualNode) == Type.VirtualNode, "Expected arg #1 to be of type VirtualNode")
		end

		local removeKeys = {}

		-- Changed or removed children
		for childKey, childNode in pairs(virtualNode.children) do
			local newElement = ElementUtils.getElementByKey(newChildElements, childKey)
			local newNode = updateVirtualNode(childNode, newElement)

			if newNode ~= nil then
				virtualNode.children[childKey] = newNode
			else
				removeKeys[childKey] = true
			end
		end

		for childKey in pairs(removeKeys) do
			virtualNode.children[childKey] = nil
		end

		-- Added children
		for childKey, newElement in ElementUtils.iterateElements(newChildElements) do
			local concreteKey = childKey
			if childKey == ElementUtils.UseParentKey then
				concreteKey = virtualNode.hostKey
			end

			if virtualNode.children[childKey] == nil then
				local childNode = mountVirtualNode(
					newElement,
					hostParent,
					concreteKey,
					virtualNode.context,
					virtualNode.legacyContext
				)

				-- mountVirtualNode can return nil if the element is a boolean
				if childNode ~= nil then
					childNode.depth = virtualNode.depth + 1
					childNode.parent = virtualNode
					virtualNode.children[childKey] = childNode
				end
			end
		end
	end

	local function updateVirtualNodeWithChildren(virtualNode, hostParent, newChildElements)
		updateChildren(virtualNode, hostParent, newChildElements)
	end

	local function updateVirtualNodeWithRenderResult(virtualNode, hostParent, renderResult)
		if Type.of(renderResult) == Type.Element
			or renderResult == nil
			or typeof(renderResult) == "boolean"
		then
			updateChildren(virtualNode, hostParent, renderResult)
		else
			error(("%s\n%s"):format(
				"Component returned invalid children:",
				virtualNode.currentElement.source or "<enable element tracebacks>"
			), 0)
		end
	end

	--[[
		Unmounts the given virtual node and releases any held resources.
	]]
	function unmountVirtualNode(virtualNode)
		if config.internalTypeChecks then
			internalAssert(Type.of(virtualNode) == Type.VirtualNode, "Expected arg #1 to be of type VirtualNode")
		end

		local kind = ElementKind.of(virtualNode.currentElement)

		if kind == ElementKind.Host then
			renderer.unmountHostNode(reconciler, virtualNode)
		elseif kind == ElementKind.Function then
			for _, childNode in pairs(virtualNode.children) do
				unmountVirtualNode(childNode)
			end
		elseif kind == ElementKind.Stateful then
			virtualNode.instance:__unmount()
		elseif kind == ElementKind.Portal then
			for _, childNode in pairs(virtualNode.children) do
				unmountVirtualNode(childNode)
			end
		elseif kind == ElementKind.Fragment then
			for _, childNode in pairs(virtualNode.children) do
				unmountVirtualNode(childNode)
			end
		else
			error(("Unknown ElementKind %q"):format(tostring(kind)), 2)
		end
	end

	local function updateFunctionVirtualNode(virtualNode, newElement)
		local children = newElement.component(newElement.props)

		updateVirtualNodeWithRenderResult(virtualNode, virtualNode.hostParent, children)

		return virtualNode
	end

	local function updatePortalVirtualNode(virtualNode, newElement)
		local oldElement = virtualNode.currentElement
		local oldTargetHostParent = oldElement.props.target

		local targetHostParent = newElement.props.target

		assert(renderer.isHostObject(targetHostParent), "Expected target to be host object")

		if targetHostParent ~= oldTargetHostParent then
			return replaceVirtualNode(virtualNode, newElement)
		end

		local children = newElement.props[Children]

		updateVirtualNodeWithChildren(virtualNode, targetHostParent, children)

		return virtualNode
	end

	local function updateFragmentVirtualNode(virtualNode, newElement)
		updateVirtualNodeWithChildren(virtualNode, virtualNode.hostParent, newElement.elements)

		return virtualNode
	end

	--[[
		Update the given virtual node using a new element describing what it
		should transform into.

		`updateVirtualNode` will return a new virtual node that should replace
		the passed in virtual node. This is because a virtual node can be
		updated with an element referencing a different component!

		In that case, `updateVirtualNode` will unmount the input virtual node,
		mount a new virtual node, and return it in this case, while also issuing
		a warning to the user.
	]]
	function updateVirtualNode(virtualNode, newElement, newState)
		if config.internalTypeChecks then
			internalAssert(Type.of(virtualNode) == Type.VirtualNode, "Expected arg #1 to be of type VirtualNode")
		end
		if config.typeChecks then
			assert(
				Type.of(newElement) == Type.Element or typeof(newElement) == "boolean" or newElement == nil,
				"Expected arg #2 to be of type Element, boolean, or nil"
			)
		end

		-- If nothing changed, we can skip this update
		if virtualNode.currentElement == newElement and newState == nil then
			return virtualNode
		end

		if typeof(newElement) == "boolean" or newElement == nil then
			unmountVirtualNode(virtualNode)
			return nil
		end

		if virtualNode.currentElement.component ~= newElement.component then
			return replaceVirtualNode(virtualNode, newElement)
		end

		local kind = ElementKind.of(newElement)

		local shouldContinueUpdate = true

		if kind == ElementKind.Host then
			virtualNode = renderer.updateHostNode(reconciler, virtualNode, newElement)
		elseif kind == ElementKind.Function then
			virtualNode = updateFunctionVirtualNode(virtualNode, newElement)
		elseif kind == ElementKind.Stateful then
			shouldContinueUpdate = virtualNode.instance:__update(newElement, newState)
		elseif kind == ElementKind.Portal then
			virtualNode = updatePortalVirtualNode(virtualNode, newElement)
		elseif kind == ElementKind.Fragment then
			virtualNode = updateFragmentVirtualNode(virtualNode, newElement)
		else
			error(("Unknown ElementKind %q"):format(tostring(kind)), 2)
		end

		-- Stateful components can abort updates via shouldUpdate. If that
		-- happens, we should stop doing stuff at this point.
		if not shouldContinueUpdate then
			return virtualNode
		end

		virtualNode.currentElement = newElement

		return virtualNode
	end

	--[[
		Constructs a new virtual node but not does mount it.
	]]
	local function createVirtualNode(element, hostParent, hostKey, context, legacyContext)
		if config.internalTypeChecks then
			internalAssert(renderer.isHostObject(hostParent) or hostParent == nil, "Expected arg #2 to be a host object")
			internalAssert(typeof(context) == "table" or context == nil, "Expected arg #4 to be of type table or nil")
			internalAssert(
				typeof(legacyContext) == "table" or legacyContext == nil,
				"Expected arg #5 to be of type table or nil"
			)
		end
		if config.typeChecks then
			assert(hostKey ~= nil, "Expected arg #3 to be non-nil")
			assert(
				Type.of(element) == Type.Element or typeof(element) == "boolean",
				"Expected arg #1 to be of type Element or boolean"
			)
		end

		return {
			[Type] = Type.VirtualNode,
			currentElement = element,
			depth = 1,
			parent = nil,
			children = {},
			hostParent = hostParent,
			hostKey = hostKey,

			-- Legacy Context API
			-- A table of context values inherited from the parent node
			legacyContext = legacyContext,

			-- A saved copy of the parent context, used when replacing a node
			parentLegacyContext = legacyContext,

			-- Context API
			-- A table of context values inherited from the parent node
			context = context or {},

			-- A saved copy of the unmodified context; this will be updated when
			-- a component adds new context and used when a node is replaced
			originalContext = nil,
		}
	end

	local function mountFunctionVirtualNode(virtualNode)
		local element = virtualNode.currentElement

		local children = element.component(element.props)

		updateVirtualNodeWithRenderResult(virtualNode, virtualNode.hostParent, children)
	end

	local function mountPortalVirtualNode(virtualNode)
		local element = virtualNode.currentElement

		local targetHostParent = element.props.target
		local children = element.props[Children]

		assert(renderer.isHostObject(targetHostParent), "Expected target to be host object")

		updateVirtualNodeWithChildren(virtualNode, targetHostParent, children)
	end

	local function mountFragmentVirtualNode(virtualNode)
		local element = virtualNode.currentElement
		local children = element.elements

		updateVirtualNodeWithChildren(virtualNode, virtualNode.hostParent, children)
	end

	--[[
		Constructs a new virtual node and mounts it, but does not place it into
		the tree.
	]]
	function mountVirtualNode(element, hostParent, hostKey, context, legacyContext)
		if config.internalTypeChecks then
			internalAssert(renderer.isHostObject(hostParent) or hostParent == nil, "Expected arg #2 to be a host object")
			internalAssert(
				typeof(legacyContext) == "table" or legacyContext == nil,
				"Expected arg #5 to be of type table or nil"
			)
		end
		if config.typeChecks then
			assert(hostKey ~= nil, "Expected arg #3 to be non-nil")
			assert(
				Type.of(element) == Type.Element or typeof(element) == "boolean",
				"Expected arg #1 to be of type Element or boolean"
			)
		end

		-- Boolean values render as nil to enable terse conditional rendering.
		if typeof(element) == "boolean" then
			return nil
		end

		local kind = ElementKind.of(element)

		local virtualNode = createVirtualNode(element, hostParent, hostKey, context, legacyContext)

		if kind == ElementKind.Host then
			renderer.mountHostNode(reconciler, virtualNode)
		elseif kind == ElementKind.Function then
			mountFunctionVirtualNode(virtualNode)
		elseif kind == ElementKind.Stateful then
			element.component:__mount(reconciler, virtualNode)
		elseif kind == ElementKind.Portal then
			mountPortalVirtualNode(virtualNode)
		elseif kind == ElementKind.Fragment then
			mountFragmentVirtualNode(virtualNode)
		else
			error(("Unknown ElementKind %q"):format(tostring(kind)), 2)
		end

		return virtualNode
	end

	--[[
		Constructs a new Roact virtual tree, constructs a root node for
		it, and mounts it.
	]]
	local function mountVirtualTree(element, hostParent, hostKey)
		if config.typeChecks then
			assert(Type.of(element) == Type.Element, "Expected arg #1 to be of type Element")
			assert(renderer.isHostObject(hostParent) or hostParent == nil, "Expected arg #2 to be a host object")
		end

		if hostKey == nil then
			hostKey = "RoactTree"
		end

		local tree = {
			[Type] = Type.VirtualTree,
			[InternalData] = {
				-- The root node of the tree, which starts into the hierarchy of
				-- Roact component instances.
				rootNode = nil,
				mounted = true,
			},
		}

		tree[InternalData].rootNode = mountVirtualNode(element, hostParent, hostKey)

		return tree
	end

	--[[
		Unmounts the virtual tree, freeing all of its resources.

		No further operations should be done on the tree after it's been
		unmounted, as indicated by its the `mounted` field.
	]]
	local function unmountVirtualTree(tree)
		local internalData = tree[InternalData]
		if config.typeChecks then
			assert(Type.of(tree) == Type.VirtualTree, "Expected arg #1 to be a Roact handle")
			assert(internalData.mounted, "Cannot unmounted a Roact tree that has already been unmounted")
		end

		internalData.mounted = false

		if internalData.rootNode ~= nil then
			unmountVirtualNode(internalData.rootNode)
		end
	end

	--[[
		Utility method for updating the root node of a virtual tree given a new
		element.
	]]
	local function updateVirtualTree(tree, newElement)
		local internalData = tree[InternalData]
		if config.typeChecks then
			assert(Type.of(tree) == Type.VirtualTree, "Expected arg #1 to be a Roact handle")
			assert(Type.of(newElement) == Type.Element, "Expected arg #2 to be a Roact Element")
		end

		internalData.rootNode = updateVirtualNode(internalData.rootNode, newElement)

		return tree
	end

	local function suspendParentEvents(virtualNode)
		local parentNode = virtualNode.parent
		while parentNode do
			if parentNode.eventManager ~= nil then
				parentNode.eventManager:suspend()
			end

			parentNode = parentNode.parent
		end
	end

	local function resumeParentEvents(virtualNode)
		local parentNode = virtualNode.parent
		while parentNode do
			if parentNode.eventManager ~= nil then
				parentNode.eventManager:resume()
			end

			parentNode = parentNode.parent
		end
	end

	reconciler = {
		mountVirtualTree = mountVirtualTree,
		unmountVirtualTree = unmountVirtualTree,
		updateVirtualTree = updateVirtualTree,

		createVirtualNode = createVirtualNode,
		mountVirtualNode = mountVirtualNode,
		unmountVirtualNode = unmountVirtualNode,
		updateVirtualNode = updateVirtualNode,
		updateVirtualNodeWithChildren = updateVirtualNodeWithChildren,
		updateVirtualNodeWithRenderResult = updateVirtualNodeWithRenderResult,

		suspendParentEvents = suspendParentEvents,
		resumeParentEvents = resumeParentEvents,
	}

	return reconciler
end

return createReconciler
 end, _env("RemoteSpy.include.node_modules.roact.src.createReconciler"))() end)

_module("createReconcilerCompat", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.createReconcilerCompat", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Contains deprecated methods from Reconciler. Broken out so that removing
	this shim is easy -- just delete this file and remove it from init.
]]

local Logging = require(script.Parent.Logging)

local reifyMessage = [[
Roact.reify has been renamed to Roact.mount and will be removed in a future release.
Check the call to Roact.reify at:
]]

local teardownMessage = [[
Roact.teardown has been renamed to Roact.unmount and will be removed in a future release.
Check the call to Roact.teardown at:
]]

local reconcileMessage = [[
Roact.reconcile has been renamed to Roact.update and will be removed in a future release.
Check the call to Roact.reconcile at:
]]

local function createReconcilerCompat(reconciler)
	local compat = {}

	function compat.reify(...)
		Logging.warnOnce(reifyMessage)

		return reconciler.mountVirtualTree(...)
	end

	function compat.teardown(...)
		Logging.warnOnce(teardownMessage)

		return reconciler.unmountVirtualTree(...)
	end

	function compat.reconcile(...)
		Logging.warnOnce(reconcileMessage)

		return reconciler.updateVirtualTree(...)
	end

	return compat
end

return createReconcilerCompat end, _env("RemoteSpy.include.node_modules.roact.src.createReconcilerCompat"))() end)

_module("createRef", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.createRef", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	A ref is nothing more than a binding with a special field 'current'
	that maps to the getValue method of the binding
]]
local Binding = require(script.Parent.Binding)

local function createRef()
	local binding, _ = Binding.create(nil)

	local ref = {}

	--[[
		A ref is just redirected to a binding via its metatable
	]]
	setmetatable(ref, {
		__index = function(self, key)
			if key == "current" then
				return binding:getValue()
			else
				return binding[key]
			end
		end,
		__newindex = function(self, key, value)
			if key == "current" then
				error("Cannot assign to the 'current' property of refs", 2)
			end

			binding[key] = value
		end,
		__tostring = function(self)
			return ("RoactRef(%s)"):format(tostring(binding:getValue()))
		end,
	})

	return ref
end

return createRef end, _env("RemoteSpy.include.node_modules.roact.src.createRef"))() end)

_module("createSignal", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.createSignal", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	This is a simple signal implementation that has a dead-simple API.

		local signal = createSignal()

		local disconnect = signal:subscribe(function(foo)
			print("Cool foo:", foo)
		end)

		signal:fire("something")

		disconnect()
]]

local function createSignal()
	local connections = {}
	local suspendedConnections = {}
	local firing = false

	local function subscribe(self, callback)
		assert(typeof(callback) == "function", "Can only subscribe to signals with a function.")

		local connection = {
			callback = callback,
			disconnected = false,
		}

		-- If the callback is already registered, don't add to the suspendedConnection. Otherwise, this will disable
		-- the existing one.
		if firing and not connections[callback] then
			suspendedConnections[callback] = connection
		end

		connections[callback] = connection

		local function disconnect()
			assert(not connection.disconnected, "Listeners can only be disconnected once.")

			connection.disconnected = true
			connections[callback] = nil
			suspendedConnections[callback] = nil
		end

		return disconnect
	end

	local function fire(self, ...)
		firing = true
		for callback, connection in pairs(connections) do
			if not connection.disconnected and not suspendedConnections[callback] then
				callback(...)
			end
		end

		firing = false

		for callback, _ in pairs(suspendedConnections) do
			suspendedConnections[callback] = nil
		end
	end

	return {
		subscribe = subscribe,
		fire = fire,
	}
end

return createSignal
 end, _env("RemoteSpy.include.node_modules.roact.src.createSignal"))() end)

_module("createSpy", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.createSpy", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	A utility used to create a function spy that can be used to robustly test
	that functions are invoked the correct number of times and with the correct
	number of arguments.

	This should only be used in tests.
]]

local assertDeepEqual = require(script.Parent.assertDeepEqual)

local function createSpy(inner)
	local self = {
		callCount = 0,
		values = {},
		valuesLength = 0,
	}

	self.value = function(...)
		self.callCount = self.callCount + 1
		self.values = {...}
		self.valuesLength = select("#", ...)

		if inner ~= nil then
			return inner(...)
		end
	end

	self.assertCalledWith = function(_, ...)
		local len = select("#", ...)

		if self.valuesLength ~= len then
			error(("Expected %d arguments, but was called with %d arguments"):format(
				self.valuesLength,
				len
			), 2)
		end

		for i = 1, len do
			local expected = select(i, ...)

			assert(self.values[i] == expected, "value differs")
		end
	end

	self.assertCalledWithDeepEqual = function(_, ...)
		local len = select("#", ...)

		if self.valuesLength ~= len then
			error(("Expected %d arguments, but was called with %d arguments"):format(
				self.valuesLength,
				len
			), 2)
		end

		for i = 1, len do
			local expected = select(i, ...)

			assertDeepEqual(self.values[i], expected)
		end
	end

	self.captureValues = function(_, ...)
		local len = select("#", ...)
		local result = {}

		assert(self.valuesLength == len, "length of expected values differs from stored values")

		for i = 1, len do
			local key = select(i, ...)
			result[key] = self.values[i]
		end

		return result
	end

	setmetatable(self, {
		__index = function(_, key)
			error(("%q is not a valid member of spy"):format(key))
		end,
	})

	return self
end

return createSpy end, _env("RemoteSpy.include.node_modules.roact.src.createSpy"))() end)

_module("forwardRef", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.forwardRef", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local assign = require(script.Parent.assign)
local None = require(script.Parent.None)
local Ref = require(script.Parent.PropMarkers.Ref)

local config = require(script.Parent.GlobalConfig).get()

local excludeRef = {
	[Ref] = None,
}

--[[
	Allows forwarding of refs to underlying host components. Accepts a render
	callback which accepts props and a ref, and returns an element.
]]
local function forwardRef(render)
	if config.typeChecks then
		assert(typeof(render) == "function", "Expected arg #1 to be a function")
	end

	return function(props)
		local ref = props[Ref]
		local propsWithoutRef = assign({}, props, excludeRef)

		return render(propsWithoutRef, ref)
	end
end

return forwardRef end, _env("RemoteSpy.include.node_modules.roact.src.forwardRef"))() end)

_module("getDefaultInstanceProperty", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.getDefaultInstanceProperty", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Attempts to get the default value of a given property on a Roblox instance.

	This is used by the reconciler in cases where a prop was previously set on a
	primitive component, but is no longer present in a component's new props.

	Eventually, Roblox might provide a nicer API to query the default property
	of an object without constructing an instance of it.
]]

local Symbol = require(script.Parent.Symbol)

local Nil = Symbol.named("Nil")
local _cachedPropertyValues = {}

local function getDefaultInstanceProperty(className, propertyName)
	local classCache = _cachedPropertyValues[className]

	if classCache then
		local propValue = classCache[propertyName]

		-- We have to use a marker here, because Lua doesn't distinguish
		-- between 'nil' and 'not in a table'
		if propValue == Nil then
			return true, nil
		end

		if propValue ~= nil then
			return true, propValue
		end
	else
		classCache = {}
		_cachedPropertyValues[className] = classCache
	end

	local created = Instance.new(className)
	local ok, defaultValue = pcall(function()
		return created[propertyName]
	end)

	created:Destroy()

	if ok then
		if defaultValue == nil then
			classCache[propertyName] = Nil
		else
			classCache[propertyName] = defaultValue
		end
	end

	return ok, defaultValue
end

return getDefaultInstanceProperty end, _env("RemoteSpy.include.node_modules.roact.src.getDefaultInstanceProperty"))() end)

_module("internalAssert", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.internalAssert", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local function internalAssert(condition, message)
	if not condition then
		error(message .. " (This is probably a bug in Roact!)", 3)
	end
end

return internalAssert end, _env("RemoteSpy.include.node_modules.roact.src.internalAssert"))() end)

_module("invalidSetStateMessages", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.invalidSetStateMessages", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	These messages are used by Component to help users diagnose when they're
	calling setState in inappropriate places.

	The indentation may seem odd, but it's necessary to avoid introducing extra
	whitespace into the error messages themselves.
]]
local ComponentLifecyclePhase = require(script.Parent.ComponentLifecyclePhase)

local invalidSetStateMessages = {}

invalidSetStateMessages[ComponentLifecyclePhase.WillUpdate] = [[
setState cannot be used in the willUpdate lifecycle method.
Consider using the didUpdate method instead, or using getDerivedStateFromProps.

Check the definition of willUpdate in the component %q.]]

invalidSetStateMessages[ComponentLifecyclePhase.WillUnmount] = [[
setState cannot be used in the willUnmount lifecycle method.
A component that is being unmounted cannot be updated!

Check the definition of willUnmount in the component %q.]]

invalidSetStateMessages[ComponentLifecyclePhase.ShouldUpdate] = [[
setState cannot be used in the shouldUpdate lifecycle method.
shouldUpdate must be a pure function that only depends on props and state.

Check the definition of shouldUpdate in the component %q.]]

invalidSetStateMessages[ComponentLifecyclePhase.Render] = [[
setState cannot be used in the render method.
render must be a pure function that only depends on props and state.

Check the definition of render in the component %q.]]

invalidSetStateMessages["default"] = [[
setState can not be used in the current situation, because Roact doesn't know
which part of the lifecycle this component is in.

This is a bug in Roact.
It was triggered by the component %q.
]]

return invalidSetStateMessages end, _env("RemoteSpy.include.node_modules.roact.src.invalidSetStateMessages"))() end)

_module("oneChild", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.oneChild", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() --[[
	Retrieves at most one child from the children passed to a component.

	If passed nil or an empty table, will return nil.

	Throws an error if passed more than one child.
]]
local function oneChild(children)
	if not children then
		return nil
	end

	local key, child = next(children)

	if not child then
		return nil
	end

	local after = next(children, key)

	if after then
		error("Expected at most child, had more than one child.", 2)
	end

	return child
end

return oneChild end, _env("RemoteSpy.include.node_modules.roact.src.oneChild"))() end)

_module("strict", "ModuleScript", "RemoteSpy.include.node_modules.roact.src.strict", "RemoteSpy.include.node_modules.roact.src", function () return setfenv(function() local function strict(t, name)
	name = name or tostring(t)

	return setmetatable(t, {
		__index = function(self, key)
			local message = ("%q (%s) is not a valid member of %s"):format(
				tostring(key),
				typeof(key),
				name
			)

			error(message, 2)
		end,

		__newindex = function(self, key, value)
			local message = ("%q (%s) is not a valid member of %s"):format(
				tostring(key),
				typeof(key),
				name
			)

			error(message, 2)
		end,
	})
end

return strict end, _env("RemoteSpy.include.node_modules.roact.src.strict"))() end)

_instance("roact-hooked", "Folder", "RemoteSpy.include.node_modules.roact-hooked", "RemoteSpy.include.node_modules")

_module("out", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out", "RemoteSpy.include.node_modules.roact-hooked", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local exports = {}
local _with_hooks = TS.import(script, script, "with-hooks")
local withHooks = _with_hooks.withHooks
local withHooksPure = _with_hooks.withHooksPure
for _k, _v in pairs(TS.import(script, script, "hooks")) do
	exports[_k] = _v
end
--[[
	*
	* `hooked` is a [higher-order component](https://reactjs.org/docs/higher-order-components.html) that turns your
	* Function Component into a [class component](https://roblox.github.io/roact/guide/components/).
	*
	* `hooked` allows you to hook into the Component's lifecycle through Hooks.
	*
	* @example
	* const MyComponent = hooked<Props>(
	*   (props) => {
	*     // render using props
	*   },
	* );
	*
	* @see https://reactjs.org/docs/hooks-intro.html
]]
local function hooked(functionComponent)
	return withHooks(functionComponent)
end
--[[
	*
	* `pure` is a [higher-order component](https://reactjs.org/docs/higher-order-components.html) that turns your
	* Function Component into a [PureComponent](https://roblox.github.io/roact/performance/reduce-reconciliation/#purecomponent).
	*
	* If your function component wrapped in `pure` has a {@link useState}, {@link useReducer} or {@link useContext} Hook
	* in its implementation, it will still rerender when state or context changes.
	*
	* @example
	* const MyComponent = pure<Props>(
	*   (props) => {
	*     // render using props
	*   },
	* );
	*
	* @see https://reactjs.org/docs/react-api.html
	* @see https://roblox.github.io/roact/performance/reduce-reconciliation/
]]
local function pure(functionComponent)
	return withHooksPure(functionComponent)
end
exports.hooked = hooked
exports.pure = pure
return exports
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out"))() end)

_module("hooks", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", "RemoteSpy.include.node_modules.roact-hooked.out", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local exports = {}
exports.useBinding = TS.import(script, script, "use-binding").useBinding
exports.useCallback = TS.import(script, script, "use-callback").useCallback
exports.useContext = TS.import(script, script, "use-context").useContext
exports.useEffect = TS.import(script, script, "use-effect").useEffect
exports.useMemo = TS.import(script, script, "use-memo").useMemo
exports.useReducer = TS.import(script, script, "use-reducer").useReducer
exports.useState = TS.import(script, script, "use-state").useState
exports.useMutable = TS.import(script, script, "use-mutable").useMutable
exports.useRef = TS.import(script, script, "use-ref").useRef
return exports
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks"))() end)

_module("use-binding", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-binding", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local createBinding = TS.import(script, TS.getModule(script, "@rbxts", "roact").src).createBinding
local memoizedHook = TS.import(script, script.Parent.Parent, "memoized-hook").memoizedHook
--[[
	*
	* `useBinding` returns a memoized *`Binding`*, a special object that Roact automatically unwraps into values. When a
	* binding is updated, Roact will only change the specific properties that are subscribed to it.
	*
	* The first value returned is a `Binding` object, which will typically be passed as a prop to a Roact host component.
	* The second is a function that can be called with a new value to update the binding.
	*
	* @example
	* const [binding, setBindingValue] = useBinding(initialValue);
	*
	* @param initialValue - Initialized as the `.current` property
	* @returns A memoized `Binding` object, and a function to update the value of the binding.
	*
	* @see https://roblox.github.io/roact/advanced/bindings-and-refs/#bindings
]]
local function useBinding(initialValue)
	return memoizedHook(function()
		local bindingSet = { createBinding(initialValue) }
		return bindingSet
	end).state
end
return {
	useBinding = useBinding,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-binding"))() end)

_module("use-callback", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-callback", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local useMemo = TS.import(script, script.Parent, "use-memo").useMemo
--[[
	*
	* Returns a memoized version of the callback that only changes if one of the dependencies has changed.
	*
	* This is useful when passing callbacks to optimized child components that rely on reference equality to prevent
	* unnecessary renders.
	*
	* `useCallback(fn, deps)` is equivalent to `useMemo(() => fn, deps)`.
	*
	* @example
	* const memoizedCallback = useCallback(
	*   () => {
	*     doSomething(a, b);
	*   },
	*   [a, b],
	* );
	*
	* @param callback - An inline callback
	* @param deps - An array of dependencies
	* @returns A memoized version of the callback
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usecallback
]]
local function useCallback(callback, deps)
	return useMemo(function()
		return callback
	end, deps)
end
return {
	useCallback = useCallback,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-callback"))() end)

_module("use-context", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-context", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
--[[
	*
	* @see https://github.com/Kampfkarren/roact-hooks/blob/main/src/createUseContext.lua
]]
local _memoized_hook = TS.import(script, script.Parent.Parent, "memoized-hook")
local memoizedHook = _memoized_hook.memoizedHook
local resolveCurrentComponent = _memoized_hook.resolveCurrentComponent
local useEffect = TS.import(script, script.Parent, "use-effect").useEffect
local useState = TS.import(script, script.Parent, "use-state").useState
local function copyComponent(component)
	return setmetatable({}, {
		__index = component,
	})
end
--[[
	*
	* Accepts a context object (the value returned from `Roact.createContext`) and returns the current context value, as
	* given by the nearest context provider for the given context.
	*
	* When the nearest `Context.Provider` above the component updates, this Hook will trigger a rerender with the latest
	* context value.
	*
	* If there is no Provider, `useContext` returns the default value of the context.
	*
	* @param context - The Context object to read from
	* @returns The latest context value of the nearest Provider
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usecontext
]]
local function useContext(context)
	local thisContext = context
	local _binding = memoizedHook(function()
		local consumer = copyComponent(resolveCurrentComponent())
		thisContext.Consumer.init(consumer)
		return consumer.contextEntry
	end)
	local contextEntry = _binding.state
	if contextEntry then
		local _binding_1 = useState(contextEntry.value)
		local value = _binding_1[1]
		local setValue = _binding_1[2]
		useEffect(function()
			return contextEntry.onUpdate:subscribe(setValue)
		end, {})
		return value
	else
		return thisContext.defaultValue
	end
end
return {
	useContext = useContext,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-context"))() end)

_module("use-effect", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-effect", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local areDepsEqual = TS.import(script, script.Parent.Parent, "utils", "are-deps-equal").areDepsEqual
local _memoized_hook = TS.import(script, script.Parent.Parent, "memoized-hook")
local memoizedHook = _memoized_hook.memoizedHook
local resolveCurrentComponent = _memoized_hook.resolveCurrentComponent
local function scheduleEffect(effect)
	local _binding = resolveCurrentComponent()
	local effects = _binding.effects
	if effects.tail == nil then
		-- This is the first effect in the list
		effects.tail = effect
		effects.head = effects.tail
	else
		-- Append to the end of the list
		local _exp = effects.tail
		_exp.next = effect
		effects.tail = _exp.next
	end
	return effect
end
--[[
	*
	* Accepts a function that contains imperative, possibly effectful code. The function passed to `useEffect` will run
	* synchronously (thread-blocking) after the Roblox Instance is created and rendered.
	*
	* The clean-up function (returned by the effect) runs before the component is removed from the UI to prevent memory
	* leaks. Additionally, if a component renders multiple times, the **previous effect is cleaned up before executing
	* the next effect**.
	*
	*`useEffect` runs in the same phase as `didMount` and `didUpdate`. All cleanup functions are called on `willUnmount`.
	*
	* @example
	* useEffect(() => {
	*   // use value
	*   return () => {
	*     // cleanup
	*   }
	* }, [value]);
	*
	* useEffect(() => {
	*   // did update
	* });
	*
	* useEffect(() => {
	*   // did mount
	*   return () => {
	*     // will unmount
	*   }
	* }, []);
	*
	* @param callback - Imperative function that can return a cleanup function
	* @param deps - If present, effect will only activate if the values in the list change
	*
	* @see https://reactjs.org/docs/hooks-reference.html#useeffect
]]
local function useEffect(callback, deps)
	local hook = memoizedHook(nil)
	local _prevDeps = hook.state
	if _prevDeps ~= nil then
		_prevDeps = _prevDeps.deps
	end
	local prevDeps = _prevDeps
	if deps and areDepsEqual(deps, prevDeps) then
		return nil
	end
	hook.state = scheduleEffect({
		id = hook.id,
		callback = callback,
		deps = deps,
	})
end
return {
	useEffect = useEffect,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-effect"))() end)

_module("use-memo", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-memo", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local areDepsEqual = TS.import(script, script.Parent.Parent, "utils", "are-deps-equal").areDepsEqual
local memoizedHook = TS.import(script, script.Parent.Parent, "memoized-hook").memoizedHook
--[[
	*
	* `useMemo` will only recompute the memoized value when one of the `deps` has changed. This optimization helps to
	* avoid expensive calculations on every render.
	*
	* Remember that the function passed to `useMemo` runs during rendering. Don’t do anything there that you wouldn’t
	* normally do while rendering. For example, side effects belong in `useEffect`, not `useMemo`.
	*
	* If no array is provided, a new value will be computed on every render. This is usually a mistake, so `deps` must be
	* explicitly written as `undefined`.
	*
	* @example
	* const memoizedValue = useMemo(() => computeExpensiveValue(a, b), [a, b]);
	*
	* @param factory - A "create" function that computes a value
	* @param deps - An array of dependencies
	* @returns A memoized value
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usememo
]]
local function useMemo(factory, deps)
	local hook = memoizedHook(function()
		return {}
	end)
	local _binding = hook.state
	local prevValue = _binding[1]
	local prevDeps = _binding[2]
	if prevValue ~= nil and (deps and areDepsEqual(deps, prevDeps)) then
		return prevValue
	end
	local nextValue = factory()
	hook.state = { nextValue, deps }
	return nextValue
end
return {
	useMemo = useMemo,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-memo"))() end)

_module("use-mutable", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-mutable", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local memoizedHook = TS.import(script, script.Parent.Parent, "memoized-hook").memoizedHook
-- Function overloads from https://github.com/DefinitelyTyped/DefinitelyTyped/blob/master/types/react/index.d.ts#L1061
--[[
	*
	* `useMutable` returns a mutable object whose `.current` property is initialized to the argument `initialValue`.
	* The returned object will persist for the full lifetime of the component.
	*
	* `useMutable()` is handy for keeping any mutable value around similar to how you’d use instance fields in classes.
	*
	* This cannot be used as a [Roact Ref](https://roblox.github.io/roact/advanced/bindings-and-refs/#refs). If you want
	* to reference a Roblox Instance, refer to {@link useRef}.
	*
	* @example
	* const container = useMutable(initialValue);
	* useEffect(() => {
	*   container.current = value;
	* });
	*
	* @param initialValue - Initialized as the `.current` property
	* @returns A memoized, mutable object
	*
	* @see https://reactjs.org/docs/hooks-reference.html#useref
]]
--[[
	*
	* `useMutable` returns a mutable object whose `.current` property is initialized to the argument `initialValue`.
	* The returned object will persist for the full lifetime of the component.
	*
	* `useMutable()` is handy for keeping any mutable value around similar to how you’d use instance fields in classes.
	*
	* This cannot be used as a [Roact Ref](https://roblox.github.io/roact/advanced/bindings-and-refs/#refs). If you want
	* to reference a Roblox Instance, refer to {@link useRef}.
	*
	* @example
	* const container = useMutable(initialValue);
	* useEffect(() => {
	*   container.current = value;
	* });
	*
	* @param initialValue - Initialized as the `.current` property
	* @returns A memoized, mutable object
	*
	* @see https://reactjs.org/docs/hooks-reference.html#useref
]]
-- convenience overload for refs given as a ref prop as they typically start with a null value
--[[
	*
	* `useMutable` returns a mutable object whose `.current` property is initialized to the argument `initialValue`.
	* The returned object will persist for the full lifetime of the component.
	*
	* `useMutable()` is handy for keeping any mutable value around similar to how you’d use instance fields in classes.
	*
	* This cannot be used as a [Roact Ref](https://roblox.github.io/roact/advanced/bindings-and-refs/#refs). If you want
	* to reference a Roblox Instance, refer to {@link useRef}.
	*
	* @example
	* const container = useMutable(initialValue);
	* useEffect(() => {
	*   container.current = value;
	* });
	*
	* @returns A memoized, mutable object
	*
	* @see https://reactjs.org/docs/hooks-reference.html#useref
]]
-- convenience overload for potentially undefined initialValue / call with 0 arguments
-- has a default to stop it from defaulting to {} instead
--[[
	*
	* `useMutable` returns a mutable object whose `.current` property is initialized to the argument `initialValue`.
	* The returned object will persist for the full lifetime of the component.
	*
	* `useMutable()` is handy for keeping any mutable value around similar to how you’d use instance fields in classes.
	*
	* This cannot be used as a [Roact Ref](https://roblox.github.io/roact/advanced/bindings-and-refs/#refs). If you want
	* to reference a Roblox Instance, refer to {@link useRef}.
	*
	* @example
	* const container = useMutable(initialValue);
	* useEffect(() => {
	*   container.current = value;
	* });
	*
	* @param initialValue - Initialized as the `.current` property
	* @returns A memoized, mutable object
	*
	* @see https://reactjs.org/docs/hooks-reference.html#useref
]]
local function useMutable(initialValue)
	return memoizedHook(function()
		return {
			current = initialValue,
		}
	end).state
end
return {
	useMutable = useMutable,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-mutable"))() end)

_module("use-reducer", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-reducer", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local _memoized_hook = TS.import(script, script.Parent.Parent, "memoized-hook")
local memoizedHook = _memoized_hook.memoizedHook
local resolveCurrentComponent = _memoized_hook.resolveCurrentComponent
--[[
	*
	* Accepts a reducer of type `(state, action) => newState`, and returns the current state paired with a `dispatch`
	* method.
	*
	* If a new state is the same value as the current state, this will bail out without rerendering the component.
	*
	* `useReducer` is usually preferable to `useState` when you have complex state logic that involves multiple sub-values.
	* It also lets you optimize performance for components that trigger deep updates because [you can pass `dispatch` down
	* instead of callbacks](https://reactjs.org/docs/hooks-faq.html#how-to-avoid-passing-callbacks-down).
	*
	* There are two different ways to initialize `useReducer` state. You can use the initial state as a second argument,
	* or [create the initial state lazily](https://reactjs.org/docs/hooks-reference.html#lazy-initialization). To do this,
	* you can pass an init function as the third argument. The initial state will be set to `initializer(initialArg)`.
	*
	* @param reducer - Function that returns a state given the current state and an action
	* @param initializerArg - State used during the initial render, or passed to `initializer` if provided
	* @param initializer - Optional function that returns an initial state given `initializerArg`
	* @returns The current state, and an action dispatcher
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usereducer
]]
-- overload where dispatch could accept 0 arguments.
--[[
	*
	* Accepts a reducer of type `(state, action) => newState`, and returns the current state paired with a `dispatch`
	* method.
	*
	* If a new state is the same value as the current state, this will bail out without rerendering the component.
	*
	* `useReducer` is usually preferable to `useState` when you have complex state logic that involves multiple sub-values.
	* It also lets you optimize performance for components that trigger deep updates because [you can pass `dispatch` down
	* instead of callbacks](https://reactjs.org/docs/hooks-faq.html#how-to-avoid-passing-callbacks-down).
	*
	* There are two different ways to initialize `useReducer` state. You can use the initial state as a second argument,
	* or [create the initial state lazily](https://reactjs.org/docs/hooks-reference.html#lazy-initialization). To do this,
	* you can pass an init function as the third argument. The initial state will be set to `initializer(initialArg)`.
	*
	* @param reducer - Function that returns a state given the current state and an action
	* @param initializerArg - State used during the initial render, or passed to `initializer` if provided
	* @param initializer - Optional function that returns an initial state given `initializerArg`
	* @returns The current state, and an action dispatcher
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usereducer
]]
-- overload where dispatch could accept 0 arguments.
--[[
	*
	* Accepts a reducer of type `(state, action) => newState`, and returns the current state paired with a `dispatch`
	* method.
	*
	* If a new state is the same value as the current state, this will bail out without rerendering the component.
	*
	* `useReducer` is usually preferable to `useState` when you have complex state logic that involves multiple sub-values.
	* It also lets you optimize performance for components that trigger deep updates because [you can pass `dispatch` down
	* instead of callbacks](https://reactjs.org/docs/hooks-faq.html#how-to-avoid-passing-callbacks-down).
	*
	* There are two different ways to initialize `useReducer` state. You can use the initial state as a second argument,
	* or [create the initial state lazily](https://reactjs.org/docs/hooks-reference.html#lazy-initialization). To do this,
	* you can pass an init function as the third argument. The initial state will be set to `initializer(initialArg)`.
	*
	* @param reducer - Function that returns a state given the current state and an action
	* @param initializerArg - State used during the initial render, or passed to `initializer` if provided
	* @param initializer - Optional function that returns an initial state given `initializerArg`
	* @returns The current state, and an action dispatcher
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usereducer
]]
-- overload for free "I"; all goes as long as initializer converts it into "ReducerState<R>".
--[[
	*
	* Accepts a reducer of type `(state, action) => newState`, and returns the current state paired with a `dispatch`
	* method.
	*
	* If a new state is the same value as the current state, this will bail out without rerendering the component.
	*
	* `useReducer` is usually preferable to `useState` when you have complex state logic that involves multiple sub-values.
	* It also lets you optimize performance for components that trigger deep updates because [you can pass `dispatch` down
	* instead of callbacks](https://reactjs.org/docs/hooks-faq.html#how-to-avoid-passing-callbacks-down).
	*
	* There are two different ways to initialize `useReducer` state. You can use the initial state as a second argument,
	* or [create the initial state lazily](https://reactjs.org/docs/hooks-reference.html#lazy-initialization). To do this,
	* you can pass an init function as the third argument. The initial state will be set to `initializer(initialArg)`.
	*
	* @param reducer - Function that returns a state given the current state and an action
	* @param initializerArg - State used during the initial render, or passed to `initializer` if provided
	* @param initializer - Optional function that returns an initial state given `initializerArg`
	* @returns The current state, and an action dispatcher
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usereducer
]]
-- overload where "I" may be a subset of ReducerState<R>; used to provide autocompletion.
-- If "I" matches ReducerState<R> exactly then the last overload will allow initializer to be omitted.
--[[
	*
	* Accepts a reducer of type `(state, action) => newState`, and returns the current state paired with a `dispatch`
	* method.
	*
	* If a new state is the same value as the current state, this will bail out without rerendering the component.
	*
	* `useReducer` is usually preferable to `useState` when you have complex state logic that involves multiple sub-values.
	* It also lets you optimize performance for components that trigger deep updates because [you can pass `dispatch` down
	* instead of callbacks](https://reactjs.org/docs/hooks-faq.html#how-to-avoid-passing-callbacks-down).
	*
	* There are two different ways to initialize `useReducer` state. You can use the initial state as a second argument,
	* or [create the initial state lazily](https://reactjs.org/docs/hooks-reference.html#lazy-initialization). To do this,
	* you can pass an init function as the third argument. The initial state will be set to `initializer(initialArg)`.
	*
	* @param reducer - Function that returns a state given the current state and an action
	* @param initializerArg - State used during the initial render, or passed to `initializer` if provided
	* @param initializer - Optional function that returns an initial state given `initializerArg`
	* @returns The current state, and an action dispatcher
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usereducer
]]
-- Implementation matches a previous overload, is this required?
local function useReducer(reducer, initializerArg, initializer)
	local currentComponent = resolveCurrentComponent()
	local hook = memoizedHook(function()
		if initializer then
			return initializer(initializerArg)
		else
			return initializerArg
		end
	end)
	local function dispatch(action)
		local nextState = reducer(hook.state, action)
		if hook.state ~= nextState then
			currentComponent:setHookState(hook.id, function()
				hook.state = nextState
				return hook.state
			end)
		end
	end
	return { hook.state, dispatch }
end
return {
	useReducer = useReducer,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-reducer"))() end)

_module("use-ref", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-ref", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local createRef = TS.import(script, TS.getModule(script, "@rbxts", "roact").src).createRef
local memoizedHook = TS.import(script, script.Parent.Parent, "memoized-hook").memoizedHook
--[[
	*
	* `useRef` returns a memoized *`Ref`*, a special type of binding that points to Roblox Instance objects that are
	* created by Roact. The returned object will persist for the full lifetime of the component.
	*
	* `useMutable()` is handy for keeping any mutable value around similar to how you’d use instance fields in classes.
	*
	* This is not mutable like React's `useRef` hook. If you want to use a mutable object, refer to {@link useMutable}.
	*
	* @example
	* const ref = useRef<TextBox>();
	*
	* useEffect(() => {
	* 	const textBox = ref.getValue();
	* 	if (textBox) {
	* 		textBox.CaptureFocus();
	* 	}
	* }, []);
	*
	* return <textbox Ref={ref} />;
	*
	* @returns A memoized `Ref` object
	*
	* @see https://roblox.github.io/roact/advanced/bindings-and-refs/#refs
]]
local function useRef()
	return memoizedHook(function()
		return createRef()
	end).state
end
return {
	useRef = useRef,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-ref"))() end)

_module("use-state", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-state", "RemoteSpy.include.node_modules.roact-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local resolve = TS.import(script, script.Parent.Parent, "utils", "resolve").resolve
local useReducer = TS.import(script, script.Parent, "use-reducer").useReducer
--[[
	*
	* Returns a stateful value, and a function to update it.
	*
	* During the initial render, the returned state (`state`) is the same as the value passed as the first argument
	* (`initialState`).
	*
	* The `setState` function is used to update the state. It always knows the current state, so it's safe to omit from
	* the `useEffect` or `useCallback` dependency lists.
	*
	* If you update a State Hook to the same value as the current state, this will bail out without rerendering the
	* component.
	*
	* @example
	* const [state, setState] = useState(initialState);
	* const [state, setState] = useState(() => someExpensiveComputation());
	* setState(newState);
	* setState((prevState) => prevState + 1)
	*
	* @param initialState - State used during the initial render. Can be a function, which will be executed on initial render
	* @returns A stateful value, and an updater function
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usestate
]]
--[[
	*
	* Returns a stateful value, and a function to update it.
	*
	* During the initial render, the returned state (`state`) is the same as the value passed as the first argument
	* (`initialState`).
	*
	* The `setState` function is used to update the state. It always knows the current state, so it's safe to omit from
	* the `useEffect` or `useCallback` dependency lists.
	*
	* If you update a State Hook to the same value as the current state, this will bail out without rerendering the
	* component.
	*
	* @example
	* const [state, setState] = useState(initialState);
	* const [state, setState] = useState(() => someExpensiveComputation());
	* setState(newState);
	* setState((prevState) => prevState + 1)
	*
	* @param initialState - State used during the initial render. Can be a function, which will be executed on initial render
	* @returns A stateful value, and an updater function
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usestate
]]
--[[
	*
	* Returns a stateful value, and a function to update it.
	*
	* During the initial render, the returned state (`state`) is the same as the value passed as the first argument
	* (`initialState`).
	*
	* The `setState` function is used to update the state. It always knows the current state, so it's safe to omit from
	* the `useEffect` or `useCallback` dependency lists.
	*
	* If you update a State Hook to the same value as the current state, this will bail out without rerendering the
	* component.
	*
	* @example
	* const [state, setState] = useState(initialState);
	* const [state, setState] = useState(() => someExpensiveComputation());
	* setState(newState);
	* setState((prevState) => prevState + 1)
	*
	* @param initialState - State used during the initial render. Can be a function, which will be executed on initial render
	* @returns A stateful value, and an updater function
	*
	* @see https://reactjs.org/docs/hooks-reference.html#usestate
]]
local function useState(initialState)
	local _binding = useReducer(function(state, action)
		return resolve(action, state)
	end, nil, function()
		return resolve(initialState)
	end)
	local state = _binding[1]
	local dispatch = _binding[2]
	return { state, dispatch }
end
return {
	useState = useState,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.hooks.use-state"))() end)

_module("memoized-hook", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.memoized-hook", "RemoteSpy.include.node_modules.roact-hooked.out", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local resolve = TS.import(script, script.Parent, "utils", "resolve").resolve
local EXCEPTION_INVALID_HOOK_CALL = table.concat({ "Invalid hook call. Hooks can only be called inside of the body of a function component.", "This is usually the result of conflicting versions of roact-hooked.", "See https://reactjs.org/link/invalid-hook-call for tips about how to debug and fix this problem." }, "\n")
local EXCEPTION_RENDER_NOT_DONE = "Failed to render hook! (Another hooked component is rendering)"
local EXCEPTION_RENDER_OVERLAP = "Failed to render hook! (Another hooked component rendered during this one)"
local currentHook
local currentlyRenderingComponent
--[[
	*
	* Prepares for an upcoming render.
]]
local function renderReady(component)
	local _arg0 = currentlyRenderingComponent == nil
	assert(_arg0, EXCEPTION_RENDER_NOT_DONE)
	currentlyRenderingComponent = component
end
--[[
	*
	* Cleans up hooks. Must be called after finishing a render!
]]
local function renderDone(component)
	local _arg0 = currentlyRenderingComponent == component
	assert(_arg0, EXCEPTION_RENDER_OVERLAP)
	currentlyRenderingComponent = nil
	currentHook = nil
end
--[[
	*
	* Returns the currently-rendering component. Throws an error if a component is not mid-render.
]]
local function resolveCurrentComponent()
	return currentlyRenderingComponent or error(EXCEPTION_INVALID_HOOK_CALL, 3)
end
--[[
	*
	* Gets or creates a new hook. Hooks are memoized for every component. See the original source
	* {@link https://github.com/facebook/react/blob/main/packages/react-reconciler/src/ReactFiberHooks.new.js#L619 here}.
	*
	* @param initialValue - Initial value for `Hook.state` and `Hook.baseState`.
]]
local function memoizedHook(initialValue)
	local currentlyRenderingComponent = resolveCurrentComponent()
	local nextHook
	if currentHook then
		nextHook = currentHook.next
	else
		nextHook = currentlyRenderingComponent.firstHook
	end
	if nextHook then
		-- The hook has already been created
		currentHook = nextHook
	else
		-- This is a new hook, should be from an initial render
		local state = resolve(initialValue)
		local id = 0
		if currentHook then
			id = currentHook.id + 1
		end
		local newHook = {
			id = id,
			state = state,
			baseState = state,
		}
		if not currentHook then
			-- This is the first hook in the list
			currentHook = newHook
			currentlyRenderingComponent.firstHook = currentHook
		else
			-- Append to the end of the list
			currentHook.next = newHook
			currentHook = currentHook.next
		end
	end
	return currentHook
end
return {
	renderReady = renderReady,
	renderDone = renderDone,
	resolveCurrentComponent = resolveCurrentComponent,
	memoizedHook = memoizedHook,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.memoized-hook"))() end)

_module("types", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.types", "RemoteSpy.include.node_modules.roact-hooked.out", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
-- Roact
-- Reducers
-- Utility types
-- Hooks
return nil
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.types"))() end)

_instance("utils", "Folder", "RemoteSpy.include.node_modules.roact-hooked.out.utils", "RemoteSpy.include.node_modules.roact-hooked.out")

_module("are-deps-equal", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.utils.are-deps-equal", "RemoteSpy.include.node_modules.roact-hooked.out.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local function areDepsEqual(nextDeps, prevDeps)
	if prevDeps == nil then
		return false
	end
	if #nextDeps ~= #prevDeps then
		return false
	end
	do
		local i = 0
		local _shouldIncrement = false
		while true do
			if _shouldIncrement then
				i += 1
			else
				_shouldIncrement = true
			end
			if not (i < #nextDeps) then
				break
			end
			if nextDeps[i + 1] == prevDeps[i + 1] then
				continue
			end
			return false
		end
	end
	return true
end
return {
	areDepsEqual = areDepsEqual,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.utils.are-deps-equal"))() end)

_module("resolve", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.utils.resolve", "RemoteSpy.include.node_modules.roact-hooked.out.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local function resolve(fn, ...)
	local args = { ... }
	if type(fn) == "function" then
		return fn(unpack(args))
	else
		return fn
	end
end
return {
	resolve = resolve,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.utils.resolve"))() end)

_module("with-hooks", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.with-hooks", "RemoteSpy.include.node_modules.roact-hooked.out", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local exports = {}
local _with_hooks = TS.import(script, script, "with-hooks")
exports.withHooks = _with_hooks.withHooks
exports.withHooksPure = _with_hooks.withHooksPure
return exports
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.with-hooks"))() end)

_module("component-with-hooks", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.with-hooks.component-with-hooks", "RemoteSpy.include.node_modules.roact-hooked.out.with-hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local _memoized_hook = TS.import(script, script.Parent.Parent, "memoized-hook")
local renderDone = _memoized_hook.renderDone
local renderReady = _memoized_hook.renderReady
local ComponentWithHooks
do
	ComponentWithHooks = {}
	function ComponentWithHooks:constructor()
	end
	function ComponentWithHooks:init()
		self.effects = {}
		self.effectHandles = {}
	end
	function ComponentWithHooks:setHookState(id, reducer)
		self:setState(function(state)
			return {
				[id] = reducer(state[id]),
			}
		end)
	end
	function ComponentWithHooks:render()
		renderReady(self)
		local _functionComponent = self.functionComponent
		local _props = self.props
		local _success, _valueOrError = pcall(_functionComponent, _props)
		local result = _success and {
			success = true,
			value = _valueOrError,
		} or {
			success = false,
			error = _valueOrError,
		}
		renderDone(self)
		if not result.success then
			error("(ComponentWithHooks) " .. result.error)
		end
		return result.value
	end
	function ComponentWithHooks:didMount()
		self:flushEffects()
	end
	function ComponentWithHooks:didUpdate()
		self:flushEffects()
	end
	function ComponentWithHooks:willUnmount()
		self:unmountEffects()
		self.effects.head = nil
	end
	function ComponentWithHooks:flushEffectsHelper(effect)
		if not effect then
			return nil
		end
		local _effectHandles = self.effectHandles
		local _id = effect.id
		local _result = _effectHandles[_id]
		if _result ~= nil then
			_result()
		end
		local handle = effect.callback()
		if handle then
			local _effectHandles_1 = self.effectHandles
			local _id_1 = effect.id
			-- ▼ Map.set ▼
			_effectHandles_1[_id_1] = handle
			-- ▲ Map.set ▲
		else
			local _effectHandles_1 = self.effectHandles
			local _id_1 = effect.id
			-- ▼ Map.delete ▼
			_effectHandles_1[_id_1] = nil
			-- ▲ Map.delete ▲
		end
		self:flushEffectsHelper(effect.next)
	end
	function ComponentWithHooks:flushEffects()
		self:flushEffectsHelper(self.effects.head)
		self.effects.head = nil
		self.effects.tail = nil
	end
	function ComponentWithHooks:unmountEffects()
		-- This does not clean up effects by order of id, but it should not matter
		-- because this is on unmount
		local _effectHandles = self.effectHandles
		local _arg0 = function(handle)
			return handle()
		end
		-- ▼ ReadonlyMap.forEach ▼
		for _k, _v in pairs(_effectHandles) do
			_arg0(_v, _k, _effectHandles)
		end
		-- ▲ ReadonlyMap.forEach ▲
		-- ▼ Map.clear ▼
		table.clear(self.effectHandles)
		-- ▲ Map.clear ▲
	end
end
return {
	ComponentWithHooks = ComponentWithHooks,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.with-hooks.component-with-hooks"))() end)

_module("with-hooks", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked.out.with-hooks.with-hooks", "RemoteSpy.include.node_modules.roact-hooked.out.with-hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.7
local TS = _G[script]
local ComponentWithHooks = TS.import(script, script.Parent, "component-with-hooks").ComponentWithHooks
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function componentWithHooksMixin(ctor)
	for k, v in pairs(ComponentWithHooks) do
		ctor[k] = v
	end
end
local function withHooks(functionComponent)
	local ComponentClass
	do
		ComponentClass = Roact.Component:extend("ComponentClass")
		function ComponentClass:init()
		end
		ComponentClass.functionComponent = functionComponent
	end
	componentWithHooksMixin(ComponentClass)
	return ComponentClass
end
local function withHooksPure(functionComponent)
	local ComponentClass
	do
		ComponentClass = Roact.PureComponent:extend("ComponentClass")
		function ComponentClass:init()
		end
		ComponentClass.functionComponent = functionComponent
	end
	componentWithHooksMixin(ComponentClass)
	return ComponentClass
end
return {
	withHooks = withHooks,
	withHooksPure = withHooksPure,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked.out.with-hooks.with-hooks"))() end)

_instance("roact-hooked-plus", "Folder", "RemoteSpy.include.node_modules.roact-hooked-plus", "RemoteSpy.include.node_modules")

_module("out", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out", "RemoteSpy.include.node_modules.roact-hooked-plus", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local exports = {}
exports.arrayToMap = TS.import(script, script, "utils", "array-to-map").arrayToMap
local _binding_utils = TS.import(script, script, "utils", "binding-utils")
exports.asBinding = _binding_utils.asBinding
exports.getBindingValue = _binding_utils.getBindingValue
exports.isBinding = _binding_utils.isBinding
exports.mapBinding = _binding_utils.mapBinding
local _set_timeout = TS.import(script, script, "utils", "set-timeout")
exports.Timeout = _set_timeout.Timeout
exports.clearTimeout = _set_timeout.clearTimeout
exports.setTimeout = _set_timeout.setTimeout
local _set_interval = TS.import(script, script, "utils", "set-interval")
exports.Interval = _set_interval.Interval
exports.clearInterval = _set_interval.clearInterval
exports.setInterval = _set_interval.setInterval
local _flipper = TS.import(script, script, "flipper")
exports.getBinding = _flipper.getBinding
exports.useGoal = _flipper.useGoal
exports.useInstant = _flipper.useInstant
exports.useLinear = _flipper.useLinear
exports.useMotor = _flipper.useMotor
exports.useSpring = _flipper.useSpring
exports.useAnimation = TS.import(script, script, "use-animation").useAnimation
exports.useClickOutside = TS.import(script, script, "use-click-outside").useClickOutside
exports.useDebouncedValue = TS.import(script, script, "use-debounced-value").useDebouncedValue
exports.useDelayedEffect = TS.import(script, script, "use-delayed-effect").useDelayedEffect
exports.useDelayedValue = TS.import(script, script, "use-delayed-value").useDelayedValue
exports.useDidMount = TS.import(script, script, "use-did-mount").useDidMount
exports.useEvent = TS.import(script, script, "use-event").useEvent
exports.useForceUpdate = TS.import(script, script, "use-force-update").useForceUpdate
exports.useGroupMotor = TS.import(script, script, "use-group-motor").useGroupMotor
exports.useHotkeys = TS.import(script, script, "use-hotkeys").useHotkeys
exports.useIdle = TS.import(script, script, "use-idle").useIdle
exports.useInterval = TS.import(script, script, "use-interval").useInterval
exports.useListState = TS.import(script, script, "use-list-state").useListState
exports.useMouse = TS.import(script, script, "use-mouse").useMouse
exports.usePromise = TS.import(script, script, "use-promise").usePromise
exports.useSequenceCallback = TS.import(script, script, "use-sequence-callback").useSequenceCallback
exports.useSequence = TS.import(script, script, "use-sequence").useSequence
exports.useSetState = TS.import(script, script, "use-set-state").useSetState
exports.useSingleMotor = TS.import(script, script, "use-single-motor").useSingleMotor
exports.useToggle = TS.import(script, script, "use-toggle").useToggle
exports.useViewportSize = TS.import(script, script, "use-viewport-size").useViewportSize
return exports
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out"))() end)

_module("flipper", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local exports = {}
exports.getBinding = TS.import(script, script, "get-binding").getBinding
exports.useGoal = TS.import(script, script, "use-goal").useGoal
exports.useInstant = TS.import(script, script, "use-instant").useInstant
exports.useLinear = TS.import(script, script, "use-linear").useLinear
exports.useMotor = TS.import(script, script, "use-motor").useMotor
exports.useSpring = TS.import(script, script, "use-spring").useSpring
return exports
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper"))() end)

_module("get-binding", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.get-binding", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local isMotor = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src).isMotor
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local AssignedBinding = setmetatable({}, {
	__tostring = function()
		return "AssignedBinding"
	end,
})
local function getBinding(motor)
	assert(motor, "Missing argument #1: motor")
	local _arg0 = isMotor(motor)
	assert(_arg0, "Provided value is not a motor")
	if motor[AssignedBinding] ~= nil then
		return motor[AssignedBinding]
	end
	local binding, setBindingValue = Roact.createBinding(motor:getValue())
	motor:onStep(setBindingValue)
	motor[AssignedBinding] = binding
	return binding
end
return {
	getBinding = getBinding,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.get-binding"))() end)

_module("use-goal", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-goal", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local getBinding = TS.import(script, script.Parent, "get-binding").getBinding
local useMotor = TS.import(script, script.Parent, "use-motor").useMotor
local function useGoal(goal)
	local motor = useMotor(goal._targetValue)
	motor:setGoal(goal)
	return getBinding(motor)
end
return {
	useGoal = useGoal,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-goal"))() end)

_module("use-instant", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-instant", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local Instant = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src).Instant
local useGoal = TS.import(script, script.Parent, "use-goal").useGoal
local function useInstant(targetValue)
	return useGoal(Instant.new(targetValue))
end
return {
	useInstant = useInstant,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-instant"))() end)

_module("use-linear", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-linear", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local Linear = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src).Linear
local useGoal = TS.import(script, script.Parent, "use-goal").useGoal
local function useLinear(targetValue, options)
	return useGoal(Linear.new(targetValue, options))
end
return {
	useLinear = useLinear,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-linear"))() end)

_module("use-motor", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-motor", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _flipper = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src)
local GroupMotor = _flipper.GroupMotor
local SingleMotor = _flipper.SingleMotor
local useMemo = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useMemo
local function createMotor(initialValue)
	if type(initialValue) == "number" then
		return SingleMotor.new(initialValue)
	elseif type(initialValue) == "table" then
		return GroupMotor.new(initialValue)
	else
		error("Invalid type for initialValue. Expected 'number' or 'table', got '" .. (tostring(initialValue) .. "'"))
	end
end
local function useMotor(initialValue)
	return useMemo(function()
		return createMotor(initialValue)
	end, {})
end
return {
	useMotor = useMotor,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-motor"))() end)

_module("use-spring", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-spring", "RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local Spring = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src).Spring
local useGoal = TS.import(script, script.Parent, "use-goal").useGoal
local function useSpring(targetValue, options)
	return useGoal(Spring.new(targetValue, options))
end
return {
	useSpring = useSpring,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.flipper.use-spring"))() end)

_module("use-animation", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-animation", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local Spring = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src).Spring
local _flipper = TS.import(script, script.Parent, "flipper")
local getBinding = _flipper.getBinding
local useMotor = _flipper.useMotor
local _object = {}
local _left = "number"
local _arg0 = function(value, ctor, options)
	if options == nil then
		options = {}
	end
	local motor = useMotor(value)
	motor:setGoal(ctor.new(value, options))
	return getBinding(motor)
end
_object[_left] = _arg0
local _left_1 = "Color3"
local _arg0_1 = function(color, ctor, options)
	if options == nil then
		options = {}
	end
	local motor = useMotor({ color.R, color.G, color.B })
	motor:setGoal({ ctor.new(color.R, options), ctor.new(color.G, options), ctor.new(color.B, options) })
	return getBinding(motor):map(function(_param)
		local r = _param[1]
		local g = _param[2]
		local b = _param[3]
		return Color3.new(r, g, b)
	end)
end
_object[_left_1] = _arg0_1
local _left_2 = "UDim"
local _arg0_2 = function(udim, ctor, options)
	local motor = useMotor({ udim.Scale, udim.Offset })
	motor:setGoal({ ctor.new(udim.Scale, options), ctor.new(udim.Offset, options) })
	return getBinding(motor):map(function(_param)
		local s = _param[1]
		local o = _param[2]
		return UDim.new(s, o)
	end)
end
_object[_left_2] = _arg0_2
local _left_3 = "UDim2"
local _arg0_3 = function(udim2, ctor, options)
	local motor = useMotor({ udim2.X.Scale, udim2.X.Offset, udim2.Y.Scale, udim2.Y.Offset })
	motor:setGoal({ ctor.new(udim2.X.Scale, options), ctor.new(udim2.X.Offset, options), ctor.new(udim2.Y.Scale, options), ctor.new(udim2.Y.Offset, options) })
	return getBinding(motor):map(function(_param)
		local xS = _param[1]
		local xO = _param[2]
		local yS = _param[3]
		local yO = _param[4]
		return UDim2.new(xS, math.round(xO), yS, math.round(yO))
	end)
end
_object[_left_3] = _arg0_3
local _left_4 = "Vector2"
local _arg0_4 = function(vector2, ctor, options)
	local motor = useMotor({ vector2.X, vector2.Y })
	motor:setGoal({ ctor.new(vector2.X, options), ctor.new(vector2.Y, options) })
	return getBinding(motor):map(function(_param)
		local X = _param[1]
		local Y = _param[2]
		return Vector2.new(X, Y)
	end)
end
_object[_left_4] = _arg0_4
local _left_5 = "table"
local _arg0_5 = function(array, ctor, options)
	local motor = useMotor(array)
	local _fn = motor
	local _arg0_6 = function(value)
		return ctor.new(value, options)
	end
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#array)
	for _k, _v in ipairs(array) do
		_newValue[_k] = _arg0_6(_v, _k - 1, array)
	end
	-- ▲ ReadonlyArray.map ▲
	_fn:setGoal(_newValue)
	return getBinding(motor)
end
_object[_left_5] = _arg0_5
local motorHooks = _object
local function useAnimation(value, ctor, options)
	local hook = motorHooks[typeof(value)]
	local _arg1 = "useAnimation: Value of type " .. (typeof(value) .. " is not supported")
	assert(hook, _arg1)
	return hook(value, (ctor or Spring), options)
end
return {
	useAnimation = useAnimation,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-animation"))() end)

_module("use-click-outside", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-click-outside", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useEffect = _roact_hooked.useEffect
local useRef = _roact_hooked.useRef
local UserInputService = TS.import(script, TS.getModule(script, "@rbxts", "services")).UserInputService
local DEFAULT_INPUTS = { Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch }
local function contains(object, mouse)
	return object.AbsolutePosition.X <= mouse.X and (object.AbsolutePosition.Y <= mouse.Y and (object.AbsolutePosition.X + object.AbsoluteSize.X >= mouse.X and object.AbsolutePosition.Y + object.AbsoluteSize.Y >= mouse.Y))
end
--[[
	*
	* @see https://mantine.dev/hooks/use-click-outside/
]]
local function useClickOutside(handler, inputs, instances)
	if inputs == nil then
		inputs = DEFAULT_INPUTS
	end
	local ref = useRef()
	useEffect(function()
		local listener = function(input)
			local instance = ref:getValue()
			if type(instances) == "table" then
				local _arg0 = function(obj)
					return obj ~= nil and not contains(obj, input.Position)
				end
				-- ▼ ReadonlyArray.every ▼
				local _result = true
				for _k, _v in ipairs(instances) do
					if not _arg0(_v, _k - 1, instances) then
						_result = false
						break
					end
				end
				-- ▲ ReadonlyArray.every ▲
				local shouldTrigger = _result
				if shouldTrigger then
					handler()
				end
			elseif instance ~= nil and not contains(instance, input.Position) then
				handler()
			end
		end
		local handle = UserInputService.InputBegan:Connect(function(input)
			local _userInputType = input.UserInputType
			if table.find(inputs, _userInputType) ~= nil then
				listener(input)
			end
		end)
		return function()
			handle:Disconnect()
		end
	end, { ref, handler, instances })
	return ref
end
return {
	useClickOutside = useClickOutside,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-click-outside"))() end)

_module("use-debounced-value", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-debounced-value", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useEffect = _roact_hooked.useEffect
local useMutable = _roact_hooked.useMutable
local useState = _roact_hooked.useState
local _set_timeout = TS.import(script, script.Parent, "utils", "set-timeout")
local clearTimeout = _set_timeout.clearTimeout
local setTimeout = _set_timeout.setTimeout
--[[
	*
	* @see https://mantine.dev/hooks/use-debounced-value/
]]
local function useDebouncedValue(value, wait, options)
	if options == nil then
		options = {
			leading = false,
		}
	end
	local _binding = useState(value)
	local _value = _binding[1]
	local setValue = _binding[2]
	local mountedRef = useMutable(false)
	local timeoutRef = useMutable(nil)
	local cooldownRef = useMutable(false)
	local cancel = function()
		return clearTimeout(timeoutRef.current)
	end
	useEffect(function()
		if mountedRef.current then
			if not cooldownRef.current and options.leading then
				cooldownRef.current = true
				setValue(value)
			else
				cancel()
				timeoutRef.current = setTimeout(function()
					cooldownRef.current = false
					setValue(value)
				end, wait)
			end
		end
	end, { value, options.leading })
	useEffect(function()
		mountedRef.current = true
		return cancel
	end, {})
	return { _value, cancel }
end
return {
	useDebouncedValue = useDebouncedValue,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-debounced-value"))() end)

_module("use-delayed-effect", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-delayed-effect", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useEffect = _roact_hooked.useEffect
local useMemo = _roact_hooked.useMemo
local setTimeout = TS.import(script, script.Parent, "utils", "set-timeout").setTimeout
local clearUpdates = TS.import(script, script.Parent, "use-delayed-value").clearUpdates
local nextId = 0
local function useDelayedEffect(effect, delayMs, deps)
	local updates = useMemo(function()
		return {}
	end, {})
	useEffect(function()
		local _original = nextId
		nextId += 1
		local id = _original
		local update = {
			timeout = setTimeout(function()
				effect()
				updates[id] = nil
			end, delayMs),
			resolveTime = os.clock() + delayMs,
		}
		-- Clear all updates that are later than the current one to prevent overlap
		clearUpdates(updates, update.resolveTime)
		updates[id] = update
	end, deps)
	useEffect(function()
		return function()
			return clearUpdates(updates)
		end
	end, {})
end
return {
	useDelayedEffect = useDelayedEffect,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-delayed-effect"))() end)

_module("use-delayed-value", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-delayed-value", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useEffect = _roact_hooked.useEffect
local useMemo = _roact_hooked.useMemo
local useState = _roact_hooked.useState
local _set_timeout = TS.import(script, script.Parent, "utils", "set-timeout")
local clearTimeout = _set_timeout.clearTimeout
local setTimeout = _set_timeout.setTimeout
local function clearUpdates(updates, laterThan)
	for id, update in pairs(updates) do
		if laterThan == nil or update.resolveTime >= laterThan then
			updates[id] = nil
			clearTimeout(update.timeout)
		end
	end
end
local nextId = 0
local function useDelayedValue(value, delayMs)
	local _binding = useState(value)
	local delayedValue = _binding[1]
	local setDelayedValue = _binding[2]
	local updates = useMemo(function()
		return {}
	end, {})
	useEffect(function()
		local _original = nextId
		nextId += 1
		local id = _original
		local update = {
			timeout = setTimeout(function()
				setDelayedValue(value)
				updates[id] = nil
			end, delayMs),
			resolveTime = os.clock() + delayMs,
		}
		-- Clear all updates that are later than the current one to prevent overlap
		clearUpdates(updates, update.resolveTime)
		updates[id] = update
	end, { value })
	useEffect(function()
		return function()
			return clearUpdates(updates)
		end
	end, {})
	return delayedValue
end
return {
	clearUpdates = clearUpdates,
	useDelayedValue = useDelayedValue,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-delayed-value"))() end)

_module("use-did-mount", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-did-mount", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useEffect = _roact_hooked.useEffect
local useMutable = _roact_hooked.useMutable
local function useDidMount()
	local ref = useMutable(true)
	useEffect(function()
		ref.current = false
	end, {})
	return ref.current
end
return {
	useDidMount = useDidMount,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-did-mount"))() end)

_module("use-event", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-event", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local useEffect = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useEffect
local function useEvent(event, callback, deps)
	if deps == nil then
		deps = {}
	end
	useEffect(function()
		local handle = event:Connect(callback)
		return function()
			return handle:Disconnect()
		end
	end, deps)
end
return {
	useEvent = useEvent,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-event"))() end)

_module("use-force-update", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-force-update", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local useReducer = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useReducer
local reducer = function(value)
	return (value + 1) % 1000000
end
local function useForceUpdate()
	local _binding = useReducer(reducer, 0)
	local update = _binding[2]
	return update
end
return {
	useForceUpdate = useForceUpdate,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-force-update"))() end)

_module("use-group-motor", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-group-motor", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local GroupMotor = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src).GroupMotor
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useBinding = _roact_hooked.useBinding
local useEffect = _roact_hooked.useEffect
local useMemo = _roact_hooked.useMemo
local function useGroupMotor(initialValue)
	local motor = useMemo(function()
		return GroupMotor.new(initialValue)
	end, {})
	local _binding = useBinding(motor:getValue())
	local binding = _binding[1]
	local setBinding = _binding[2]
	useEffect(function()
		motor:onStep(setBinding)
	end, {})
	local setGoal = function(goal)
		motor:setGoal(goal)
	end
	return { binding, setGoal, motor }
end
return {
	useGroupMotor = useGroupMotor,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-group-motor"))() end)

_module("use-hotkeys", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-hotkeys", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local useEffect = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useEffect
local UserInputService = TS.import(script, TS.getModule(script, "@rbxts", "services")).UserInputService
local function isHotkeyPressed(hotkey)
	local _exp = UserInputService:GetKeysPressed()
	local _arg0 = function(key)
		return key.KeyCode
	end
	-- ▼ ReadonlyArray.map ▼
	local _newValue = table.create(#_exp)
	for _k, _v in ipairs(_exp) do
		_newValue[_k] = _arg0(_v, _k - 1, _exp)
	end
	-- ▲ ReadonlyArray.map ▲
	local keysDown = _newValue
	local _arg0_1 = function(key)
		if type(key) == "string" then
			local _arg0_2 = Enum.KeyCode[key]
			return table.find(keysDown, _arg0_2) ~= nil
		else
			return table.find(keysDown, key) ~= nil
		end
	end
	-- ▼ ReadonlyArray.every ▼
	local _result = true
	for _k, _v in ipairs(hotkey) do
		if not _arg0_1(_v, _k - 1, hotkey) then
			_result = false
			break
		end
	end
	-- ▲ ReadonlyArray.every ▲
	return _result
end
local function useHotkeys(hotkeys)
	useEffect(function()
		local handle = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
				local _arg0 = function(_param)
					local hotkey = _param[1]
					local event = _param[2]
					local _name = input.KeyCode.Name
					local _condition = table.find(hotkey, _name) ~= nil
					if _condition then
						_condition = isHotkeyPressed(hotkey)
					end
					if _condition then
						event()
					end
				end
				for _k, _v in ipairs(hotkeys) do
					_arg0(_v, _k - 1, hotkeys)
				end
			end
		end)
		return function()
			handle:Disconnect()
		end
	end, { hotkeys })
end
return {
	useHotkeys = useHotkeys,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-hotkeys"))() end)

_module("use-idle", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-idle", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useCallback = _roact_hooked.useCallback
local useEffect = _roact_hooked.useEffect
local useMutable = _roact_hooked.useMutable
local useState = _roact_hooked.useState
local UserInputService = TS.import(script, TS.getModule(script, "@rbxts", "services")).UserInputService
local _set_timeout = TS.import(script, script.Parent, "utils", "set-timeout")
local clearTimeout = _set_timeout.clearTimeout
local setTimeout = _set_timeout.setTimeout
local DEFAULT_INPUTS = { Enum.UserInputType.Keyboard, Enum.UserInputType.Touch, Enum.UserInputType.Gamepad1, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3 }
local DEFAULT_OPTIONS = {
	inputs = DEFAULT_INPUTS,
	useWindowFocus = true,
	initialState = true,
}
local function useIdle(timeout, options)
	local _object = {}
	for _k, _v in pairs(DEFAULT_OPTIONS) do
		_object[_k] = _v
	end
	if type(options) == "table" then
		for _k, _v in pairs(options) do
			_object[_k] = _v
		end
	end
	local _binding = _object
	local inputs = _binding.inputs
	local useWindowFocus = _binding.useWindowFocus
	local initialState = _binding.initialState
	local _binding_1 = useState(initialState)
	local idle = _binding_1[1]
	local setIdle = _binding_1[2]
	local timer = useMutable()
	local handleInput = useCallback(function()
		setIdle(false)
		if timer.current then
			clearTimeout(timer.current)
		end
		timer.current = setTimeout(function()
			setIdle(true)
		end, timeout)
	end, { timeout })
	useEffect(function()
		local events = UserInputService.InputBegan:Connect(function(input)
			local _userInputType = input.UserInputType
			if table.find(inputs, _userInputType) ~= nil then
				handleInput()
			end
		end)
		return function()
			events:Disconnect()
		end
	end, { handleInput })
	useEffect(function()
		if not useWindowFocus then
			return nil
		end
		local windowFocused = UserInputService.WindowFocused:Connect(handleInput)
		local windowFocusReleased = UserInputService.WindowFocusReleased:Connect(function()
			if timer.current then
				clearTimeout(timer.current)
				timer.current = nil
			end
			setIdle(true)
		end)
		return function()
			windowFocused:Disconnect()
			windowFocusReleased:Disconnect()
		end
	end, { useWindowFocus, handleInput })
	return idle
end
return {
	useIdle = useIdle,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-idle"))() end)

_module("use-interval", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-interval", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useMutable = _roact_hooked.useMutable
local useState = _roact_hooked.useState
local _set_interval = TS.import(script, script.Parent, "utils", "set-interval")
local clearInterval = _set_interval.clearInterval
local setInterval = _set_interval.setInterval
--[[
	*
	* @see https://mantine.dev/hooks/use-interval/
]]
local function useInterval(fn, intervalMs)
	local _binding = useState(false)
	local active = _binding[1]
	local setActive = _binding[2]
	local intervalRef = useMutable()
	local start = function()
		if not active then
			setActive(true)
			intervalRef.current = setInterval(fn, intervalMs)
		end
	end
	local stop = function()
		setActive(false)
		clearInterval(intervalRef.current)
	end
	local toggle = function()
		if active then
			stop()
		else
			start()
		end
	end
	return {
		start = start,
		stop = stop,
		toggle = toggle,
		active = active,
	}
end
return {
	useInterval = useInterval,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-interval"))() end)

_module("use-list-state", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-list-state", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local useState = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useState
local function slice(array, start, finish)
	if start == nil then
		start = 0
	end
	if finish == nil then
		finish = math.huge
	end
	local _arg0 = function(_, index)
		return index >= start and index < finish
	end
	-- ▼ ReadonlyArray.filter ▼
	local _newValue = {}
	local _length = 0
	for _k, _v in ipairs(array) do
		if _arg0(_v, _k - 1, array) == true then
			_length += 1
			_newValue[_length] = _v
		end
	end
	-- ▲ ReadonlyArray.filter ▲
	return _newValue
end
--[[
	*
	* @see https://mantine.dev/hooks/use-list-state/
]]
local function useListState(initialValue)
	if initialValue == nil then
		initialValue = {}
	end
	local _binding = useState(initialValue)
	local state = _binding[1]
	local setState = _binding[2]
	local append = function(...)
		local items = { ... }
		return setState(function(current)
			local _array = {}
			local _length = #_array
			local _currentLength = #current
			table.move(current, 1, _currentLength, _length + 1, _array)
			_length += _currentLength
			table.move(items, 1, #items, _length + 1, _array)
			return _array
		end)
	end
	local prepend = function(...)
		local items = { ... }
		return setState(function(current)
			local _array = {}
			local _length = #_array
			local _itemsLength = #items
			table.move(items, 1, _itemsLength, _length + 1, _array)
			_length += _itemsLength
			table.move(current, 1, #current, _length + 1, _array)
			return _array
		end)
	end
	local insert = function(index, ...)
		local items = { ... }
		return setState(function(current)
			local _array = {}
			local _length = #_array
			local _array_1 = slice(current, 0, index)
			local _Length = #_array_1
			table.move(_array_1, 1, _Length, _length + 1, _array)
			_length += _Length
			local _itemsLength = #items
			table.move(items, 1, _itemsLength, _length + 1, _array)
			_length += _itemsLength
			local _array_2 = slice(current, index)
			table.move(_array_2, 1, #_array_2, _length + 1, _array)
			return _array
		end)
	end
	local apply = function(fn)
		return setState(function(current)
			local _arg0 = function(item, index)
				return fn(item, index)
			end
			-- ▼ ReadonlyArray.map ▼
			local _newValue = table.create(#current)
			for _k, _v in ipairs(current) do
				_newValue[_k] = _arg0(_v, _k - 1, current)
			end
			-- ▲ ReadonlyArray.map ▲
			return _newValue
		end)
	end
	local remove = function(...)
		local indices = { ... }
		return setState(function(current)
			local _arg0 = function(_, index)
				return not (table.find(indices, index) ~= nil)
			end
			-- ▼ ReadonlyArray.filter ▼
			local _newValue = {}
			local _length = 0
			for _k, _v in ipairs(current) do
				if _arg0(_v, _k - 1, current) == true then
					_length += 1
					_newValue[_length] = _v
				end
			end
			-- ▲ ReadonlyArray.filter ▲
			return _newValue
		end)
	end
	local pop = function()
		return setState(function(current)
			local _array = {}
			local _length = #_array
			table.move(current, 1, #current, _length + 1, _array)
			local cloned = _array
			cloned[#cloned] = nil
			return cloned
		end)
	end
	local shift = function()
		return setState(function(current)
			local _array = {}
			local _length = #_array
			table.move(current, 1, #current, _length + 1, _array)
			local cloned = _array
			table.remove(cloned, 1)
			return cloned
		end)
	end
	local reorder = function(_param)
		local from = _param.from
		local to = _param.to
		return setState(function(current)
			local _array = {}
			local _length = #_array
			table.move(current, 1, #current, _length + 1, _array)
			local cloned = _array
			local item = table.remove(cloned, from + 1)
			if item ~= nil then
				table.insert(cloned, to + 1, item)
			end
			return cloned
		end)
	end
	local setItem = function(index, item)
		return setState(function(current)
			local _array = {}
			local _length = #_array
			table.move(current, 1, #current, _length + 1, _array)
			local cloned = _array
			cloned[index + 1] = item
			return cloned
		end)
	end
	local setItemProp = function(index, prop, value)
		return setState(function(current)
			local _array = {}
			local _length = #_array
			table.move(current, 1, #current, _length + 1, _array)
			local cloned = _array
			local _object = {}
			local _spread = cloned[index + 1]
			if type(_spread) == "table" then
				for _k, _v in pairs(_spread) do
					_object[_k] = _v
				end
			end
			_object[prop] = value
			cloned[index + 1] = _object
			return cloned
		end)
	end
	local applyWhere = function(condition, fn)
		return setState(function(current)
			local _arg0 = function(item, index)
				if condition(item, index) then
					return fn(item, index)
				else
					return item
				end
			end
			-- ▼ ReadonlyArray.map ▼
			local _newValue = table.create(#current)
			for _k, _v in ipairs(current) do
				_newValue[_k] = _arg0(_v, _k - 1, current)
			end
			-- ▲ ReadonlyArray.map ▲
			return _newValue
		end)
	end
	return { state, {
		setState = setState,
		append = append,
		prepend = prepend,
		insert = insert,
		pop = pop,
		shift = shift,
		apply = apply,
		applyWhere = applyWhere,
		remove = remove,
		reorder = reorder,
		setItem = setItem,
		setItemProp = setItemProp,
	} }
end
return {
	slice = slice,
	useListState = useListState,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-list-state"))() end)

_module("use-mouse", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-mouse", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useBinding = _roact_hooked.useBinding
local useEffect = _roact_hooked.useEffect
local UserInputService = TS.import(script, TS.getModule(script, "@rbxts", "services")).UserInputService
local function useMouse(onChange)
	local _binding = useBinding(UserInputService:GetMouseLocation())
	local location = _binding[1]
	local setLocation = _binding[2]
	useEffect(function()
		local handle = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local location = UserInputService:GetMouseLocation()
				setLocation(location)
				local _result = onChange
				if _result ~= nil then
					_result(location)
				end
			end
		end)
		return function()
			handle:Disconnect()
		end
	end, {})
	return location
end
return {
	useMouse = useMouse,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-mouse"))() end)

_module("use-promise", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-promise", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useEffect = _roact_hooked.useEffect
local useReducer = _roact_hooked.useReducer
-- https://github.com/bsonntag/react-use-promise
local function resolvePromise(promise)
	if type(promise) == "function" then
		return promise()
	end
	return promise
end
local states = {
	pending = "pending",
	rejected = "rejected",
	resolved = "resolved",
}
local defaultState = {
	err = nil,
	result = nil,
	state = states.pending,
}
local function reducer(state, action)
	local _exp = action.type
	repeat
		if _exp == (states.pending) then
			return defaultState
		end
		if _exp == (states.resolved) then
			return {
				err = nil,
				result = action.payload,
				state = states.resolved,
			}
		end
		if _exp == (states.rejected) then
			return {
				err = action.payload,
				result = nil,
				state = states.rejected,
			}
		end
		return state
	until true
end
local function usePromise(promise, deps)
	if deps == nil then
		deps = {}
	end
	local _binding = useReducer(reducer, defaultState)
	local _binding_1 = _binding[1]
	local err = _binding_1.err
	local result = _binding_1.result
	local state = _binding_1.state
	local dispatch = _binding[2]
	useEffect(function()
		promise = resolvePromise(promise)
		if not promise then
			return nil
		end
		local canceled = false
		dispatch({
			type = states.pending,
		})
		local _arg0 = function(result)
			return not canceled and dispatch({
				payload = result,
				type = states.resolved,
			})
		end
		local _arg1 = function(err)
			return not canceled and dispatch({
				payload = err,
				type = states.rejected,
			})
		end
		promise:andThen(_arg0, _arg1)
		return function()
			canceled = true
		end
	end, deps)
	return { result, err, state }
end
return {
	usePromise = usePromise,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-promise"))() end)

_module("use-sequence-callback", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-sequence-callback", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useEffect = _roact_hooked.useEffect
local useMemo = _roact_hooked.useMemo
local useMutable = _roact_hooked.useMutable
local useDidMount = TS.import(script, script.Parent, "use-did-mount").useDidMount
local resolve = TS.import(script, script.Parent, "utils", "resolve").resolve
local _set_timeout = TS.import(script, script.Parent, "utils", "set-timeout")
local clearTimeout = _set_timeout.clearTimeout
local setTimeout = _set_timeout.setTimeout
local function useSequenceCallback(sequence, onUpdate, deps)
	if deps == nil then
		deps = {}
	end
	local updates = useMemo(function()
		return resolve(sequence.updates)
	end, deps)
	local callback = useMutable(onUpdate)
	callback.current = onUpdate
	local didMount = useDidMount()
	useEffect(function()
		if didMount and sequence.ignoreMount then
			return nil
		end
		local timeout
		local index = 0
		local runNext
		runNext = function()
			if index < #updates then
				local _binding = updates[index + 1]
				local delay = _binding[1]
				local func = _binding[2]
				timeout = setTimeout(function()
					callback.current(func())
					runNext()
				end, delay)
				index += 1
			end
		end
		runNext()
		return function()
			return clearTimeout(timeout)
		end
	end, { updates, didMount })
end
return {
	useSequenceCallback = useSequenceCallback,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-sequence-callback"))() end)

_module("use-sequence", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-sequence", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useEffect = _roact_hooked.useEffect
local useMemo = _roact_hooked.useMemo
local useState = _roact_hooked.useState
local useDidMount = TS.import(script, script.Parent, "use-did-mount").useDidMount
local resolve = TS.import(script, script.Parent, "utils", "resolve").resolve
local _set_timeout = TS.import(script, script.Parent, "utils", "set-timeout")
local clearTimeout = _set_timeout.clearTimeout
local setTimeout = _set_timeout.setTimeout
local function useSequence(sequence, deps)
	if deps == nil then
		deps = {}
	end
	local _binding = useState(sequence.initialState)
	local state = _binding[1]
	local setState = _binding[2]
	local updates = useMemo(function()
		return resolve(sequence.updates)
	end, deps)
	local didMount = useDidMount()
	useEffect(function()
		if didMount and sequence.ignoreMount then
			return nil
		end
		local timeout
		local index = 0
		local runNext
		runNext = function()
			if index < #updates then
				local _binding_1 = updates[index + 1]
				local delay = _binding_1[1]
				local func = _binding_1[2]
				timeout = setTimeout(function()
					setState(func())
					runNext()
				end, delay)
				index += 1
			end
		end
		runNext()
		return function()
			return clearTimeout(timeout)
		end
	end, { updates, didMount })
	return state
end
return {
	useSequence = useSequence,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-sequence"))() end)

_module("use-set-state", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-set-state", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local useState = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useState
local resolve = TS.import(script, script.Parent, "utils", "resolve").resolve
--[[
	*
	* @see https://mantine.dev/hooks/use-set-state/
]]
local function useSetState(initialState)
	local _binding = useState(initialState)
	local state = _binding[1]
	local _setState = _binding[2]
	local setState = function(statePartial)
		return _setState(function(current)
			local _object = {}
			for _k, _v in pairs(current) do
				_object[_k] = _v
			end
			for _k, _v in pairs(resolve(statePartial, current)) do
				_object[_k] = _v
			end
			return _object
		end)
	end
	return { state, setState }
end
return {
	useSetState = useSetState,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-set-state"))() end)

_module("use-single-motor", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-single-motor", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local SingleMotor = TS.import(script, TS.getModule(script, "@rbxts", "flipper").src).SingleMotor
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useBinding = _roact_hooked.useBinding
local useEffect = _roact_hooked.useEffect
local useMemo = _roact_hooked.useMemo
local function useSingleMotor(initialValue)
	local motor = useMemo(function()
		return SingleMotor.new(initialValue)
	end, {})
	local _binding = useBinding(motor:getValue())
	local binding = _binding[1]
	local setBinding = _binding[2]
	useEffect(function()
		motor:onStep(setBinding)
	end, {})
	local setGoal = function(goal)
		motor:setGoal(goal)
	end
	return { binding, setGoal, motor }
end
return {
	useSingleMotor = useSingleMotor,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-single-motor"))() end)

_module("use-toggle", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-toggle", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local useState = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useState
--[[
	*
	* @see https://mantine.dev/hooks/use-toggle/
]]
local function useToggle(initialValue, options)
	local _binding = useState(initialValue)
	local state = _binding[1]
	local setState = _binding[2]
	local toggle = function(value)
		if value ~= nil then
			setState(value)
		else
			setState(function(current)
				if current == options[1] then
					return options[2]
				end
				return options[1]
			end)
		end
	end
	return { state, toggle }
end
--[[
	*
	* @see https://mantine.dev/hooks/use-toggle/
]]
local function useBooleanToggle(initialValue)
	if initialValue == nil then
		initialValue = false
	end
	return useToggle(initialValue, { true, false })
end
return {
	useToggle = useToggle,
	useBooleanToggle = useBooleanToggle,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-toggle"))() end)

_module("use-viewport-size", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.use-viewport-size", "RemoteSpy.include.node_modules.roact-hooked-plus.out", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useBinding = _roact_hooked.useBinding
local useEffect = _roact_hooked.useEffect
local useState = _roact_hooked.useState
local Workspace = TS.import(script, TS.getModule(script, "@rbxts", "services")).Workspace
--[[
	*
	* Returns a binding to the current screen size.
	* @param onChange Fires when the viewport size changes
]]
local function useViewportSize(onChange)
	local _binding = useState(Workspace.CurrentCamera)
	local camera = _binding[1]
	local setCamera = _binding[2]
	local _binding_1 = useBinding(camera.ViewportSize)
	local size = _binding_1[1]
	local setSize = _binding_1[2]
	useEffect(function()
		local handle = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			if Workspace.CurrentCamera then
				setCamera(Workspace.CurrentCamera)
				setSize(Workspace.CurrentCamera.ViewportSize)
				local _result = onChange
				if _result ~= nil then
					_result(Workspace.CurrentCamera.ViewportSize)
				end
			end
		end)
		return function()
			handle:Disconnect()
		end
	end, {})
	useEffect(function()
		local handle = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			setSize(camera.ViewportSize)
			local _result = onChange
			if _result ~= nil then
				_result(camera.ViewportSize)
			end
		end)
		return function()
			handle:Disconnect()
		end
	end, { camera })
	return size
end
return {
	useViewportSize = useViewportSize,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.use-viewport-size"))() end)

_instance("utils", "Folder", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils", "RemoteSpy.include.node_modules.roact-hooked-plus.out")

_module("array-to-map", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.array-to-map", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local function arrayToMap(array, callback)
	local map = {}
	local _arg0 = function(value, index)
		local _binding = callback(value, index, array)
		local k = _binding[1]
		local v = _binding[2]
		map[k] = v
	end
	for _k, _v in ipairs(array) do
		_arg0(_v, _k - 1, array)
	end
	return map
end
return {
	arrayToMap = arrayToMap,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.array-to-map"))() end)

_module("binding-utils", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.binding-utils", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local function isBinding(value)
	return type(value) == "table" and value.getValue ~= nil
end
local function asBinding(value)
	if isBinding(value) then
		return value
	else
		return (Roact.createBinding(value))
	end
end
local function mapBinding(value, transform)
	if isBinding(value) then
		return value:map(transform)
	else
		return (Roact.createBinding(transform(value)))
	end
end
local function getBindingValue(value)
	if isBinding(value) then
		return value:getValue()
	else
		return value
	end
end
return {
	isBinding = isBinding,
	asBinding = asBinding,
	mapBinding = mapBinding,
	getBindingValue = getBindingValue,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.binding-utils"))() end)

_module("resolve", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.resolve", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local function resolve(fn, ...)
	local args = { ... }
	if type(fn) == "function" then
		return fn(unpack(args))
	else
		return fn
	end
end
return {
	resolve = resolve,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.resolve"))() end)

_module("set-interval", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.set-interval", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local TS = _G[script]
local RunService = TS.import(script, TS.getModule(script, "@rbxts", "services")).RunService
local Interval
do
	Interval = setmetatable({}, {
		__tostring = function()
			return "Interval"
		end,
	})
	Interval.__index = Interval
	function Interval.new(...)
		local self = setmetatable({}, Interval)
		return self:constructor(...) or self
	end
	function Interval:constructor(callback, milliseconds, ...)
		local args = { ... }
		self.running = true
		task.defer(function()
			local clock = 0
			local hb
			hb = RunService.Heartbeat:Connect(function(step)
				clock += step
				if not self.running then
					hb:Disconnect()
				elseif clock >= milliseconds / 1000 then
					clock -= milliseconds / 1000
					callback(unpack(args))
				end
			end)
		end)
	end
	function Interval:clear()
		self.running = false
	end
end
local function setInterval(callback, milliseconds, ...)
	local args = { ... }
	return Interval.new(callback, milliseconds, unpack(args))
end
local function clearInterval(interval)
	local _result = interval
	if _result ~= nil then
		_result:clear()
	end
end
return {
	setInterval = setInterval,
	clearInterval = clearInterval,
	Interval = Interval,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.set-interval"))() end)

_module("set-timeout", "ModuleScript", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.set-timeout", "RemoteSpy.include.node_modules.roact-hooked-plus.out.utils", function () return setfenv(function() -- Compiled with roblox-ts v1.3.3
local Timeout
do
	Timeout = setmetatable({}, {
		__tostring = function()
			return "Timeout"
		end,
	})
	Timeout.__index = Timeout
	function Timeout.new(...)
		local self = setmetatable({}, Timeout)
		return self:constructor(...) or self
	end
	function Timeout:constructor(callback, milliseconds, ...)
		local args = { ... }
		self.running = true
		task.delay(milliseconds / 1000, function()
			if self.running then
				callback(unpack(args))
			end
		end)
	end
	function Timeout:clear()
		self.running = false
	end
end
local function setTimeout(callback, milliseconds, ...)
	local args = { ... }
	return Timeout.new(callback, milliseconds, unpack(args))
end
local function clearTimeout(timeout)
	timeout:clear()
end
return {
	setTimeout = setTimeout,
	clearTimeout = clearTimeout,
	Timeout = Timeout,
}
 end, _env("RemoteSpy.include.node_modules.roact-hooked-plus.out.utils.set-timeout"))() end)

_instance("roact-rodux-hooked", "Folder", "RemoteSpy.include.node_modules.roact-rodux-hooked", "RemoteSpy.include.node_modules")

_module("out", "ModuleScript", "RemoteSpy.include.node_modules.roact-rodux-hooked.out", "RemoteSpy.include.node_modules.roact-rodux-hooked", function () return setfenv(function() -- Compiled with roblox-ts v1.2.3
local TS = _G[script]
local exports = {}
exports.Provider = TS.import(script, script, "components", "provider").Provider
exports.useDispatch = TS.import(script, script, "hooks", "use-dispatch").useDispatch
exports.useSelector = TS.import(script, script, "hooks", "use-selector").useSelector
exports.useStore = TS.import(script, script, "hooks", "use-store").useStore
exports.shallowEqual = TS.import(script, script, "helpers", "shallow-equal").shallowEqual
exports.RoactRoduxContext = TS.import(script, script, "components", "context").RoactRoduxContext
return exports
 end, _env("RemoteSpy.include.node_modules.roact-rodux-hooked.out"))() end)

_instance("components", "Folder", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.components", "RemoteSpy.include.node_modules.roact-rodux-hooked.out")

_module("context", "ModuleScript", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.components.context", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.components", function () return setfenv(function() -- Compiled with roblox-ts v1.2.3
local TS = _G[script]
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
local RoactRoduxContext = Roact.createContext(nil)
return {
	RoactRoduxContext = RoactRoduxContext,
}
 end, _env("RemoteSpy.include.node_modules.roact-rodux-hooked.out.components.context"))() end)

_module("provider", "ModuleScript", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.components.provider", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.components", function () return setfenv(function() -- Compiled with roblox-ts v1.2.3
local TS = _G[script]
local RoactRoduxContext = TS.import(script, script.Parent, "context").RoactRoduxContext
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local hooked = _roact_hooked.hooked
local useMemo = _roact_hooked.useMemo
local Roact = TS.import(script, TS.getModule(script, "@rbxts", "roact").src)
--[[
	*
	* Makes the Rodux store available to the `useStore()` calls in the component hierarchy below.
]]
local Provider = hooked(function(_param)
	local store = _param.store
	local children = _param[Roact.Children]
	local contextValue = useMemo(function()
		return {
			store = store,
		}
	end, { store })
	local _ptr = {
		value = contextValue,
	}
	local _ptr_1 = {}
	local _length = #_ptr_1
	if children then
		for _k, _v in pairs(children) do
			if type(_k) == "number" then
				_ptr_1[_length + _k] = _v
			else
				_ptr_1[_k] = _v
			end
		end
	end
	return Roact.createElement(RoactRoduxContext.Provider, _ptr, _ptr_1)
end)
return {
	Provider = Provider,
}
 end, _env("RemoteSpy.include.node_modules.roact-rodux-hooked.out.components.provider"))() end)

_instance("helpers", "Folder", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.helpers", "RemoteSpy.include.node_modules.roact-rodux-hooked.out")

_module("shallow-equal", "ModuleScript", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.helpers.shallow-equal", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.helpers", function () return setfenv(function() -- Compiled with roblox-ts v1.2.3
local TS = _G[script]
local Object = TS.import(script, TS.getModule(script, "@rbxts", "object-utils"))
--[[
	*
	* Compares two arbitrary values for shallow equality. Object values are compared based on their keys, i.e. they must
	* have the same keys and for each key the value must be equal.
]]
local function shallowEqual(left, right)
	if left == right then
		return true
	end
	if not (type(left) == "table") or not (type(right) == "table") then
		return false
	end
	local keysLeft = Object.keys(left)
	local keysRight = Object.keys(right)
	if #keysLeft ~= #keysRight then
		return false
	end
	local _arg0 = function(value, index)
		return value == right[index]
	end
	-- ▼ ReadonlyArray.every ▼
	local _result = true
	for _k, _v in ipairs(keysLeft) do
		if not _arg0(_v, _k - 1, keysLeft) then
			_result = false
			break
		end
	end
	-- ▲ ReadonlyArray.every ▲
	return _result
end
return {
	shallowEqual = shallowEqual,
}
 end, _env("RemoteSpy.include.node_modules.roact-rodux-hooked.out.helpers.shallow-equal"))() end)

_instance("hooks", "Folder", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks", "RemoteSpy.include.node_modules.roact-rodux-hooked.out")

_module("use-dispatch", "ModuleScript", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks.use-dispatch", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.3
local TS = _G[script]
local useMutable = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useMutable
local useStore = TS.import(script, script.Parent, "use-store").useStore
--[[
	*
	* A hook to access the Rodux Store's `dispatch` method.
	*
	* @returns Rodux store's `dispatch` method
	*
	* @example
	* import Roact from "@rbxts/roact";
	* import { hooked } from "@rbxts/roact-hooked";
	* import { useDispatch } from "@rbxts/roact-rodux-hooked";
	* import type { RootStore } from "./store";
	*
	* export const CounterComponent = hooked(() => {
	*   const dispatch = useDispatch<RootStore>();
	*   return (
	*     <textlabel
	*       Text={"Increase counter"}
	*       Event={{
	*         Activated: () => dispatch({ type: "increase-counter" }),
	*       }}
	*     />
	*   );
	* });
]]
local function useDispatch()
	local store = useStore()
	return useMutable(function(action)
		return store:dispatch(action)
	end).current
end
return {
	useDispatch = useDispatch,
}
 end, _env("RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks.use-dispatch"))() end)

_module("use-selector", "ModuleScript", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks.use-selector", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.3
local TS = _G[script]
local _roact_hooked = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out)
local useEffect = _roact_hooked.useEffect
local useMutable = _roact_hooked.useMutable
local useReducer = _roact_hooked.useReducer
local useStore = TS.import(script, script.Parent, "use-store").useStore
--[[
	*
	* This interface allows you to easily create a hook that is properly typed for your store's root state.
	*
	* @example
	* interface RootState {
	*   property: string;
	* }
	*
	* const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
]]
--[[
	*
	* A hook to access the Rodux Store's state. This hook takes a selector function as an argument. The selector is called
	* with the store state.
	*
	* This hook takes an optional equality comparison function as the second parameter that allows you to customize the
	* way the selected state is compared to determine whether the component needs to be re-rendered.
	*
	* @param selector - The selector function
	* @param equalityFn - The function that will be used to determine equality
	*
	* @returns The selected portion of the state
	*
	* @example
	* import Roact from "@rbxts/roact";
	* import { hooked } from "@rbxts/roact-hooked";
	* import { useSelector } from "@rbxts/roact-rodux-hooked";
	* import type { RootState } from "./store";
	*
	* export const CounterComponent = hooked(() => {
	*   const count = useSelector((state: RootState) => state.counter);
	*   return <textlabel Text={`Counter: ${count}`} />;
	* });
]]
local function useSelector(selector, equalityFn)
	if equalityFn == nil then
		equalityFn = function(a, b)
			return a == b
		end
	end
	local _binding = useReducer(function(s)
		return s + 1
	end, 0)
	local forceRender = _binding[2]
	local store = useStore()
	local latestSubscriptionCallbackError = useMutable()
	local latestSelector = useMutable()
	local latestStoreState = useMutable()
	local latestSelectedState = useMutable()
	local storeState = store:getState()
	local selectedState
	TS.try(function()
		local _value = selector ~= latestSelector.current or storeState ~= latestStoreState.current or latestSubscriptionCallbackError.current
		if _value ~= "" and _value then
			local newSelectedState = selector(storeState)
			-- ensure latest selected state is reused so that a custom equality function can result in identical references
			if latestSelectedState.current == nil or not equalityFn(newSelectedState, latestSelectedState.current) then
				selectedState = newSelectedState
			else
				selectedState = latestSelectedState.current
			end
		else
			selectedState = latestSelectedState.current
		end
	end, function(err)
		if latestSubscriptionCallbackError.current ~= nil then
			err ..= "\nThe error may be correlated with this previous error:\n" .. latestSubscriptionCallbackError.current .. "\n\n"
		end
		error(err)
	end)
	useEffect(function()
		latestSelector.current = selector
		latestStoreState.current = storeState
		latestSelectedState.current = selectedState
		latestSubscriptionCallbackError.current = nil
	end)
	useEffect(function()
		local function checkForUpdates(newStoreState)
			local _exitType, _returns = TS.try(function()
				-- Avoid calling selector multiple times if the store's state has not changed
				if newStoreState == latestStoreState.current then
					return TS.TRY_RETURN, {}
				end
				local newSelectedState = latestSelector.current(newStoreState)
				if equalityFn(newSelectedState, latestSelectedState.current) then
					return TS.TRY_RETURN, {}
				end
				latestSelectedState.current = newSelectedState
				latestStoreState.current = newStoreState
			end, function(err)
				-- we ignore all errors here, since when the component
				-- is re-rendered, the selectors are called again, and
				-- will throw again, if neither props nor store state
				-- changed
				latestSubscriptionCallbackError.current = err
			end)
			if _exitType then
				return unpack(_returns)
			end
			task.spawn(forceRender)
		end
		local subscription = store.changed:connect(checkForUpdates)
		checkForUpdates(store:getState())
		return function()
			return subscription:disconnect()
		end
	end, { store })
	return selectedState
end
return {
	useSelector = useSelector,
}
 end, _env("RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks.use-selector"))() end)

_module("use-store", "ModuleScript", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks.use-store", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks", function () return setfenv(function() -- Compiled with roblox-ts v1.2.3
local TS = _G[script]
local RoactRoduxContext = TS.import(script, script.Parent.Parent, "components", "context").RoactRoduxContext
local useContext = TS.import(script, TS.getModule(script, "@rbxts", "roact-hooked").out).useContext
--[[
	*
	* A hook to access the Rodux Store.
	*
	* @returns The Rodux store
	*
	* @example
	* import Roact from "@rbxts/roact";
	* import { hooked } from "@rbxts/roact-hooked";
	* import { useStore } from "@rbxts/roact-rodux-hooked";
	* import type { RootStore } from "./store";
	*
	* export const CounterComponent = hooked(() => {
	*   const store = useStore<RootStore>();
	*   return <textlabel Text={store.getState()} />;
	* });
]]
local function useStore()
	return useContext(RoactRoduxContext).store
end
return {
	useStore = useStore,
}
 end, _env("RemoteSpy.include.node_modules.roact-rodux-hooked.out.hooks.use-store"))() end)

_module("types", "ModuleScript", "RemoteSpy.include.node_modules.roact-rodux-hooked.out.types", "RemoteSpy.include.node_modules.roact-rodux-hooked.out", function () return setfenv(function() -- Compiled with roblox-ts v1.2.3
--[[
	*
	* A Roact Context
]]
return nil
 end, _env("RemoteSpy.include.node_modules.roact-rodux-hooked.out.types"))() end)

_instance("rodux", "Folder", "RemoteSpy.include.node_modules.rodux", "RemoteSpy.include.node_modules")

_module("src", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src", "RemoteSpy.include.node_modules.rodux", function () return setfenv(function() local Store = require(script.Store)
local createReducer = require(script.createReducer)
local combineReducers = require(script.combineReducers)
local makeActionCreator = require(script.makeActionCreator)
local loggerMiddleware = require(script.loggerMiddleware)
local thunkMiddleware = require(script.thunkMiddleware)

return {
	Store = Store,
	createReducer = createReducer,
	combineReducers = combineReducers,
	makeActionCreator = makeActionCreator,
	loggerMiddleware = loggerMiddleware.middleware,
	thunkMiddleware = thunkMiddleware,
}
 end, _env("RemoteSpy.include.node_modules.rodux.src"))() end)

_module("NoYield", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src.NoYield", "RemoteSpy.include.node_modules.rodux.src", function () return setfenv(function() --!nocheck

--[[
	Calls a function and throws an error if it attempts to yield.

	Pass any number of arguments to the function after the callback.

	This function supports multiple return; all results returned from the
	given function will be returned.
]]

local function resultHandler(co, ok, ...)
	if not ok then
		local message = (...)
		error(debug.traceback(co, message), 2)
	end

	if coroutine.status(co) ~= "dead" then
		error(debug.traceback(co, "Attempted to yield inside changed event!"), 2)
	end

	return ...
end

local function NoYield(callback, ...)
	local co = coroutine.create(callback)

	return resultHandler(co, coroutine.resume(co, ...))
end

return NoYield
 end, _env("RemoteSpy.include.node_modules.rodux.src.NoYield"))() end)

_module("Signal", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src.Signal", "RemoteSpy.include.node_modules.rodux.src", function () return setfenv(function() --[[
	A limited, simple implementation of a Signal.

	Handlers are fired in order, and (dis)connections are properly handled when
	executing an event.
]]
local function immutableAppend(list, ...)
	local new = {}
	local len = #list

	for key = 1, len do
		new[key] = list[key]
	end

	for i = 1, select("#", ...) do
		new[len + i] = select(i, ...)
	end

	return new
end

local function immutableRemoveValue(list, removeValue)
	local new = {}

	for i = 1, #list do
		if list[i] ~= removeValue then
			table.insert(new, list[i])
		end
	end

	return new
end

local Signal = {}

Signal.__index = Signal

function Signal.new(store)
	local self = {
		_listeners = {},
		_store = store
	}

	setmetatable(self, Signal)

	return self
end

function Signal:connect(callback)
	if typeof(callback) ~= "function" then
		error("Expected the listener to be a function.")
	end

	if self._store and self._store._isDispatching then
		error(
			'You may not call store.changed:connect() while the reducer is executing. ' ..
				'If you would like to be notified after the store has been updated, subscribe from a ' ..
				'component and invoke store:getState() in the callback to access the latest state. '
		)
	end

	local listener = {
		callback = callback,
		disconnected = false,
		connectTraceback = debug.traceback(),
		disconnectTraceback = nil
	}

	self._listeners = immutableAppend(self._listeners, listener)

	local function disconnect()
		if listener.disconnected then
			error((
				"Listener connected at: \n%s\n" ..
				"was already disconnected at: \n%s\n"
			):format(
				tostring(listener.connectTraceback),
				tostring(listener.disconnectTraceback)
			))
		end

		if self._store and self._store._isDispatching then
			error("You may not unsubscribe from a store listener while the reducer is executing.")
		end

		listener.disconnected = true
		listener.disconnectTraceback = debug.traceback()
		self._listeners = immutableRemoveValue(self._listeners, listener)
	end

	return {
		disconnect = disconnect
	}
end

function Signal:fire(...)
	for _, listener in ipairs(self._listeners) do
		if not listener.disconnected then
			listener.callback(...)
		end
	end
end

return Signal end, _env("RemoteSpy.include.node_modules.rodux.src.Signal"))() end)

_module("Store", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src.Store", "RemoteSpy.include.node_modules.rodux.src", function () return setfenv(function() local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)
local NoYield = require(script.Parent.NoYield)

local ACTION_LOG_LENGTH = 3

local rethrowErrorReporter = {
	reportReducerError = function(prevState, action, errorResult)
		error(string.format("Received error: %s\n\n%s", errorResult.message, errorResult.thrownValue))
	end,
	reportUpdateError = function(prevState, currentState, lastActions, errorResult)
		error(string.format("Received error: %s\n\n%s", errorResult.message, errorResult.thrownValue))
	end,
}

local function tracebackReporter(message)
	return debug.traceback(tostring(message))
end

local Store = {}

-- This value is exposed as a private value so that the test code can stay in
-- sync with what event we listen to for dispatching the Changed event.
-- It may not be Heartbeat in the future.
Store._flushEvent = RunService.Heartbeat

Store.__index = Store

--[[
	Create a new Store whose state is transformed by the given reducer function.

	Each time an action is dispatched to the store, the new state of the store
	is given by:

		state = reducer(state, action)

	Reducers do not mutate the state object, so the original state is still
	valid.
]]
function Store.new(reducer, initialState, middlewares, errorReporter)
	assert(typeof(reducer) == "function", "Bad argument #1 to Store.new, expected function.")
	assert(middlewares == nil or typeof(middlewares) == "table", "Bad argument #3 to Store.new, expected nil or table.")
	if middlewares ~= nil then
		for i=1, #middlewares, 1 do
			assert(
				typeof(middlewares[i]) == "function",
				("Expected the middleware ('%s') at index %d to be a function."):format(tostring(middlewares[i]), i)
			)
		end
	end

	local self = {}

	self._errorReporter = errorReporter or rethrowErrorReporter
	self._isDispatching = false
	self._reducer = reducer
	local initAction = {
		type = "@@INIT",
	}
	self._actionLog = { initAction }
	local ok, result = xpcall(function()
		self._state = reducer(initialState, initAction)
	end, tracebackReporter)
	if not ok then
		self._errorReporter.reportReducerError(initialState, initAction, {
			message = "Caught error in reducer with init",
			thrownValue = result,
		})
		self._state = initialState
	end
	self._lastState = self._state

	self._mutatedSinceFlush = false
	self._connections = {}

	self.changed = Signal.new(self)

	setmetatable(self, Store)

	local connection = self._flushEvent:Connect(function()
		self:flush()
	end)
	table.insert(self._connections, connection)

	if middlewares then
		local unboundDispatch = self.dispatch
		local dispatch = function(...)
			return unboundDispatch(self, ...)
		end

		for i = #middlewares, 1, -1 do
			local middleware = middlewares[i]
			dispatch = middleware(dispatch, self)
		end

		self.dispatch = function(_self, ...)
			return dispatch(...)
		end
	end

	return self
end

--[[
	Get the current state of the Store. Do not mutate this!
]]
function Store:getState()
	if self._isDispatching then
		error(("You may not call store:getState() while the reducer is executing. " ..
			"The reducer (%s) has already received the state as an argument. " ..
			"Pass it down from the top reducer instead of reading it from the store."):format(tostring(self._reducer)))
	end

	return self._state
end

--[[
	Dispatch an action to the store. This allows the store's reducer to mutate
	the state of the application by creating a new copy of the state.

	Listeners on the changed event of the store are notified when the state
	changes, but not necessarily on every Dispatch.
]]
function Store:dispatch(action)
	if typeof(action) ~= "table" then
		error(("Actions must be tables. " ..
			"Use custom middleware for %q actions."):format(typeof(action)),
			2
		)
	end

	if action.type == nil then
		error("Actions may not have an undefined 'type' property. " ..
			"Have you misspelled a constant? \n" ..
			tostring(action), 2)
	end

	if self._isDispatching then
		error("Reducers may not dispatch actions.")
	end

	local ok, result = pcall(function()
		self._isDispatching = true
		self._state = self._reducer(self._state, action)
		self._mutatedSinceFlush = true
	end)

	self._isDispatching = false

	if not ok then
		self._errorReporter.reportReducerError(
			self._state,
			action,
			{
				message = "Caught error in reducer",
				thrownValue = result,
			}
		)
	end

	if #self._actionLog == ACTION_LOG_LENGTH then
		table.remove(self._actionLog, 1)
	end
	table.insert(self._actionLog, action)
end

--[[
	Marks the store as deleted, disconnecting any outstanding connections.
]]
function Store:destruct()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end

	self._connections = nil
end

--[[
	Flush all pending actions since the last change event was dispatched.
]]
function Store:flush()
	if not self._mutatedSinceFlush then
		return
	end

	self._mutatedSinceFlush = false

	-- On self.changed:fire(), further actions may be immediately dispatched, in
	-- which case self._lastState will be set to the most recent self._state,
	-- unless we cache this value first
	local state = self._state

	local ok, errorResult = xpcall(function()
		-- If a changed listener yields, *very* surprising bugs can ensue.
		-- Because of that, changed listeners cannot yield.
		NoYield(function()
			self.changed:fire(state, self._lastState)
		end)
	end, tracebackReporter)

	if not ok then
		self._errorReporter.reportUpdateError(
			self._lastState,
			state,
			self._actionLog,
			{
				message = "Caught error flushing store updates",
				thrownValue = errorResult,
			}
		)
	end

	self._lastState = state
end

return Store
 end, _env("RemoteSpy.include.node_modules.rodux.src.Store"))() end)

_module("combineReducers", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src.combineReducers", "RemoteSpy.include.node_modules.rodux.src", function () return setfenv(function() --[[
	Create a composite reducer from a map of keys and sub-reducers.
]]
local function combineReducers(map)
	return function(state, action)
		-- If state is nil, substitute it with a blank table.
		if state == nil then
			state = {}
		end

		local newState = {}

		for key, reducer in pairs(map) do
			-- Each reducer gets its own state, not the entire state table
			newState[key] = reducer(state[key], action)
		end

		return newState
	end
end

return combineReducers
 end, _env("RemoteSpy.include.node_modules.rodux.src.combineReducers"))() end)

_module("createReducer", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src.createReducer", "RemoteSpy.include.node_modules.rodux.src", function () return setfenv(function() return function(initialState, handlers)
	return function(state, action)
		if state == nil then
			state = initialState
		end

		local handler = handlers[action.type]

		if handler then
			return handler(state, action)
		end

		return state
	end
end
 end, _env("RemoteSpy.include.node_modules.rodux.src.createReducer"))() end)

_module("loggerMiddleware", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src.loggerMiddleware", "RemoteSpy.include.node_modules.rodux.src", function () return setfenv(function() -- We want to be able to override outputFunction in tests, so the shape of this
-- module is kind of unconventional.
--
-- We fix it this weird shape in init.lua.
local prettyPrint = require(script.Parent.prettyPrint)
local loggerMiddleware = {
	outputFunction = print,
}

function loggerMiddleware.middleware(nextDispatch, store)
	return function(action)
		local result = nextDispatch(action)

		loggerMiddleware.outputFunction(("Action dispatched: %s\nState changed to: %s"):format(
			prettyPrint(action),
			prettyPrint(store:getState())
		))

		return result
	end
end

return loggerMiddleware
 end, _env("RemoteSpy.include.node_modules.rodux.src.loggerMiddleware"))() end)

_module("makeActionCreator", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src.makeActionCreator", "RemoteSpy.include.node_modules.rodux.src", function () return setfenv(function() --[[
	A helper function to define a Rodux action creator with an associated name.
]]
local function makeActionCreator(name, fn)
	assert(type(name) == "string", "Bad argument #1: Expected a string name for the action creator")

	assert(type(fn) == "function", "Bad argument #2: Expected a function that creates action objects")

	return setmetatable({
		name = name,
	}, {
		__call = function(self, ...)
			local result = fn(...)

			assert(type(result) == "table", "Invalid action: An action creator must return a table")

			result.type = name

			return result
		end
	})
end

return makeActionCreator
 end, _env("RemoteSpy.include.node_modules.rodux.src.makeActionCreator"))() end)

_module("prettyPrint", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src.prettyPrint", "RemoteSpy.include.node_modules.rodux.src", function () return setfenv(function() local indent = "    "

local function prettyPrint(value, indentLevel)
	indentLevel = indentLevel or 0
	local output = {}

	if typeof(value) == "table" then
		table.insert(output, "{\n")

		for tableKey, tableValue in pairs(value) do
			table.insert(output, indent:rep(indentLevel + 1))
			table.insert(output, tostring(tableKey))
			table.insert(output, " = ")

			table.insert(output, prettyPrint(tableValue, indentLevel + 1))
			table.insert(output, "\n")
		end

		table.insert(output, indent:rep(indentLevel))
		table.insert(output, "}")
	elseif typeof(value) == "string" then
		table.insert(output, string.format("%q", value))
		table.insert(output, " (string)")
	else
		table.insert(output, tostring(value))
		table.insert(output, " (")
		table.insert(output, typeof(value))
		table.insert(output, ")")
	end

	return table.concat(output, "")
end

return prettyPrint end, _env("RemoteSpy.include.node_modules.rodux.src.prettyPrint"))() end)

_module("thunkMiddleware", "ModuleScript", "RemoteSpy.include.node_modules.rodux.src.thunkMiddleware", "RemoteSpy.include.node_modules.rodux.src", function () return setfenv(function() --[[
	A middleware that allows for functions to be dispatched.
	Functions will receive a single argument, the store itself.
	This middleware consumes the function; middleware further down the chain
	will not receive it.
]]
local function tracebackReporter(message)
	return debug.traceback(message)
end

local function thunkMiddleware(nextDispatch, store)
	return function(action)
		if typeof(action) == "function" then
			local ok, result = xpcall(function()
				return action(store)
			end, tracebackReporter)

			if not ok then
				-- report the error and move on so it's non-fatal app
				store._errorReporter.reportReducerError(store:getState(), action, {
					message = "Caught error in thunk",
					thrownValue = result,
				})
				return nil
			end

			return result
		end

		return nextDispatch(action)
	end
end

return thunkMiddleware
 end, _env("RemoteSpy.include.node_modules.rodux.src.thunkMiddleware"))() end)

_instance("roselect", "Folder", "RemoteSpy.include.node_modules.roselect", "RemoteSpy.include.node_modules")

_module("src", "ModuleScript", "RemoteSpy.include.node_modules.roselect.src", "RemoteSpy.include.node_modules.roselect", function () return setfenv(function() local function defaultEqualityCheck(a, b)
	return a == b
end

local function isDictionary(tbl)
	if type(value) ~= "table" then
		return false
	end

	for k, _ in pairs(tbl) do
		if type(k) ~= "number" then
			return true
		end
	end
	
	return false
end

local function isDependency(value)
	return type(value) == "table" and isDictionary(value) == false and value["dependencies"] == nil
end

local function reduce(tbl, callback, initialValue)
        tbl = tbl or {}
	local value = initialValue or tbl[1]

	for i, v in ipairs(tbl) do
		value = callback(value, v, i)
	end

	return value
end

local function areArgumentsShallowlyEqual(equalityCheck, prev, nextValue)
	if prev == nil or nextValue == nil or #prev ~= #nextValue then
		return false
	end

	for i = 1, #prev do
		if equalityCheck(prev[i], nextValue[i]) == false then
			return false
		end
	end

	return true
end

local function defaultMemoize(func, equalityCheck)
	if equalityCheck == nil then
		equalityCheck = defaultEqualityCheck
	end

	local lastArgs
	local lastResult

	return function(...)
		local args = {...}

		if areArgumentsShallowlyEqual(equalityCheck, lastArgs, args) == false then
			lastResult = func(unpack(args))
		end

		lastArgs = args
		return lastResult
	end
end

local function getDependencies(funcs)
	local dependencies = if isDependency(funcs[1]) then funcs[1] else funcs

	for _, dep in ipairs(dependencies) do
		if isDependency(dep) then
			error("Selector creators expect all input-selectors to be functions.", 2)
		end
	end

	return dependencies
end

local function createSelectorCreator(memoize, ...)
	local memoizeOptions = {...}

	return function(...)
		local funcs = {...}

		local recomputations = 0
		local resultFunc = table.remove(funcs, #funcs)
		local dependencies = getDependencies(funcs)

		local memoizedResultFunc = memoize(
			function(...)
				recomputations += 1
				return resultFunc(...)
			end,
			unpack(memoizeOptions)
		)

		local selector = setmetatable({
			resultFunc = resultFunc,
			dependencies = dependencies,
			recomputations = function()
				return recomputations
			end,
			resetRecomputations = function()
				recomputations = 0
				return recomputations
			end
		}, {
			__call = memoize(function(self, ...)
				local params = {}

				for i = 1, #dependencies do
					table.insert(params, dependencies[i](...))
				end

				return memoizedResultFunc(unpack(params))
			end)
		})

		return selector
	end
end

local createSelector = createSelectorCreator(defaultMemoize)

local function createStructuredSelector(selectors, selectorCreator)
	if type(selectors) ~= "table" then
		error((
			"createStructuredSelector expects first argument to be an object where each property is a selector, instead received a %s"
		):format(type(selectors)), 2)
	elseif selectorCreator == nil then
		selectorCreator = createSelector
	end

	local keys = {}
	for key, _ in pairs(selectors) do
		table.insert(keys, key)
	end

	local funcs = table.create(#keys)
	for _, key in ipairs(keys) do
		table.insert(funcs, selectors[key])
	end

	return selectorCreator(
		funcs,
		function(...)
			return reduce({...}, function(composition, value, index)
				composition[keys[index]] = value
				return composition
			end)
		end
	)
end

return {
	defaultMemoize = defaultMemoize,
	reduce = reduce,
	createSelectorCreator = createSelectorCreator,
	createSelector = createSelector,
	createStructuredSelector = createStructuredSelector,
} end, _env("RemoteSpy.include.node_modules.roselect.src"))() end)

_module("services", "ModuleScript", "RemoteSpy.include.node_modules.services", "RemoteSpy.include.node_modules", function () return setfenv(function() return setmetatable({}, {
	__index = function(self, serviceName)
		local service = game:GetService(serviceName)
		self[serviceName] = service
		return service
	end,
})
 end, _env("RemoteSpy.include.node_modules.services"))() end)

_instance("types", "Folder", "RemoteSpy.include.node_modules.types", "RemoteSpy.include.node_modules")

_instance("include", "Folder", "RemoteSpy.include.node_modules.types.include", "RemoteSpy.include.node_modules.types")

_instance("generated", "Folder", "RemoteSpy.include.node_modules.types.include.generated", "RemoteSpy.include.node_modules.types.include")

start()