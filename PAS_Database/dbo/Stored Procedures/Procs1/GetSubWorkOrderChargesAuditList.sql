/*************************************************************           
 ** File:   [GetSubWorkOrderChargesAuditList]           
 ** Author:   Subhash Saliya
 ** Description: Get Search Data for Work order Chagres List    
 ** Purpose:         
 ** Date:   23-Feb-2021        
          
 ** PARAMETERS: @POId varchar(60)   
 ** RETURN VALUE:           
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    02/23/2021   Subhash Saliya	Created
    2    01/11/2024   Devendra Shekh	added UOM changes
	3	 01/17/2025	  Moin Bloch	  Modified (Added @WorkOrderFormTypeId from WO)    
    4	 07/Mar/2025  Bhargav Saliya  UTC Date Changes 
 EXECUTE [GetSubWorkOrderChargesAuditList] 148, null, 0
**************************************************************/ 

CREATE   PROCEDURE [dbo].[GetSubWorkOrderChargesAuditList]
@subWorkOrderChargesId bigint = null,
@EmployeeId bigint = 0
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY	

			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
			SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE E.EmployeeId = @EmployeeId; 

			DECLARE @WorkOrderFormTypeId BIT = 0; 
			DECLARE @WorkOrderId BIGINT = 0; 

			SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[SubWorkOrderCharges] WITH(NOLOCK) WHERE [SubWorkOrderChargesId] = @subWorkOrderChargesId;

			SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
		
				SELECT	
					 woc.ChargesTypeId,
                     ct.ChargeType AS ChargeType,
                     woc.Description,
                     woc.Quantity,
                     woc.UnitCost,
                     woc.ExtendedCost,
                     woc.VendorId,
                     v.VendorName,
                     woc.CreatedBy,
					 CASE WHEN CAST(woc.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(woc.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
                     woc.IsActive,
                     woc.IsDeleted,
                     woc.MasterCompanyId,
                     woc.TaskId,
                     woc.UpdatedBy,
					 CASE WHEN CAST(woc.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(woc.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate,
                     woc.SubWOPartNoId,
                     woc.SubWorkOrderChargesId,
                     woc.WorkOrderId,
					 CASE WHEN @WorkOrderFormTypeId = 1 THEN  ISNULL(WOT.[TaskName],'')  ELSE ISNULL(ts.[Description],'') END AS TaskName,
					 woc.ReferenceNo AS ReferenceNo,
					 ISNULL(gl.AccountName,'') AS GLAccountName,
					 woc.UOMId,  
					 um.ShortName AS 'UOM'
				FROM [dbo].[SubWorkOrderChargesAudit] woc WITH(NOLOCK)
					JOIN [dbo].[Charge] ct WITH(NOLOCK) ON woc.ChargesTypeId = ct.ChargeId
					LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON woc.VendorId = v.VendorId
					LEFT JOIN [dbo].[Task] ts WITH(NOLOCK) ON woc.TaskId = ts.TaskId
					LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = woc.TaskId
					LEFT JOIN [dbo].[GLAccount] gl  WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId
					LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON um.UnitOfMeasureId = woc.UOMId  
				WHERE woc.subWorkOrderChargesId = @subWorkOrderChargesId
				
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderChargesAuditList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@subWorkOrderChargesId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END