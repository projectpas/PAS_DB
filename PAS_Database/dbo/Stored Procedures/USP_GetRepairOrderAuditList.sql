/*************************************************************           
 ** File:   [USP_GetRepairOrderAuditList]           
 ** Author:   Bhargav Saliya 
 ** Description: Get Data for Repair Order History    
 ** Purpose:         
 ** Date:   18-April-2025      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    18-April-2025   Bhargav Saliya		Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetRepairOrderAuditList]
    @RepairOrderId INT,
	@EmployeeId BIGINT 
AS
BEGIN
    SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

		SELECT 
			ro.RepairOrderAuditId,
			ro.RepairOrderId,
			ro.RepairOrderNumber,
			ro.OpenDate,
			ro.ClosedDate,
			ro.NeedByDate,
			ro.Priority,
			ro.VendorName,
			ro.VendorCode,
			ro.VendorContact,
			ro.VendorContactPhone AS ContactPhone,
			ro.Terms AS CreditTerms,
			ro.CreditLimit,
			ro.ApprovedDate,
			ro.Resale,
			ro.DeferredReceiver,
			ro.Status,
			ro.Requisitioner AS RequestedBy,
			ro.IsDeleted,
			ro.ApprovedBy,
			CASE WHEN CAST(ro.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(ro.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate],
			ro.IsActive,
			CASE WHEN CAST(ro.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(ro.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END [CreatedDate],
			ro.CreatedBy,
			ro.UpdatedBy
		FROM [dbo].[RepairOrderAudit] ro
		WHERE ro.RepairOrderId = @RepairOrderId
		ORDER BY ro.RepairOrderAuditId DESC;
	
	END TRY 
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetRepairOrderAuditList',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH 
END