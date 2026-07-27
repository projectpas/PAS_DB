
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_GetHistory   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetHistory.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************             
 ** File:   [USP_GetHistory]             
 ** Author:  Amit Ghediya  
 ** Description: This stored procedure is used History data  
 ** Purpose:           
 ** Date:   20/03/2023        
            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    20/03/2023   Amit Ghediya    Created  
	2    20/03/2023   Amit Ghediya    Added DB Standards  
    3	 02/04/2025   Bhargav Saliya  UTC Date Changes 
	3    01/09/2025   Moin Bloch	  Updated Added New Field [Activity]
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
-- EXEC USP_GetHistory 1,1,'',0,'',1,1  
************************************************************************/  
CREATE       PROCEDURE [dbo].[USP_GetHistory]  
 @PageNumber INT,  
 @PageSize INT,  
 @SortColumn VARCHAR(50)=null,  
 @SortOrder INT,  
 @GlobalFilter VARCHAR(50) = null,   
 @HistoryId VARCHAR(20),  
 @RefferenceId BIGINT,  
 @WorkOrderNum VARCHAR(MAX) = null,  
 @PartNumber VARCHAR(MAX) = null,  
 @OldValue VARCHAR(MAX) = null,  
 @NewValue VARCHAR(MAX) = null,  
 @Activity VARCHAR(30) = null,   
 @HistoryText VARCHAR(MAX) = null,  
 @MasterCompanyId INT,  
 @CreatedDate DATETIME=null,  
 @UpdatedDate  DATETIME=null,  
 @CreatedBy VARCHAR(50)=null,  
 @UpdatedBy VARCHAR(50)=null,
 @EmployeeId bigint=null
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
   DECLARE @RecordFrom INT;  

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

    SET @RecordFrom = (@PageNumber-1) * @PageSize;  
      
    IF @SortColumn IS NULL  
    BEGIN  
     SET @SortColumn=UPPER('CreatedDate')  
    END   
    Else  
    BEGIN   
     SET @SortColumn=UPPER(@SortColumn)  
    END  
  
    ;With Result AS(  
    SELECT HS.[HistoryId],  
		 HS.[ModuleId],  
		 --HS.[RefferenceId],  
		 Wo.[WorkOrderNum],  
		 IM.[partnumber],  
		 HS.[OldValue],  
		 HS.[NewValue],  
		 HS.[HistoryText],  
		 HS.[FieldsName],  
		 HS.[CreatedBy],  
		 HS.[CreatedDate],  
		 HS.[UpdatedBy],  
		 CASE WHEN CAST(HS.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(HS.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate],
         HS.[Activity]
	FROM [dbo].[History] HS WITH (NOLOCK)  
		INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON HS.RefferenceId = Wo.WorkOrderId  
		 LEFT JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON HS.SubRefferenceId = WOPN.ID  
		 LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId  
     AND ISNULL(IM.IsNonStock,0) = 0
		  WHERE HS.RefferenceId = @RefferenceId --AND HS.MasterCompanyId = @MasterCompanyId    
    ),  
    FinalResult AS (  
    SELECT HistoryId, ModuleId, WorkOrderNum, partnumber, OldValue, NewValue,Activity,HistoryText, FieldsName  
      ,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy FROM Result  
    WHERE (  
     (@GlobalFilter <>'' AND ((HistoryId LIKE '%' +@GlobalFilter+'%') OR   
       (OldValue LIKE '%' +@GlobalFilter+'%') OR  
       (NewValue LIKE '%' +@GlobalFilter+'%') OR  
	   (Activity LIKE '%' +@GlobalFilter+'%') OR 
       (HistoryText LIKE '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND   
       (ISNULL(@OldValue,'') ='' OR OldValue LIKE  '%'+@OldValue+'%') AND  
       (ISNULL(@NewValue,'') ='' OR NewValue LIKE  '%'+@NewValue+'%') AND  
       (ISNULL(@PartNumber,'') ='' OR partnumber LIKE  '%'+@PartNumber+'%') AND  
       (ISNULL(@WorkOrderNum,'') ='' OR WorkOrderNum LIKE  '%'+@WorkOrderNum+'%') AND  
       (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE  '%'+@UpdatedBy+'%') AND  
       (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)) AND  
	   (ISNULL(@Activity,'') ='' OR Activity LIKE  '%'+@Activity+'%') AND 
       (ISNULL(@HistoryText,'') ='' OR HistoryText LIKE '%'+@HistoryText+'%'))  
       )),  
      ResultCount AS (SELECT COUNT(HistoryId) AS NumberOfItems FROM FinalResult)  
      SELECT HistoryId, ModuleId, WorkOrderNum, partnumber, OldValue, NewValue, Activity, HistoryText, FieldsName,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,  
      NumberOfItems FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 AND @SortColumn='HistoryId')  THEN HistoryId END DESC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='OldValue')  THEN OldValue END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='NewValue')  THEN NewValue END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='PartNumber')  THEN partnumber END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='HistoryText')  THEN HistoryText END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC, 
	 CASE WHEN (@SortOrder=1 AND @SortColumn='ACTIVITY')  THEN Activity END ASC, 
	   
     CASE WHEN (@SortOrder=-1 AND @SortColumn='HistoryId')  THEN HistoryId END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='OldValue')  THEN OldValue END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='NewValue')  THEN NewValue END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN partnumber END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='HistoryText')  THEN HistoryText END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC, 
	 CASE WHEN (@SortOrder=-1 AND @SortColumn='ACTIVITY')  THEN Activity END DESC

     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
    END  
    COMMIT  TRANSACTION  
    END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_GetHistory'   
            , @ProcedureParameters VARCHAR(3000) = '@HistoryId = ''' + CAST(ISNULL(@HistoryId, '') AS VARCHAR(100))  
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