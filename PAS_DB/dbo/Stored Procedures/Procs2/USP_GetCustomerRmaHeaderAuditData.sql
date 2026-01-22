/*************************************************************           
 ** File:   [USP_GetCustomerRmaHeaderAuditData]           
 ** Author:   Subhash Saliya
 ** Description: Get Customer RMA Audit Data
 ** Purpose:         
 ** Date:   18-april-2022        
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    04/18/2022   Subhash Saliya		Created
	2	 23/06/2023   Ayesha Sultana		Alter - Added Receiver Num in Customer RMA History
	3    24-Mar-2025  Divyesh Kathiriya		Update CreatedDate, UpdatedDate and InvoiceDate based on Employee time zone
	
 -- exec USP_GetCustomerRmaHeaderAuditData 92,1,226   
**************************************************************/ 

CREATE Procedure [dbo].[USP_GetCustomerRmaHeaderAuditData]
@RMAHeaderId BIGINT,
@ModuleID INT,
@EmployeeId BIGINT
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 

			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
			FROM 
				DBO.Employee E WITH (NOLOCK) 
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


		    SELECT [RMAHeaderId]
			  ,CRM.[RMANumber]
			  ,CRM.[CustomerId]
			  ,CRM.[CustomerName]
			  ,CRM.[CustomerCode]
			  ,CRM.[CustomerContactId]
			  ,CRM.[ContactInfo]
			  ,CRM.[OpenDate]
			  ,CRM.[InvoiceId]
			  ,CRM.[InvoiceNo]
			  ,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					CASE WHEN CAST(CRM.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CRM.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			   ELSE (CAST(CRM.InvoiceDate AS DATETIME)) END InvoiceDate
			  ,CRM.[RMAStatusId]
			  ,CRM.[RMAStatus]
			  ,CRM.[Iswarranty]
			  ,CRM.[ValidDate]
			  ,CRM.[RequestedId]
			  ,CRM.[Requestedby]
			  ,CRM.[ApprovedbyId]
			  ,CRM.[Approvedby]
			  ,CRM.[ApprovedDate]
			  ,CRM.[ReturnDate]
			  ,CRM.[WorkOrderId]
			  ,CRM.[WorkOrderNum]
			  ,CRM.[ReceiverNum]
			  ,CRM.[ManagementStructureId]
			  ,CRM.[Notes]
			  ,CRM.[Memo]
			  ,CRM.[MasterCompanyId]
			  ,CRM.[CreatedBy]
			  ,CRM.[UpdatedBy]
			  ,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					CASE WHEN CAST(CRM.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CRM.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			   ELSE (CAST(CRM.CreatedDate AS DATETIME)) END CreatedDate
			  ,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					CASE WHEN CAST(CRM.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CRM.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			   ELSE (CAST(CRM.UpdatedDate AS DATETIME)) END UpdatedDate
			  ,CRM.[IsActive]
			  ,CRM.[IsDeleted]
			  ,CRM.[isWorkOrder]
			  ,CRM.ReferenceId
			  ,MSD.LastMSLevel
			  ,MSD.AllMSlevels
		  FROM [dbo].[CustomerRMAHeaderAudit] CRM  WITH (NOLOCK) 
		  INNER JOIN dbo.RMACreditMemoManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = CRM.RMAHeaderId

		  WHERE  RMAHeaderId =@RMAHeaderId 
         END
			
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCustomerRmaHeaderAuditData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RMAHeaderId, '') + ''
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