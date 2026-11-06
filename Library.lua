-- XenUI | client-side Luau ModuleScript
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local Xen = {}

local bg = Color3.fromRGB(19,19,22)
local rail = Color3.fromRGB(25,25,29)
local panel = Color3.fromRGB(30,30,35)
local hover = Color3.fromRGB(43,43,49)
local white = Color3.fromRGB(242,242,246)
local muted = Color3.fromRGB(163,163,174)
local function make(kind, parent, props)
    local obj = Instance.new(kind)
    for key,value in pairs(props or {}) do obj[key] = value end
    obj.Parent = parent
    return obj
end
local function round(obj, radius)
    make("UICorner", obj, {CornerRadius=UDim.new(0,radius or 6)})
end
local function box(parent,color,size,pos)
    return make("Frame",parent,{BackgroundColor3=color,BorderSizePixel=0,Size=size,Position=pos or UDim2.new()})
end
local function text(parent, value, size, bold, button)
    return make(button and "TextButton" or "TextLabel",parent,{
        Text=value,TextSize=size,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextColor3=white,BackgroundTransparency=1,BorderSizePixel=0,
        TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.fromScale(1,1),
        TextTruncate=Enum.TextTruncate.AtEnd,
    })
end
local function stack(parent,gap,horizontal)
    return make("UIListLayout",parent,{Padding=UDim.new(0,gap),SortOrder=Enum.SortOrder.LayoutOrder,
        FillDirection=horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical})
end
local function inputBox(parent, placeholder)
    local field = make("TextBox",parent,{BackgroundColor3=panel,BorderSizePixel=0,Text="",PlaceholderText=placeholder,
        TextColor3=white,PlaceholderColor3=muted,ClearTextOnFocus=false,TextSize=13,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left})
    round(field)
    make("UIPadding",field,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,8)})
    return field
end

function Xen.Window(config)
    config=config or {}
    local gui=make("ScreenGui",config.Parent or Players.LocalPlayer:WaitForChild("PlayerGui"),{
        Name=config.Name or "XenUI",ResetOnSpawn=false,DisplayOrder=config.DisplayOrder or 30,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    local window={Flags={},Gui=gui}
    local connections, tabs, flags = {}, {}, {}
    local activeTab, activePage, drag, slide
    local live, query = true, ""
    local accent=config.Accent or Color3.fromRGB(255,58,78)
    local selected = bg:Lerp(accent, .15)
    local function connect(event,fn)
        table.insert(connections,event:Connect(fn))
    end
    local playing = {}
    local function animate(object, goals, seconds, finished)
        local previous = playing[object]
        if previous then
            playing[object] = nil
            previous:Cancel()
        end
        if config.ReduceMotion then
            for key, value in pairs(goals) do object[key] = value end
            if finished then finished() end
            return
        end
        local tween = Tween:Create(object, TweenInfo.new(seconds or .18, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), goals)
        playing[object] = tween
        tween.Completed:Once(function(state)
            if playing[object] == tween then
                playing[object] = nil
                if live and state == Enum.PlaybackState.Completed and finished then finished() end
            end
            tween:Destroy()
        end)
        tween:Play()
    end

    -- One frame listener tracks all moving sliders and sleeps once they settle.
    local fills, frameConnection = {}, nil
    local function slideTo(fill, target)
        if config.ReduceMotion then fill.Size = UDim2.fromScale(target, 1); return end
        fills[fill] = target
        if frameConnection then return end
        frameConnection = RunService.RenderStepped:Connect(function(dt)
            local weight = 1 - math.exp(-38 * dt)
            for bar, goal in pairs(fills) do
                local current = bar.Size.X.Scale
                if math.abs(goal - current) < .001 then
                    bar.Size = UDim2.fromScale(goal, 1)
                    fills[bar] = nil
                else
                    bar.Size = UDim2.fromScale(current + (goal - current) * weight, 1)
                end
            end
            if next(fills) == nil then frameConnection:Disconnect(); frameConnection = nil end
        end)
    end
    local function callback(fn,v)
        if fn then task.spawn(fn,v) end
    end
    local function surface(button)
        button.AutoButtonColor=false
        button.MouseEnter:Connect(function() animate(button,{BackgroundColor3=hover}) end)
        button.MouseLeave:Connect(function() animate(button,{BackgroundColor3=panel}) end)
    end
    local shell=box(gui,bg,UDim2.fromOffset(680,430),UDim2.fromScale(.5,.5))
    shell.AnchorPoint=Vector2.new(.5,.5)
    shell.ClipsDescendants=true
    round(shell,10)
    make("UIStroke",shell,{Color=bg:Lerp(accent,.35),Thickness=1})
    local scale=make("UIScale",shell,{})
    local function resize()
        local sz=gui.AbsoluteSize
        scale.Scale=math.clamp(math.min((sz.X-12)/680,(sz.Y-12)/430),.05,1)
    end
    connect(gui:GetPropertyChangedSignal("AbsoluteSize"),resize)
    resize()
    local sidebar=box(shell,rail,UDim2.new(0,154,1,0))
    local brand=text(sidebar,config.Title or "Xen",23,true)
    brand.TextColor3=accent
    brand.Position=UDim2.fromOffset(17,0);brand.Size=UDim2.fromOffset(130,62)
    local nav=make("ScrollingFrame",sidebar,{Position=UDim2.fromOffset(8,68),Size=UDim2.new(1,-16,1,-122),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
    stack(nav,4)
    local profile=text(sidebar,config.Profile or Players.LocalPlayer.DisplayName,13,true)
    profile.TextColor3=white
    profile.Position=UDim2.new(0,17,1,-44); profile.Size=UDim2.fromOffset(130,30)
    local top=box(shell,bg,UDim2.new(1,-154,0,50),UDim2.fromOffset(154,0))
    top.Active=true;brand.Active=true
    local search=inputBox(top,"Buscar nesta aba…")
    search.Position=UDim2.fromOffset(14,10);search.Size=UDim2.new(.68,0,0,30)
    local hide=text(top,"−",22,true,true)
    hide.Position=UDim2.new(1,-42,0,8);hide.Size=UDim2.fromOffset(32,32);hide.TextXAlignment=Enum.TextXAlignment.Center
    local launcher=text(gui,config.Title or "Xen",14,true,true)
    launcher.BackgroundTransparency=0;launcher.BackgroundColor3=rail;launcher.TextColor3=accent;round(launcher)
    launcher.TextXAlignment=Enum.TextXAlignment.Center;launcher.Position=UDim2.fromOffset(10,10)
    launcher.Size=UDim2.fromOffset(88,34);launcher.Visible=false
    local opened = true
    local function show(value)
        if opened == value then return end
        opened = value
        drag, slide = nil, nil
        launcher.Visible = not value
        local size = gui.AbsoluteSize
        local fit = math.clamp(math.min((size.X-12)/680, (size.Y-12)/430), .05, 1)
        if value then
            shell.Visible = true
            animate(scale, {Scale = fit}, .16)
        else
            search:ReleaseFocus()
            animate(scale, {Scale = fit * .95}, .10, function()
                if not opened then shell.Visible = false end
            end)
        end
    end
    hide.Activated:Connect(function() show(false) end)
    launcher.Activated:Connect(function() show(true) end)
    function window:IsVisible() return opened end
    function window:Set(id,value)
        if flags[id] then flags[id]:Set(value) end
    end
    function window:SetVisible(value) show(value) end
    local function pointer(i) return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
    local function startDrag(i)
        if pointer(i) then drag={input=i,from=i.Position,pos=shell.AbsolutePosition+shell.AbsoluteSize*.5} end
    end
    connect(top.InputBegan,startDrag);connect(brand.InputBegan,startDrag)
    connect(Input.InputChanged,function(i)
        local gesture=slide or drag
        if not gesture then return end
        if i~=gesture.input and not (gesture.input.UserInputType==Enum.UserInputType.MouseButton1 and i.UserInputType==Enum.UserInputType.MouseMovement) then return end
        if slide then slide.update(i.Position.X);return end
        local diff=i.Position-drag.from
        local size=gui.AbsoluteSize;local half=shell.AbsoluteSize*.5
        shell.Position=UDim2.fromOffset(math.clamp(drag.pos.X+diff.X,half.X,math.max(half.X,size.X-half.X)),
            math.clamp(drag.pos.Y+diff.Y,half.Y,math.max(half.Y,size.Y-half.Y)))
    end)
    connect(Input.InputEnded,function(i)
        if slide and i==slide.input then slide=nil end
        if drag and i==drag.input then drag=nil end
    end)
    connect(Input.InputBegan,function(i,processed)
        if not processed and not Input:GetFocusedTextBox() and i.KeyCode==(config.MenuKey or Enum.KeyCode.RightShift) then show(not opened) end
    end)
    local strip=make("ScrollingFrame",shell,{Position=UDim2.fromOffset(168,53),Size=UDim2.new(1,-184,0,35),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=1,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X})
    stack(strip,8,true)
    local empty=text(shell,"Nenhum controle encontrado",14,false)
    empty.Position=UDim2.fromOffset(174,106);empty.Size=UDim2.fromOffset(300,24);empty.TextColor3=muted;empty.Visible=false
    local function filter()
        local any=false
        if activePage then
            for _,group in ipairs(activePage.groups) do
                local matched=false
                for _,entry in ipairs(group.rows) do
                    local visible=query=="" or string.find(entry.key,query,1,true)~=nil
                    entry.row.Visible=visible;matched=matched or visible
                end
                group.frame.Visible=matched;any=any or matched
            end
        end
        empty.Visible=query~="" and not any
    end
    search:GetPropertyChangedSignal("Text"):Connect(function()
        query=string.lower(search.Text);filter()
    end)
    local function selectPage(page)
        if activePage == page then return end
        if activePage then activePage.body.Visible=false;animate(activePage.line,{BackgroundTransparency=1});animate(activePage.btn,{TextColor3=muted}) end
        activePage=page
        if page then
            page.tab.last=page;page.body.Visible=true
            page.body.GroupTransparency=config.ReduceMotion and 0 or .65
            page.body.Position = UDim2.fromOffset(config.ReduceMotion and 168 or 178,95)
            animate(page.body,{GroupTransparency=0,Position=UDim2.fromOffset(168,95)},.19)
            animate(page.line,{BackgroundTransparency=0});animate(page.btn,{TextColor3=accent})
        end
        filter()
    end
    local function selectTab(tab)
        for _,t in ipairs(tabs) do
            animate(t.btn,{BackgroundTransparency=t==tab and 0 or 1,TextColor3=t==tab and accent or muted})
            for _,p in ipairs(t.pages) do p.btn.Visible=t==tab end
        end
        activeTab=tab;strip.CanvasPosition=Vector2.zero
        selectPage(tab.last or tab.pages[1])
    end
    function window:Tab(name)
        local btn=text(nav,"    "..name,14,true,true);btn.Size=UDim2.new(1,-3,0,34);btn.BackgroundColor3=selected;btn.AutoButtonColor=false;round(btn)
        local tab={btn=btn,pages={}};table.insert(tabs,tab);btn.LayoutOrder=#tabs
        btn.Activated:Connect(function() selectTab(tab) end)
        if not activeTab then selectTab(tab) else btn.TextColor3=muted end
        function tab:Page(title)
            local b=text(strip,title,13,true,true);b.Size=UDim2.fromOffset(100,30);b.TextXAlignment=Enum.TextXAlignment.Center
            b.TextColor3=muted;b.Visible=activeTab==tab;b.LayoutOrder=#tab.pages+1
            local line=box(b,accent,UDim2.new(1,-10,0,2),UDim2.new(0,5,1,-2));line.BackgroundTransparency=1
            local body=make("CanvasGroup",shell,{BackgroundTransparency=1,Visible=false,Position=UDim2.fromOffset(168,95),Size=UDim2.new(1,-182,1,-107)})
            local scroll=make("ScrollingFrame",body,{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),
                ScrollBarThickness=3,ScrollBarImageColor3=muted,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
            stack(scroll,10)
            local page={btn=b,body=body,line=line,groups={},tab=tab};table.insert(tab.pages,page)
            b.Activated:Connect(function() selectPage(page) end)
            if activeTab==tab and not activePage then selectPage(page) end
            function page:Section(label)
                local frame=box(scroll,rail,UDim2.new(1,-6,0,0));round(frame,7)
                frame.AutomaticSize=Enum.AutomaticSize.Y;frame.LayoutOrder=#page.groups+1
                make("UIPadding",frame,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,8)})
                stack(frame,3)
                local header=text(frame,label,14,true);header.Size=UDim2.new(1,0,0,34)
                local group={rows={},frame=frame};table.insert(page.groups,group)
                local function row(title,height)
                    local r=box(frame,rail,UDim2.new(1,0,0,height));r.LayoutOrder=#group.rows+1
                    table.insert(group.rows,{row=r,key=string.lower(label.." "..title)})
                    filter();return r
                end
                local function valueHandle(id,initial,normalize,paint,fn)
                    assert(type(id)=="string" and not flags[id],"Expected unique control ID: "..tostring(id))
                    local h={}
                    function h:Set(v,silent)
                        v=normalize(v)
                        if window.Flags[id]==v then return end
                        window.Flags[id]=v;paint(v)
                        if not silent then callback(fn,v) end
                    end
                    function h:Get() return window.Flags[id] end
                    flags[id]=h;h:Set(initial,true);return h
                end
                function group:Label(title)
                    local r=row(title,28)
                    local label=text(r,title,12,false)
                    label.TextColor3=muted
                    return {SetText=function(_,v)
                        if label.Text~=v then label.Text=v end
                    end}
                end
                function group:Toggle(id,title,default,fn)
                    local r=row(title,32);local button=text(r,title,13,false,true)
                    local pill=box(button,panel,UDim2.fromOffset(38,20),UDim2.new(1,-40,.5,-10));round(pill,12)
                    local knob=box(pill,muted,UDim2.fromOffset(14,14),UDim2.fromOffset(3,3));round(knob,10)
                    local h=valueHandle(id,default,function(v) return v==true end,function(on)
                        animate(pill,{BackgroundColor3=on and accent or panel})
                        animate(knob,{BackgroundColor3=on and bg or muted,Position=UDim2.fromOffset(on and 21 or 3,3)})
                    end,fn)
                    button.Activated:Connect(function() h:Set(not h:Get()) end);return h
                end
                function group:Slider(id,title,min,max,step,default,fn)
                    assert(max>min and step>0,"Invalid slider range")
                    local r=row(title,48);local caption=text(r,title,13,false);caption.Size=UDim2.new(.7,0,0,23)
                    local read=text(r,"",12,false);read.TextXAlignment=Enum.TextXAlignment.Right
                    read.Size=UDim2.new(.3,0,0,23);read.Position=UDim2.fromScale(.7,0);read.TextColor3=muted
                    local hit=text(r,"",12,false,true);hit.Position=UDim2.fromOffset(0,23);hit.Size=UDim2.new(1,0,0,24);hit.Active=true
                    local track=box(hit,hover,UDim2.new(1,-10,0,4),UDim2.fromOffset(5,10));round(track,4)
                    local fill=box(track,accent,UDim2.fromScale(0,1));round(fill,4)
                    local knob=box(fill,accent,UDim2.fromOffset(10,10),UDim2.new(1,-5,.5,-5));round(knob,5)
                    local h=valueHandle(id,default or min,function(v)
                        v=math.clamp(tonumber(v) or min,min,max)
                        return v==max and max or math.clamp(min+math.round((v-min)/step)*step,min,max)
                    end,function(v)
                        read.Text=string.format("%.5g",v);slideTo(fill,(v-min)/(max-min))
                    end,fn)
                    hit.InputBegan:Connect(function(i)
                        if not pointer(i) then return end
                        local function update(x) h:Set(min+(max-min)*math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)) end
                        slide={input=i,update=update};update(i.Position.X)
                    end);return h
                end
                function group:Button(title,fn)
                    local r=row(title,32);local b=text(r,title,13,true,true);b.BackgroundTransparency=0;b.BackgroundColor3=panel
                    b.TextXAlignment=Enum.TextXAlignment.Center;round(b);surface(b);b.Activated:Connect(function() callback(fn) end)
                end
                function group:Input(id,title,default,fn)
                    local r=row(title,36);local caption=text(r,title,13,false);caption.Size=UDim2.fromScale(.45,1)
                    local field=inputBox(r,title);field.Position=UDim2.fromScale(.46,.06);field.Size=UDim2.fromScale(.54,.88)
                    local h=valueHandle(id,default or "",tostring,function(v) field.Text=v end,fn)
                    field.FocusLost:Connect(function() h:Set(field.Text) end);return h
                end
                function group:Dropdown(id,title,values,default,fn)
                    assert(#values>0,"Dropdown needs options")
                    local r=row(title,34);r.ClipsDescendants=true
                    local b=text(r,"",13,false,true);b.Size=UDim2.new(1,0,0,34)
                    local open=false
                    local function expand(on) open=on;animate(r,{Size=UDim2.new(1,0,0,34+(on and #values*28 or 0))},on and .20 or .13) end
                    local h=valueHandle(id,default or values[1],function(v) assert(table.find(values,v),"Unknown option");return v end,
                        function(v) b.Text=title.."    ·    "..v.."   ▾" end,fn)
                    b.Activated:Connect(function() expand(not open) end)
                    for n,v in ipairs(values) do
                        local opt=text(r,"   "..v,13,false,true);opt.Position=UDim2.fromOffset(0,34+(n-1)*28);opt.Size=UDim2.new(1,0,0,27)
                        opt.BackgroundTransparency=0;opt.BackgroundColor3=panel;round(opt);surface(opt)
                        opt.Activated:Connect(function() h:Set(v);expand(false) end)
                    end
                    return h
                end
                return group
            end
            return page
        end
        return tab
    end
    local function cleanup()
        if not live then return end
        live=false
        if frameConnection then frameConnection:Disconnect(); frameConnection=nil end
        table.clear(fills)
        for _, tween in pairs(table.clone(playing)) do tween:Cancel() end
        table.clear(playing)
        for _,c in ipairs(connections) do c:Disconnect() end
        table.clear(connections);drag=nil;slide=nil
    end
    gui.Destroying:Connect(cleanup)
    function window:Destroy() cleanup();gui:Destroy() end
    return window
end
return Xen
