/*************************************************************           
 ** File:   [GetWorkOrderLaborTrackingList]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Get WorkOrder Labor Tracking Detail 
 ** Purpose:         
 ** Date:   10/02/2023   
       
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    10/02/2023   Subhash Saliya	Created     

	--[dbo].[GetWorkOrderLaborTrackingList] 1,10,null,1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,2,0,1
**************************************************************/

Create         PROCEDURE [dbo].[GetSubWorkOrderLaborTrackingList]  
 -- Add the parameters for the stored procedure here  
 @PageNumber int=null,  
 @PageSize int=null,  
 @SortColumn varchar(50)=null,  
 @SortOrder int,  
 @TaskStatus  varchar(50)='',  
 @GlobalFilter varchar(50) = '',  
 @WorkOrderNum varchar(50)=null,  
 @TaskName varchar(255)=null,  
 @PartNumber varchar(50)=null,  
 @PartDescription varchar(50)=null,   
 @StartTime datetime=null,  
 @EndTime datetime=null,
 @StatusChangedDate datetime=null, 
 @TotalHours varchar(50)=null,  
 @TotalMinutes varchar(50)=null,  
 @CreatedDate datetime=null,  
 @UpdatedDate  datetime=null,  
 @CreatedBy  varchar(50)=null,  
 @UpdatedBy  varchar(50)=null,  
 @MasterCompanyId int=null,  
 @EmployeeId bigint=null,   
 @TaskId bigint=null,
 @WorkFlowWOId bigint=null,
 @IsFromEmployee bit =0,
 @WorkOrderLaborId bigint=null,
 @TaskStatusGr varchar(50)=null 
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN   
    DECLARE @RecordFrom int;  
    DECLARE @IsActive bit=1  
    DECLARE @Count Int;  
    DECLARE @WorkOrderStatusId int;    
  
    IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
    BEGIN  
    DROP TABLE #TempResult   
    END  
	    IF OBJECT_ID(N'tempdb..#TempResultWOF') IS NOT NULL  
    BEGIN  
    DROP TABLE #TempResultWOF   
    END  
    SET @RecordFrom = (@PageNumber-1)*@PageSize;  

    IF (@GlobalFilter IS NULL OR @GlobalFilter = '')  
    BEGIN  
     Set @GlobalFilter= ''  
    END   
  
    IF @SortColumn is null  
    BEGIN  
     Set @SortColumn=Upper('CreatedDate')  
    END   
    Else  
    BEGIN   
     Set @SortColumn=Upper(@SortColumn)  
    END  
  
	  IF Upper(@TaskStatus) = 'ALL'   
      BEGIN  
       SET @TaskStatus = ''  
      END
	  ELSE IF  Upper(@TaskStatus) = 'OPEN' 
	  BEGIN
	    SET @TaskStatus = 'COMPLETED'  
	  END
    IF(@IsFromEmployee = 1)
	BEGIN
	;WITH Result(WorkOrderLaborTrackingId,WorkOrderLaborId,WorkOrderNum,SubWorkOrderNo,WorkOrderId,PartNumber,PartDescription,ManufacturerName,OpenDate,StartTime,EndTime,TotalHours,TotalMinutes,IsCompleted,CreatedDate
	,UpdatedDate,CreatedBy,UpdatedBy,IsActive,IsDeleted,EmployeeName,TaskStatusGr,TaskStatusId,StatusChangedDate,TaskName)
	AS (
	SELECT   
		WOT.SubWorkOrderLaborTrackingId as WorkOrderLaborTrackingId,
		WOT.SubWorkOrderLaborId as WorkOrderLaborId,
        SWO.SubWorkOrderNo as WorkOrderNum, 
		SWO.SubWorkOrderNo,
        WO.WorkOrderId,  
        IM.partnumber AS PartNumber,  
        IM.PartDescription AS PartDescription,  
		IM.ManufacturerName ManufacturerName,
        WO.OpenDate,  
        WOT.StartTime,  
        WOT.EndTime,
		format(WOT.TotalHours,'00')TotalHours, 
		format(WOT.TotalMinutes,'00')TotalMinutes,
		WOT.IsCompleted,
        WO.CreatedDate,  
        WO.UpdatedDate,  
        WO.CreatedBy,  
        WO.UpdatedBy,  
        WO.IsActive,  
        WO.IsDeleted,  
        EMP.FirstName + ' ' + EMP.LastName AS EmployeeName
		,TS.[Description] TaskStatusGr
		,TS.TaskStatusId
		,WOL.StatusChangedDate StatusChangedDate
		,T.[Description] TaskName
       FROM SubWorkOrderLaborTracking WOT WITH(NOLOCK)  
	    JOIN dbo.Task T WITH(NOLOCK) on WOT.TaskId = T.TaskId 
	    JOIN dbo.SubWorkOrderLabor WOL WITH(NOLOCK) on WOT.SubWorkOrderLaborId = WOL.SubWorkOrderLaborId
		JOIN dbo.SubWorkOrderLaborHeader LH WITH(NOLOCK) on WOL.SubWorkOrderLaborHeaderId = LH.SubWorkOrderLaborHeaderId
		JOIN dbo.WorkOrder WO WITH(NOLOCK) on LH.WorkOrderId = WO.WorkOrderId
		JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) on LH.SubWorkOrderId = SWO.SubWorkOrderId
		INNER JOIN dbo.SubWorkOrderPartNumber WPN WITH(NOLOCK) ON LH.SubWOPartNoId = WPN.SubWOPartNoId  
		JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
		LEFT JOIN dbo.TaskStatus TS WITH(NOLOCK) ON WOL.TaskStatusId = TS.TaskStatusId AND Ts.MasterCompanyId = @MasterCompanyId
        LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WOT.EmployeeId 		
		
       WHERE (WOT.MasterCompanyId = @MasterCompanyId  AND WOT.EmployeeId = @EmployeeId AND (@TaskName = '' OR Ts.[Description] != @TaskStatus)) 
	   
	   UNION ALL

	   SELECT   
		0 AS WorkOrderLaborTrackingId,
		WOL.SubWorkOrderLaborId as WorkOrderLaborId,
        SWO.SubWorkOrderNo as WorkOrderNum, 
		SWO.SubWorkOrderNo,
        WO.WorkOrderId,  
        IM.partnumber AS PartNumber,  
        IM.PartDescription AS PartDescription, 
		IM.ManufacturerName ManufacturerName,
        WO.OpenDate,  
        NULL AS StartTime,  
        NULL AS EndTime,
	    format(FLOOR(WOL.Adjustments),'00')TotalHours, 
		format(convert(int,(WOL.Adjustments - FLOOR(WOL.Adjustments))* 100),'00')TotalMinutes,
		0 AS IsCompleted,
        WO.CreatedDate,  
        WO.UpdatedDate,  
        WO.CreatedBy,  
        WO.UpdatedBy,  
        WO.IsActive,  
        WO.IsDeleted,  
        EMP.FirstName + ' ' + EMP.LastName AS EmployeeName
		,TS.[Description] TaskStatusGr
		,TS.TaskStatusId
		,WOL.StatusChangedDate StatusChangedDate
		,T.[Description] TaskName
       FROM  dbo.SubWorkOrderLabor WOL WITH(NOLOCK)
	    JOIN dbo.Task T WITH(NOLOCK) on WOL.TaskId = T.TaskId 
		JOIN dbo.SubWorkOrderLaborHeader LH WITH(NOLOCK) on WOL.SubWorkOrderLaborHeaderId = LH.SubWorkOrderLaborHeaderId
		JOIN dbo.WorkOrder WO WITH(NOLOCK) on LH.WorkOrderId = WO.WorkOrderId
		JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) on LH.SubWorkOrderId = SWO.SubWorkOrderId
		INNER JOIN dbo.SubWorkOrderPartNumber WPN WITH(NOLOCK) ON LH.SubWOPartNoId = WPN.SubWOPartNoId  
		JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
		LEFT JOIN dbo.TaskStatus TS WITH(NOLOCK) ON WOL.TaskStatusId = TS.TaskStatusId AND Ts.MasterCompanyId = @MasterCompanyId
        LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WOL.EmployeeId 
		
		WHERE (WOL.MasterCompanyId = @MasterCompanyId  AND WOL.EmployeeId = @EmployeeId AND (@TaskName = '' OR Ts.[Description] != @TaskStatus)) AND WOL.Adjustments >0
	),ResultCount AS(Select COUNT(WorkOrderId) AS totalItems FROM Result)	

		Select * INTO #TempResult from  Result  
        WHERE (  
        (@GlobalFilter <>'' AND (  
        (@WorkOrderNum like '%' +@GlobalFilter+'%') OR  
		(@TaskName like '%' +@GlobalFilter+'%') OR 
		(@TaskStatusGr like '%' +@GlobalFilter+'%') OR  
        (@PartNumber like '%' +@GlobalFilter+'%') OR  
        (@PartDescription like '%' +@GlobalFilter+'%') OR  
        (@StartTime like '%' +@GlobalFilter+'%') OR  
        (@EndTime like '%' +@GlobalFilter+'%') OR  
        (@StatusChangedDate like '%' +@GlobalFilter+'%') OR    
        (@TotalHours like '%' +@GlobalFilter+'%' ) OR   
        (@TotalMinutes like '%' +@GlobalFilter+'%') OR  
        (CreatedBy like '%' +@GlobalFilter+'%') OR  
        (UpdatedBy like '%' +@GlobalFilter+'%') 
        ))  
        OR     
        (@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND  
		(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND  
        (IsNull(@TaskName,'') ='' OR TaskName like '%' + @TaskName+'%') AND 
		(IsNull(@TaskStatusGr,'') ='' OR TaskStatusGr like '%' + @TaskStatusGr+'%') AND 
        (IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
        (IsNull(@StartTime,'') ='' OR Cast(StartTime as Date)=Cast(@StartTime as Date)) AND  
        (IsNull(@EndTime,'') ='' OR  Cast(EndTime as Date) = Cast(@EndTime as Date)) AND  
        (IsNull(@StatusChangedDate,'') ='' OR  Cast(StatusChangedDate as Date) =Cast(@StatusChangedDate as Date)) AND  
        (IsNull(@TotalHours,'') ='' OR TotalHours like '%' + @TotalHours+'%') AND  
        (IsNull(@TotalMinutes,'') ='' OR TotalMinutes like '%' + @TotalMinutes+'%') AND
        (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
        (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND  
        (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND  
        (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date))
        ))  
  
       SELECT @Count = COUNT(WorkOrderLaborTrackingId) from #TempResult     
  
       SELECT *, @Count As NumberOfItems FROM #TempResult  
        ORDER BY    
        CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='StartTime')  THEN StartTime END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='EndTime')  THEN EndTime END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='StatusChangedDate')  THEN StatusChangedDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TotalHours')  THEN TotalHours END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TotalMinutes')  THEN TotalMinutes END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TaskName')  THEN TaskName END ASC,
		CASE WHEN (@SortOrder=1 and @SortColumn='TaskStatusGr')  THEN TaskStatusGr END ASC, 
  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END DESC,  
           CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='StartTime')  THEN StartTime END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='EndTime')  THEN EndTime END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='StatusChangedDate')  THEN StatusChangedDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='TotalHours')  THEN TotalHours END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='TotalMinutes')  THEN TotalMinutes END DESC,
		 CASE WHEN (@SortOrder=-1 and @SortColumn='TaskStatusGr')  THEN TaskStatusGr END DESC, 
        CASE WHEN (@SortOrder=-1 and @SortColumn='TaskName')  THEN TaskName END DESC
        
  
        OFFSET @RecordFrom ROWS   
        FETCH NEXT @PageSize ROWS ONLY  
	END
	ELSE
	BEGIN
	  ;WITH Result AS(  
       SELECT DISTINCT  
		WOT.SubWorkOrderLaborTrackingId as WorkOrderLaborTrackingId,
		WOT.SubWorkOrderLaborId as WorkOrderLaborId,
        SWO.SubWorkOrderNo as WorkOrderNum, 
		SWO.SubWorkOrderNo,
        WO.WorkOrderId,  
        IM.partnumber AS PartNumber,  
        IM.PartDescription AS PartDescription,  
		IM.ManufacturerName ManufacturerName,
        WO.OpenDate,  
        WOT.StartTime,  
        WOT.EndTime,
		format(WOT.TotalHours,'00')TotalHours, 
		format(WOT.TotalMinutes,'00')TotalMinutes,
		WOT.IsCompleted,
        WO.CreatedDate,  
        WO.UpdatedDate,  
        WO.CreatedBy,  
        WO.UpdatedBy,  
        WO.IsActive,  
        WO.IsDeleted,  
        EMP.FirstName + ' ' + EMP.LastName AS EmployeeName
		,TS.[Description] TaskStatusGr
		,TS.TaskStatusId
		,WOL.StatusChangedDate StatusChangedDate
		,T.[Description] TaskName
       FROM SubWorkOrderLaborTracking WOT WITH(NOLOCK)  
	    JOIN dbo.Task T WITH(NOLOCK) on WOT.TaskId = T.TaskId 
	    JOIN dbo.SubWorkOrderLabor WOL WITH(NOLOCK) on WOT.SubWorkOrderLaborId = WOL.SubWorkOrderLaborId
		JOIN dbo.SubWorkOrderLaborHeader LH WITH(NOLOCK) on WOL.SubWorkOrderLaborHeaderId = LH.SubWorkOrderLaborHeaderId
		JOIN dbo.WorkOrder WO WITH(NOLOCK) on LH.WorkOrderId = WO.WorkOrderId
		JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) on LH.SubWorkOrderId = SWO.SubWorkOrderId
		INNER JOIN dbo.SubWorkOrderPartNumber WPN WITH(NOLOCK) ON LH.SubWOPartNoId = WPN.SubWOPartNoId  
		JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
		LEFT JOIN dbo.TaskStatus TS WITH(NOLOCK) ON WOL.TaskStatusId = TS.TaskStatusId AND Ts.MasterCompanyId = @MasterCompanyId
        LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WOT.EmployeeId 		
		
       WHERE (WOT.MasterCompanyId = @MasterCompanyId AND WOL.SubWorkOrderLaborId = @WorkOrderLaborId  AND WOT.TaskId = @TaskId AND Lh.SubWorkOrderLaborHeaderId = @WorkFlowWOId AND (@TaskName = '' OR Ts.[Description] != @TaskStatus)) 
	   
	   UNION ALL

	    SELECT DISTINCT  
		0 AS WorkOrderLaborTrackingId,
		WOL.SubWorkOrderLaborId as WorkOrderLaborId,
        SWO.SubWorkOrderNo as WorkOrderNum, 
		SWO.SubWorkOrderNo,
        WO.WorkOrderId,  
        IM.partnumber AS PartNumber,  
        IM.PartDescription AS PartDescription,  
		IM.ManufacturerName ManufacturerName,
        WO.OpenDate,  
        NULL AS StartTime,  
        NULL AS EndTime,
		format(FLOOR(WOL.Adjustments),'00')TotalHours, 
		format(convert(int,(WOL.Adjustments - FLOOR(WOL.Adjustments))* 100),'00')TotalMinutes,
		0 AS IsCompleted,
        WO.CreatedDate,  
        WO.UpdatedDate,  
        WO.CreatedBy,  
        WO.UpdatedBy,  
        WO.IsActive,  
        WO.IsDeleted,  
        EMP.FirstName + ' ' + EMP.LastName AS EmployeeName
		,TS.[Description] TaskStatusGr
		,TS.TaskStatusId
		,WOL.StatusChangedDate StatusChangedDate
		,T.[Description] TaskName
       FROM  dbo.SubWorkOrderLabor WOL WITH(NOLOCK)
	    JOIN dbo.Task T WITH(NOLOCK) on WOL.TaskId = T.TaskId 
		JOIN dbo.SubWorkOrderLaborHeader LH WITH(NOLOCK) on WOL.SubWorkOrderLaborHeaderId = LH.SubWorkOrderLaborHeaderId
		JOIN dbo.WorkOrder WO WITH(NOLOCK) on LH.WorkOrderId = WO.WorkOrderId
		JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) on LH.SubWorkOrderId = SWO.SubWorkOrderId
		INNER JOIN dbo.SubWorkOrderPartNumber WPN WITH(NOLOCK) ON LH.SubWOPartNoId = WPN.SubWOPartNoId  
		JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId  
		LEFT JOIN dbo.TaskStatus TS WITH(NOLOCK) ON WOL.TaskStatusId = TS.TaskStatusId AND Ts.MasterCompanyId = @MasterCompanyId
        LEFT JOIN dbo.Employee EMP WITH(NOLOCK) ON EMP.EmployeeId = WOL.EmployeeId 		
		
       WHERE (WOL.MasterCompanyId = @MasterCompanyId AND WOL.SubWorkOrderLaborId = @WorkOrderLaborId  AND WOL.TaskId = @TaskId AND Lh.SubWorkOrderLaborHeaderId = @WorkFlowWOId AND (@TaskName = '' OR Ts.[Description] != @TaskStatus)) AND WOL.Adjustments >0
	   

	   ),ResultCount AS(Select COUNT(WorkOrderId) AS totalItems FROM Result)		
        Select * INTO #TempResultWOF from  Result  
        WHERE (  
        (@GlobalFilter <>'' AND (  
        (@WorkOrderNum like '%' +@GlobalFilter+'%') OR  
		(@TaskName like '%' +@GlobalFilter+'%') OR 
		(@TaskStatusGr like '%' +@GlobalFilter+'%') OR  
        (@PartNumber like '%' +@GlobalFilter+'%') OR  
        (@PartDescription like '%' +@GlobalFilter+'%') OR  
        (@StartTime like '%' +@GlobalFilter+'%') OR  
        (@EndTime like '%' +@GlobalFilter+'%') OR  
        (@StatusChangedDate like '%' +@GlobalFilter+'%') OR    
        (@TotalHours like '%' +@GlobalFilter+'%' ) OR   
        (@TotalMinutes like '%' +@GlobalFilter+'%') OR  
        (CreatedBy like '%' +@GlobalFilter+'%') OR  
        (UpdatedBy like '%' +@GlobalFilter+'%') 
        ))  
        OR     
        (@GlobalFilter='' AND (IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like '%' + @WorkOrderNum+'%') AND  
		(IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND  
        (IsNull(@TaskName,'') ='' OR TaskName like '%' + @TaskName+'%') AND 
	    (IsNull(@TaskStatusGr,'') ='' OR TaskStatusGr like '%' + @TaskStatusGr+'%') AND 
        (IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND
        (IsNull(@StartTime,'') ='' OR Cast(StartTime as Date)=Cast(@StartTime as Date)) AND  
        (IsNull(@EndTime,'') ='' OR  Cast(EndTime as Date) = Cast(@EndTime as Date)) AND  
        (IsNull(@StatusChangedDate,'') ='' OR  Cast(StatusChangedDate as Date) =Cast(@StatusChangedDate as Date)) AND  
        (IsNull(@TotalHours,'') ='' OR TotalHours like '%' + @TotalHours+'%') AND  
        (IsNull(@TotalMinutes,'') ='' OR TotalMinutes like '%' + @TotalMinutes+'%') AND
        (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
        (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND  
        (IsNull(@CreatedDate,'') ='' OR Cast(CreatedDate as Date)=Cast(@CreatedDate as date)) AND  
        (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date))
        ))  
  
       SELECT @Count = COUNT(WorkOrderLaborTrackingId) from #TempResultWOF   
  
       SELECT *, @Count As NumberOfItems FROM #TempResultWOF  
        ORDER BY    
        CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN PartNumber END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN PartDescription END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='StartTime')  THEN StartTime END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='EndTime')  THEN EndTime END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='StatusChangedDate')  THEN StatusChangedDate END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TotalHours')  THEN TotalHours END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TotalMinutes')  THEN TotalMinutes END ASC,  
        CASE WHEN (@SortOrder=1 and @SortColumn='TaskName')  THEN TaskName END ASC,
		CASE WHEN (@SortOrder=1 and @SortColumn='TaskStatusGr')  THEN TaskStatusGr END ASC,
  
        CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN PartNumber END DESC,  
           CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN PartDescription END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='StartTime')  THEN StartTime END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='EndTime')  THEN EndTime END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='StatusChangedDate')  THEN StatusChangedDate END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='TotalHours')  THEN TotalHours END DESC,  
        CASE WHEN (@SortOrder=-1 and @SortColumn='TotalMinutes')  THEN TotalMinutes END DESC,
		CASE WHEN (@SortOrder=-1 and @SortColumn='TaskStatusGr')  THEN TaskStatusGr END DESC,
        CASE WHEN (@SortOrder=-1 and @SortColumn='TaskName')  THEN TaskName END DESC
        
  
        OFFSET @RecordFrom ROWS   
        FETCH NEXT @PageSize ROWS ONLY  
	END
    IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
    BEGIN  
    DROP TABLE #TempResult   
    END  
      IF OBJECT_ID(N'tempdb..#TempResultWOF') IS NOT NULL  
    BEGIN  
    DROP TABLE #TempResultWOF   
    END  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderLaborTrackingList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, 0) + ''
			  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END