/*************************************************************           
 ** File:   [GetWorkOrderChargesAuditList]           
 ** Author:   Subhash Saliya
 ** Description: Get  for Work order Chagres History List    
 ** Purpose:         
 ** Date:   23-Feb-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/23/2021   Subhash Saliya Created
	2    06/25/2020   Hemant  Saliya Added Transation & Content Management
	3    02/14/2025   Bhargav Saliya UTC Date Changes

     
 EXECUTE [GetWorkOrderChargesAuditList] 154, null
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetWorkOrderChargesAuditList]
	@workOrderChargesId bigint = null,
	@EmployeeId bigint = 0
AS
BEGIN

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
    BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT	
					woc.ChargesTypeId,
                    woc.ChargeType,
                    woc.Description,
                    woc.Quantity,
                    woc.UnitCost,
                    woc.ExtendedCost,
                    woc.Vendor as VendorName,
                    woc.CreatedBy,
					CASE WHEN CAST(woc.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(woc.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
                    woc.IsActive,
                    woc.IsDeleted,
                    woc.MasterCompanyId,
                    woc.TaskId,
                    woc.UpdatedBy,
					CASE WHEN CAST(woc.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(woc.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate,
                    woc.WorkFlowWorkOrderId,
                    woc.WorkOrderChargesId,
                    woc.WorkOrderId,
					woc.ChargesTypeId,
					woc.WorkOrderChargesAuditId,
					isnull(woc.Task,'') as TaskName,
					woc.ReferenceNo as RefNum,
					isnull(woc.GlAccount,'') as GLAccountName
				FROM dbo.WorkOrderChargesAudit woc WITH(NOLOCK)				
				WHERE  woc.workOrderChargesId = @workOrderChargesId
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderChargesAuditList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderChargesId, '') + ''													   
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