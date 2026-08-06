/*************************************************************             
 ** File:   [USP_GetKitPartHistory]             
 ** Author:  Shrey Chandegara  
 ** Description: This stored procedure is used History data  
 ** Purpose:           
 ** Date:   28-02-2024        
            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    28-02-2024   Shrey Chandegara    Created 
	2    05/02/2025   Ayushi Patel		  converted the date into utc (created , updated) , Added a case to get timeZone
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
       
-- EXEC USP_GetKitPartHistory 1,1,'',0,'',1,1  
************************************************************************/  
CREATE       PROCEDURE [dbo].[USP_GetKitPartHistory]  
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
 @HistoryText VARCHAR(MAX) = null,  
 @MasterCompanyId INT,  
 @CreatedDate DATETIME=null,  
 @UpdatedDate  DATETIME=null,  
 @CreatedBy VARCHAR(50)=null,  
 @UpdatedBy VARCHAR(50)=null,
 @IsFromKitHeader BIT=0,
 @EmployeeId bigint
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
   DECLARE @RecordFrom INT;  
    SET @RecordFrom = (@PageNumber-1) * @PageSize;  
   DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
				SELECT 
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

    IF @SortColumn is null  
    BEGIN  
     SET @SortColumn=Upper('CreatedDate')  
    END   
    Else  
    BEGIN   
     SET @SortColumn=Upper(@SortColumn)  
    END  
  
    IF(@IsFromKitHeader = 0)
		BEGIN
				;With Result AS(  
				SELECT HS.[HistoryId],  
				 HS.[ModuleId],  
				 --HS.[RefferenceId],  
				-- Wo.[WorkOrderNum],  
				   IM.[partnumber],  
				 HS.[OldValue],  
				 HS.[NewValue],  
				 HS.[HistoryText],  
				 HS.[FieldsName],  
				 HS.[CreatedBy],  
				 --HS.[CreatedDate],
				 case when CAST(HS.[CreatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(HS.[CreatedDate], @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate,
				 HS.[UpdatedBy],  
				 --HS.[UpdatedDate]
				 case when CAST(HS.[UpdatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(HS.[UpdatedDate], @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate
				FROM DBO.[History] HS WITH (NOLOCK)  
				INNER JOIN DBO.[KitItemMasterMapping] WO WITH (NOLOCK) ON HS.RefferenceId = Wo.KitItemMasterMappingId  
				LEFT JOIN DBO.[ItemMaster] IM WITH (NOLOCK) ON HS.SubRefferenceId = IM.ItemMasterId  
				 AND ISNULL(IM.IsNonStock,0) = 0
				WHERE HS.RefferenceId = @RefferenceId --AND HS.MasterCompanyId = @MasterCompanyId    
				),  
				FinalResult AS (  
				SELECT HistoryId, ModuleId, partnumber, OldValue, NewValue, HistoryText, FieldsName  
				  ,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy FROM Result  
				WHERE (  
				 (@GlobalFilter <>'' AND ((HistoryId like '%' +@GlobalFilter+'%') OR   
				   (OldValue like '%' +@GlobalFilter+'%') OR  
				   (NewValue like '%' +@GlobalFilter+'%') OR  
				   (HistoryText like '%' +@GlobalFilter+'%')  
				   ))  
				   OR     
				   (@GlobalFilter='' AND   
				   (IsNull(@OldValue,'') ='' OR OldValue like  '%'+@OldValue+'%') and  
				   (IsNull(@NewValue,'') ='' OR NewValue like  '%'+@NewValue+'%') and  
				   (IsNull(@PartNumber,'') ='' OR partnumber like  '%'+@PartNumber+'%') and  
				   --(IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like  '%'+@WorkOrderNum+'%') and  
				   (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like  '%'+@UpdatedBy+'%') and  
				   (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and  
				   (IsNull(@HistoryText,'') ='' OR HistoryText like '%'+@HistoryText+'%'))  
				   )),  
				  ResultCount AS (Select COUNT(HistoryId) AS NumberOfItems FROM FinalResult)  
				  SELECT HistoryId, ModuleId, partnumber, OldValue, NewValue, HistoryText, FieldsName,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,  
				  NumberOfItems FROM FinalResult, ResultCount  
  
				 ORDER BY    
				 CASE WHEN (@SortOrder=1 and @SortColumn='HistoryId')  THEN HistoryId END DESC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='OldValue')  THEN OldValue END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='NewValue')  THEN NewValue END ASC,  
				 --CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN partnumber END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='HistoryText')  THEN HistoryText END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='HistoryId')  THEN HistoryId END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='OldValue')  THEN OldValue END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='NewValue')  THEN NewValue END DESC,  
				-- CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN partnumber END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='HistoryText')  THEN HistoryText END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC  
				 OFFSET @RecordFrom ROWS   
				 FETCH NEXT @PageSize ROWS ONLY							
		END

	ELSE
		BEGIN
					;With Result AS(  
				SELECT HS.[HistoryId],  
				 HS.[ModuleId],  
				 --HS.[RefferenceId],  
				-- Wo.[WorkOrderNum],  
				   IM.[partnumber],  
				 HS.[OldValue],  
				 HS.[NewValue],  
				 HS.[HistoryText],  
				 HS.[FieldsName],  
				 HS.[CreatedBy],  
				 --HS.[CreatedDate],
				 case when CAST(HS.[CreatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(HS.[CreatedDate], @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate,
				 HS.[UpdatedBy],  
				 --HS.[UpdatedDate]
				 case when CAST(HS.[UpdatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(HS.[UpdatedDate], @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate
				FROM DBO.[History] HS WITH (NOLOCK)  
				INNER JOIN DBO.[KitItemMasterMapping] WO WITH (NOLOCK) ON HS.RefferenceId = Wo.KitItemMasterMappingId  
				LEFT JOIN DBO.[ItemMaster] IM WITH (NOLOCK) ON HS.SubRefferenceId = IM.ItemMasterId  
				 AND ISNULL(IM.IsNonStock,0) = 0
				WHERE wo.KitId = @RefferenceId --AND HS.MasterCompanyId = @MasterCompanyId    
				),  
				FinalResult AS (  
				SELECT HistoryId, ModuleId, partnumber, OldValue, NewValue, HistoryText, FieldsName  
				  ,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy FROM Result  
				WHERE (  
				 (@GlobalFilter <>'' AND ((HistoryId like '%' +@GlobalFilter+'%') OR   
				   (OldValue like '%' +@GlobalFilter+'%') OR  
				   (NewValue like '%' +@GlobalFilter+'%') OR  
				   (HistoryText like '%' +@GlobalFilter+'%')  
				   ))  
				   OR     
				   (@GlobalFilter='' AND   
				   (IsNull(@OldValue,'') ='' OR OldValue like  '%'+@OldValue+'%') and  
				   (IsNull(@NewValue,'') ='' OR NewValue like  '%'+@NewValue+'%') and  
				   (IsNull(@PartNumber,'') ='' OR partnumber like  '%'+@PartNumber+'%') and  
				   --(IsNull(@WorkOrderNum,'') ='' OR WorkOrderNum like  '%'+@WorkOrderNum+'%') and  
				   (IsNull(@UpdatedBy,'') ='' OR UpdatedBy like  '%'+@UpdatedBy+'%') and  
				   (IsNull(@UpdatedDate,'') ='' OR Cast(UpdatedDate as date)=Cast(@UpdatedDate as date)) and  
				   (IsNull(@HistoryText,'') ='' OR HistoryText like '%'+@HistoryText+'%'))  
				   )),  
				  ResultCount AS (Select COUNT(HistoryId) AS NumberOfItems FROM FinalResult)  
				  SELECT HistoryId, ModuleId, partnumber, OldValue, NewValue, HistoryText, FieldsName,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,  
				  NumberOfItems FROM FinalResult, ResultCount  
  
				 ORDER BY    
				 CASE WHEN (@SortOrder=1 and @SortColumn='HistoryId')  THEN HistoryId END DESC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='OldValue')  THEN OldValue END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='NewValue')  THEN NewValue END ASC,  
				 --CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN partnumber END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='HistoryText')  THEN HistoryText END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
				 CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,  
  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='HistoryId')  THEN HistoryId END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='OldValue')  THEN OldValue END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='NewValue')  THEN NewValue END DESC,  
				-- CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN partnumber END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='HistoryText')  THEN HistoryText END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
				 CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC  
				 OFFSET @RecordFrom ROWS   
				 FETCH NEXT @PageSize ROWS ONLY	
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
            , @AdhocComments     VARCHAR(150)    = 'USP_GetHistory'   
            , @ProcedureParameters VARCHAR(3000) = '@HistoryId = ''' + CAST(ISNULL(@HistoryId, '') as varchar(100))  
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
 END CATCH  
END