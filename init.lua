-- Copyright 2015 BMC Software, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local framework = require('framework.lua')
local json = require('json')
local Plugin = framework.Plugin
local WebRequestDataSource = framework.WebRequestDataSource
local PollerCollection = framework.PollerCollection
local DataSourcePoller = framework.DataSourcePoller
local megaBytesToBytes = framework.util.megaBytesToBytes
local isHttpSuccess = framework.util.isHttpSuccess
local parseJson = framework.util.parseJson
local ipack = framework.util.ipack
framework.functional()
framework.table()
framework.string()

local params = framework.boundary.param

local function createOptions(config)
  local options = {}
  options.host = config.host
  options.port = config.port
  options.path = ''
  return options 
end

local function addPollers(item, pollers)
  if(item.instance_type == 'master') then  	
  	--Datasource to poll all the master details.
	local options = createOptions(item)
	options.path = '/metrics/master/json/'
  	options.meta = { instance_type = 'master', source = item.source }
  	local ds1 = WebRequestDataSource:new(options)  	
    	pollers:add(DataSourcePoller:new(item.pollInterval, ds1))

	--Datasource to poll active drivers
	local options1 = createOptions(item)
	options1.path = '/metrics/master/json/'
    	options1.meta = { instance_type = 'drivers', source = item.source }
    	local ds2 = WebRequestDataSource:new(options1)
    	pollers:add(DataSourcePoller:new(item.pollInterval, ds2))
		
  else
  	--Datasource to poll all the worker application details.
	item.path = '/metrics/json/'
	item.meta = { instance_type = 'app', source = item.source }
  	local ds3 = WebRequestDataSource:new(item)
  	pollers:add(DataSourcePoller:new(item.pollInterval, ds3))
  end
  
end

local function createPollers(items)
  local pollers = PollerCollection:new()
  for _, item in ipairs(items) do
    addPollers(item, pollers)
  end
  return pollers
end

local function getFuzzy(fuzzyKey, map)
  local predicate = partial(contains, escape(fuzzyKey))
  local k = filter(predicate, keys(map))[1]
  return get(k, map)
end

local pollers = createPollers(params.items)
local plugin = Plugin:new(params, pollers)

local getValue = partial(get, 'value')
local getFuzzyValue = compose(getFuzzy, getValue)
local getFuzzyNumber = compose(getFuzzyValue, tonumber)

function plugin:onParseValues(data, extra)
  if not isHttpSuccess(extra.status_code) then
    self:emitEvent('error', ('Http Response status code %d instead of OK. Verify your Spark endpoint configuration.'):format(extra.status_code))
    return
  end

  local success, parsed = parseJson(data) 
  if not success then
    self:emitEvent('error', 'Can not parse metrics. Verify your Spark endpoint configuration.') 
    return
  end

  local result = {}
  local source = extra.info.source
  local metric = function (...)
    ipack(result, ...)
  end
  local instance_type = extra.info.instance_type
  if instance_type == 'master' then
    metric('SPARK_MASTER_ALIVE_WORKERS_COUNT', getValue(parsed.gauges['master.aliveWorkers']), nil, source)
    metric('SPARK_MASTER_WORKERS_COUNT', getValue(parsed.gauges['master.workers']), nil, source)

    local runningApps = getValue(parsed.gauges['master.apps'])
    local waitingApps = getValue(parsed.gauges['master.waitingApps'])
    metric('SPARK_MASTER_APPLICATIONS_RUNNING_COUNT', runningApps, nil, source)
    metric('SPARK_MASTER_APPLICATIONS_WAITING_COUNT', waitingApps, nil, source)
    
    if(runningApps == 0 and waitingApps > 0) then
	metric('SPARK_MASTER_NO_APPLICATIONS_RUNNING', 1, nil, source)
    else
	metric('SPARK_MASTER_NO_APPLICATIONS_RUNNING', 0, nil, source)
    end
	
    metric('SPARK_MASTER_JVM_MEMORY_USED', getValue(parsed.gauges['jvm.total.used']), nil, source)
    metric('SPARK_MASTER_JVM_MEMORY_COMMITTED', getValue(parsed.gauges['jvm.total.committed']), nil, source)
    metric('SPARK_MASTER_JVM_HEAP_MEMORY_COMMITTED', getValue(parsed.gauges['jvm.heap.committed']), nil, source)
    metric('SPARK_MASTER_JVM_HEAP_MEMORY_USED', getValue(parsed.gauges['jvm.heap.used']), nil, source)
    metric('SPARK_MASTER_JVM_HEAP_MEMORY_USAGE', getValue(parsed.gauges['jvm.heap.usage']), nil, source)
    metric('SPARK_MASTER_JVM_NONHEAP_MEMORY_COMMITTED', getValue(parsed.gauges['jvm.non-heap.committed']), nil, source)
    metric('SPARK_MASTER_JVM_NONHEAP_MEMORY_USED', getValue(parsed.gauges['jvm.non-heap.used']), nil, source)
    metric('SPARK_MASTER_JVM_NONHEAP_MEMORY_USAGE', getValue(parsed.gauges['jvm.non-heap.usage']), nil, source)

  elseif instance_type == 'drivers' then
    local activeDrivers = parsed.activedrivers
    if(activeDrivers ~= nil) then 
	if(table.getn(activeDrivers) > 1) then
		metric('SPARK_MASTER_ACTIVE_DRIVERS_EXEEDED', 1, nil, source)
	else
		metric('SPARK_MASTER_ACTIVE_DRIVERS_EXEEDED', 0, nil, source)
	end
    else
	metric('SPARK_MASTER_ACTIVE_DRIVERS_EXEEDED', 0, nil, source)
    end
    
  elseif instance_type == 'app' then
    parsed = get('gauges', parsed)
    metric('SPARK_APP_JOBS_ACTIVE', getFuzzyValue('job.activeJobs', parsed), nil, source)
    metric('SPARK_APP_JOBS_ALL', getFuzzyValue('job.allJobs', parsed), nil, source)
    metric('SPARK_APP_STAGES_FAILED', getFuzzyValue('stage.failedStages', parsed), nil, source)
    metric('SPARK_APP_STAGES_RUNNING', getFuzzyValue('stage.runningStages', parsed), nil, source)
    metric('SPARK_APP_STAGES_WAITING', getFuzzyValue('stage.waitingStages', parsed), nil, source)
    metric('SPARK_APP_BLKMGR_DISK_SPACE_USED', megaBytesToBytes(getFuzzyNumber('BlockManager.disk.diskSpaceUsed_MB', parsed)), nil, source)
    metric('SPARK_APP_BLKMGR_MEMORY_USED', megaBytesToBytes(getFuzzyNumber('BlockManager.memory.memUsed_MB', parsed)), nil, source)
    metric('SPARK_APP_BLKMGR_MEMORY_FREE', megaBytesToBytes(getFuzzyNumber('BlockManager.memory.remainingMem_MB', parsed)), nil, source)
    metric('SPARK_APP_JVM_MEMORY_COMMITTED', getFuzzyNumber('jvm.total.committed', parsed), nil, source)
    metric('SPARK_APP_JVM_MEMORY_USED', getFuzzyNumber('jvm.total.used', parsed), nil, source)
    metric('SPARK_APP_JVM_HEAP_MEMORY_COMMITTED', getFuzzyNumber('jvm.heap.committed', parsed), nil, source)
    metric('SPARK_APP_JVM_HEAP_MEMORY_USED', getFuzzyNumber('jvm.heap.used', parsed), nil, source)
    metric('SPARK_APP_JVM_HEAP_MEMORY_USAGE', getFuzzyNumber('jvm.heap.usage', parsed), nil, source)
    metric('SPARK_APP_JVM_NONHEAP_MEMORY_COMMITTED', getFuzzyNumber('jvm.non-heap.committed', parsed), nil, source)
    metric('SPARK_APP_JVM_NONHEAP_MEMORY_USED', getFuzzyNumber('jvm.non-heap.used', parsed), nil, source)
    metric('SPARK_APP_JVM_NONHEAP_MEMORY_USAGE', getFuzzyNumber('jvm.non-heap.usage', parsed), nil, source)
  end
  return result
end

plugin:run()

