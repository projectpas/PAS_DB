/*************************************************************           
 ** File:   [GetWorkOrderSettlementDetailsAudit]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Work order Settlement Details Audit 
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/02/2020   Subhash Saliya Created
	2	 06/28/2021	  Hemant Saliya  Added Transation & Content Managment
	3	 02/14/2025	  Bhargav Saliya  UTC Date Changes
     
--EXEC [GetWorkOrderSettlementDetailsAudit] 1,346,269
**************************************************************/

CREATE PROCEDURE [dbo].[GetWorkOrderSettlementDetailsAudit]
@WorkOrderSettlementDetailId bigint,
@EmployeeId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT  wosd.WorkOrderId, 
						wos.WorkOrderSettlementName, 
						wos.WorkOrderSettlementId, 
						ISNULL(wosd.WorkFlowWorkOrderId,0) as WorkFlowWorkOrderId,
						ISNULL(wosd.workOrderPartNoId,0) as workOrderPartNoId,
						ISNULL(wosd.WorkOrderSettlementDetailId,0) as WorkOrderSettlementDetailId,
						wosd.IsMastervalue,
						wosd.Isvalue_NA,
					    wosd.Memo,
					    ISNULL(wosd.ConditionId,0) as ConditionId,
					    ISNULL(wosd.UserId,0) as UserId,
					    wosd.UserName,
						CASE WHEN CAST(wosd.sattlement_DateTime AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wosd.sattlement_DateTime, @CurrntEmpTimeZoneDesc) AS DATETIME))END sattlement_DateTime,
						wosd.MasterCompanyId,
						wosd.CreatedBy,
						wosd.UpdatedBy,
						CASE WHEN CAST(wosd.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wosd.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
						CASE WHEN CAST(wosd.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(wosd.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END UpdatedDate,
						wosd.IsActive,
						wosd.IsDeleted,
						co.Description as conditionName
				FROM DBO.WorkOrderSettlementDetailsAudit wosd  WITH(NOLOCK)
					LEFT JOIN dbo.WorkOrderSettlement wos WITH(NOLOCK) on wosd.WorkOrderSettlementId = wos.WorkOrderSettlementId
					LEFT JOIN dbo.condition co WITH(NOLOCK) on co.conditionid = wosd.ConditionId
				WHERE wosd.WorkOrderSettlementDetailId = @WorkOrderSettlementDetailId -- and wosd.WorkflowWorkOrderId = @workflowWorkorderId and wosd.workOrderPartNoId = @workOrderPartNoId --AND wop.ID = @workOrderPartNoId 
		END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderSettlementDetailsAudit' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderSettlementDetailId, '') + ''
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