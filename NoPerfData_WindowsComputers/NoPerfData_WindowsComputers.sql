
/*
You will probably have to change the IsVirtualNode for your OperationsManager database. These are column headers in the mtv_computer table


Processor > % Processor Time (or and objectname ='Processor Information' and countername='% Processor Time' for later versions)
LogicalDisk > % Free Space > C:
Memory > Available MBytes
*/

if object_id('tempdb..#temptable') IS NOT NULL
DROP TABLE #temptable

SELECT     distinct bmetarget.Name into #temptable
FROM        OperationsManager.dbo.BaseManagedEntity AS BMESource WITH (nolock) INNER JOIN
OperationsManager.dbo.Relationship AS R WITH (nolock) ON
R.SourceEntityId = BMESource.BaseManagedEntityId INNER JOIN
OperationsManager.dbo.BaseManagedEntity AS BMETarget WITH (nolock) ON
--R.TargetEntityId = BMETarget.BaseManagedEntityId inner join mtv_computer d on bmetarget.name=d.[DisplayName_55270A70_AC47_C853_C617_236B0CFF9B4C]
R.TargetEntityId = BMETarget.BaseManagedEntityId inner join mtv_computer d on bmetarget.name=d.[DisplayName]
and d.IsVirtualNode_B880813A_A3C6_D422_463E_E5739F81BDCA is null
WHERE     (bmetarget.fullname like 'Microsoft.Windows.Computer%')

if object_id('tempdb..#healthstate') IS NOT NULL
DROP TABLE #healthstate

select  megv.path, megv.ismanaged, megv.isavailable, megv.healthstate into #healthstate
from managedentitygenericview as megv with (nolock) inner join managedtypeview as mtv with (nolock)
on megv.monitoringclassid=mtv.id
where mtv.name ='microsoft.systemcenter.agent'

if object_id('tempdb..#perfcpudata') IS NOT NULL
DROP TABLE #perfcpudata

select Path, 'CPU' as 'Cat' into #perfcpudata
from PerformanceDataAllView pdv with (NOLOCK)
inner join PerformanceCounterView pcv on pdv.performancesourceinternalid = pcv.performancesourceinternalid
inner join BaseManagedEntity bme on pcv.ManagedEntityId = bme.BaseManagedEntityId
where (TimeSampled < GETUTCDATE() AND TimeSampled > DATEADD(MINUTE,-240, GETUTCDATE()))
and objectname ='Processor Information' and countername='% Processor Time'
-- and objectname ='Processor' and countername='% Processor Time'


if object_id('tempdb..#perfmemdata') IS NOT NULL
DROP TABLE #perfmemdata

select Path,'Memory' as 'Cat' into #perfmemdata
from PerformanceDataAllView pdv with (NOLOCK)
inner join PerformanceCounterView pcv on pdv.performancesourceinternalid = pcv.performancesourceinternalid
inner join BaseManagedEntity bme on pcv.ManagedEntityId = bme.BaseManagedEntityId
where (TimeSampled < GETUTCDATE() AND TimeSampled > DATEADD(MINUTE,-240, GETUTCDATE()))
and objectname ='Memory' and countername='Available MBytes'

if object_id('tempdb..#perfdiskdata') IS NOT NULL
DROP TABLE #perfdiskdata

select Path,'Disk' as 'Cat' into #perfdiskdata
from PerformanceDataAllView pdv with (NOLOCK)
inner join PerformanceCounterView pcv on pdv.performancesourceinternalid = pcv.performancesourceinternalid
inner join BaseManagedEntity bme on pcv.ManagedEntityId = bme.BaseManagedEntityId
where (TimeSampled < GETUTCDATE() AND TimeSampled > DATEADD(MINUTE,-240, GETUTCDATE()))
and objectname ='LogicalDisk' and countername='% Free Space' and instancename='C:'

if object_id('tempdb..#temptable1') IS NOT NULL
DROP TABLE #temptable1
create table #temptable1 (
name nvarchar(250),
cat nvarchar(20),
val nvarchar(2)
)
insert into #temptable1
select name, 'CPU' as 'cat', '1' as 'val'
from #temptable where name not in
(select path from #perfcpudata)

insert into #temptable1
select name, 'Memory' as 'cat', '1' as 'val'
from #temptable where name not in
(select path from #perfmemdata)

insert into #temptable1
select name, 'Disk' as 'cat', '1' as 'val'
from #temptable where name not in
(select path from #perfdiskdata)

if object_id('tempdb..#output') IS NOT NULL
DROP TABLE #output
create table #output (
name nvarchar(250),
cpu nvarchar(2),
memory nvarchar(2),
disk nvarchar(2)
)

insert into #output
select distinct tt.name ,'0','0','0'
from #temptable1 as tt, #healthstate as hs
where tt.name=hs.path collate SQL_Latin1_General_CP1_CI_AS
and hs.ismanaged=1
and hs.healthstate is not null

update #output set cpu=1 where #output.name in (select name from #temptable1 where #temptable1.name=#output.name and #temptable1.cat='CPU')
update #output set memory=1 where #output.name in (select name from #temptable1 where #temptable1.name=#output.name and #temptable1.cat='Memory')
update #output set disk=1 where #output.name in (select name from #temptable1 where #temptable1.name=#output.name and #temptable1.cat='Disk')

select * from #output
-- 1 is bad
-- if everything is healthy then server isn't listed
