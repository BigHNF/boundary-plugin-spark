Boundary Spark Plugin
=====================

A Boundary Meter plugin that collects metrics from the Spark MetricsServlet sink.
For reference see - http://spark.apache.org/docs/1.2.0/monitoring.html

## Prerequisites

### Supported OS

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   v   |    v    |    v    |  v   |

#### Boundary Meter Versions V4.0 or greater

- To install new meter go to Settings->Installation or [see instructons](https://help.boundary.com/hc/en-us/sections/200634331-Installation). 
- To upgrade the meter to the latest version - [see instructons](https://help.boundary.com/hc/en-us/articles/201573102-Upgrading-the-Boundary-Meter).

### Plugin Setup

#### MetricsServlet
MetricsServlet is added by default as a sink in master, worker and client driver.
See the conf/metrics.properties file on your Spark installation for more details.

#### *jvm source*
You can also enable the *jvm source* for instance master, worker, driver and executor to get detailed metrics of the JVM.

The plugin gathers metrics from the master and a defined, running application. So you need to configure the host and port for the WebUI of the master and application process.

#### WebUI Ports
By default, the WebUI for the master runs on port 8080 and, for example, the WebUI for the shell application runs on 4040. These are the default values for this parameters. You can change them based on your configuration.

### Plugin Configuration Fields

|  Property   | UI Display Name | Description |
|:-----------:|:---------------:|:-----------:|
|host|Master Host|Host of the metrics on the Master WebUI|
|port|Master Port|Port of the metrics on the Master WebUI|
|path|Master Path|Path of the metrics on the Master WebUI|
|app_host|Application Host|Host of the metrics on the Application WebUI|
|app_port|Application Port|Port of the metrics on the Application WebUI|
|app_path|Application Path|Path of the metrics on the Application WebUI|
|pollInterval|Poll Time (ms)|The Poll Interval to call the command. Defaults 2000 milliseconds (2 seconds)|
|source|Source|The source to display in the leged for this instance.|

### Metrics collected
Tracks the following metrics for Spark.

| Metric Name | Description | Context |
|:-----------:|:-----------:|:-------:|
| SPARK_MASTER_WORKERS_COUNT | The number of active workers on the master. | Master |
| SPARK_MASTER_APPLICATIONS_RUNNING_COUNT | Running application count on the master. | Master|
| SPARK_MASTER_APPLICATIONS_WAITING_COUNT | Waiting application count on the master. | Master |
| SPARK_MASTER_JVM_MEMORY_USED | Memory used by the JVM on the master. | Master |
| SPARK_MASTER_JVM_MEMORY_COMMITTED | Memory committed by the JVM on the master. | Master |
| SPARK_MASTER_JVM_HEAP_MEMORY_USED | Heap memory used by the JVM on the master. | Master |
| SPARK_MASTER_JVM_HEAP_MEMORY_USAGE | Percentage of heap memory used by the JVM on the master. | Master |
| SPARK_MASTER_JVM_NONHEAP_MEMORY_COMMITTED | Non-heap memory committed by the JVM on the master. | Master |
| SPARK_MASTER_JVM_NONHEAP_MEMORY_USED | Non-heap memory used by the JVM on the master. | Master |
| SPARK_MASTER_JVM_NONHEAP_MEMORY_USAGE | Percentage of non-heap memory usage by the JVM on the master. | Master
| SPARK_APP_JOBS_ACTIVE | Jobs running on the application | App (i.e. Shell) |
| SPARK_APP_JOBS_ALL | All jobs created by the application. | App |
| SPARK_APP_STAGES_FAILED | Failed stages for the application. | App |
| SPARK_APP_STAGES_RUNNING | Running stages for the application. | App |
| SPARK_APP_STAGES_WAITING | Waiting stages for the application. | App |
| SPARK_APP_BLKMGR_DISK_SPACE_USED | Block manager disk space used | App |
| SPARK_APP_BLKMGR_MEMORY_USED | Block manager memory used | App |
| SPARK_APP_BLKMGR_MEMORY_FREE | Block manager remaining memory | App |
| SPARK_APP_JVM_MEMORY_COMMITTED | Memory committed by the JVM of the app | App |
| SPARK_APP_JVM_MEMORY_USED | Memory used by the JVM of the app | App |
| SPARK_APP_JVM_HEAP_MEMORY_COMMITTED | Heap memory committed by the JVM of the app | App |
| SPARK_APP_JVM_HEAP_MEMORY_USED | Heap memory used by the JVM of the app | App |
| SPARK_APP_JVM_HEAP_MEMORY_USAGE | Percentage of heap memory in use by the JVM of the app | App |
| SPARK_APP_JVM_NOHEAP_MEMORY_COMMITTED | Non-heap memory committed by the JVM of the app | App |
| SPARK_APP_JVM_NONHEAP_MEMORY_USED | Non-heap memory used by the JVM of the app | App |
| SPARK_APP_JVM_NONHEAP_MEMORY_USAGE | Percentage of non-heap memory in use by the JVM of the app | App |

### References

None