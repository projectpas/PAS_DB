
/*************************************************************           
 ** File:   [USP_ClosedLaborRunningTask]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Add/Update WorkOrder Labor Tracking Detail 
 ** Purpose:         
 ** Date:   07/02/2023   
       
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/02/2023   Subhash Saliya	Created   
**  2    05/26/2023   HEMANT SALIYA     Added WO Type ID for Get Seeting based on WO Type

	exec USP_ClosedLaborRunningTask 1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ClosedLaborRunningTask]
 @MasterCompanyId bigint
 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

             DECLARE  @WorkOrderLaborId int= 1;
             --DECLARE  @LaborlogoffHours int= 0;
			 DECLARE  @SubWorkOrderLaborId int= 0;
             
             --SELECT @LaborlogoffHours=isnull(LaborlogoffHours,0) from WorkOrderSettings wos WITH(NOLOCK)  where wos.MasterCompanyId=@MasterCompanyId
             
			 ---------------work order -------------------------
             DECLARE db_cursor CURSOR FOR 
             SELECT WL.WorkOrderLaborId 
             FROM dbo.WorkOrderLabor WL WITH(NOLOCK) 
				 INNER JOIN dbo.WorkOrderLaborHeader WLH WITH(NOLOCK) ON WLH.WorkOrderLaborHeaderId = WL.WorkOrderLaborHeaderId 
				 INNER JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WLH.WorkOrderId 
				 INNER JOIN dbo.WorkOrderLaborTracking WLT WITH(NOLOCK) on WLT.WorkOrderLaborId = WL.WorkOrderLaborId 
				 INNER JOIN dbo.WorkOrderSettings WOS WITH(NOLOCK) ON WL.MasterCompanyId = WOS.MasterCompanyId AND WO.WorkOrderTypeId = WOS.WorkOrderTypeId
			 WHERE ISNULL(WLT.IsCompleted,0) = 0  AND  DATEADD(HOUR, ISNULL(WOS.LaborlogoffHours,0) , WLT.StartTime) < GETUTCDATE() AND WL.MasterCompanyId = @MasterCompanyId
             
             OPEN db_cursor  
             FETCH NEXT FROM db_cursor INTO @WorkOrderLaborId  
             
             WHILE @@FETCH_STATUS = 0  
             BEGIN  
             
              EXEC USP_AddUpdateWorkOrderLaborTrackingDetailScheduler @WorkOrderLaborId,0
             	  
               FETCH NEXT FROM db_cursor INTO @WorkOrderLaborId 
             END 

             CLOSE db_cursor  
             DEALLOCATE db_cursor

			 ---------------sub work order -------------------------

			 DECLARE db_cursorSubWorkOrder CURSOR FOR 
             SELECT WL.SubWorkOrderLaborId 
             FROM dbo.SubWorkOrderLabor WL WITH(NOLOCK) 
				INNER JOIN dbo.SubWorkOrderLaborHeader WLH WITH(NOLOCK) ON WLH.SubWorkOrderLaborHeaderId = WL.SubWorkOrderLaborHeaderId 
				INNER JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WLH.WorkOrderId 
				INNER JOIN dbo.SubWorkOrderLaborTracking WLT WITH(NOLOCK) on WLT.SubWorkOrderLaborId = WL.SubWorkOrderLaborId 
				INNER JOIN dbo.WorkOrderSettings WOS WITH(NOLOCK) ON WL.MasterCompanyId = WOS.MasterCompanyId AND WO.WorkOrderTypeId = WOS.WorkOrderTypeId
             WHERE ISNULL(WLT.IsCompleted,0) = 0  AND  DATEADD(HOUR, ISNULL(WOS.LaborlogoffHours,0) , WLT.StartTime) < GETUTCDATE() AND WL.MasterCompanyId = @MasterCompanyId
             
             OPEN db_cursorSubWorkOrder  
             FETCH NEXT FROM db_cursorSubWorkOrder INTO @SubWorkOrderLaborId  
             
             WHILE @@FETCH_STATUS = 0  
             BEGIN  
				EXEC USP_AddUpdateWorkOrderLaborTrackingDetailManualSubWorkOrderScheduler @SubWorkOrderLaborId,0
				FETCH NEXT FROM db_cursorSubWorkOrder INTO @SubWorkOrderLaborId 
             END 
             
             CLOSE db_cursorSubWorkOrder  
             DEALLOCATE db_cursorSubWorkOrder
END