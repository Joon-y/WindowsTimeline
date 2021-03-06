-- Timeline feature's database (ActivitiesCache.db).
-- 
-- Dates/Times in the database are stored in Unixepoch and UTC by default. 
-- Using the 'localtime'  converts it to our TimeZone.
-- 
-- The 'Device ID' may be found in the user’s NTUSER.dat at
-- Software\Microsoft\Windows\CurrentVersion\TaskFlow\DeviceCache\
-- which shows the originating device info.
--
-- The Query uses the SQLite JSON1 extension to parse information from the BLOBs found at 
-- the Activity and ActivityOperation tables. 
--
-- Known folder GUIDs 
-- "https://docs.microsoft.com/en-us/dotnet/framework/winforms/controls/known-folder-guids-for-file-dialog-custom-places"
-- 
-- Duration or totalEngagementTime += e.EndTime.Value.Ticks - e.StartTime.Ticks) 
-- https://docs.microsoft.com/en-us/uwp/api/windows.applicationmodel.useractivities
-- 
-- StartTime: The start time for the UserActivity
-- EndTime: The time when the user stopped engaging with the UserActivity  
-- 
-- Costas Katsavounidis (kacos2000 [at] gmail.com)
-- May 2020


SELECT -- SmartLookup View Query
	ETag as 'Etag', --entity tag (unique)
	case
	    when ActivityType in (2,3,11,12,15) 
			then json_extract(AppId, '$[0].application')	
		when json_extract(AppId, '$[0].application') = '308046B0AF4A39CB' 
			then 'Mozilla Firefox-64bit'
		when json_extract(AppId, '$[0].application') = 'E7CF176E110C211B'
			then 'Mozilla Firefox-32bit'
		when json_extract(AppId, '$[1].application') = '308046B0AF4A39CB' 
			then 'Mozilla Firefox-64bit'
		when json_extract(AppId, '$[1].application') = 'E7CF176E110C211B'
			then 'Mozilla Firefox-32bit'
		when length (json_extract(AppId, '$[0].application')) between 17 and 22 
			then replace(replace(replace(replace(replace(replace(json_extract(AppId, '$[1].application'),
			'{'||'6D809377-6AF0-444B-8957-A3773F02200E'||'}', '*ProgramFiles (x64)' ),  
			'{'||'7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E'||'}', '*ProgramFiles (x32)'),
			'{'||'1AC14E77-02E7-4E5D-B744-2EB1AE5198B7'||'}', '*System' ),
			'{'||'F38BF404-1D43-42F2-9305-67DE0B28FC23'||'}', '*Windows'),
			'{'||'D65231B0-B2F1-4857-A4CE-A8E7C6EA7D27'||'}', '*System32'),
		    'Microsoft.AutoGenerated.{923DD477-5846-686B-A659-0FCCD73851A8}', 'Microsoft.Windows.Shell.RunDialog')  
			else  replace(replace(replace(replace(replace(replace
			(json_extract(AppId, '$[0].application'),
			'{'||'6D809377-6AF0-444B-8957-A3773F02200E'||'}', '*ProgramFiles (x64)'),
			'{'||'7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E'||'}', '*ProgramFiles (x32)'),
			'{'||'1AC14E77-02E7-4E5D-B744-2EB1AE5198B7'||'}', '*System'),
			'{'||'F38BF404-1D43-42F2-9305-67DE0B28FC23'||'}', '*Windows'),
			'{'||'D65231B0-B2F1-4857-A4CE-A8E7C6EA7D27'||'}', '*System32'),
		    'Microsoft.AutoGenerated.{923DD477-5846-686B-A659-0FCCD73851A8}', 'Microsoft.Windows.Shell.RunDialog') 	
	end as 'Application', --Program name with simple Known folder GUIDs conversion
	case 
		when ActivityType = 5 
		then json_extract(Payload, '$.appDisplayName') 
		else ''
	end as 'DisplayName', --Display name of the application from the Payload field 
	case 
		when ActivityType = 5
		then json_extract(Payload, '$.displayText') 
		else '' 
	end as 'DisplayText', --Opened filename or url from the Payload field
	case 
		when ActivityType = 5  
		then json_extract(Payload, '$.description') 
		else ''  
	end as 'Description', --Full path /url of the file/url opened from the Payload field
	case 
		when ActivityType = 5 
		then json_extract(Payload, '$.contenturi') 
		else ''  
	end as 'Content', --Full path /url, Volume Id & Object Id from the Payload field
	trim(AppActivityId,'ECB32AF3-1440-4086-94E3-5311F97F89C4\')  as 'AppActivityId', --Full path /url 
	case 
		when ActivityType in (2,3) then Payload
		when ActivityType = 10 and json_extract(Payload,'$') notnull
		then json_extract(Payload,'$.1[0].content') --Base64 encoded
		when ActivityType = 5 and json_extract(Payload, '$.shellContentDescription') like '%FileShellLink%' 
	    then json_extract(Payload, '$.shellContentDescription.FileShellLink') 
		when ActivityType = 6 
		then case 
			when json_extract(Payload,'$.devicePlatform') notnull 
			then json_extract(Payload, '$.type')||' - ' ||json_extract(Payload,'$.devicePlatform')
			else json_extract(Payload, '$.type')||' - ' ||json_extract(Payload,'$.userTimezone') end
		else ''	
	end as 'Payload/Timezone', --Payload for types 10,11,12,15 (encoded), Payload (FileShellLink) for type 5 and Payload (type & userTimezone) for type 6
	case  
		when ActivityType = 2 then 'Notification('||ActivityType||')' 
		when ActivityType = 3 then 'Mobile Backup('||ActivityType||')' 
		when ActivityType = 5 then 'Open App/File/Page('||ActivityType||')' 
		when ActivityType = 6 then 'App In Use/Focus  ('||ActivityType||')'  
		when ActivityType = 10 then 'Clipboard ('||ActivityType||')'  
		when ActivityType = 16 then 'Copy/Paste('||ActivityType||')' 
		when ActivityType in (11,12,15) then 'System ('||ActivityType||')' 
		else ActivityType 
	end as 'Activity_type',
	"Group" as 'Group', 
	case 
		when json_extract(AppId, '$') like '%afs_crossplatform%' 
		then 'Yes' 
		else 'No' 
		end as 'Synced',	   
	case 
		when json_extract(AppId, '$[0].platform') = 'afs_crossplatform' 
		then json_extract(AppId, '$[1].platform')
		else json_extract(AppId, '$[0].platform') 
	end as 'Platform',
    case ActivityStatus 
		when 1 then 'Active' 
		when 2 then 'Updated' 
		when 3 then 'Deleted' 
		when 4 then 'Ignored' 
	end as 'TileStatus',
	'Yes' as 'UploadQueue',
	'' as 'IsLocalOnly',
	case 
		when ActivityType in (2,3,11,12,15) 
		then ''
		else coalesce(json_extract(Payload, '$.activationUri'),json_extract(Payload, '$.reportingApp')) 
	end as 'App/Uri',
   Priority as 'Priority',	  
   case 
		when ActivityType = 6 and Payload notnull
		then time(json_extract(Payload, '$.activeDurationSeconds'),'unixepoch')
		else '' 
   end as 'ActiveDuration',
   case 
		when ActivityType = 6  and cast((EndTime - StartTime) as integer) > 0 
		then time(cast((EndTime - StartTime) as integer),'unixepoch') 
   end as 'Calculated Duration', --EndTime - StartTime
   datetime(StartTime, 'unixepoch', 'localtime') as 'StartTime', 
   datetime(LastModifiedTime, 'unixepoch', 'localtime') as 'LastModified',
	case 
		when OriginalLastModifiedOnClient > 0 
		then datetime(OriginalLastModifiedOnClient, 'unixepoch', 'localtime') 
		else '' 
	end as 'LastModifiedOnClient',
	case 
		when EndTime > 0 
		then datetime(EndTime, 'unixepoch', 'localtime') 
		else '' 
	end as 'EndTime',
	case 
		when CreatedInCloud > 0 
		then datetime(CreatedInCloud, 'unixepoch', 'localtime') 
		else '' 
	end as 'CreatedInCloud',
    case 
		when ActivityType = 10 
		then cast((ExpirationTime - LastModifiedTime)/3600 as integer)||' hours'
		else cast((ExpirationTime - LastModifiedTime)/86400 as integer)||' days' 
    end as 'ExpiresIn', --ExpirationTime - LastModifiedTime (in hours for activitytype 10 or days for the rest) 
   datetime(ExpirationTime, 'unixepoch', 'localtime') as 'Expiration',
   case 
	when Tag notnull
	then Tag
	else ''
   end as 'Tag',
   MatchId as 'MatchID',
   PlatformDeviceId as 'Device ID', -- Can be used to identify the source device in NTUSER.dat
   PackageIdHash as 'PackageIdHash', --Unique hash of the application (different version of the same application has a different hash)
	 '{' || substr(hex(Id), 1, 8) || '-' || 
			substr(hex(Id), 9, 4) || '-' || 
			substr(hex(Id), 13, 4) || '-' || 
			substr(hex(Id), 17, 4) || '-' || 
			substr(hex(Id), 21, 12) || '}' as 'ID',
	case 
		when hex(ParentActivityId) = '00000000000000000000000000000000'
		then '' else  
		 '{' || substr(hex(ParentActivityId), 1, 8) || '-' || 
				substr(hex(ParentActivityId), 9, 4) || '-' || 
				substr(hex(ParentActivityId), 13, 4) || '-' || 
				substr(hex(ParentActivityId), 17, 4) || '-' || 
				substr(hex(ParentActivityId), 21, 12) || '}' 
	end as 'ParentActivityId', --this ID  can be used to find the source/target of the copy/paste operation
	case 
		when ActivityType = 16 
		then json_extract(Payload, '$.clipboardDataId') 
		else ''
	end as 'ClipboardDataId',		
	case 
		when ActivityType = 10 
		then json_extract(ClipboardPayload,'$[0].content')
		else ''
	end as 'Clipboard Text(Base64)',--Use CyberChef to decode https://gchq.github.io/CyberChef/#recipe=From_Base64('A-Za-z0-9%2B/%3D',true)	
	case 
		when ActivityType = 16 
		then json_extract(Payload, '$.gdprType')
		else ''
	end as 'gdpr type',
   GroupAppActivityId as 'GroupAppActivityId',
   EnterpriseId as 'EnterpriseId',
   case 
		when OriginalPayload notnull
		then OriginalPayload
		else ''
	end as 'OriginalPayload'

from SmartLookup
order by LastModified desc


