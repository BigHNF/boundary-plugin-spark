-- Copyright 2015 Boundary, Inc.
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
framework.functional()
framework.table()
framework.string()

local params = framework.boundary.param

local function createDataSource(item)
  item.path = item.instance_type == 'master' and '/metrics/master/json/' or '/metrics/json/'
  item.meta = item.instance_type
  local ds = WebRequestDataSource:new(item)
  return ds
end

local function poller(item)
  local ds = createDataSource(item)
  return DataSourcePoller:new(item.pollInterval, ds)
end

local function createPollers(items)
  local pollers = PollerCollection:new()
  for _, i in ipairs(items) do
    pollers:add(poller(i))
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
  if extra.info == 'master' then
    result['SPARK_MASTER_WORKERS_COUNT'] = getValue(parsed.gauges['master.workers'])
    result['SPARK_MASTER_APPLICATIONS_RUNNING_COUNT'] = getValue(parsed.gauges['master.apps'])
    result['SPARK_MASTER_APPLICATIONS_WAITING_COUNT'] = getValue(parsed.gauges['master.waitingApps'])
    result['SPARK_MASTER_JVM_MEMORY_USED'] = getValue(parsed.gauges['jvm.total.used'])
    result['SPARK_MASTER_JVM_MEMORY_COMMITTED'] = getValue(parsed.gauges['jvm.total.committed'])
    result['SPARK_MASTER_JVM_HEAP_MEMORY_COMMITTED'] = getValue(parsed.gauges['jvm.heap.committed'])
    result['SPARK_MASTER_JVM_HEAP_MEMORY_USED'] = getValue(parsed.gauges['jvm.heap.used'])
    result['SPARK_MASTER_JVM_HEAP_MEMORY_USAGE'] = getValue(parsed.gauges['jvm.heap.usage'])
    result['SPARK_MASTER_JVM_NONHEAP_MEMORY_COMMITTED'] = getValue(parsed.gauges['jvm.non-heap.committed'])
    result['SPARK_MASTER_JVM_NONHEAP_MEMORY_USED'] = getValue(parsed.gauges['jvm.non-heap.used'])
    result['SPARK_MASTER_JVM_NONHEAP_MEMORY_USAGE'] = getValue(parsed.gauges['jvm.non-heap.usage'])
  elseif extra.info == 'app' then
    parsed = get('gauges', parsed)
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
  end
  return result
end

plugin:run()

