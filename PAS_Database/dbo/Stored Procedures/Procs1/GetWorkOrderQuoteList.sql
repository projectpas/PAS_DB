/*************************************************************             
 ** File:   [GetWorkOrderQuoteList]             
 ** Author:    
 ** Description: Get Search Data for WorkOrderQuoteList   
 ** Purpose:           
 ** Date:     
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author             Change Description              
 ** --   --------     -------           --------------------------------            
    1    07/08/2023   Ekta Chandegra     Convert text into uppercase   
	2    06/29/2024   Abhishek Jirawla   Adding flag to return only specified status for pending Approval
	3    18 July 2024   Shrey Chandegara       Modified( use this function @CurrntEmpTimeZoneDesc for date issue.)
	4    30/07/2024   HEMANT SALIYA Serial Number Changes
**************************************************************/   
CREATE   PROCEDURE [dbo].[GetWorkOrderQuoteList]  
 @PageNumber int,  
 @PageSize int,  
 @SortColumn varchar(50) = null,  
 @SortOrder int,  
 @GlobalFilter varchar(50) = '',  
 @quoteNumber varchar(50) = null,  
 @workOrderNum varchar(50) = null,  
 @customerName varchar(50) = null,  
 @customerCode varchar(50) = null,  
 @openDate datetime = null,  
 @promiseDate datetime = null,  
 @estCompletionDate datetime = null,  
 @estShipDate datetime = null,  
 @StatusId int = null,  
 @CreatedDate datetime = null,  
 @UpdatedDate datetime = null,  
 @CreatedBy varchar(50) = null,  
 @UpdatedBy varchar(50) = null,  
 @MasterCompanyId varchar(200) = null,  
 @quoteStatus varchar(200) = null,  
 @VersionNo varchar(20) = null,  
 @PartNumber varchar(20) = null,  
 @PartDescription varchar(20) = null,  
 @SerialNumber varchar(20) = null,  
 @WorkOrderStatus varchar(50) = null,
 @EmployeeId varchar(200)=null,
 @MSModuleID INT=12,
 @WoStage  varchar(200)=null,
 @WoStatus varchar(200)=null,
 @ManufacturerName varchar(200)=null,
 @IsPendingApproval bit = null
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
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId
      
    IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
    BEGIN  
    DROP TABLE #TempResult   
    END  
  
    SET @RecordFrom = (@PageNumber-1)*@PageSize;  
  
    IF (@GlobalFilter IS NULL OR @GlobalFilter = '')  
    BEGIN  
     SET @GlobalFilter= ''  
    END   
  
    IF @SortColumn is null  
    BEGIN  
     Set @SortColumn=Upper('CreatedDate')  
    END   
    Else  
    BEGIN   
     Set @SortColumn=Upper(@SortColumn)  
    END  

    ;WITH Result AS(  
         SELECT  
			woq.WorkOrderQuoteId as WorkOrderQuoteId,  
			wo.WorkOrderId as WorkOrderId,  
			UPPER(woq.QuoteNumber) as quoteNumber,  
			UPPER(wo.WorkOrderNum) 'WorkOrderNum',  
			UPPER(cust.Name) as customerName,  
			UPPER(cust.CustomerCode) 'CustomerCode',  
			UPPER(im.partnumber) as PartNumber,  
			UPPER(im.PartDescription) 'PartDescription',  
			CASE WHEN ISNULL(wopn.RevisedSerialNumber, '') != '' THEN UPPER(wopn.RevisedSerialNumber) ELSE UPPER(STL.SerialNumber) END AS SerialNumber,
			--UPPER(stl.SerialNumber) 'SerialNumber',  
            woq.OpenDate,  
            (SELECT TOP 1 wop.PromisedDate FROM dbo.WorkOrderPartNumber wop WITH(NOLOCK) WHERE  wo.WorkOrderId=wop.WorkOrderId ) as  promisedDate,  
            (SELECT TOP 1 wop.EstimatedShipDate FROM dbo.WorkOrderPartNumber wop WITH(NOLOCK) WHERE  wo.WorkOrderId=wop.WorkOrderId ) as estShipDate,  
            (SELECT TOP 1 wop.EstimatedCompletionDate FROM dbo.WorkOrderPartNumber wop WITH(NOLOCK) WHERE  wo.WorkOrderId=wop.WorkOrderId ) as estCompletionDate,  
            UPPER(wqs.Description) as quoteStatus,  
            woq.QuoteStatusId as quoteStatusId,  
            woq.IsActive,  
            UPPER(woq.CreatedBy) 'CreatedBy',  
            woq.CreatedDate,  
            UPPER(woq.UpdatedBy) 'UpdatedBy',  
            woq.UpdatedDate,  
			woq.IsVersionIncrease,  
			UPPER(woq.VersionNo) 'VersionNo',  
			(CASE WHEN wopp.ApprovalActionId IS NULL THEN UPPER('Pending') ELSE   
					CASE WHEN wopp.ApprovalActionId = 2 THEN UPPER(appsI.Description) ELSE   
					CASE WHEN wopp.ApprovalActionId = 4 THEN UPPER(appsC.Description) ELSE  
					CASE WHEN wopp.ApprovalActionId = 5 THEN UPPER(appsC.Description) ELSE  
					CASE WHEN wopp.ApprovalActionId = 1 THEN CASE WHEN appsI.Description IS NULL THEN UPPER(appsA.Description)   
						ELSE UPPER(appsI.Description)
					END  
                ELSE  
					CASE WHEN wopp.ApprovalActionId = 3 THEN   
					CASE WHEN appsC.Description IS NULL THEN UPPER(appsA.Description) ELSE UPPER(appsC.Description) END ELSE  UPPER('Pending')
					END  
					END  
				  END  
				 END  
				END  
			END) AS WorkOrderStatus,
			UPPER(wos.CodeDescription) as WoStage,
			UPPER(woss.Description) as WoStatus,
			UPPER(im.ManufacturerName) 'ManufacturerName'
		FROM dbo.WorkOrderQuote woq WITH (NOLOCK)  
			JOIN dbo.WorkOrder wo WITH (NOLOCK) on woq.WorkOrderId = wo.WorkOrderId  
			JOIN dbo.WorkOrderPartNumber wopn WITH (NOLOCK) on woq.WorkOrderId = wopn.WorkOrderId
			JOIN dbo.WorkOrderStage wos WITH (NOLOCK) on wos.WorkOrderStageId = wopn.WorkOrderStageId 
			JOIN dbo.WorkOrderStatus woss WITH (NOLOCK) on woss.Id = wo.WorkOrderStatusId 
			JOIN dbo.ItemMaster im WITH (NOLOCK) on wopn.ItemMasterId = im.ItemMasterId  
			LEFT JOIN dbo.Stockline stl WITH (NOLOCK) on wopn.StockLineId = stl.StockLineId  
			JOIN dbo.WorkOrderQuoteStatus wqs WITH (NOLOCK) on woq.QuoteStatusId = wqs.WorkOrderQuoteStatusId  
			JOIN dbo.Customer cust WITH (NOLOCK) on woq.CustomerId = cust.CustomerId 
			LEFT JOIN dbo.WorkOrderApproval wopp WITH (NOLOCK) on wopp.WorkOrderPartNoId = wopn.ID  
			LEFT JOIN dbo.ApprovalStatus appsI WITH (NOLOCK) on wopp.InternalStatusId = appsI.ApprovalStatusId  
			LEFT JOIN dbo.ApprovalStatus appsA WITH (NOLOCK) on 4 = appsA.ApprovalStatusId  
			LEFT JOIN dbo.ApprovalStatus appsC WITH (NOLOCK) on wopp.CustomerStatusId = appsC.ApprovalStatusId  
		WHERE woq.MasterCompanyId = @MasterCompanyId AND isnull(woq.IsDeleted, 0) = 0 AND (((@IsPendingApproval = 0 OR @IsPendingApproval IS NULL) AND (@StatusId = 0 OR woq.QuoteStatusId = @StatusId)) OR (@IsPendingApproval = 1 AND (wopp.ApprovalActionId IN (0, 1, 2, 4) OR wopp.ApprovalActionId IS NULL)))
			 ), ResultCount AS(SELECT COUNT(WorkOrderQuoteId) AS totalItems FROM Result)  
			  SELECT * INTO #TempResult FROM  Result  
			  WHERE (  
			  (@GlobalFilter <>'' AND (  
			  (quoteNumber like '%' +@GlobalFilter+'%') OR        
			  (WorkOrderNum like '%' +@GlobalFilter+'%') OR  
			  (ManufacturerName like '%' +@GlobalFilter+'%') OR 
			  (customerName like '%' +@GlobalFilter+'%') OR  
			  (CustomerCode like '%' +@GlobalFilter+'%') OR  
			  (VersionNo like '%' +@GlobalFilter+'%') OR  
			  (OpenDate like '%' +@GlobalFilter+'%') OR  
			  (promisedDate like '%' +@GlobalFilter+'%') OR  
			  (estShipDate like '%'+@GlobalFilter+'%') OR  
				(estCompletionDate like '%' +@GlobalFilter+'%' ) OR   
			  (quoteStatus like '%' +@GlobalFilter+'%') OR  
			  (quoteStatusId like '%' +@GlobalFilter+'%') OR  
			  (CreatedBy like '%' +@GlobalFilter+'%') OR  
			   (quoteStatus like '%' +@GlobalFilter+'%') OR  
			  (UpdatedBy like '%' +@GlobalFilter+'%') OR  
			  (PartNumber like '%' +@GlobalFilter+'%') OR  
			  (PartDescription like '%' +@GlobalFilter+'%') OR  
			  (SerialNumber like '%' +@GlobalFilter+'%') OR  
			  (WoStage like '%' +@GlobalFilter+'%') OR  
			  (WoStatus like '%' +@GlobalFilter+'%') OR 
			  (WorkOrderStatus like '%' +@GlobalFilter+'%')  
			  )
			  )  
    			OR     
			  (@GlobalFilter='' AND (IsNull(@workOrderNum,'') ='' OR WorkOrderNum like '%' + @workOrderNum+'%') AND  
			  (IsNull(@quoteNumber,'') ='' OR quoteNumber like '%' + @quoteNumber+'%') AND  
			  (IsNull(@customerName,'') ='' OR customerName like '%' + @customerName+'%') AND  
			  (IsNull(@customerCode,'') ='' OR customerCode like '%' + @customerCode+'%') AND 
			  (IsNull(@ManufacturerName,'') ='' OR ManufacturerName like '%' + @ManufacturerName+'%') AND 
			  (IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND  
			  (IsNull(@CreatedBy,'') ='' OR CreatedBy like '%' + @CreatedBy+'%') AND  
			  (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like '%' + @UpdatedBy+'%') AND  
			  (IsNull(@quoteStatus,'') ='' OR quoteStatus like '%' + @quoteStatus+'%') AND  
			  (IsNull(@CreatedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc )AS date)=Cast(@CreatedDate as date)) AND  
			  (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and  
			  (IsNull(@OpenDate,'') ='' OR CAST(OpenDate AS date)=Cast(@OpenDate as date)) AND  
			  (IsNull(@estCompletionDate,'') ='' OR Cast(estCompletionDate as Date)=Cast(@estCompletionDate as date)) AND  
			  (IsNull(@promiseDate,'') ='' OR Cast(promisedDate as Date)=Cast(@promiseDate as date)) AND  
			  (IsNull(@EstShipDate,'') ='' OR Cast(estShipDate as Date)=Cast(@EstShipDate as date)) AND  
			  (IsNull(@PartNumber,'') ='' OR PartNumber like '%' + @PartNumber+'%') AND  
			  (IsNull(@PartDescription,'') ='' OR PartDescription like '%' + @PartDescription+'%') AND  
			  (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND  
			  (IsNull(@WoStage,'') ='' OR WoStage like '%' + @WoStage+'%') AND  
			  (IsNull(@WoStatus,'') ='' OR WoStatus like '%' + @WoStatus+'%') AND 
			  (IsNull(@WorkOrderStatus,'') ='' OR WorkOrderStatus like '%' + @WorkOrderStatus+'%')  
			  ))  
  
			  SELECT @Count = COUNT(WorkOrderQuoteId) from #TempResult     
  
			  SELECT *, @Count As NumberOfItems FROM #TempResult  
			  ORDER BY    
			  CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='QUOTENUMBER')  THEN quoteNumber END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='VERSIONNO')  THEN VersionNo END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='OPENDATE')  THEN OpenDate END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='ESTSHIPDATE')  THEN estShipDate END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='QUOTESTATUSID')  THEN quoteStatusId END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='QUOTESTATUS')  THEN quoteStatus END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='ESTCOMPLETIONDATE')  THEN estCompletionDate END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='SERIALNUMBER')  THEN SerialNumber END ASC,  
			  CASE WHEN (@SortOrder=1 and @SortColumn='WORKORDERSTATUS')  THEN WorkOrderStatus END ASC,
			  CASE WHEN (@SortOrder=1 and @SortColumn='WOSTAGE')  THEN WoStage END ASC, 
			  CASE WHEN (@SortOrder=1 and @SortColumn='WOSTATUS')  THEN WoStatus END ASC, 
			  CASE WHEN (@SortOrder=1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC, 
  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTENUMBER')  THEN quoteNumber END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='VERSIONNO')  THEN VersionNo END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERNUM')  THEN WorkOrderNum END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='OPENDATE')  THEN OpenDate END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='PROMISEDATE')  THEN PromisedDate END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='ESTSHIPDATE')  THEN estShipDate END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='ESTCOMPLETIONDATE')  THEN estCompletionDate END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTESTATUSID')  THEN quoteStatusId END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTESTATUS')  THEN quoteStatus END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,  
			  CASE WHEN (@SortOrder=-1 and @SortColumn='SERIALNUMBER')  THEN SerialNumber END DESC, 
			  CASE WHEN (@SortOrder=-1 and @SortColumn='WOSTAGE')  THEN WoStage END DESC, 
			  CASE WHEN (@SortOrder=-1 and @SortColumn='WOSTATUS')  THEN WoStatus END DESC, 
			  CASE WHEN (@SortOrder=-1 and @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC, 
			  CASE WHEN (@SortOrder=-1 and @SortColumn='WORKORDERSTATUS')  THEN WorkOrderStatus END DESC  
  
		  OFFSET @RecordFrom ROWS   
		  FETCH NEXT @PageSize ROWS ONLY  
  
      IF OBJECT_ID(N'tempdb..#TempResult') IS NOT NULL  
      BEGIN  
      DROP TABLE #TempResult   
      END  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQuoteList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@quoteNumber, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH   
END