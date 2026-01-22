/*************************************************************           
 ** File:   [USP_GetTravelerSetupList]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA   
 ** Purpose:         
 ** Date:   01/03/2023        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    01/03/2023   Subhash Saliya		Created
    2    10-Feb-2025  Divyesh Kathiriya		Update CreatedDate and UpdateDate based on Employee time zone 

-- EXEC [USP_GetTraveler_Setup_TaskList] 44,0,226
**************************************************************/

CREATE       PROCEDURE [dbo].[USP_GetTraveler_Setup_TaskList]
 @Traveler_SetupId bigint,
 @IsDeleted bit=0,
 @EmployeeId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
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


					SELECT [Traveler_Setup_TaskId]
						  ,[Traveler_SetupId]
						  ,[TaskId]
						  ,[TaskName]
						  ,[Notes]
						  ,[Sequence]
						  ,[MasterCompanyId]
						  ,[CreatedBy]
						  ,[UpdatedBy]						  
						  ,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
								CASE WHEN CAST(CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
						   ELSE (CAST(CreatedDate AS DATETIME)) END CreatedDate
						  ,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
								CASE WHEN CAST(UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
						   ELSE (CAST(UpdatedDate AS DATETIME)) END UpdatedDate
						  ,[IsActive]
						  ,[IsDeleted]
						  ,TeardownTypeId
						  ,TeardownTypeName
					  FROM [dbo].[Traveler_Setup_Task]  where IsDeleted=@IsDeleted and Traveler_SetupId=@Traveler_SetupId 
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetTraveler_Setup_TaskList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@Traveler_SetupId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END