<!--- default variables --->
<cfparam name="dsn" default="your datasource here">
<cfparam name="mail_to" default="your email address here">

<!--- step by step create an printable report of morning/last nights' activities --->

<!--- step one Scheduled Tasks Last Night --->

<!--- Failed Jobs Report --->
<cfquery name="production_failed_reports" datasource="#dsn#">
SELECT a.name
FROM msdb.dbo.sysjobs A, msdb.dbo.sysjobservers B
WHERE A.job_id = B.job_id
AND B.last_run_outcome = 0
</cfquery>

<!--- Disabled Jobs Report --->
<cfquery name="production_disabled_reports" datasource="#dsn#">
SELECT name
FROM msdb.dbo.sysjobs
WHERE enabled = 0
ORDER BY name
</cfquery>

<!--- step two Backup Status Report --->
<cfquery name="production_backup_reports" datasource="#dsn#">
select b.name as database_name, isnull(str(abs(datediff(day, getdate(), max(backup_finish_date)))), 'never') as dayssincelastbackup, isnull(convert(char(10), max(backup_finish_date), 101), 'never') as lastbackupdate
from master.dbo.sysdatabases b left outer join msdb.dbo.backupset a on a.database_name = b.name and a.type = 'd'
group by b.name
order by b.name
</cfquery>

<!--- step three Hard Drive Status Report --->
<cfquery name="production_harddrive_reports" datasource="#dsn#">
EXEC master..xp_fixeddrives
</cfquery>


<cfquery name="production_status_reports" datasource="#dsn#">
EXEC master..sp_helpdb
</cfquery>

<cfquery name="production_slowest_queries" datasource="#dsn#">
select top 10
    qs.execution_count,
    st.dbid,
    DB_NAME(st.dbid) as DbName,
    st.text
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_sql_text(sql_handle) st
order by execution_count desc
</cfquery>

<!--- now put into cfmail tag --->
<cfmail to="#mail_to#" subject="SQL DBA Report" from="#mail_to#" type=html>
<font face="verdana, arial, helvetica, sans-serif" size=+1>SQL DBA Report for #dateformat(now(),'dddd mmm, d, yyyy')# #timeformat(now(),'hh:mm:ss tt')#</font>
<br><Br>
<font face="verdana, arial, helvetica, sans-serif" size=-1><b>Failed Jobs Report:</b></font>#chr(10)#<br><br>
<Cfif production_failed_reports.recordcount gt 0>
On Production:#chr(10)#<br>
<cfloop query="production_failed_reports">
#production_failed_reports.name##chr(10)#<br>
</cfloop>
</cfif>
<br>
<font face="verdana, arial, helvetica, sans-serif" size=-1><b>Disabled Jobs Report:</b></font>#chr(10)#<br><br>
<Cfif production_disabled_reports.recordcount gt 0>
On Production:#chr(10)#<br>
<cfloop query="production_disabled_reports">
#production_disabled_reports.name##chr(10)#<br>
</cfloop>
</cfif>
<font face="verdana, arial, helvetica, sans-serif" size=-1><b>Backup Reports:</b></font>#chr(10)#<br><br>
<Cfif (production_backup_reports.recordcount gt 0)>
<table width=100% cellspacing=0 cellpadding=2 border=1 bordercolor=0D4D77>
<tr bgcolor=BEC8D8>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>Server</font></td>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>Database Name</font></td>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>Days Since Last Backed Up</font></td>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>Last BackUp Date</font></td>
</tr>
</cfif>
<Cfif production_backup_reports.recordcount gt 0>
<cfloop query="production_backup_reports">
<tr>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>Production</font></td>
<td align=left><font face="verdana, arial, helvetica, sans-serif" size=-1> #production_backup_reports.database_name#</font></td>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>#production_backup_reports.dayssincelastbackup#</font></td>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>#production_backup_reports.lastbackupdate#</font></td>
</tr>
</cfloop>
</cfif>
<Cfif (production_backup_reports.recordcount gt 0)>
</table>
</cfif>
<br>
<font face="verdana, arial, helvetica, sans-serif" size=-1><b>Database Size Report:</b></font>#chr(10)#<br><br>
<Cfif (production_status_reports.recordcount gt 0)>
<table width=100% cellspacing=0 cellpadding=2 border=1 bordercolor=0D4D77>
<tr bgcolor=BEC8D8>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>Server</font></td>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>Database Name</font></td>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>Hard Drive Space Usage</font></td>
</tr>
</cfif>
<cfif production_status_reports.recordcount gt 0>
<cfloop query="production_status_reports">
<tr>
<td align=center><font face="verdana, arial, helvetica, sans-serif" size=-1>Production</font></td>
<td align=left><font face="verdana, arial, helvetica, sans-serif" size=-1> #production_status_reports.name#</font></td>
<td align=left><font face="verdana, arial, helvetica, sans-serif" size=-1> #production_status_reports.db_size#</font></td>
</tr>
</cfloop>
</cfif>
<Cfif (production_status_reports.recordcount gt 0)>
    </table>
</cfif>
<br>
</cfmail>
