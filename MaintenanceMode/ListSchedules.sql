/*
From https://azurecloudai.blog/2019/12/04/infrastructure-system-center-operations-manager-sql-query-for-scom-maintenance-mode-schedules/ 
*/

Use OperationsManager
SELECT
      [ScheduleName]
      , ( SELECT  BaseManagedEntity.DisplayName + '; '
  FROM  BaseManagedEntity with (NOLOCK)
  left join [OperationsManager].[dbo].[ScheduleEntity] on BaseManagedEntity.BaseManagedEntityId = ScheduleEntity.BaseManagedEntityId 
  where  ScheduleEntity.ScheduleId = MMS.ScheduleId
   FOR XML PATH('') 
   ) as ObjectName
 
      , case 
         when Recursive = 0 then 'False' 
         when Recursive = 1 then 'True' 
         else 'Undefined' 
       end as "Recursive" 
      , case 
         when IsEnabled = 0 then 'False' 
         when IsEnabled = 1 then 'True' 
         else 'Undefined' 
       end as "IsEnabled" 
      , case 
         when Status = 0 then 'Not Running' 
         when Status = 1 then 'Running' 
         else 'Running' 
       end as "Status" 
       
      , case 
         when IsRecurrence = 0 then 'False' 
         when IsRecurrence = 1 then 'True' 
         else 'Undefined' 
       end as "IsRecurrence" 
      ,[Duration]
      ,[Comments]
      ,[User]
      ,[NextRunTIme]
      ,[LastRunTIme]
  FROM [OperationsManager].[dbo].[MaintenanceModeSchedule] as MMS with (NOLOCK)