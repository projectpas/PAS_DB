/*************************************************************           
 ** File:   [GetSubWorkOrderFreightAuditList]           
 ** Author:   Subhash Saliya
 ** Description: Get Data for Work order freight Audit List    
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
	2	 01/17/2025	  Moin Bloch	 Modified (Added @WorkOrderFormTypeId from WO)    
	3	 07/Mar/2025  Bhargav Saliya UTC Date Changes
     
 EXECUTE [GetSubWorkOrderFreightAuditList] 27,0
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetSubWorkOrderFreightAuditList]
@subWorkOrderFreightId bigint = null,
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

			SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[SubWorkOrderFreight] WITH(NOLOCK) WHERE [SubWorkOrderFreightId] = @subWorkOrderFreightId;

			SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
		
	
					SELECT	
					    wf.Amount,
                        wf.CreatedBy,
						CASE WHEN CAST(wf.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wf.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
                        wf.IsActive,
                        wf.IsDeleted,
                        wf.MasterCompanyId,
                        wf.Memo,
                        wf.ShipViaId,
                        wf.UpdatedBy,
						CASE WHEN CAST(wf.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wf.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate,
                        wf.[Weight],
                        wf.SubWOPartNoId,
                        wf.SubWorkOrderFreightId,
                        wf.WorkOrderId,
                        wf.SubWorkOrderId,
                        sv.[Name] AS ShipVia,
                        wf.TaskId,
                        --isnull(ts.Description,'') as TaskName,
						CASE WHEN @WorkOrderFormTypeId = 1 THEN  ISNULL(WOT.[TaskName],'')  ELSE ISNULL(ts.[Description],'') END AS TaskName,
                        wf.[Length],
                        wf.Width,
                        wf.Height,
                        wf.UOMId,
                        wf.DimensionUOMId,
                        wf.CurrencyId,
                        isnull(uom.[Description],'') AS UOM,
                        isnull(duom.[Description],'') DimensionUOM,
                        cur.Code AS Currency					
					FROM [dbo].[SubWorkOrderFreightAudit] wf WITH(NOLOCK)
						JOIN [dbo].[ShippingVia] sv WITH(NOLOCK) ON wf.ShipViaId = sv.ShippingViaId
						LEFT JOIN [dbo].[Task] ts  WITH(NOLOCK) ON wf.TaskId = ts.TaskId
						LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = wf.TaskId
						LEFT JOIN [dbo].[UnitOfMeasure] uom   WITH(NOLOCK) ON wf.UOMId = uom.UnitOfMeasureId
						LEFT JOIN [dbo].[UnitOfMeasure] duom   WITH(NOLOCK) ON wf.DimensionUOMId = duom.UnitOfMeasureId
						LEFT JOIN [dbo].[Currency] cur  WITH(NOLOCK) ON wf.CurrencyId = cur.CurrencyId
					WHERE wf.subWorkOrderFreightId = @subWorkOrderFreightId        
				
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderFreightAuditList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@subWorkOrderFreightId, '') + ''
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