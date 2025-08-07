/*************************************************************           
 ** File:   [USP_UpdateEmployeeActiveStatus]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Update EmployeeActiveStatus List
 ** Purpose:         
 ** Date:   07-08-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    07-08-2025    Sahdev Saliya       Created  

   EXEC [USP_EmployeeUpdateforActiveStatus] 2, 1, 'admin', 2;
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_EmployeeUpdateforActiveStatus]
@id  BIGINT=NULL,
@IsActive BIT=NULL,
@UpdatedBy VARCHAR(256)=NULL,
@EmployeeId BIGINT=NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

		UPDATE [dbo].[Employee]
		   SET [IsActive] = @IsActive,
			   [UpdatedDate] = GETUTCDATE(),
			   [UpdatedBy] = @UpdatedBy
	     WHERE [EmployeeId] = @id;
		 BEGIN TRY

			SELECT [EmployeeId]
			  ,[EmployeeCode]
			  ,[EmployeeIdAsPerPayroll]
			  ,[FirstName]
			  ,[LastName]
			  ,[MiddleName]
			  ,[JobTitleId]
			  ,[EmployeeExpertiseId]
			  ,[DateOfBirth]
			  ,[StartDate]
			  ,[MobilePhone]
			  ,[WorkPhone]
			  ,[Fax]
			  ,[Email]
			  ,[SSN]
			  ,[InMultipleShifts]
			  ,[AllowOvertime]
			  ,[AllowDoubleTime]
			  ,[IsHourly]
			  ,[HourlyPay]
			  ,[EmployeeCertifyingStaff]
			  ,[SupervisorId]
			  ,[MasterCompanyId]
			  ,[CreatedBy]
			  ,[UpdatedBy]
			  ,[CreatedDate]
			  ,[UpdatedDate]
			  ,[IsActive]
			  ,[IsDeleted]
			  ,[ManagementStructureId]
			  ,[LegalEntityId]
			  ,[Memo]
			  ,[CurrencyId]
			  ,[StationId]
			  ,[AttachmentId]
			  ,[EmployeeExpIds]
			  ,[EmailSignature]
			  ,[EmailSignatureLogo]
			  ,[UserSignature]
			  ,[TimeZoneId]
			  ,[CurrencyFormatId]
			  ,[DecimalPrecisionId]
			  ,[ShortDateTimeFormatId]
			  ,[LongDateTimeFormatId]
			  ,[TextTransformId]
			  ,[IsIncludeInCC]
			  ,[IsAllowToChangeManagementStructure]
			  ,[SiteId]
			  ,[TwoFactorAuthentication]
			  ,[TwoFactorAuthenticationType]
			  ,[TwoFactorAuthenticatorKey]
		  FROM [dbo].[Employee] WITH(NOLOCK) 
		 WHERE [EmployeeId] = @id;

	  END TRY
	  BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_EmployeeUpdateforActiveStatus' 
				  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') as varchar(100))   
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