local framework = require('framework.lua')
local json = require('json')
local Plugin = framework.Plugin
local WebRequestDataSource = framework.WebRequestDataSource
local PollerCollection = framework.PollerCollection
local DataSourcePoller = framework.DataSourcePoller
require('fun')()
local string = require('string')
local table = require('table')
local get = framework.table.get
local partial = framework.functional.partial
local contains = framework.string.contains
local compose = framework.functional.compose
local keys = framework.table.keys
local escape = framework.string.escape
local clone = framework.table.clone

local params = framework.boundary.param
params.name = 'Spark Master Plugin'
params.tags = 'spark'
params.version = '2.0'

local ds_master = WebRequestDataSource:new(params)
local pluginMaster = Plugin:new(params, ds_master)

function pluginMaster:onParseValues(data)
	local parsed = json.parse(data)	
	local result = {}
	result['SPARK_MASTER_WORKERS_COUNT'] = tonumber(parsed.gauges['master.workers'].value)
	result['SPARK_MASTER_APPLICATIONS_RUNNING_COUNT'] = tonumber(parsed.gauges['master.apps'].value)
	result['SPARK_MASTER_APPLICATIONS_WAITING_COUNT'] = tonumber(parsed.gauges['master.waitingApps'].value)
	result['SPARK_MASTER_JVM_MEMORY_USED'] = tonumber(parsed.gauges['jvm.total.used'].value)
	result['SPARK_MASTER_JVM_MEMORY_COMMITTED'] = tonumber(parsed.gauges['jvm.total.committed'].value)
	result['SPARK_MASTER_JVM_HEAP_MEMORY_COMMITTED'] = tonumber(parsed.gauges['jvm.heap.committed'].value)
	result['SPARK_MASTER_JVM_HEAP_MEMORY_USED'] = tonumber(parsed.gauges['jvm.heap.used'].value)
	result['SPARK_MASTER_JVM_HEAP_MEMORY_USAGE'] = tonumber(parsed.gauges['jvm.heap.usage'].value)
	result['SPARK_MASTER_JVM_NONHEAP_MEMORY_COMMITTED'] = tonumber(parsed.gauges['jvm.non-heap.committed'].value)
	result['SPARK_MASTER_JVM_NONHEAP_MEMORY_USED'] = tonumber(parsed.gauges['jvm.non-heap.used'].value)
	result['SPARK_MASTER_JVM_NONHEAP_MEMORY_USAGE'] = tonumber(parsed.gauges['jvm.non-heap.usage'].value)
	return result
end

pluginMaster:run()

-- Params for App
local appParams = clone(params)
appParams.name = 'Spark App Plugin'
appParams.host = params.app_host
appParams.port = params.app_port
appParams.path = params.app_path
local ds_app = WebRequestDataSource:new(appParams)  
local pluginWebUI = Plugin:new(appParams, ds_app)

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

function pluginWebUI:onParseValues(data)
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

pluginWebUI:run()
