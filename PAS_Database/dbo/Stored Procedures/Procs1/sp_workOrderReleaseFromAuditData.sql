/*************************************************************           
 ** File:   [sp_workOrderReleaseFromAuditData]           
 ** Author:   Hemant Saliya
 ** Description: Get Data for Work order Quote Materila Audit List    
 ** Purpose:         
 ** Date:   16-March-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/16/2021   Hemant Saliya Created
    2    02/14/2025   Bhargav Saliya  UTC Date Changes

     
 EXECUTE [sp_workOrderReleaseFromAuditData] 198
**************************************************************/ 
CREATE Procedure [dbo].[sp_workOrderReleaseFromAuditData]
@ReleaseFromId bigint,
@EmployeeId bigint = 0
AS
BEGIN
		
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 

  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT 
				   wro.ReleaseFromAuditId
				  ,wro.[ReleaseFromId]
				  ,wro.[WorkorderId]
				  ,wro.[workOrderPartNoId]
				  ,wro.[Country]
				  ,wro.[OrganizationName]
				  ,wro.[InvoiceNo]
				  ,wro.[ItemName]
				  ,wro.[Description]
				  ,wro.[PartNumber]
				  ,wro.[Reference]
				  ,wro.[Quantity]
				  ,wro.[Batchnumber]
				  ,wro.[status]
				  ,wro.[Remarks]
				  ,wro.[Certifies]
				  ,wro.[approved]
				  ,wro.[Nonapproved]
				  ,wro.[AuthorisedSign]
				  ,wro.[AuthorizationNo]
				  ,wro.[PrintedName]
				  ,wro.[Date]
				  ,wro.[AuthorisedSign2]
				  ,wro.[ApprovalCertificate]
				  ,wro.[PrintedName2]
				  ,wro.[Date2]
				  ,wro.[CFR]
				  ,wro.[Otherregulation]
				  ,wro.[MasterCompanyId]
				  ,wro.[CreatedBy]
				  ,wro.[UpdatedBy]
				  ,CASE WHEN CAST(wro.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wro.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate
				  ,CASE WHEN CAST(wro.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wro.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate
				  ,wro.[IsActive]
				  ,wro.[IsDeleted]
				  ,wro.[trackingNo]
				  ,wro.[OrganizationAddress]
				  ,wro.[is8130from]
			FROM [dbo].[Work_ReleaseFrom_8130Audit] wro WITH(NOLOCK)
			WHERE wro.ReleaseFromId=@ReleaseFromId

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_workOrderReleaseFromAuditData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReleaseFromId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END