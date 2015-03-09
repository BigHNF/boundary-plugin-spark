local framework = require('framework/framework.lua')
local http = require('http')
local json = require('json')
local Plugin = framework.Plugin
local HttpPlugin = framework.HttpPlugin
require('fun')()
local string = require('string')
local table = require('table')

local params = framework.boundary.param
params.name = 'Spark Master Plugin'
params.version = '1.0'

local pluginMaster = HttpPlugin:new(params)

function get(key, map)
	return map[key]
end

function contains(pattern, str)
	local s,e = string.find(str, pattern)

	return s ~= nil
end

function partial(func, x) 

	return function (...)
		return func(x, ...) 
	end
end

function compose(f, g)
	return function(...) 
		return g(f(...))
	end
end

function escape(str)
	local s, c = string.gsub(str, '%.', '%%.')
	s, c = string.gsub(s, '%-', '%%-')
	return s
end

function keys(map)
	local result = {}
	for k,_ in pairs(map) do
		table.insert(result, k)
	end

	return result
end

function clone(t)
	if type(t) ~= 'table' then return t end

	local meta = getmetatable(t)
	local target = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
			target[k] = clone(v)
		else
			target[k] = v
		end
	end
	setmetatable(target, meta)
	return target
end

function pluginMaster:onParseResponse(data)
	local parsed = json.parse(data)	
	local result = {}

	result['SPARK_MASTER_WORKERS_COUNT'] = tonumber(get('value', get('master.workers', get('gauges', parsed))))
	result['SPARK_MASTER_APPLICATIONS_RUNNING_COUNT'] = tonumber(get('value', get('master.apps', get('gauges', parsed))))
	result['SPARK_MASTER_APPLICATIONS_WAITING_COUNT'] = tonumber(get('value', get('master.waitingApps', get('gauges', parsed))))
	result['SPARK_MASTER_JVM_MEMORY_USED'] = tonumber(get('value', get('jvm.total.used', get('gauges', parsed))))
	result['SPARK_MASTER_JVM_MEMORY_COMMITTED'] = tonumber(get('value', get('jvm.total.committed', get('gauges', parsed))))
	result['SPARK_MASTER_JVM_HEAP_MEMORY_COMMITTED'] = tonumber(get('value', get('jvm.heap.committed', get('gauges', parsed))))
	result['SPARK_MASTER_JVM_HEAP_MEMORY_USED'] = tonumber(get('value', get('jvm.heap.used', get('gauges', parsed))))
	result['SPARK_MASTER_JVM_HEAP_MEMORY_USAGE'] = tonumber(get('value', get('jvm.heap.usage', get('gauges', parsed))))
	result['SPARK_MASTER_JVM_NONHEAP_MEMORY_COMMITTED'] = tonumber(get('value', get('jvm.non-heap.committed', get('gauges', parsed))))
	result['SPARK_MASTER_JVM_NONHEAP_MEMORY_USED'] = tonumber(get('value', get('jvm.non-heap.used', get('gauges', parsed))))
	result['SPARK_MASTER_JVM_NONHEAP_MEMORY_USAGE'] = tonumber(get('value', get('jvm.non-heap.usage', get('gauges', parsed))))

	return result
end

pluginMaster:poll()

-- Params for App
local appParams = clone(params)
appParams.name = 'Spark App Plugin'
appParams.host = params.app_host
appParams.port = params.app_port
appParams.path = params.app_path
local pluginWebUI = HttpPlugin:new(appParams)

function getFuzzy(fuzzyKey, map)
	local predicate = partial(contains, escape(fuzzyKey))
	local k = head(filter(predicate, keys(map)))

	return get(k, map)
end

getValue = partial(get, 'value')
getFuzzyValue = compose(getFuzzy, getValue)
getFuzzyNumber = compose(getFuzzyValue, tonumber)

function megaBytesToBytes(mb)
	return mb * 1024 * 1024
end

function pluginWebUI:onParseResponse(data)
	local parsed = json.parse(data)
	parsed = get('gauges', parsed)
	local result = {}
	result['SPARK_APP_JOBS_ACTIVE'] = getFuzzyValue('job.activeJobs', parsed) 
	result['SPARK_APP_JOBS_ALL'] = getFuzzyValue('job.allJobs', parsed)
	result['SPARK_APP_STAGES_FAILED'] = getFuzzyValue('stage.failedStages', parsed)
	result['SPARK_APP_STAGES_RUNNING'] = getFuzzyValue('stage.runningStages', parsed)
	result['SPARK_APP_STAGES_WAITING'] = getFuzzyValue('stage.waitingStages', parsed)
	result['SPARK_APP_BLKMGR_DISK_SPACE_USED'] = megaBytesToBytes(getFuzzyNumber('BlockManager.disk.diskSpaceUsed_MB', parsed))
	result['SPARK_APP_BLKMGR_MEMORY_USED'] = megaBytesToBytes(getFuzzyNumber('BlockManager.memory.memUsed_MB', parsed))
	result['SPARK_APP_BLKMGR_MEMORY_FREE'] = megaBytesToBytes(getFuzzyNumber('BlockManager.memory.remainingMem_MB', parsed))
	result['SPARK_APP_JVM_MEMORY_COMMITTED'] = getFuzzyNumber('jvm.total.committed', parsed)
	result['SPARK_APP_JVM_MEMORY_USED'] = getFuzzyNumber('jvm.total.used', parsed)
	result['SPARK_APP_JVM_HEAP_MEMORY_COMMITTED'] = getFuzzyNumber('jvm.heap.committed', parsed)
	result['SPARK_APP_JVM_HEAP_MEMORY_USED'] = getFuzzyNumber('jvm.heap.used', parsed)
	result['SPARK_APP_JVM_HEAP_MEMORY_USAGE'] = getFuzzyNumber('jvm.heap.usage', parsed)
	result['SPARK_APP_JVM_NONHEAP_MEMORY_COMMITTED'] = getFuzzyNumber('jvm.non-heap.committed', parsed)
	result['SPARK_APP_JVM_NONHEAP_MEMORY_USED'] = getFuzzyNumber('jvm.non-heap.used', parsed)
	result['SPARK_APP_JVM_NONHEAP_MEMORY_USAGE'] = getFuzzyNumber('jvm.non-heap.usage', parsed)

	return result
end

pluginWebUI:poll()
