/********************************************************************************************

***  ���������� ������ � ������� sp_whoisactive ***
------------------------------------------------

� ���������� ���� ������ ��� ����������� ������� �������
� ��������� ���������, ����� ��� CPU, ����������, ������� ������� ��� �����
������� �������� ��������� sp_whoisactive, ����������, �������� �� �� ������,

https://github.com/SqlAdmin/AwesomeSQLServer/blob/master/T-SQL%20Scripts/sp_whoisactive.sql

*******************************************************************************************/ 

-- ����� �������� ����� ���������� � ������� �������

EXEC sp_whoisactive


------------------------------------------------
/*** 1. ������������ ����� ���������� � ������ ������ ������� ***/
------------------------------------------------

--[Dd hh:mm:ss.mss] � ��� ��������� ������� ���������� ����� ����������, ��� ������� ������ � ����� ����
--[������������� ������]
--[CPU] - ��� ��������� ������� - ��������� ����� ��, ����������� ���� ��������, ��� ������ ������ - ��������� ����� 
--�� �� "��� �����" ���� ������;
--[sql_text] - ���������� ����� ������������ ������ �������, ���� ����� ���������� ������������ �������, ���� ������ ����;

EXEC sp_WhoIsActive @get_plans = 1,
                    @get_avg_time = 1,
                    @output_column_list = '[dd%][session_id][database_name][cpu%][sql_text]',
                    @sort_order = '[start_time] ASC'


-----------------------------------------------------------
/*** 2. ������������� ������� ������ ������� ������� ***/
-----------------------------------------------------------
--[used_memory] - ��� ��������� ������� - ���������� ������������������ �������, �������������� ��� ���������� 
--����� �������;
--[sql_text] - ���������� ����� ������������ ������ �������, ���� ����� ���������� ������������ �������, ����
--������ ����;
--[tempdb_allocations] � ��� ��������� ������� � ��� ���������� �������� ������ � TempDB �� ����� ���������� 
--�������;
--[tempdb_current] � ��� ��������� ������� � ���������� ������� � TempDB, ���������� ��� ����� �������; 
EXEC sp_WhoIsActive @output_column_list = '[dd%][session_id][database_name][sql_text][used_memory][tempdb_allocations][tempdb_current]',
                    @sort_order = '[start_time] ASC';


--------------------------------------------------------------
/*** 3. ������� ������, ����� � ���� ���������� ***/
--------------------------------------------------------------                   
----[sql_text] - ���������� ����� ������������ ������ �������, ���� ����� ���������� ������������ �������, ����
--������ ����;

EXEC sp_WhoIsActive @get_full_inner_text = 1,
                    @get_plans = 1,
                    @get_outer_command = 1,
                    @output_column_list = '[dd%][session_id][database_name][sql_text][sql_command][query_plan]',
                    @sort_order = '[start_time] ASC';


-----------------------------------------------------------------
/*** 4. ���������� �������� ������ ������� ���������� ������ ***/
----------------------------------------------------------------- 
--[tran_log_writes] �������� ���������� � ����� ���� ������, � ������� ���� �������� ���������� �� ����� ����������. 
EXEC sp_WhoIsActive @get_transaction_info = 1,
                    @output_column_list = '[dd%][session_id][database_name][tran_log_writes]',
                    @sort_order = '[start_time] ASC';

               