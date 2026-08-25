/*************************************************************           
 ** File:   [GetWOAssetList]           
 ** Author:   
 ** Description: This stored procedure is used retrieve WO Asset List (TOOLS)
 ** Purpose:         
 ** Date:                
 ** PARAMETERS:         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Unknown        Created
	2    01/29/2025   Moin Bloch     Updated for WorkOrderTask
	3    02/26/2025   AMIT GHEDIYA   Get taskid from wotask.
	4    02/13/2025   Bhargav Saliya UTC Date Changes
	5    20/08/2026   Sumit Kumar    Modified to prepend sequence number to task label only for duplicated tasks (e.g. '1 - TEARDOWN') on Dynamic WOs [PN-17643]
	6    08/18/2026   Abhishek Jirawla Replace AssetAttributeType with YangibleClassId
     
    EXEC GetWOAssetList @PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@GlobalFilter=N'',@WorkFlowWorkOrderId=3305,@Name=NULL,@AssetId=NULL,@Description=NULL,@AssetTypeName=NULL,@Quantity=0,@CheckInDate=NULL,@CheckOutDate=NULL,@CheckInBy=NULL,@CheckOutBy=NULL,@IsDeleted=0,@MasterCompanyId=1,@Status=NULL,@TaskName=NULL,@IsFromWorkFlowNew=NULL
**************************************************************/
CREATE   PROCEDURE [dbo].[GetWOAssetList]  
 @PageSize INT,  
 @PageNumber INT,  
 @SortColumn VARCHAR(50) = NULL,  
 @SortOrder INT,   
 @GlobalFilter VARCHAR(50) = NULL,  
 @WorkFlowWorkOrderId BIGINT = NULL,  
 @Name VARCHAR(50) = NULL,   
 @AssetId VARCHAR(50) = NULL,  
 @Description VARCHAR(50) = NULL,  
 @AssetTypeName VARCHAR(50) = NULL,  
 @Quantity INT = NULL,      
 @CheckInDate DATETIME = NULL,  
 @CheckOutDate  DATETIME = NULL,  
 @CheckInBy  VARCHAR(50) = NULL,  
 @CheckOutBy  VARCHAR(50) = NULL,  
 @IsDeleted BIT= NULL,  
 @MasterCompanyId BIGINT = NULL,  
 @Status  VARCHAR(50) = NULL,  
 @TaskName  VARCHAR(50) = NULL,  
 @IsFromWorkFlowNew  VARCHAR(50) = '',
 @EmployeeId BIGINT = 0
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON    
    BEGIN TRY  

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId;

	-- Declare and populate table variable to get active task counts to detect duplicates 
	DECLARE @WorkOrderId BIGINT = 0, @WorkOrderPartNumberId BIGINT = 0;
	SELECT @WorkOrderId = WorkOrderId, @WorkOrderPartNumberId = WorkOrderPartNoId 
	FROM dbo.WorkOrderWorkFlow WITH(NOLOCK) 
	WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

	DECLARE @DupTasks TABLE (TaskId BIGINT, TaskCount INT);

	INSERT INTO @DupTasks (TaskId, TaskCount)
	SELECT TaskId, COUNT(*) AS TaskCount
	FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
	WHERE WorkOrderId = @WorkOrderId 
	  AND WorkOrderPartNumberId = @WorkOrderPartNumberId
	  AND [IsActive] = 1 AND [IsDeleted] = 0
	GROUP BY TaskId;
  
    DECLARE @RecordFrom INT;  
    DECLARE @IsActive BIT=1  
    DECLARE @Count INT;  
  
    SET @RecordFrom = (@PageNumber-1)*@PageSize;  
    IF @IsDeleted IS NULL  
    BEGIN  
     SET @IsDeleted=0  
    END  
    
    IF @SortColumn IS NULL  
    BEGIN  
     SET @SortColumn=UPPER('CreatedDate')  
    END   
    ELSE  
    BEGIN   
     SET @SortColumn=UPPER(@SortColumn)  
    END  
    
    ;WITH Result AS(  
     SELECT   
       WOA.AssetRecordId,  
       WOA.WorkOrderId,  
       WOA.WorkFlowWorkOrderId AS WorkOrderWfId,  
       AI.InventoryNumber AS InventoryNumber,
	   AI.StklineNumber AS StklineNumber,
	   AI.ControlNumber AS ControlNumber,
       WOA.WorkOrderAssetId,  
       A.AssetId,  
       A.[Description],  
       A.[Name],  
 	   CASE WHEN ISNULL(WO.WorkOrderFormTypeId,0) = 1 
            THEN (CASE WHEN ISNULL(Dup.TaskCount, 0) > 1 AND ISNULL(WOT.[SequenceNumber], '') <> '' 
                       THEN WOT.[SequenceNumber] + ' - ' + WOT.[TaskName] 
                       ELSE WOT.[TaskName] 
                  END) 
            ELSE T.[Description] 
       END TaskName, -- Prepend sequence number to TaskName if duplicate tasks exist   
       --T.TaskId,  
	   CASE WHEN ISNULL(WO.WorkOrderFormTypeId,0) = 1 THEN WOT.[TaskId] ELSE T.[TaskId] END TaskId,
       TY.TangibleClassName AS AssetTypeName,  
       AAT.TangibleClassId,  
       WOA.Quantity,  
       (CIE.FirstName + ' ' + CIE.LastName) AS CheckInEmp,  
       (CIB.FirstName + ' ' + CIB.LastName) AS CheckInBy,  
       (COE.FirstName + ' ' + COE.LastName) AS CheckOutEmp,  
       (COB.FirstName + ' ' + COB.LastName) AS CheckOutBy,  
       WOA.IsActive,  
       WOA.IsDeleted,  
       WOA.CreatedDate,  
       WOA.CreatedBy,  
       WOA.UpdatedDate,  
       WOA.UpdatedBy,  
       WOA.MasterCompanyId,  
       CASE WHEN CAST(COCI.CheckInDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(COCI.CheckInDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CheckInDate,
	   CASE WHEN CAST(COCI.CheckOutDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(COCI.CheckOutDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CheckOutDate,  
       WOA.IsFromWorkFlow,  
       CASE WHEN ISNULL(WOA.IsFromWorkFlow,0) =0 THEN 'No' ELSE 'Yes' END IsFromWorkFlowNew,  
       CASE WHEN  ISNULL(COCI.CheckOutDate,'') !='' THEN 'Checked Out of WO' WHEN ISNULL(COCI.CheckInDate,'') !='' THEN 'Checked In To WO'  ELSE ''  END  AS [Status]  
      FROM dbo.WorkOrderAssets WOA WITH(NOLOCK)  
       JOIN dbo.Asset A WITH(NOLOCK) ON WOA.AssetRecordId = A.AssetRecordId  
       LEFT JOIN dbo.Task T WITH(NOLOCK) ON T.TaskId = WOA.TaskId  
	   LEFT JOIN dbo.WorkOrderTask WOT WITH(NOLOCK) ON WOT.WorkOrderTaskId = WOA.TaskId 
	   LEFT JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WOA.WorkOrderId 
       LEFT JOIN dbo.DeprNonDeprTangibleAssets AAT WITH(NOLOCK) ON A.DeprNonDeprTangibleAssetsId = AAT.DeprNonDeprTangibleAssetsId  	
       LEFT JOIN dbo.TangibleClass TY WITH(NOLOCK) ON AAT.TangibleClassId=TY.TangibleClassId 
       LEFT JOIN dbo.CheckInCheckOutWorkOrderAsset COCI WITH(NOLOCK) ON WOA.WorkOrderAssetId = COCI.WorkOrderAssetId AND COCI.IsQtyCheckOut = 1  
       LEFT JOIN dbo.AssetInventory AI WITH(NOLOCK) ON COCI.AssetInventoryId =  AI.AssetInventoryId  
       LEFT JOIN dbo.Employee CIE WITH(NOLOCK) ON COCI.CheckInEmpId = CIE.EmployeeId  
       LEFT JOIN dbo.Employee CIB WITH(NOLOCK) ON COCI.CheckInById = CIB.EmployeeId  
       LEFT JOIN dbo.Employee COE WITH(NOLOCK) ON COCI.CheckOutEmpId = COE.EmployeeId  
       LEFT JOIN dbo.Employee COB WITH(NOLOCK) ON COCI.CheckOutById = COB.EmployeeId  
      WHERE WOA.IsDeleted = @IsDeleted AND WOA.MasterCompanyId = @MasterCompanyId AND WOA.WorkFlowWorkOrderId = @WorkFlowWorkOrderId  
     ), ResultCount AS(SELECT COUNT(AssetRecordId) AS totalItems FROM Result)  
     SELECT * INTO #TempResult FROM  Result  
     WHERE (  
     (@GlobalFilter <>'' AND (([Name] LIKE '%' +@GlobalFilter+'%' ) OR (AssetId LIKE '%' +@GlobalFilter+'%') OR  
       ([Description] LIKE '%' +@GlobalFilter+'%') OR  
       (AssetTypeName LIKE '%' +@GlobalFilter+'%') OR  
       (CAST(Quantity AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR       
       (CheckOutBy LIKE '%' +@GlobalFilter+'%') OR  
       ([Status] LIKE '%' +@GlobalFilter+'%') OR  
       (TaskName LIKE '%' +@GlobalFilter+'%') OR  
       (IsFromWorkFlow LIKE '%' +@GlobalFilter+'%') OR  
       (CheckInBy LIKE '%' +@GlobalFilter+'%')))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@Name,'') ='' OR [Name] LIKE '%' + @Name+'%') AND   
       (ISNULL(@AssetId,'') ='' OR AssetId LIKE '%' + @AssetId+'%') AND  
       (ISNULL(@Description,'') ='' OR [Description] LIKE '%' + @Description+'%') AND  
       (ISNULL(@AssetTypeName,'') ='' OR AssetTypeName LIKE '%' + @AssetTypeName+'%') AND  
       (ISNULL(@Quantity,'') ='' OR Quantity = @Quantity) AND   
       (ISNULL(@CheckInBy,'') ='' OR CheckInBy LIKE '%' + @CheckInBy+'%') AND  
       (ISNULL(@Status,'') ='' OR [Status] LIKE '%' + @Status+'%') AND  
       (ISNULL(@TaskName,'') ='' OR TaskName LIKE '%' + @TaskName+'%') AND  
       (ISNULL(@CheckOutBy,'') ='' OR CheckOutBy LIKE '%' + @CheckOutBy+'%') AND  
       (ISNULL(@IsFromWorkFlowNew,'') ='' OR IsFromWorkFlowNew LIKE '%' + @IsFromWorkFlowNew+'%' ) AND  
       (ISNULL(@CheckInDate,'') ='' OR CAST(CheckInDate AS DATE)=CAST(@CheckInDate AS DATE)) AND  
       (ISNULL(@CheckOutDate,'') ='' OR CAST(CheckOutDate AS DATE)=CAST(@CheckOutDate AS DATE))))  
  
    SELECT @Count = COUNT(AssetRecordId) FROM #TempResult     
  
    SELECT *, @Count AS NumberOfItems FROM #TempResult  
     ORDER BY       
     CASE WHEN (@SortOrder=1 AND @SortColumn='NAME')  THEN [Name] END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='STATUS')  THEN [Status] END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='ASSETID')  THEN AssetId END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='DESCRIPTION')  THEN [Description] END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='ASSETTYPENAME')  THEN AssetTypeName END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='QUANTITY')  THEN Quantity END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CHECKINBY')  THEN CheckInBy END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CHECKOUTBY')  THEN CheckOutBy END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CHECKINDATE')  THEN CheckInDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CHECKOUTDATE')  THEN CheckOutDate END ASC,       
     CASE WHEN (@SortOrder=1 AND @SortColumn='TASKNAME')  THEN TaskName END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='ISFROMWORKFLOW')  THEN IsFromWorkFlow END ASC,  
  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='NAME')  THEN [Name] END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='STATUS')  THEN [Status] END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='ASSETID')  THEN AssetId END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='DESCRIPTION')  THEN [Description] END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='ASSETTYPENAME')  THEN AssetTypeName END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='QUANTITY')  THEN Quantity END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CHECKINBY')  THEN CheckInBy END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CHECKOUTBY')  THEN CheckOutBy END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CHECKINDATE')  THEN CheckInDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CHECKOUTDATE')  THEN CheckOutDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='TASKNAME')  THEN TaskName END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='ISFROMWORKFLOW')  THEN IsFromWorkFlow END DESC  
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY        
   
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWOAssetList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageSize, '') + ''',  
                @Parameter2 = ' + ISNULL(@PageNumber ,'') +'''  
                @Parameter3 = ' + ISNULL(@SortColumn ,'') +'''  
                @Parameter4 = ' + ISNULL(@GlobalFilter ,'') +'''  
                @Parameter5 = ' + ISNULL(@WorkFlowWorkOrderId ,'') +'''  
                @Parameter6 = ' + ISNULL(@Name ,'') +'''  
                @Parameter7 = ' + ISNULL(@AssetId ,'') +'''  
                @Parameter8 = ' + ISNULL(@Description ,'') +'''  
                @Parameter9 = ' + ISNULL(@AssetTypeName ,'') +'''  
                @Parameter10 = ' + ISNULL(@Quantity ,'') +'''  
                @Parameter11 = ' + ISNULL(CAST(@CheckInDate AS VARCHAR(20)) ,'') +'''  
                @Parameter12 = ' + ISNULL(CAST(@CheckOutDate AS VARCHAR(20)) ,'') +'''  
                @Parameter13 = ' + ISNULL(@CheckInBy ,'') +'''  
                @Parameter14 = ' + ISNULL(@CheckOutBy ,'') +'''  
                @Parameter15 = ' + ISNULL(CAST(@IsDeleted AS VARCHAR(10)) ,'') +'''  
                @Parameter16 = ' + ISNULL(@MasterCompanyId ,'') +'''  
                @Parameter17 = ' + ISNULL(@TaskName ,'') +'''  
                @Parameter18 = ' + ISNULL(CAST(@Status AS VARCHAR(20)) ,'') +''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName   = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN  
  END CATCH  
END