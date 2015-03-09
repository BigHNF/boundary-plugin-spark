# boundary-plugin-spark
A Boundary spark plugin that collects metrics from the MetricsServlet sink. http://spark.apache.org/docs/1.2.0/monitoring.html

### Supported OS
|    OS   | Linux | Windows | OS X |
|:-------:|:-----:|:-------:|:----:|
|Supported|   v   |    v    |  v   |


### Plugin setup
MetricsServlet is added by default as a sink in master, worker and client driver.
See the conf/metrics.properties file on you Spark installation for more details.

You can also enable the *jvm source* for instance master, worker, driver and executor to get detailed metrics of the JVM.

The plugin get metrics from the master and a running application. So you need to configure the host and port for the WebUI of the master and application process.

By default, the WebUI for the master runs on port 8080 and, for example, the WebUI for the shell application runs on 4040. These are the default values for this parameters. You can change them based on your configuration.

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
