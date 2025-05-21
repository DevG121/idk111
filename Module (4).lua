-- [ Initialize ] --
-- Destroy Previous UI's --
if _G.DivineInstance then
    pcall(function()
        _G.DivineInstance:Destroy() -- Safely destroy existing GUI
    end)
end

-- Set Global Reference --
_G.DivineInstance = Divine.ScreenGui -- Track the ScreenGui directly

-- [ Yield ] --
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- // CONSTANTS \\ --
-- [ Services ] --
local Services = setmetatable({}, {
	__index = function(self, serviceName)
		local service = game:GetService(serviceName)
		if service then
			rawset(self, serviceName, service)
		end
		return service
	end
})

-- [ LocalPlayer ] --
local LocalPlayer = Services.Players.LocalPlayer

-- // Variables \\ --
local LassoActive = false
local SelectedParts = {}
local Camera = workspace.CurrentCamera
local PModels = workspace:FindFirstChild("PlayerModels")
local highlightedItems = {}


-- [ Other ] --
local Binds = {}

-- // Functions \\ --
local Utility = {
	new = function(Class, Properties, Children)
		-- Your existing new() implementation
		local NewInstance = Instance.new(Class)
		-- ... rest of your utility code ...
		return NewInstance
	end,
	Tween = function(Object, TweenInfo, Goal)
		-- Your existing Tween implementation
	end,
	CreateDrag = function(Frame, Parent, Settings)
		-- Your existing drag implementation
	end
}

--[[
Utility.new(Class: string, Properties: Dictionary, Children: Array)
    Creates a new object with the Properties
]]
function Utility.new(Class, Properties, Children)
	local NewInstance = Instance.new(Class)
	for i,v in pairs(Properties or {}) do
		if i ~= "Parent" then
			NewInstance[i] = v
		end
	end
	for i,v in ipairs(Children or {}) do
		if typeof(v) == "Instance" then
			v.Parent = NewInstance
		end
	end

	NewInstance.Parent = Properties.Parent
	return NewInstance
end

--[[
Utility.Tween(Object: Instance, TweenInformation: TweenInfo, Goal: Dictionary)
    Creates a tween
]]
function Utility.Tween(Object, TweenInformation, Goal)
	-- [ Tween ] --
	local Tween = Services.TweenService:Create(Object, TweenInformation, Goal)

	-- [ Info ] --
	local Info = {}

	-- Yield --
	function Info:Yield()
		Tween:Play()
		Tween.Completed:Wait(10)
	end

	return setmetatable(Info, {__index = function(Self, Index)
		local Value = Tween[Index]
		return typeof(Value) ~= "function" and Value or function(self, ...)
			return Tween[Index](Tween, ...)
		end
	end})
end

--[[
Utility:Wait()
    Yields for a short period of time.
]]
function Utility.Wait(Seconds)
	if Seconds then
		local StartTime = time()
		repeat
			Services.RunService.Heartbeat:Wait(0.1)
		until time() - StartTime > Seconds
	else
		return Services.RunService.Heartbeat:Wait(0.1)
	end
end

--[[
Utility.BindKey(Key: KeyCode, Callback: Function, ID: string)
    Binds a key
]]
function Utility.BindKey(Key, Callback, ID)
	local BindID = ID or Services.HttpService:GenerateGUID(true)
	Services.ContextActionService:BindAction(BindID, Callback, false, Key)
	return BindID
end

--[[
Utility:DraggingEnabled()
    Allows Dragging for the Frame Provided
]]
function Utility.CreateDrag(Frame, Parent, Settings)
	-- Main --
	local DragPro = {
		DragEnabled = true;
		Dragging = false;
		Settings = Settings or {
			TweenDuration = 0.1,
			TweenStyle = Enum.EasingStyle.Quad
		}
	}

	-- Info --
	local DragInfo = {
		Parent = Parent or Frame;
		DragInput = nil;
		MousePosition = nil;
		FramePosition = nil;
	}

	-- Script --
	local Connections = {}

	function DragPro:Initialize()
		table.insert(Connections,
			Frame.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					DragPro.Dragging = true
					DragInfo.MousePosition = Input.Position
					DragInfo.FramePosition = DragInfo.Parent.Position

					repeat
						Input.Changed:Wait()
					until Input.UserInputState == Enum.UserInputState.End
					DragPro.Dragging = false
				end
			end)
		)

		table.insert(Connections,
			Frame.InputChanged:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
					DragInfo.DragInput = Input
				end
			end)
		)

		table.insert(Connections,
			Services.UserInputService.InputChanged:Connect(function(Input)
				if DragPro.Dragging and Input == DragInfo.DragInput then
					local delta = Input.Position - DragInfo.MousePosition
					local newPosition = UDim2.new(
						DragInfo.FramePosition.X.Scale,
						DragInfo.FramePosition.X.Offset + delta.X,
						DragInfo.FramePosition.Y.Scale,
						DragInfo.FramePosition.Y.Offset + delta.Y
					)
					Parent.Position = newPosition

				end
			end)
		)
	end

	-- Functions --
	function DragPro:Destroy()
		for i,v in ipairs(Connections) do
			v:Disconnect()
		end
	end

	DragPro:Initialize()

	-- Return --
	return DragPro
end

-- // Main Module \\ --
-- [ Divine ] --
local Divine = {
	Utility = Utility,
	ScreenGui = Utility.new("ScreenGui", {
		DisplayOrder = 5,
		Name = "Divine",
		Parent = Services.RunService:IsStudio() and LocalPlayer:FindFirstChildOfClass("PlayerGui") or Services.CoreGui,
		IgnoreGuiInset = true,
		ResetOnSpawn = false
	});
	Settings = {
		Name = "Template";
		Debug = false;
	};
	ColorScheme = {
		Primary = Color3.fromRGB(255, 0, 255);
		Text = Color3.new(255, 255, 255);
	};
}
-- Create selection box
Divine.SelectionBox = Utility.new("Frame", {
	Name = "SelectionBox",
	Parent = Divine.ScreenGui,
	BackgroundColor3 = Color3.fromRGB(255, 0, 255), -- Green color
	BackgroundTransparency = 0.3,
	BorderSizePixel = 2,
	BorderColor3 = Color3.fromRGB(197, 0, 197),
	ZIndex = 100,
	AnchorPoint = Vector2.new(0, 0),
	Visible = false
})


-- Intro --
function Divine.LoadingScreen()
	coroutine.wrap(function()
		local LoadingScreen = Utility.new("Frame", {
			Name = "LoadingScreen",
			Parent = Divine.ScreenGui,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 5
		}, {
			Utility.new("VideoFrame", {
				Name = "LoadingVideo",
				Visible = false,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(0, 750, 0, 425),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				ZIndex = 10,
				Looped = true,
				Playing = true,
				TimePosition = 0,
				Video = "rbxassetid://5608337069"
			})
		})
		Utility.Tween(LoadingScreen, TweenInfo.new(1), {BackgroundTransparency = 0}):Yield()

		-- Loading --    
		if not LoadingScreen.LoadingVideo.IsLoaded then
			LoadingScreen.LoadingVideo.Loaded:Wait(10)
		end
		LoadingScreen.LoadingVideo.Visible = true

		-- Wait for all assets to load --
		Utility.Wait(2.5)
		Services.ContentProvider:PreloadAsync({Divine.ScreenGui})
		Utility.Wait(0.25)

		-- Destroy Screen --
		LoadingScreen.LoadingVideo.Visible = false
		Utility.Tween(LoadingScreen, TweenInfo.new(1), {BackgroundTransparency = 1}):Yield()
		LoadingScreen:Destroy()
	end)()
	Utility.Wait(1)
end

-- [ Options ] --
local function CreateOptions(Frame)
	local Options = {}

	function Options.TextLabel(Title)
		local Container = Utility.new("Frame", {
			Name = "Switch",
			Parent = typeof(Frame) == "Instance" and Frame or Frame(),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 25),
		}, {
			Utility.new("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 1, 0),
				Font = Enum.Font.Gotham,
				Text = Title and tostring(Title) or "TextLabel",
				RichText = true,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.3,
				TextXAlignment = Enum.TextXAlignment.Left
			})
		})

		local Properties = {
			Text = Title and tostring(Title) or "TextLabel";
		}

		return setmetatable({}, {
			__index = function(Self, Index)
				return Properties[Index]
			end;
			__newindex = function(Self, Index, Value)
				if Index == "Text" then
					Container.Title.Text = Value and tostring(Value) or "TextLabel"
				end
				Properties[Index] = Value
			end;
		})
	end

	function Options.Button(Title, ButtonText, Callback)
		local Properties = {
			Title = Title and tostring(Title) or "Button";
			Function = Callback or function(Status) end;
		}

		local Container = Utility.new("ImageButton", {
			Name = "Button",
			Parent = typeof(Frame) == "Instance" and Frame or Frame(),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 25),
		}, {
			Utility.new("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0.5, 0, 1, 0),
				Font = Enum.Font.Gotham,
				Text = Title and tostring(Title) or "Button",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.3,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			Utility.new("TextButton", {
				Name = "Button",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(50, 55, 60),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0.2, 25, 0, 20),
				Text = ButtonText and tostring(ButtonText) or "Button",
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextTransparency = 0.3
			}, {
				Utility.new("UICorner", {CornerRadius = UDim.new(0, 4)})
			})
		})

		Container.Button.MouseButton1Down:Connect(function()
			local Success, Error = pcall(Properties.Function)
			assert(Divine.Settings.Debug == false or Success, Error)
		end)

		return setmetatable({}, {
			__index = function(Self, Index)
				return Properties[Index]
			end;
			__newindex = function(Self, Index, Value)
				if Index == "Title" then
					Container.Title.Text = Value and tostring(Value) or "Button"
				elseif Index == "ButtonText" then
					Container.Button.Text = Value and tostring(Value) or "Button"
				end
				Properties[Index] = Value
			end
		})
	end

	function Options.Switch(Title, Callback)
		local Properties = {
			Title = Title and tostring(Title) or "Switch";
			Value = false;
			Function = Callback or function(Status) end;
		}

		local Container = Utility.new("ImageButton", {
			Name = "Switch",
			Parent = typeof(Frame) == "Instance" and Frame or Frame(),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 25),
		}, {
			Utility.new("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Font = Enum.Font.Gotham,
				Text = Title and tostring(Title) or "Switch",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.3,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			Utility.new("Frame", {
				Name = "Switch",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(100, 100, 100),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 25, 0, 15),
			}, {
				Utility.new("UICorner", {CornerRadius = UDim.new(1, 0)}),
				Utility.new("Frame", {
					Name = "Circle",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14)
				}, {Utility.new("UICorner", {CornerRadius = UDim.new(1, 0)})})
			})
		})

		local Tweens = {
			[true] = {
				Utility.Tween(Container.Switch, TweenInfo.new(0.5), {BackgroundColor3 = Divine.ColorScheme.Primary}),
				Utility.Tween(Container.Switch.Circle, TweenInfo.new(0.25), {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0)})
			};

			[false] = {
				Utility.Tween(Container.Switch, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}),
				Utility.Tween(Container.Switch.Circle, TweenInfo.new(0.25), {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0)})
			};
		}

		Container.MouseButton1Down:Connect(function()
			Properties.Value = not  Properties.Value
			for i,v in ipairs(Tweens[Properties.Value]) do
				v:Play()
			end
			local Success, Error = pcall(Properties.Function, Properties.Value)
			assert(Divine.Settings.Debug == false or Success, Error)
		end)

		return setmetatable({}, {
			__index = function(Self, Index)
				return Properties[Index]
			end;
			__newindex = function(Self, Index, Value)
				if Index == "Title" then
					Container.Title.Text = Value and tostring(Value) or "Switch"
				elseif Index == "Value" then
					for i,v in ipairs(Tweens[Value]) do
						v:Play()
					end
					local Success, Error = pcall(Properties.Function, Value)
					assert(Divine.Settings.Debug == false or Success, Error)
				end
				Properties[Index] = Value
			end;
		})
	end

	function Options.Toggle(Title, Callback)
		local Properties = {
			Title = Title and tostring(Title) or "Switch";
			Value = false;
			Function = Callback or function(Status) end;
		}

		local Container = Utility.new("ImageButton", {
			Name = "Toggle",
			Parent = typeof(Frame) == "Instance" and Frame or Frame(),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 25)
		}, {
			Utility.new("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Font = Enum.Font.Gotham,
				Text = Title and tostring(Title) or "Switch",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.3,
				TextXAlignment = Enum.TextXAlignment.Left
			}),

			Utility.new("ImageLabel", {
				Name = "Toggle",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 20, 0, 20),
				ZIndex = 2,
				Image = "rbxassetid://6031068420"
			}, {
				Utility.new("ImageLabel", {
					Name = "Fill",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Image = "rbxassetid://6031068421",
					ImageTransparency = 1
				})
			})
		})

		local Tweens = {
			[true] = {
				Utility.Tween(Container.Toggle.Fill, TweenInfo.new(0.2), {ImageTransparency = 0}),
				Utility.Tween(Container.Toggle, TweenInfo.new(0.5), {ImageColor3 = Color3.fromRGB(240, 240, 240)})
			};
			[false] = {
				Utility.Tween(Container.Toggle.Fill, TweenInfo.new(0.2), {ImageTransparency = 1}),
				Utility.Tween(Container.Toggle, TweenInfo.new(0.5), {ImageColor3 = Color3.fromRGB(255, 255, 255)})
			};
		}

		Container.MouseButton1Down:Connect(function()
			Properties.Value = not Properties.Value
			for i,v in ipairs(Tweens[Properties.Value]) do
				v:Play()
			end
			local Success, Error = pcall(Properties.Function, Properties.Value)
			assert(Divine.Settings.Debug == false or Success, Error)
		end)

		return setmetatable({}, {
			__index = function(Self, Index)
				return Properties[Index]
			end;
			__newindex = function(Self, Index, Value)
				if Index == "Title" then
					Container.Title.Text = Value and tostring(Value) or "Switch"
				elseif Index == "Value" then
					for i,v in ipairs(Tweens[Value]) do
						v:Play()
					end
					local Success, Error = pcall(Properties.Function, Value)
					assert(Divine.Settings.Debug == false or Success, Error)
				end
				Properties[Index] = Value
			end
		})
	end

	function Options.TextBox(Title, PlaceHolder, Callback)
		local Properties = {
			Title = Title and tostring(Title) or "TextBox";
			Value = "";
			PlaceHolder = PlaceHolder and tostring(PlaceHolder) or "Input";
			Function = Callback or function(Status) end;
		}

		local Container = Utility.new("ImageButton", {
			Name = "TextBox",
			Parent = typeof(Frame) == "Instance" and Frame or Frame(),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 25)
		}, {
			Utility.new("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0.5, 0, 1, 0),
				Font = Enum.Font.Gotham,
				Text = Title and tostring(Title) or "TextBox",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.3,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			Utility.new("ImageLabel", {
				Name = "TextBox",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0.2, 25, 0, 20),
				Image = "rbxassetid://3570695787",
				ImageColor3 = Color3.fromRGB(50, 55, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(100, 100, 100, 100),
				SliceScale = 0.04
			}, {
				Utility.new("TextBox", {
					Name = "Input",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Font = Enum.Font.Gotham,
					PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
					PlaceholderText = PlaceHolder and tostring(PlaceHolder) or "Input",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.3,
					TextXAlignment = Enum.TextXAlignment.Left
				}, {Utility.new("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})})
			})
		})

		Container.MouseButton1Down:Connect(function()
			Container.TextBox.Input:CaptureFocus()
		end)

		Container.TextBox.Input:GetPropertyChangedSignal("Text"):Connect(function()
			local TextLength = Container.TextBox.Input.TextBounds.X
			local MaxSize = (Container.AbsoluteSize.X - Container.Title.TextBounds.X) - 40
			if Container.TextBox.Input.TextTruncate == Enum.TextTruncate.None then
				Utility.Tween(Container.TextBox, TweenInfo.new(0.1), {Size = UDim2.new(0.2, math.clamp(TextLength - (Container.AbsoluteSize.X * 0.2) + 15, 25, MaxSize), 0, 20)}):Play()
			end
			Container.TextBox.Input.TextTruncate = TextLength + 10 > MaxSize and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
			Properties.Value = Container.TextBox.Input.Text
		end)

		Container.TextBox.Input.FocusLost:Connect(function(EnterPressed, Input)
			if EnterPressed then
				coroutine.wrap(function()
					local Success, Error = pcall(Properties.Function, Properties.Value)
					assert(Divine.Settings.Debug == false or Success, Error)
				end)
				Container.TextBox.Input.Text = ""
			end
		end)

		return setmetatable({}, {
			__index = function(Self, Index)
				return Properties[Index]
			end;
			__newindex = function(Self, Index, Value)
				if Index == "Title" then
					Container.Title.Text = Value and tostring(Value) or "TextBox"
				elseif Index == "Placeholder" then
					Container.TextBox.Input.PlaceholderText = Value and tostring(Value) or "Input"
				elseif Index == "Value" then
					Container.TextBox.Input.Text = Value and tostring(Value) or ""
				end
				Properties[Index] = Value
			end
		})
	end

	function Options.Dropdown(Title, List, Callback, Placeholder)
		local Properties = {
			Title = Title and tostring(Title) or "Dropdown";
			Value = nil;
			List = List or {};
			Function = Callback or function(Value) end;
			Placeholder = Placeholder and tostring(Placeholder) or "Select...";
			_options = {},
			_container = nil,
			_parentFrame = Frame,
			_isExpanded = false
		}

		local Container = Utility.new("ImageButton", {
			Name = "Dropdown",
			Parent = typeof(Frame) == "Instance" and Frame or Frame(),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 25)
		}, {
			Utility.new("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0.5, 0, 1, 0),
				Font = Enum.Font.Gotham,
				Text = Title and tostring(Title) or "Dropdown",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.3,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			Utility.new("ImageLabel", {
				Name = "Dropdown",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0.2, 25, 0, 20),
				Image = "rbxassetid://3570695787",
				ImageColor3 = Color3.fromRGB(50, 55, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(100, 100, 100, 100),
				SliceScale = 0.04
			}, {
				Utility.new("TextButton", {
					Name = "Button",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Text = Properties.Placeholder,
					Font = Enum.Font.Gotham,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.3
				})
			})
		})

		-- [NEW OPTION SYSTEM] --
		local OptionContainer = Utility.new("Frame", {
			Name = "ExpandFrame",
			Parent = Container,
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			Position = UDim2.new(0, 0, 1, 5),
			Size = UDim2.new(1, 0, 0, 0),
			Visible = false
		}, {
			Utility.new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2)
			})
		})

		function Properties:AddOption(OptionName, Icon)
			local OptionFrame = Utility.new("Frame", {
				Name = "Option",
				Parent = OptionContainer,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 25),
				LayoutOrder = #OptionContainer:GetChildren()
			}, {
				-- ADD THESE ELEMENTS --
				Utility.new("TextLabel", {
					Name = "Label",
					Text = OptionName,
					-- ... text properties ...
					_searchable = true
				}),
				Utility.new("Frame", {
					Name = "SwitchContainer",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.new(0, 50, 0, 25),
					BackgroundTransparency = 1
				})
			})

		end -- ✅ Close AddOption function

		-- [TOGGLE LOGIC] --
		Container.Dropdown.Button.MouseButton1Click:Connect(function()
			OptionContainer.Visible = not OptionContainer.Visible
			OptionContainer.Size = UDim2.new(1, 0, 0, OptionContainer.UIListLayout.AbsoluteContentSize.Y)
		end)

		-- Return the Dropdown object
		return setmetatable({}, {
			__index = Properties,
			__newindex = function(t, index, value)
				if index == "Value" then
					Container.Dropdown.Button.Text = tostring(value)
					Properties.Function(value)
				end
			end
		})
	end -- ✅ Close Dropdown function


	function Options.Slider(Title, Settings, Callback)
		Settings = Settings or {}
		local Properties = {
			Title = Title and tostring(Title) or "Slider";
			Value = nil;
			Settings = Settings;
			Function = Callback or function(Status) end;
		}
		for i,v in pairs({Precise = false, Default = 30, Min = 1, Max = 300}) do
			if Properties.Settings[i] == nil then
				Properties.Settings[i] = v
			end
		end
		Properties.Value = math.clamp(Properties.Settings.Default or Properties.Settings.Min, Properties.Settings.Min, Properties.Settings.Max)

		local Container = Utility.new("ImageButton", {
			Name = "Slider",
			Parent = typeof(Frame) == "Instance" and Frame or Frame(),
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
			BackgroundTransparency = 0,
			Size = UDim2.new(1, 0, 0, 35),
			AutoButtonColor = false,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(100, 100, 100, 100),
			SliceScale = 0.04
		}, {
			-- ✅ ADD THIS TITLE TEXT LABEL ▼
			Utility.new("TextLabel", {
				Name = "Title",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 0), -- X=10px from left, Y=5px from top
				Size = UDim2.new(0.5, -15, 0, 20), -- Half width minus padding
				Font = Enum.Font.Gotham,
				Text = Title or "Slider", -- Uses the "Speed Multiplier" text from your LocalScript
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.3,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			-- Add UICorner for rounded edges
			Utility.new("UICorner", {
				CornerRadius = UDim.new(0, 6) -- Match dropdown corner radius
			}),

			Utility.new("TextBox", {
				Name = "Value",
				Active = true,
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Position = UDim2.new(1, 0, 0, 2),
				Size = UDim2.new(0, 75, 0, 20),
				Font = Enum.Font.Gotham,
				Text = tostring(Properties.Value),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				TextTransparency = 0.3,
				TextXAlignment = Enum.TextXAlignment.Right
			}),

			Utility.new("ImageLabel", {
				Name = "Bar",
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0, 25),
				Size = UDim2.new(1, 5, 0, 5),
				Image = "rbxassetid://3570695787", -- Rounded rectangle asset
				ImageColor3 = Color3.fromRGB(100, 100, 100), -- Secondary color (adjust to match dropdowns)
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(100, 100, 100, 100), -- Rounded edges
				SliceScale = 0.04
			}, {
				Utility.new("ImageLabel", {
					Name = "Fill",
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 0, 1, 0),
					Image = "rbxassetid://3570695787", -- Same rounded asset
					ImageColor3 = Divine.ColorScheme.Primary, -- Primary color (pink)
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(100, 100, 100, 100),
					SliceScale = 0.04
				}, {
					Utility.new("Frame", {
						Name = "Circle",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0,
						ZIndex = 2,
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 10, 0, 10)
					}, {
						Utility.new("UICorner", {CornerRadius = UDim.new(1, 0)}),
						Utility.new("Frame", {
							Name = "Ripple",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 0.1,
							Position = UDim2.new(0.5, 0, 0.5, 0),
							Size = UDim2.new(0, 0, 0, 0)
						}, {Utility.new("UICorner", {CornerRadius = UDim.new(1, 0)})})
					})
				})
			})
		})

		local Info = {
			Sliding = false;
			LastSelected = 0;
			LastUpdated = 0;
			Idled = false;
		}

		local function UpdateSlider	(Value)
			if time() - Info.LastUpdated < 0.01 then
				return
			end
			Info.LastUpdated = time()

			Value = math.floor(Value + 0.5) -- Rounds to nearest integer

			Value = math.clamp(Value, Properties.Settings.Min, Properties.Settings.Max)
			if Properties.Settings.Precise then
				Value = math.floor(Value + 0.5)
			end
			Container.Value.Text = tostring(Value)
			Properties.Value = Value
			local Percentage = math.clamp((Value - Properties.Settings.Min) / (Properties.Settings.Max - Properties.Settings.Min), 0, 1)
			Utility.Tween(Container.Bar.Fill, TweenInfo.new(0.1), {Size = UDim2.new(Percentage, 0, 1, 0)}):Play()
		end

		Services.UserInputService.InputChanged:Connect(function(Input)
			if Info.Sliding == true and Input.UserInputType == Enum.UserInputType.MouseMovement then
				UpdateSlider(((Input.Position.X - Container.Bar.AbsolutePosition.X) / Container.Bar.AbsoluteSize.X) * Properties.Settings.Max)
				Info.LastSelected = time()
				local Success, Error = pcall(Properties.Function, Properties.Value)
				assert(Divine.Settings.Debug == false or Success, Error)
			end
		end)

		local CircleTweens = {
			Visible = Utility.Tween(Container.Bar.Fill.Circle, TweenInfo.new(0.25), {BackgroundTransparency = 0}), -- Keep visible
			Hidden = Utility.Tween(Container.Bar.Fill.Circle, TweenInfo.new(0.5), {BackgroundTransparency = 0}) -- Never hide
		}
		local RippleTweens = {
			Visible = Utility.Tween(Container.Bar.Fill.Circle.Ripple, TweenInfo.new(0.25), {Size = UDim2.new(0, 26, 0, 26), BackgroundTransparency = 0.75}),
			Hidden = Utility.Tween(Container.Bar.Fill.Circle.Ripple, TweenInfo.new(0.25), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
		}
		Container.MouseButton1Down:Connect(function()
			Info.Sliding = true
			UpdateSlider(((Services.UserInputService:GetMouseLocation().X - Container.Bar.AbsolutePosition.X) / Container.Bar.AbsoluteSize.X) * Properties.Settings.Max)
			Info.LastSelected = time()
			CircleTweens.Visible:Play()
			RippleTweens.Visible:Play()
			local Success, Error = pcall(Properties.Function, Properties.Value)
			assert(Divine.Settings.Debug == false or Success, Error)
		end)
		Container.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Info.Sliding = false
				Info.LastSelected = time()

				RippleTweens.Hidden:Play()
				Info.Idled = true
				repeat
					Utility.Wait(0.1)
					if Info.Idled == false then
						return
					end
				until time() - Info.LastSelected > 2.5
				CircleTweens.Hidden:Play()
				Info.Idled = false
			end
		end)

		Container.Value.FocusLost:Connect(function()
			local Text = Container.Value.Text
			if Text == "" then
				-- Replace with code to force integers:
				if Text == "" then
					Container.Value.Text = tostring(Properties.Settings.Min)
				else
					-- Convert to integer
					local Number = math.floor(tonumber(Text) or Properties.Settings.Min)
					Container.Value.Text = tostring(Number)
				end
				UpdateSlider(tonumber(Container.Value.Text) or Properties.Settings.Min)
			end
		end)

		Container.Value:GetPropertyChangedSignal("Text"):Connect(function()
			local Text = Container.Value.Text
			if not table.find({"", "-"}, Text) and not tonumber(Text) then
				Container.Value.Text = Text:sub(1, #Text - 1)
			elseif not table.find({"", "-"}, Text) then
				UpdateSlider(tonumber(Text))
			end
		end)

		UpdateSlider(Properties.Value)
		return setmetatable({}, {
			__index = function(Self, Index)
				return Properties[Index]
			end;
			__newindex = function(Self, Index, Value)
				if Index == "Title" then
					Container.Title.Text = Value and tostring(Value) or "TextBox"
				elseif Index == "Value" then
					UpdateSlider(tonumber(Value))
				end
				Properties[Index] = Value
			end
		})
	end
	return Options
end

function Divine.new(Name, Header, Icon)
	local Main = Utility.new(
		-- Class --
		"ImageButton",

		-- Properties --
		{
			Name = "Main",
			Parent = Divine.ScreenGui,
			Active = true,
			Modal = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 700, 0, 475),
			ZIndex = 0,
			ClipsDescendants = true,
			Image = "rbxassetid://3570695787",
			ImageColor3 = Color3.fromRGB(0, 0, 0),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(100, 100, 100, 100),
			SliceScale = 0.1
		},

		-- Children --
		{
			-- Contents
			Utility.new("Frame", {
				Name = "Contents",
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Position = UDim2.new(0, 200, 0, 0),
				Size = UDim2.new(1, -200, 1, 0),
				ZIndex = 0
			}, {
				Utility.new("UIPageLayout", {
					EasingStyle = Enum.EasingStyle.Quad,
					TweenTime = 0.25,
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					GamepadInputEnabled = false,
					ScrollWheelInputEnabled = false,
					TouchInputEnabled = false
				})
			}),

			-- SideBar
			Utility.new("ImageLabel", {
				Name = "SideBar",
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 200, 1, 0),
				Image = "rbxassetid://3570695787",
				ImageColor3 = Color3.fromRGB(10, 10, 10),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(100, 100, 100, 100),
				SliceScale = 0.1
			}, {
				-- Add this UIPadding
				Utility.new("UIPadding", {
					PaddingLeft = UDim.new(0, 10),  -- Left margin
					PaddingRight = UDim.new(0, 10), -- Right margin
					PaddingTop = UDim.new(0, 5)     -- Optional top margin
				}),

				-- Info
				Utility.new("Frame", {
					Name = "Info",
					BackgroundTransparency = 1,
					LayoutOrder = -5,
					Size = UDim2.new(1, 0, 0, 75)
				}, {
					Utility.new("ImageLabel", {
						Name = "Logo",
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 30, 0, 30),
						Image = "rbxassetid://71477318548275",
						ScaleType = Enum.ScaleType.Fit
					}),
					Utility.new("TextLabel", {
						Name = "Title",
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 35, 0, 15),
						Size = UDim2.new(1, -35, 0, 25),
						Font = Enum.Font.GothamBold,
						Text = Name and tostring(Name) or "Divine",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left
					}),
					Utility.new("TextLabel", {
						Name = "Header",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0, 32),
						Size = UDim2.new(0, 125, 0, 15),
						Font = Enum.Font.Gotham,
						Text = Header and tostring(Header) or "v1.0.0",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 15,
						TextTransparency = 0.3,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left
					}),
					Utility.new("Frame", {
						Name = "Divider",
						AnchorPoint = Vector2.new(0.5, 1),
						BackgroundColor3 = Color3.fromRGB(255, 0, 255),
						BackgroundTransparency = 0.25,
						BorderSizePixel = 0,
						Position = UDim2.new(0.5, 0, 1, 0),
						Size = UDim2.new(1, 0, 0, 1)
					}, {Utility.new("UIGradient", {Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, 0.1), NumberSequenceKeypoint.new(1, 1)}})}),

					Utility.new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 20)})
				}),
				Utility.new("ScrollingFrame", {
					Name = "TabContainer",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0, 75),
					Size = UDim2.new(1, -10, 0.8, -50), -- Create 3px space for scrollbar
					ScrollBarThickness = 6, -- Optimal visibility
					ScrollBarImageColor3 = Color3.fromRGB(47, 47, 47), -- Dark gray
					ScrollBarImageTransparency = 0, -- Slight transparency
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ClipsDescendants = true,
					BorderSizePixel = 0
				}, {
					Utility.new("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 2)
					}),
					Utility.new("UIPadding", {
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 9)
					})
				}),
				Utility.new("Frame", {
					Name = "SearchBarContainer",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -10, 0, 45),
					AnchorPoint = Vector2.new(0, 1), -- Critical anchor point
					Position = UDim2.new(0, 0, 1, -5) -- 5px from bottom
				}, {
					Utility.new("Frame", {
						Name = "SearchBar",
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 40),
						Position = UDim2.new(0, 0, 0, 0)
					}, {
						-- Magenta Border Stroke
						Utility.new("UIStroke", {
							Color = Divine.ColorScheme.Primary,
							Thickness = 2,
							Transparency = 0.3
						}),
						Utility.new("UICorner", {CornerRadius = UDim.new(0, 6)}),
						Utility.new("ImageLabel", {
							Name = "SearchIcon",
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 15, 0.5, 0),
							Size = UDim2.new(0, 20, 0, 20),
							Image = "rbxassetid://126152496049439",
							ImageColor3 = Color3.fromRGB(255, 255, 255),
							ImageTransparency = 0.3
						}),
						Utility.new("TextBox", {
							Name = "SearchBox",
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 45, 0.5, 0),
							Size = UDim2.new(1, -60, 1, 0),
							Font = Enum.Font.Gotham,
							PlaceholderText = "Search Features...",

							PlaceholderColor3 = Color3.fromRGB(255, 255, 255),
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 14,
							TextTransparency = 0.3,
							TextXAlignment = Enum.TextXAlignment.Left
						})
					})
				}),
				-- Ornaments
				Utility.new("Folder", {Name = "Ornaments"}, {
					Utility.new("Frame", {
						Name = "Shadow",
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0, 0),
						Size = UDim2.new(1, -5, 1, 0),
						ZIndex = 0
					}, {
						Utility.new("ImageLabel", {
							Name = "umbraShadow",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 2, 1, 2),
							ZIndex = 0,
							Image = "rbxassetid://1316045217",
							ImageColor3 = Color3.fromRGB(58, 0, 58),
							ImageTransparency = 0.86,
							ScaleType = Enum.ScaleType.Slice,
							SliceCenter = Rect.new(10, 10, 118, 118)
						}),
						Utility.new("ImageLabel", {
							Name = "penumbraShadow",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 2, 1, 2),
							ZIndex = 0,
							Image = "rbxassetid://1316045217",
							ImageColor3 = Color3.fromRGB(58, 0, 58),
							ImageTransparency = 0.76,
							ScaleType = Enum.ScaleType.Slice,
							SliceCenter = Rect.new(10, 10, 118, 118)
						}),
						Utility.new("ImageLabel", {
							Name = "ambientShadow",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 2, 1, 2),
							ZIndex = 0,
							Image = "rbxassetid://1316045217",
							ImageColor3 = Color3.fromRGB(58, 0, 58),
							ImageTransparency = 0.75,
							ScaleType = Enum.ScaleType.Slice,
							SliceCenter = Rect.new(10, 10, 118, 118)
						})
					}),
					Utility.new("Frame", {
						Name = "Hider",
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromRGB(10, 10, 10),
						BorderSizePixel = 0,
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 5, 1, 0)
					})
				}),
				-- UIListLayout
				Utility.new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
			}),

			-- UISizeConstraint
			Utility.new("UISizeConstraint", {MaxSize = Vector2.new(1400, 950), MinSize = Vector2.new(300, 200)})
		}
	)
	local DragPro = Utility.CreateDrag(Main, Main, {TweenDuration = 0.15, TweenStyle = Enum.EasingStyle.Quad})
	local UIPageLayout = Main.Contents.UIPageLayout

	-- Scripts --
	Main.SideBar.MouseWheelBackward:Connect(function()
		UIPageLayout:Next()
	end)

	Main.SideBar.MouseWheelForward:Connect(function()
		UIPageLayout:Previous()
	end)

	-- Window --
	local Window = {
		Title = Name and tostring(Name) or "Divine",
		Header = Header and tostring(Header) or "v1.0.0",
		Icon = tostring(Icon) or "4370345701",
		Toggled = true -- Start as visible
	}

	-- Initialize WindowInfo with default position
	local WindowInfo = {
		SizeSave = UDim2.new(0, 700, 0, 500),
		PositionSave = UDim2.new(0.5, 0, 0.5, 0) -- Start centered
	}



	function Window:Toggle(Value)
		Window.Toggled = Value or not Window.Toggled

		if Window.Toggled == true then
			-- Reopen logic (unchanged)
			Main.Visible = true
			Main.AnchorPoint = Vector2.new(0, 0)
			Main.Position = WindowInfo.PositionSave
			Main.Size = WindowInfo.SizeSave
			Utility.Tween(Main, TweenInfo.new(0.25), {Size = WindowInfo.SizeSave}):Yield()
			Main.UISizeConstraint.MinSize = Vector2.new(300, 200)
		else
			-- Save the current position/size
			WindowInfo.SizeSave = Main.Size
			WindowInfo.PositionSave = Main.Position

			-- Calculate the GUI’s current center
			local centerX = Main.AbsolutePosition.X + (Main.AbsoluteSize.X / 2)
			local centerY = Main.AbsolutePosition.Y + (Main.AbsoluteSize.Y / 2)

			-- Animate closing from the GUI’s center
			Main.AnchorPoint = Vector2.new(0.5, 0.5)
			Main.Position = UDim2.new(0, centerX, 0, centerY)
			Main.UISizeConstraint.MinSize = Vector2.new(0, 0)

			-- Play the tween and WAIT for it to finish
			local closeTween = Utility.Tween(Main, TweenInfo.new(0.5), {Size = UDim2.new(0, 0, 0, 0)})
			closeTween:Yield() -- Wait for the animation to complete
			Main.Visible = false
		end
	end

	function Window.Tab(Title, Icon)
		local TabFrame = Utility.new("ScrollingFrame", {
			Name = "Tab",
			Parent = Main.Contents,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -40, 1, -40),
			ScrollBarThickness = 0

		}, {
			Utility.new("UIListLayout", {HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})		})

		local TabButton = Utility.new("Frame", {
			Name = "Button",
			Parent = Main.SideBar.TabContainer,
			BackgroundColor3 = Divine.ColorScheme.Primary,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 40)
		}, {

			-- Add a UICorner here
			Utility.new("UICorner", {
				CornerRadius = UDim.new(0, 6) -- Adjust "6" for roundness
			}),
			Utility.new("ImageLabel", {
				Name = "Icon",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0.5, 0),
				Size = UDim2.new(0, 20, 0, 20),
				Image = Icon and "rbxassetid://" .. tostring(Icon) or "rbxassetid://6023426915",
				ImageTransparency = 0.3
			}),
			Utility.new("TextLabel", {
				Name = "Title",
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 40, 0.5, 0),
				Size = UDim2.new(1, -50, 0, 19),
				Font = Enum.Font.Gotham,
				Text = Title and tostring(Title) or "Tab",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 15,
				TextTransparency = 0.3,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left
			})

		})
		TabButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			Main.SideBar.TabContainer.CanvasSize = UDim2.new(
				0, 0, 0.1, Main.SideBar.TabContainer.UIListLayout.AbsoluteContentSize.Y
			)
		end)


		local function updateScroll()
			local contentSize = Main.SideBar.TabContainer.UIListLayout.AbsoluteContentSize.Y
			Main.SideBar.TabContainer.CanvasSize = UDim2.new(0, 0, 0, contentSize + 10) -- +10px buffer
		end

		-- Update when:
		Main.SideBar.TabContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScroll)
		Main.SideBar.TabContainer.ChildAdded:Connect(updateScroll)
		Main.SideBar.TabContainer.ChildRemoved:Connect(updateScroll)
		updateScroll() -- Initial update

		-- Scripts --
		TabFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			TabFrame.CanvasSize = UDim2.new(0, 0, 0, TabFrame.UIListLayout.AbsoluteContentSize.Y)
		end)

		TabButton.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				UIPageLayout:JumpTo(TabFrame)
				Utility.Wait()
				DragPro.Dragging = false
			end
		end)

		local ButtonTweens = {
			Focused = {
				Utility.Tween(TabButton, TweenInfo.new(0.25), {BackgroundTransparency = 0}),
				Utility.Tween(TabButton.Title, TweenInfo.new(0.25), {TextTransparency = 0}),
				Utility.Tween(TabButton.Icon, TweenInfo.new(0.25), {ImageTransparency = 0})
			};
			Idle = {
				Utility.Tween(TabButton, TweenInfo.new(0.25), {BackgroundTransparency = 1}),
				Utility.Tween(TabButton.Title, TweenInfo.new(0.25), {TextTransparency = 0.3}),
				Utility.Tween(TabButton.Icon, TweenInfo.new(0.25), {ImageTransparency = 0.3})
			};
			Selected = false;
		}

		UIPageLayout:GetPropertyChangedSignal("CurrentPage"):Connect(function()
			local PageFocused = UIPageLayout.CurrentPage == TabFrame
			if PageFocused and ButtonTweens.Selected == false then
				for i,v in ipairs(ButtonTweens.Focused) do
					v:Play()
				end
			elseif PageFocused == false and ButtonTweens.Selected == true then
				for i,v in ipairs(ButtonTweens.Idle) do
					v:Play()
				end
			end
			ButtonTweens.Selected = PageFocused
		end)

		-- Tab --
		local Tab = {}

		function Tab.Folder(Title, Description)
			local Properties = {}

			-- Inside the Divine.new function, find the Tab table (around line 1147):
			local Tab = {}

			-- Add this INSIDE the Tab table (after Folder/Cheat methods):
			function Tab.Slider(Title, Settings, Callback)
				local SliderFrame = Utility.new("Frame", {
					Name = "SliderContainer",
					Parent = TabFrame,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 35)
				})

				-- Reuse existing slider logic
				local SliderOptions = CreateOptions(SliderFrame)
				local Slider = SliderOptions.Slider(Title, Settings, Callback)

				return Slider
			end
			-- Inside the Folder function
			function Properties:Switch(Title, Callback)
				return Options.Switch(Title, Callback)
			end

			local Base =  Utility.new("ImageLabel", {
				Name = "Content",
				Parent = TabFrame,
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Size = UDim2.new(1, 0, 0, 40),
				Image = "rbxassetid://3570695787",
				ImageColor3 = Color3.fromRGB(10, 10, 10),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(100, 100, 100, 100),
				SliceScale = 0.05
			}, {
				-- Icon --
				Utility.new("ImageLabel", {
					Name = "Icon",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0, 10),
					Size = UDim2.new(0, 10, 0, 10),
					Image = "rbxassetid://6031625146",
					ImageTransparency = 0.3
				}),

				-- Title --
				Utility.new("TextLabel", {
					Name = "Title",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 20, 0, 10),
					Size = UDim2.new(1, -50, 0, 20),
					Font = Enum.Font.Gotham,
					Text = Title and tostring(Title) or "Folder",
					RichText = true,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 15,
					TextTransparency = 0.3,
					TextXAlignment = Enum.TextXAlignment.Left
				}),

				-- Arrow --
				Utility.new("ImageLabel", {
					Name = "Arrow",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(1, 0, 0, 10),
					Size = UDim2.new(0, 25, 0, 25),
					Image = "rbxassetid://6034818372",
					ImageTransparency = 0.3,
					ScaleType = Enum.ScaleType.Fit,
					SliceCenter = Rect.new(30, 30, 30, 30),
					SliceScale = 7
				}),

				-- UIPadding --
				Utility.new("UIPadding", {PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10)}),

				-- Info --
				Utility.new("ImageButton", {
					Name = "Info",
					Active = true,
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Position = UDim2.new(0.5, 0, 0, 30),
					Size = UDim2.new(1, 0, 0, 0)
				}, {
					Utility.new("TextLabel", {
						Name = "Description",
						BackgroundTransparency = 1,
						LayoutOrder = -5,
						Size = UDim2.new(1, 0, 0, 30),
						Font = Enum.Font.Gotham,
						Text = Description and tostring(Description) or "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras justo urna, mattis et neque non.",
						RichText = true,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14,
						TextTransparency = 0.3,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top
					}),
					Utility.new("UIListLayout", {
						Padding = UDim.new(0, 1),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				})
			})
			Base.Info.Description.Size = UDim2.new(1, 0, 0, Services.TextService:GetTextSize(Base.Info.Description.Text, 14, Enum.Font.Gotham, Vector2.new(Base.Info.Description.AbsoluteSize.X, math.huge)).Y + 5)

			local Info = {
				Collapsed = true;
			}

			local Tweens = {
				[true] = {
					function()
						Utility.Tween(Base, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 45 + Base.Info.UIListLayout.AbsoluteContentSize.Y)}):Play()
						Utility.Wait(0.1)
						Base.Icon.Image = "rbxassetid://6026681577"
					end,
					Utility.Tween(Base.Arrow, TweenInfo.new(0.5), {ImageTransparency = 0, Rotation = 180}),
					Utility.Tween(Base.Title, TweenInfo.new(0.5), {TextTransparency = 0, TextColor3 = Divine.ColorScheme.Primary}),
					Utility.Tween(Base.Icon, TweenInfo.new(0.5), {ImageTransparency = 0, ImageColor3 = Divine.ColorScheme.Primary}),
				};
				[false] = {
					function()
						Utility.Wait(0.1)
						Base.Icon.Image = "rbxassetid://6031625146"
					end,
					Utility.Tween(Base, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 40)}),
					Utility.Tween(Base.Arrow, TweenInfo.new(0.5), {ImageTransparency = 0.3, Rotation = 0}),
					Utility.Tween(Base.Title, TweenInfo.new(0.5), {TextTransparency = 0.3, TextColor3 = Color3.fromRGB(255, 255, 255)}),
					Utility.Tween(Base.Icon, TweenInfo.new(0.5), {ImageTransparency = 0.3, ImageColor3 = Color3.fromRGB(255, 255, 255)})
				};
			}

			Base.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					for i,v in ipairs(Tweens[Info.Collapsed]) do
						if typeof(v) == "function" then
							coroutine.wrap(v)()
						else
							v:Play()
						end
					end
					Info.Collapsed = not Info.Collapsed
					Utility.Wait()
					DragPro.Dragging = false
				end
			end)

			Base.Info.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				Base.Info.Size = UDim2.new(1, 0, 0, Base.Info.UIListLayout.AbsoluteContentSize.Y + 5)
			end)

			-- Folder --
			for i,v in pairs(CreateOptions(Base.Info)) do
				Properties[i] = v
			end

			return setmetatable({}, {
				__index = function(Self, Index)
					return Properties[Index]
				end;
				__newindex = function(Self, Index, Value)
					if Index == "Title" then
						Base.Title.Text = Value and tostring(Value) or "Folder"
					elseif Index == "Description" then
						Base.Info.Description.Text = Value and tostring(Value) or "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras justo urna, mattis et neque non."
						Base.Info.Description.Size = UDim2.new(1, 0, 0, Services.TextService:GetTextSize(Base.Info.Description.Text, 14, Enum.Font.Gotham, Vector2.new(Base.Info.Description.AbsoluteSize.X, math.huge)).Y + 5)
					end
					rawset(Properties, Index, Value)
				end;
			})
		end

		function Tab.Cheat(Title, Description, Callback)
			local Properties = {
				Function = Callback or function(Status) end;
			}

			local Base = Utility.new("ImageLabel", {
				Name = "Content",
				Parent = TabFrame,
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Size = UDim2.new(1, 0, 0, 40),
				Image = "rbxassetid://3570695787",
				ImageColor3 = Color3.fromRGB(10,10, 10),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(100, 100, 100, 100),
				SliceScale = 0.05
			}, {
				-- Icon --
				Utility.new("ImageLabel", {
					Name = "Icon",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0, 10),
					Size = UDim2.new(0, 10, 0, 10),
					Image = "rbxassetid://6031625146",
					ImageTransparency = 0.3
				}),

				-- Title --
				Utility.new("TextLabel", {
					Name = "Title",
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 20, 0, 10),
					Size = UDim2.new(1, -50, 0, 20),
					Font = Enum.Font.Gotham,
					Text = Title and tostring(Title) or "Cheat",
					RichText = true,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 15,
					TextTransparency = 0.3,
					TextXAlignment = Enum.TextXAlignment.Left
				}),

				-- Switch --
				Utility.new("ImageButton", {
					Name = "Switch",
					AutoButtonColor = false,
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 0, 255),
					Position = UDim2.new(1, -30, 0, 10),
					Size = UDim2.new(0, 30, 0, 15)
				}, {
					Utility.new("UICorner", {CornerRadius = UDim.new(1, 0)}),
					Utility.new("Frame", {
						Name = "Circle",
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						Position = UDim2.new(0, 0, 0.5, 0),
						Size = UDim2.new(0, 14, 0, 14)
					}, {Utility.new("UICorner", {CornerRadius = UDim.new(1, 0)})})
				}),

				-- Arrow --
				Utility.new("ImageLabel", {
					Name = "Arrow",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.new(1, 0, 0, 10),
					Size = UDim2.new(0, 25, 0, 25),
					Image = "rbxassetid://6034818372",
					ImageTransparency = 0.3,
					ScaleType = Enum.ScaleType.Fit,
					SliceCenter = Rect.new(30, 30, 30, 30),
					SliceScale = 7
				}),

				-- UIPadding --
				Utility.new("UIPadding", {PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10)}),

				-- Info --
				Utility.new("ImageButton", {
					Name = "Info",
					Active = true,
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Position = UDim2.new(0.5, 0, 0, 30),
					Size = UDim2.new(1, 0, 0, 0),
					ImageTransparency = 1
				}, {
					Utility.new("TextLabel", {
						Name = "Description",
						BackgroundTransparency = 1,
						LayoutOrder = -5,
						Size = UDim2.new(1, 0, 0, 30),
						Font = Enum.Font.Gotham,
						Text = Description and tostring(Description) or "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras justo urna, mattis et neque non.",
						RichText = true,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14,
						TextTransparency = 0.3,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top
					}),
					Utility.new("UIListLayout", {
						Padding = UDim.new(0, 1),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				})
			})
			Base.Info.Description.Size = UDim2.new(1, 0, 0, Services.TextService:GetTextSize(Base.Info.Description.Text, 14, Enum.Font.Gotham, Vector2.new(Base.Info.Description.AbsoluteSize.X, math.huge)).Y + 5)

			local Info = {
				Toggled = false;
				Collapsed = true;
			}

			local FolderTweens = {
				[true] = {
					function()
						Utility.Tween(Base, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 45 + Base.Info.UIListLayout.AbsoluteContentSize.Y)}):Play()
						Utility.Wait(0.1)
						Base.Icon.Image = "rbxassetid://6026681577"
					end,
					Utility.Tween(Base.Arrow, TweenInfo.new(0.5), {ImageTransparency = 0, Rotation = 180}),
					Utility.Tween(Base.Title, TweenInfo.new(0.5), {TextTransparency = 0, TextColor3 = Divine.ColorScheme.Primary}),
					Utility.Tween(Base.Icon, TweenInfo.new(0.5), {ImageTransparency = 0, ImageColor3 = Divine.ColorScheme.Primary}),
				};
				[false] = {
					function()
						Utility.Wait(0.1)
						Base.Icon.Image = "rbxassetid://6031625146"
					end,
					Utility.Tween(Base, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 40)}),
					Utility.Tween(Base.Arrow, TweenInfo.new(0.5), {ImageTransparency = 0.3, Rotation = 0}),
					Utility.Tween(Base.Title, TweenInfo.new(0.5), {TextTransparency = 0.3, TextColor3 = Color3.fromRGB(255, 255, 255)}),
					Utility.Tween(Base.Icon, TweenInfo.new(0.5), {ImageTransparency = 0.3, ImageColor3 = Color3.fromRGB(255, 255, 255)}),
				};
			}

			local SwitchTweens = {
				[true] = {
					Utility.Tween(Base.Switch, TweenInfo.new(0.5), {BackgroundColor3 = Divine.ColorScheme.Primary}),
					Utility.Tween(Base.Switch.Circle, TweenInfo.new(0.25), {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0)})
				};

				[false] = {
					Utility.Tween(Base.Switch, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}),
					Utility.Tween(Base.Switch.Circle, TweenInfo.new(0.25), {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0)})
				};
			}

			Base.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					for i,v in ipairs(FolderTweens[Info.Collapsed]) do
						if typeof(v) == "function" then
							coroutine.wrap(v)()
						else
							v:Play()
						end
					end
					Info.Collapsed = not Info.Collapsed
					Utility.Wait()
					DragPro.Dragging = false
				end
			end)

			Base.Switch.MouseButton1Down:Connect(function()
				Info.Toggled = not Info.Toggled
				for i,v in ipairs(SwitchTweens[Info.Toggled]) do
					v:Play()
				end
				local Success, Error = pcall(Properties.Function, Info.Toggled)
				assert(Divine.Settings.Debug == false or Success, Error)
			end)

			Base.Info.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				Base.Info.Size = UDim2.new(1, 0, 0, Base.Info.UIListLayout.AbsoluteContentSize.Y + 5)
			end)

			-- Cheat --
			for i,v in pairs(CreateOptions(Base.Info)) do
				Properties[i] = v
			end

			return setmetatable({}, {
				__index = function(Self, Index)
					return Properties[Index]
				end;
				__newindex = function(Self, Index, Value)
					if Index == "Title" then
						Base.Title.Text = Value and tostring(Value) or "Cheat"
					elseif Index == "Description" then
						Base.Info.Description.Text = Value and tostring(Value) or "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras justo urna, mattis et neque non."
						Base.Info.Description.Size = UDim2.new(1, 0, 0, Services.TextService:GetTextSize(Base.Info.Description.Text, 14, Enum.Font.Gotham, Vector2.new(Base.Info.Description.AbsoluteSize.X, math.huge)).Y + 5)
					elseif Index == "Value" then
						Info.Toggled = Value
						for i,v in ipairs(SwitchTweens[Info.Toggled]) do
							v:Play()
						end
						local Success, Error = pcall(Properties.Function, Info.Toggled)
						assert(Divine.Settings.Debug == false or Success, Error)
					end
					rawset(Self, Index, Value)
				end
			})
		end

		-- Inside the Tab table (after Folder/Cheat methods):
		function Tab.Slider(Title, Settings, Callback)
			local SliderFrame = Utility.new("Frame", {
				Name = "SliderContainer",
				Parent = TabFrame, -- Directly parent to the tab's ScrollingFrame
				BackgroundTransparency = 1,
				Size = UDim2.new(0.97, 0, 0, 35)
			})

			-- Reuse existing slider logic
			local SliderOptions = CreateOptions(SliderFrame)
			local Slider = SliderOptions.Slider(Title, Settings, Callback)

			return Slider
		end

		return setmetatable(Tab, {__newindex = function(Self, Index, Value)
			if Index == "Title" then
				TabButton.Title.Text = Value and tostring(Value) or "Tab"
			elseif Index == "Icon" then
				TabButton.Icon.Image = Value and "rbxassetid://" .. tostring(Value) or "rbxassetid://4370345701"
			end
		end})
	end

	function Window:Alert()

	end

	return setmetatable(Window, {__newindex = function(Self, Index, Value)
		if Index == "Title" then
			Main.SideBar.Info.Title.Text = Value and tostring(Value) or "Divine"
		elseif Index == "Header" then
			Main.SideBar.Info.Header.Text = Value and tostring(Value) or "v1.0.0"
		elseif Index == "Icon" then
			Main.SideBar.Info.Logo.Image = Value and "rbxassetid://" .. tostring(Value) or "rbxassetid://4370345701"
		end
		rawset(Self, Index, Value)
	end})
end
-- Drag selection logic
Services.UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and LassoEnabled then -- Added check
		dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
		SelectionBox.Position = UDim2.new(0, dragStartPos.X, 0, dragStartPos.Y)
		SelectionBox.Size = UDim2.new()
		SelectionBox.Visible = true -- Only show if lasso is enabled
		isDragging = true
	end
end)

Services.UserInputService.InputChanged:Connect(function(input)
	if isDragging and LassoEnabled and input.UserInputType == Enum.UserInputType.MouseMovement then
		local currentPos = input.Position
		SelectionBox.Size = UDim2.new(
			0, math.abs(currentPos.X - dragStartPos.X),
			0, math.abs(currentPos.Y - dragStartPos.Y)
		)
		SelectionBox.Position = UDim2.new(
			0, math.min(currentPos.X, dragStartPos.X),
			0, math.min(currentPos.Y, dragStartPos.Y)
		)
	end
end)

Services.UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and LassoEnabled then
		SelectionBox.Visible = false
		isDragging = false
		-- Process selected objects here
	end
end)
-- Global search controller
local SearchSystem = {
	allDropdowns = {}
}

function Divine:SearchDropdowns(searchText)
	local cleanText = searchText:lower()

	-- Clear previous highlights
	for _, dropdown in ipairs(SearchSystem.allDropdowns) do
		for _, option in ipairs(dropdown._options) do
			option.frame.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	-- Search through all dropdowns
	for _, dropdown in ipairs(SearchSystem.allDropdowns) do
		-- Auto-expand parent containers
		if dropdown._parentFrame and dropdown._parentFrame.ClassName == "ScrollingFrame" then
			local parentContainer = dropdown._parentFrame.Parent
			if parentContainer:FindFirstChild("Arrow") then
				-- Expand folders automatically
				parentContainer.Arrow.Rotation = 180
				parentContainer.Info.Size = UDim2.new(1, 0, 0, parentContainer.Info.UIListLayout.AbsoluteContentSize.Y + 5)
			end
		end

		-- Highlight matches
		for _, option in ipairs(dropdown._options) do
			if option.text:find(cleanText) then
				option.frame.Label.TextColor3 = Divine.ColorScheme.Primary
				-- Auto-scroll to match
				local parentScroller = dropdown._container.Parent
				if parentScroller:IsA("ScrollingFrame") then
					parentScroller.CanvasPosition = Vector2.new(0, option.frame.AbsolutePosition.Y - parentScroller.AbsolutePosition.Y)
				end
			end
		end
	end
end

-- Track all dropdowns when created
local originalCreateOptions = CreateOptions
function CreateOptions(Frame)
	local Options = originalCreateOptions(Frame)

	local originalDropdown = Options.Dropdown
	function Options.Dropdown(...)
		local dropdown = originalDropdown(...)
		table.insert(SearchSystem.allDropdowns, dropdown)
		return dropdown
	end

	return Options
end
return Divine
