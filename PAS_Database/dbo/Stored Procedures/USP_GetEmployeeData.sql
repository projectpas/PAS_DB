/*************************************************************           
 ** File:   [USP_GetEmployeeData]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get EmployeeData List
 ** Purpose:         
 ** Date:   13-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    13-06-2025    Sahdev Saliya       Created  
	2    18-06-2025    Abhishek Jirawla    Added retrieve of TwoFactorAuthentication details

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetEmployeeData]
    @EmployeeId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	     BEGIN TRY

			SELECT
                  emp.FirstName,
                  emp.LastName,
                  emp.MiddleName,
                  emp.EmployeeCode,
                  emp.Email,
                  emp.TimeZoneId,
                  emp.CurrencyFormatId,
                  emp.DecimalPrecisionId,
                  ShortDateFormatId = emp.ShortDateTimeFormatId,
                  LongDateFormatId = emp.LongDateTimeFormatId,
                  emp.TextTransformId,
                  emp.IsIncludeInCC,
                  emp.IsAllowToChangeManagementStructure,
                  emp.SiteId,
                  emp.TwoFactorAuthentication,
                  emp.TwoFactorAuthenticationType
			FROM [DBO].employee emp WITH(NOLOCK)
			WHERE emp.EmployeeId = @EmployeeId
		END TRY    

    BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetEmployeeData' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeId, '')
			 
				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END