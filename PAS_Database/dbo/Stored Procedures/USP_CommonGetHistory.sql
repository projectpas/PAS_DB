/*************************************************************             
 ** File:   [USP_CommonGetHistory]             
 ** Author:  Bhargav Saliya  
 ** Description: This stored procedure is used History data  
 ** Purpose:           
 ** Date:   29/10/2025       
            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    29/10/2025   Bhargav Saliya     Created  
************************************************************************/  
CREATE   PROCEDURE [dbo].[USP_CommonGetHistory]  
 @PageSize INT,  
 @PageNumber INT,  
 @SortColumn VARCHAR(50)=null,  
 @SortOrder INT,  
 @GlobalFilter VARCHAR(50) = null,  
 @ReferenceId BIGINT,  
 @ModuleId BIGINT,  
 @TableName VARCHAR(MAX) = null, 
 @ColumnName VARCHAR(MAX) = null,  
 @OldValue VARCHAR(MAX) = null,
 @NewValue VARCHAR(MAX) = null,
 @Activity VARCHAR(MAX) = null,
 @MasterCompanyId INT,
 @UpdatedBy VARCHAR(MAX) = null, 
 @UpdatedDate VARCHAR(MAX) = null, 
 @EmployeeId bigint=null

AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
   DECLARE @RecordFrom INT;  

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '',@PrimaryKeyName VARCHAR(100) = '';
	DECLARE @ModuleName VARCHAR(100) = (SELECT ModuleName FROM dbo.Module WITH (NOLOCK) WHERE ModuleId = @ModuleId);
		
	SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
	WHERE E.EmployeeId = @EmployeeId; 

    SET @RecordFrom = (@PageNumber-1) * @PageSize;  
      
    IF @SortColumn IS NULL  
    BEGIN  
     SET @SortColumn=UPPER('UpdatedDate')  
    END   
    Else  
    BEGIN   
     SET @SortColumn=UPPER(@SortColumn)  
    END  

	IF(UPPER(@ModuleName) = 'CUSTOMER')
	BEGIN
		SET @PrimaryKeyName = 'CustomerId'
	END
	ELSE IF(UPPER(@ModuleName) = 'WORKORDER')
	BEGIN
		SET @PrimaryKeyName = 'WorkOrderId'
	END
	ELSE IF(UPPER(@ModuleName) = 'VENDOR')
	BEGIN
		SET @PrimaryKeyName = 'VendorId'
	END
  
    ;With Result AS(  
    SELECT   
         AL.AuditId,
         AL.TableName,
         AL.ColumnName,
         AL.OldValue,
         AL.NewValue,
         AL.UpdatedBy,
		 CASE WHEN CAST(AL.ChangedAt AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(AL.ChangedAt, @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate]
	FROM [dbo].[AuditLog] AL WITH (NOLOCK)  
    WHERE JSON_VALUE(AL.PKJson, '$.' + @PrimaryKeyName) = CAST(@ReferenceId AS NVARCHAR(20))    
    ),  
    FinalResult AS (  
    SELECT AuditId, TableName, ColumnName, OldValue, NewValue, UpdatedBy,UpdatedDate FROM Result  
    WHERE (  
     (@GlobalFilter <>'' AND ((TableName LIKE '%' +@GlobalFilter+'%') OR   
       (ColumnName LIKE '%' +@GlobalFilter+'%') OR  
       (OldValue LIKE '%' +@GlobalFilter+'%') OR  
       (NewValue LIKE '%' +@GlobalFilter+'%') OR  
	   (UpdatedBy LIKE '%' +@GlobalFilter+'%') OR 
       (UpdatedDate LIKE '%' +@GlobalFilter+'%')  
       ))  
       OR     
       (@GlobalFilter='' AND   
       (ISNULL(@OldValue,'') ='' OR OldValue LIKE  '%'+@OldValue+'%') AND  
       (ISNULL(@NewValue,'') ='' OR NewValue LIKE  '%'+@NewValue+'%') AND  
       (ISNULL(@TableName,'') ='' OR TableName LIKE  '%'+@TableName+'%') AND  
       (ISNULL(@ColumnName,'') ='' OR ColumnName LIKE  '%'+@ColumnName+'%') AND  
       (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE  '%'+@UpdatedBy+'%') AND  
       (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)))  
       )),  
      ResultCount AS (SELECT COUNT(AuditId) AS NumberOfItems FROM FinalResult)  
      SELECT AuditId, TableName, ColumnName, OldValue, NewValue, UpdatedBy, UpdatedDate,NumberOfItems FROM FinalResult, ResultCount  
  
     ORDER BY    
     CASE WHEN (@SortOrder=1 AND @SortColumn='OldValue')  THEN OldValue END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='NewValue')  THEN NewValue END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='TableName')  THEN TableName END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='ColumnName')  THEN ColumnName END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
     CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC, 
	   
     CASE WHEN (@SortOrder=-1 AND @SortColumn='OldValue')  THEN OldValue END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='NewValue')  THEN NewValue END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='TableName')  THEN TableName END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='ColumnName')  THEN ColumnName END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
     CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC 

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
            , @AdhocComments     VARCHAR(150)    = 'USP_CommonGetHistory'   
            , @ProcedureParameters VARCHAR(3000) = '@ReferenceId = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100))  
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