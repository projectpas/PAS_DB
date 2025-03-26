/************************************************************************************           
 ** File:   [GetVendorAuditInfoList]           
 ** Author: 
 ** Description: This stored procedure is used to get Vendor Audit Info Data List.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR   Date					Author				Change Description            
 ** --   --------				 -------		  --------------------------------          
	 1    12-03-2025			Amit Ghediya		Created

	 EXEC [dbo].[GetVendorAuditInfoList] 4169
****************************************************************************************/
CREATE    PROCEDURE [dbo].[GetVendorAuditInfoList]
	@VendorId BIGINT = NULL,
	@EmployeeId BIGINT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
				DECLARE @CurrentDate DATETIME,@CurrntEmpTimeZoneDesc VARCHAR(100) = '',@Expired VARCHAR(10) = 'Expired';

				--Set TodayDate for Expired as Employee Timezone
				SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE E.EmployeeId = @EmployeeId; 

				SET @CurrentDate = Cast(DBO.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) AS DATE);
				
				SELECT	
					VOI.[VendorAuditInfoId],
					VOI.[VendorId],
					VOT.[VendorOrderTypeId],
					VOT.[OrderTypeName],
					VAT.[VendorAuditTypeId],
					VAT.[VendorAuditType],
					VOI.[FrequencyDays],
					VOI.[LastAuditDate],
					VOI.[NextAuditDate],
					(CASE WHEN  
							@CurrentDate > Cast(DBO.ConvertUTCtoLocal(VOI.[NextAuditDate], @CurrntEmpTimeZoneDesc) AS DATE)
						THEN 
							@Expired 
						ELSE '' 
					END) AS Expired,
					VOI.[AuditFindings],
					VOI.[ActionsTaken],
					VOI.[CreatedBy],
					VOI.[UpdatedBy],
					VOI.[CreatedDate],
					VOI.[UpdatedDate],
					VOI.[IsActive],
					VOI.[IsDeleted],
					VOI.[MasterCompanyId]
				FROM [dbo].[VendorAuditInfo] VOI WITH(NOLOCK)				
					INNER JOIN [dbo].[VendorOrderType] VOT WITH(NOLOCK) ON VOI.VendorOrderTypeId = VOT.VendorOrderTypeId
					INNER JOIN [dbo].[VendorAuditType] VAT WITH(NOLOCK) ON VOI.VendorAuditTypeId = VAT.VendorAuditTypeId
				WHERE voi.VendorId = @VendorId;
		
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetVendorAuditInfoList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorId, '')
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