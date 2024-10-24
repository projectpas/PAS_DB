﻿CREATE         VIEW [dbo].[vw_WorkOrderStage]
AS
SELECT WOS.[WorkOrderStageId]
      ,WOS.[Code]
      ,WOS.[Stage]
      ,WOS.[Sequence]
      ,WOS.[Description]
	    ,WOS.[StatusId]
      ,WS.[Description] as 'Status'
      ,WOS.[Memo]
      ,WOS.[MasterCompanyId]
      ,WOS.[CreatedBy]
      ,WOS.[UpdatedBy]
      ,WOS.[CreatedDate]
      ,WOS.[UpdatedDate]
      ,WOS.[IsActive]
      ,WOS.[IsDeleted]
      ,WOS.[StageCode]
      ,WOS.[CodeDescription]
      ,WOS.[IncludeInDashboard]
	  ,WOS.[IncludeInStageReport]
      ,WOS.[ManagerId]
      ,WOS.[IsCustAlerts]
	  ,EMP.FirstName + ' ' + EMP.LastName AS EmployeeName
	  ,WOS.WorkableBacklog
	  ,WOS.IncludeInTAT
	  ,WOS.QuoteDays
	  ,WOS.ShippedDays
  FROM [dbo].[WorkOrderStage] WOS 
  LEFT JOIN [dbo].Employee EMP ON WOS.ManagerId=EMP.EmployeeId
  LEFT JOIN [dbo].[WorkOrderStatus] WS ON WOS.StatusId=WS.Id