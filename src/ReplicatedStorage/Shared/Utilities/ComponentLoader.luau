local CollectionService = game:GetService("CollectionService")
local ComponentLoader = {}

local CachedInstances = {}

local function loadComponent(modulescript: ModuleScript)
	if not modulescript:IsA("ModuleScript") then
		return
	end
	local module = require(modulescript)
	local thisTag = module.Tag

	local function instanceAdded(instance)
		CachedInstances[instance] = CachedInstances[instance] or {}
		local newComponent = module.new(instance)
		CachedInstances[instance][thisTag] = newComponent
	end

	local function instanceRemoving(instance)
		for tag, component in CachedInstances[instance] do
			if component.destroy then
				component:destroy()
			end
			component[tag] = nil
		end
	end

	for _, existing in CollectionService:GetTagged(thisTag) do
		instanceAdded(existing)
	end
	CollectionService:GetInstanceAddedSignal(thisTag):Connect(instanceAdded)
	CollectionService:GetInstanceRemovedSignal(thisTag):Connect(instanceRemoving)
end

function ComponentLoader.load(componentDirectory: any)
	local components = componentDirectory:GetChildren()
	for _, component in components do
		loadComponent(component)
	end
end

return ComponentLoader
