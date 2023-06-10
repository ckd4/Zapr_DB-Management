/*** ЗАПРОСЫ МОНИТОРИНГА ПАМЯТИ SQL SERVER ***/
----------------------------------
/*** 1. Состояние системной памяти ***/
----------------------------------

--[Total Physical Memory] – объём оперативной памяти доступный в операционной системе.
--[Available Physical Memory] – объём оперативной памяти доступный для SQL Server, без учета уже захваченной SQL Server.
--[Total Page File (MB)] – Объём “Сommit limit”. Commit Limit = Оперативная память + все файлы подкачки.
--[Available Page File (MB)] – Объём файла подкачки.
--[Memory State] – Состояние RAM. 
SELECT total_physical_memory_kb / 1024                             AS 
       [Total Physical Memory], 
       available_physical_memory_kb / 1024                         AS 
       [Available Physical Memory], 
       total_page_file_kb / 1024                                   AS 
       [Total Page File (MB)], 
       available_page_file_kb / 1024                               AS 
       [Available Page File (MB)], 
       100 - ( 100 * Cast(available_physical_memory_kb AS DECIMAL(18, 3)) / Cast 
               ( 
                     total_physical_memory_kb AS DECIMAL(18, 3)) ) AS 
       'Percentage Used', 
       system_memory_state_desc                                    AS 
       [Memory State] 
FROM   sys.dm_os_sys_memory; 

---------------------------------------
/*** 2. Состояние памяти SQL Server ***/
---------------------------------------
--Buffer pool – это область в памяти, которая используется для кэширования страниц, 
--данных таблиц и их индексов, размер страниц 8Кб. Использования Buffer pool уменьшает ввод/вывод в файл базы данных 
--и таким образом увеличивает производительность сервера.
-- это покажет, сколько памяти выделено SQL Server для фиксации буферного пула.
--SQL Server создает в памяти пул буферов для хранения страниц, считываемых из базы данных.
--если много пул буферов - системе не хватит памяти

--[Buffer Pool Committed] - фактическая память, выделенная/использованная процессом (SQL Server).
--[Buffer Pool Committed Targer]- Фактическая память, которую SQL Server пытался использовать.
SELECT
      (committed_kb)/1024.0 as [Buffer Pool Committed (MB)],
      (committed_target_kb)/1024.0 as [Buffer Pool Committed Targer (MB)] 
FROM  sys.dm_os_sys_info;

----------------------------------------------
/*** 3. Физическая Память, Используемая SQL Server***/
----------------------------------------------
-- Найдите Физическую память, используемую SQL Server
--Физическая память, используемая SQL Server, - это общий объем 
--оперативной памяти (физической), используемой SQL Server.

--[Physical Memory Used By SQL] - Физическая память, Используемая SQL
--[Locked Page Allocation] -  если это значение > 0, это означает, что заблокированные 
--страницы включены для SQL Server, что является одной из лучших практик.
--[Available Commit Limit] - указывает доступный объем памяти, который может быть 
--зафиксирован процессом sqlservr.exe.
--[Page Fault Count] - выборка страниц из файла подкачки на жестком диске, а не из физической памяти. 
--Постоянно высокое количество серьезных ошибок в секунду указывает на нехватку памяти.

select
      convert(decimal (5,2),physical_memory_in_use_kb/1048576.0) AS 'Physical Memory Used By SQL (GB)',
      convert(decimal (5,2),locked_page_allocations_kb/1048576.0) As 'Locked Page Allocation',
       convert(decimal (5,2),available_commit_limit_kb/1048576.0) AS 'Available Commit Limit (GB)',
      page_fault_count as 'Page Fault Count'
from  sys.dm_os_process_memory;

------------------------------------------
/*** 4. Использование пула буферов Базами данных ***/
------------------------------------------
--[DataBase Name] - Имя базы данных
--[DB Buffer Pages] - общее количество соответствующих страниц базы данных, находящихся в буферном пуле.
--[DB Buffer Pages Used] - Размер используемого буфера для базы данных в МБ
--[DB Buffer Pages Free] - Свободный размер буфера для базы данных
--[DB Buffer Percentag] - Процент использования буферного пула для базы данных.

DECLARE @total_buffer INT;
SELECT  @total_buffer = cntr_value 
FROM   sys.dm_os_performance_counters
WHERE  RTRIM([object_name]) LIKE '%Buffer Manager' 
       AND counter_name = 'Database Pages';
 
;WITH DBBuffer AS
(
SELECT  database_id,
        COUNT_BIG(*) AS db_buffer_pages,
        SUM (CAST ([free_space_in_bytes] AS BIGINT)) / (1024 * 1024) AS [MBEmpty]
FROM    sys.dm_os_buffer_descriptors
GROUP BY database_id
)
SELECT
       CASE [database_id] WHEN 32767 THEN 'Resource DB' ELSE DB_NAME([database_id]) END AS 'DataBase Name',
       db_buffer_pages AS 'DB Buffer Pages',
       db_buffer_pages / 128 AS 'DB Buffer Pages Used (MB)',
       [mbempty] AS 'DB Buffer Pages Free (MB)',
       CONVERT(DECIMAL(6,3), db_buffer_pages * 100.0 / @total_buffer) AS 'DB Buffer Percentage'
FROM   DBBuffer
ORDER BY [DB Buffer Pages Used (MB)] DESC;

--------------------------------------------
/*** 5. Память, Используемая Объектами Базы Данных ***/
--------------------------------------------

--[Object] - Имя объекта
--[Type] - Тип объекта
--[Index] - Название индекса
--[Index_Type] - Тип индекса
--[buffer pages] - объектно-ориентированное количество страниц находится в пуле буферов
--[buffer MB] - Объектное использование буфера в МБ
--Кластеризованный (Clustered) – это индекс, который хранит данные
--таблицы в отсортированном, по значению ключа индекса, виде.

;WITH obj_buffer 
     AS (SELECT [Object] = o.NAME, 
                [Type] = o.type_desc, 
                [Index] = COALESCE(i.NAME, ''), 
                [Index_Type] = i.type_desc, 
                p.[object_id], 
                p.index_id, 
                au.allocation_unit_id 
         FROM   sys.partitions AS p 
                INNER JOIN sys.allocation_units AS au 
                        ON p.hobt_id = au.container_id 
                INNER JOIN sys.objects AS o 
                        ON p.[object_id] = o.[object_id] 
                INNER JOIN sys.indexes AS i 
                        ON o.[object_id] = i.[object_id] 
                           AND p.index_id = i.index_id 
         WHERE  au.[type] IN ( 1, 2, 3 ) 
                AND o.is_ms_shipped = 0) 
SELECT obj.[object], 
       obj.[type], 
       obj.[index], 
       obj.index_type, 
       Count_big(b.page_id)       AS 'Buffer Pages', 
       Count_big(b.page_id) / 128 AS 'Buffer MB' 
FROM   obj_buffer obj 
       INNER JOIN sys.dm_os_buffer_descriptors AS b 
               ON obj.allocation_unit_id = b.allocation_unit_id 
WHERE  b.database_id = Db_id() 
GROUP  BY obj.[object], 
          obj.[type], 
          obj.[index], 
          obj.index_type 
ORDER  BY [buffer pages] DESC; 

----------------------------------------
/*** 6. Самые дорогостоящие хранимые процедуры ***/
----------------------------------------
-- На основе логических операций чтения

--[SP Name] - Имя хранимой процедуры
--[TotalLogicalReads] - общее количество логических операций чтения с момента
--последней компиляции этой хранимой процедуры.
--[AvgLogicalRead] - среднее число логических операций чтения с момента
--последней компиляции этой хранимой процедуры.
--[execution_count] - количество раз, когда SP был выполнен с момента его компиляции.
--[total_elapsed_time] - общее время, прошедшее для этого процесса с момента последней компиляции.
--[avg_elapsed_time] - Среднее прошедшее время
--[cached_time] - время добавления хранимой процедуры в кеш.

SELECT TOP(25) p.NAME                                      AS [SP Name], 
               qs.total_logical_reads                      AS 
               [TotalLogicalReads], 
               qs.total_logical_reads / qs.execution_count AS [AvgLogicalReads], 
               qs.execution_count                          AS 'execution_count', 
               qs.total_elapsed_time                       AS 
               'total_elapsed_time', 
               qs.total_elapsed_time / qs.execution_count  AS 'avg_elapsed_time' 
               , 
               qs.cached_time                              AS 
               'cached_time' 
FROM   sys.procedures AS p 
       INNER JOIN sys.dm_exec_procedure_stats AS qs 
               ON p.[object_id] = qs.[object_id] 
WHERE  qs.database_id = Db_id() 
ORDER  BY qs.total_logical_reads DESC; 

----------------------------------------------
/*** 7. Счетчики максимальной производительности – Память ***/
----------------------------------------------

--Общий объем серверной памяти (ГБ)
--Память целевого сервера (ГБ)
--Память для подключения (МБ)
--Память блокировки (МБ)
--Кэш-память SQL (МБ)
--Память оптимизатора (МБ)
--Выделенная рабочая память (МБ)
--Использование памяти курсора (МБ)
--Страницы базы данных (МБ)
--Страницы кэша (МБ)
--Ожидаемый срок службы страницы в секундах
--Свободный список остановок/сек.
--Контрольные страницы/сек
--Ленивая запись в секунду
--Ожидающие предоставления памяти
--Память предоставляет выдающиеся
--процесс _ физическая_ память _ низкий уровень
--процесс _ виртуальный _ объем памяти _ низкий
--Максимальная серверная память (МБ)
--Минимальная память сервера (МБ)
--Коэффициент попадания в буферный кэш

-- Получить размер страницы SQL Server в байтах 
DECLARE @pg_size      INT, 
        @Instancename VARCHAR(50) 

SELECT @pg_size = low 
FROM   master..spt_values 
WHERE  number = 1 
       AND type = 'E' 

-- Извлеките счетчики perfmon во временную таблицу
IF Object_id('tempdb..#perfmon_counters') IS NOT NULL 
  DROP TABLE #perfmon_counters 

SELECT * 
INTO   #perfmon_counters 
FROM   sys.dm_os_performance_counters; 

-- Получите имя экземпляра SQL Server, необходимое для получения коэффициента попадания в буфер и кэш
SELECT @Instancename = LEFT([object_name], ( Charindex(':', [object_name]) )) 
FROM   #perfmon_counters 
WHERE  counter_name = 'Buffer cache hit ratio'; 

SELECT * 
FROM   (SELECT 'Total Server Memory (GB)' AS Counter, 
               ( cntr_value / 1048576.0 ) AS Value 
        FROM   #perfmon_counters 
        WHERE  counter_name = 'Total Server Memory (KB)' 
        UNION ALL 
        SELECT 'Target Server Memory (GB)', 
               ( cntr_value / 1048576.0 ) 
        FROM   #perfmon_counters 
        WHERE  counter_name = 'Target Server Memory (KB)' 
        UNION ALL 
        SELECT 'Connection Memory (MB)', 
               ( cntr_value / 1024.0 ) 
        FROM   #perfmon_counters 
        WHERE  counter_name = 'Connection Memory (KB)' 
        UNION ALL 
        SELECT 'Lock Memory (MB)', 
               ( cntr_value / 1024.0 ) 
        FROM   #perfmon_counters 
        WHERE  counter_name = 'Lock Memory (KB)' 
        UNION ALL 
        SELECT 'SQL Cache Memory (MB)', 
               ( cntr_value / 1024.0 ) 
        FROM   #perfmon_counters 
        WHERE  counter_name = 'SQL Cache Memory (KB)' 
        UNION ALL 
        SELECT 'Optimizer Memory (MB)', 
               ( cntr_value / 1024.0 ) 
        FROM   #perfmon_counters 
        WHERE  counter_name = 'Optimizer Memory (KB) ' 
        UNION ALL 
        SELECT 'Granted Workspace Memory (MB)', 
               ( cntr_value / 1024.0 ) 
        FROM   #perfmon_counters 
        WHERE  counter_name = 'Granted Workspace Memory (KB) ' 
        UNION ALL 
        SELECT 'Cursor memory usage (MB)', 
               ( cntr_value / 1024.0 ) 
        FROM   #perfmon_counters 
        WHERE  counter_name = 'Cursor memory usage' 
               AND instance_name = '_Total' 
        UNION ALL 
        SELECT 'Total pages Size (MB)', 
               ( cntr_value * @pg_size ) / 1048576.0 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Buffer Manager' 
               AND counter_name = 'Total pages' 
        UNION ALL 
        SELECT 'Database pages (MB)', 
               ( cntr_value * @pg_size ) / 1048576.0 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Buffer Manager' 
               AND counter_name = 'Database pages' 
        UNION ALL 
        SELECT 'Free pages (MB)', 
               ( cntr_value * @pg_size ) / 1048576.0 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Buffer Manager' 
               AND counter_name = 'Free pages' 
        UNION ALL 
        SELECT 'Reserved pages (MB)', 
               ( cntr_value * @pg_size ) / 1048576.0 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Buffer Manager' 
               AND counter_name = 'Reserved pages' 
        UNION ALL 
        SELECT 'Stolen pages (MB)', 
               ( cntr_value * @pg_size ) / 1048576.0 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Buffer Manager' 
               AND counter_name = 'Stolen pages' 
        UNION ALL 
        SELECT 'Cache Pages (MB)', 
               ( cntr_value * @pg_size ) / 1048576.0 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Plan Cache' 
               AND counter_name = 'Cache Pages' 
               AND instance_name = '_Total' 
        UNION ALL 
        SELECT 'Page Life Expectency in seconds', 
               cntr_value 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Buffer Manager' 
               AND counter_name = 'Page life expectancy' 
        UNION ALL 
        SELECT 'Free list stalls/sec', 
               cntr_value 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Buffer Manager' 
               AND counter_name = 'Free list stalls/sec' 
        UNION ALL 
        SELECT 'Checkpoint pages/sec', 
               cntr_value 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Buffer Manager' 
               AND counter_name = 'Checkpoint pages/sec' 
        UNION ALL 
        SELECT 'Lazy writes/sec', 
               cntr_value 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Buffer Manager' 
               AND counter_name = 'Lazy writes/sec' 
        UNION ALL 
        SELECT 'Memory Grants Pending', 
               cntr_value 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Memory Manager' 
               AND counter_name = 'Memory Grants Pending' 
        UNION ALL 
        SELECT 'Memory Grants Outstanding', 
               cntr_value 
        FROM   #perfmon_counters 
        WHERE  object_name = @Instancename + 'Memory Manager' 
               AND counter_name = 'Memory Grants Outstanding' 
        UNION ALL 
        SELECT 'process_physical_memory_low', 
               process_physical_memory_low 
        FROM   sys.dm_os_process_memory WITH (nolock) 
        UNION ALL 
        SELECT 'process_virtual_memory_low', 
               process_virtual_memory_low 
        FROM   sys.dm_os_process_memory WITH (nolock) 
        UNION ALL 
        SELECT 'Max_Server_Memory (MB)', 
               [value_in_use] 
        FROM   sys.configurations 
        WHERE  [name] = 'max server memory (MB)' 
        UNION ALL 
        SELECT 'Min_Server_Memory (MB)', 
               [value_in_use] 
        FROM   sys.configurations 
        WHERE  [name] = 'min server memory (MB)' 
        UNION ALL 
        SELECT 'BufferCacheHitRatio', 
               ( a.cntr_value * 1.0 / b.cntr_value ) * 100.0 
        FROM   sys.dm_os_performance_counters a 
               JOIN (SELECT cntr_value, 
                            object_name 
                     FROM   sys.dm_os_performance_counters 
                     WHERE  counter_name = 'Buffer cache hit ratio base' 
                            AND object_name = @Instancename + 'Buffer Manager') 
                    b 
                 ON a.object_name = b.object_name 
        WHERE  a.counter_name = 'Buffer cache hit ratio' 
               AND a.object_name = @Instancename + 'Buffer Manager') AS D; 

