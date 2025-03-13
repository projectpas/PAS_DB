/*************************************************************             
 ** File:   [USP_GetTravelerSetupList]             
 ** Author:   Subhash Saliya  
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA     
 ** Purpose:           
 ** Date:   12/22/2022          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author				Change Description              
 ** --   --------     -------				--------------------------------            
    1    12/22/2022   Subhash Saliya		Created  
	2    01/09/2025   Moin Bloch			Changed [WorkScope] Discription to [WorkScopeCode]
	3    10-Feb-2025  Divyesh Kathiriya		Update CreatedDate and UpdateDate based on Employee time zone 
       
-- EXEC [USP_GetTravelerSetupList] 1,InActive,false,226  
**************************************************************/  
  
CREATE    PROCEDURE [dbo].[USP_GetTravelerSetupList]  
 @MasterCompanyId bigint ,  
 @Status varchar(100) , 
 @isdeleted bit,
 @EmployeeId BIGINT
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
    Declare @IsActive bit=1  
    DECLARE @EmpLegalEntiyId BIGINT = 0;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
	SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
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


    IF @Status='InActive'  
       BEGIN   
        SET @IsActive=0  
       END   
       ELSE IF @Status='Active'  
       BEGIN   
        SET @IsActive=1  
       END   
       ELSE IF @Status='ALL'  
       BEGIN   
        SET @IsActive=NULL  
       END  
    SELECT TS.[Traveler_SetupId]  
              ,TS.[TravelerId]  
              ,TS.[WorkScopeId]  
              ,WS.[WorkScopeCode] AS [WorkScope]  
              ,TS.[Version]  
			  ,TS.[ItemMasterId]  
			  ,TS.[PartNumber]  
              ,TS.[MasterCompanyId]  
              ,TS.[CreatedBy]  
              ,TS.[UpdatedBy]  
              ,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					CASE WHEN CAST(TS.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(TS.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			   ELSE (CAST(TS.CreatedDate AS DATETIME)) END CreatedDate
			  ,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					CASE WHEN CAST(TS.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(TS.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			   ELSE (CAST(TS.UpdatedDate AS DATETIME)) END UpdatedDate
              ,TS.[IsActive]  
              ,TS.[IsDeleted]  
              ,TS.[IsVersionIncrease]  
         FROM [dbo].[Traveler_Setup] TS WITH(NOLOCK)
		 LEFT JOIN [dbo].[WorkScope] WS WITH(NOLOCK) ON TS.[WorkScopeId] = WS.[WorkScopeId] 
		 WHERE TS.IsDeleted=@isdeleted  
		 AND (@IsActive IS NULL OR TS.IsActive=@IsActive) 
		 AND TS.MasterCompanyId=@MasterCompanyId ORDER BY TS.CreatedDate DESC   
                  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_GetTravelerSetupList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END