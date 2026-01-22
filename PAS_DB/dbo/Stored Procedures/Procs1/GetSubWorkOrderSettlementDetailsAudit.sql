
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
     
--EXEC [GetWorkOrderSettlementDetailsAudit] 1,346,269
**************************************************************/

Create PROCEDURE [dbo].[GetSubWorkOrderSettlementDetailsAudit]
@SubWorkOrderSettlementDetailId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT  wosd.WorkOrderId, 
						wos.WorkOrderSettlementName, 
						wos.WorkOrderSettlementId, 
						ISNULL(wosd.SubWorkOrderId,0) as SubWorkOrderId,
						ISNULL(wosd.SubWOPartNoId,0) as SubWOPartNoId,
						ISNULL(wosd.SubWorkOrderSettlementDetailId,0) as SubWorkOrderSettlementDetailId,
						wosd.IsMastervalue,
						wosd.Isvalue_NA,
					    wosd.Memo,
					    ISNULL(wosd.ConditionId,0) as ConditionId,
					    ISNULL(wosd.UserId,0) as UserId,
					    wosd.UserName,
					    wosd.sattlement_DateTime,
						wosd.MasterCompanyId,
						wosd.CreatedBy,
						wosd.UpdatedBy,
						wosd.CreatedDate,
						wosd.UpdatedDate,
						wosd.IsActive,
						wosd.IsDeleted,
						co.Description as conditionName
				FROM DBO.SubWorkOrderSettlementDetailsAudit wosd  WITH(NOLOCK)
					LEFT JOIN dbo.WorkOrderSettlement wos WITH(NOLOCK) on wosd.WorkOrderSettlementId = wos.WorkOrderSettlementId
					LEFT JOIN dbo.condition co WITH(NOLOCK) on co.conditionid = wosd.ConditionId
				WHERE wosd.SubWorkOrderSettlementDetailId = @SubWorkOrderSettlementDetailId -- and wosd.WorkflowWorkOrderId = @workflowWorkorderId and wosd.workOrderPartNoId = @workOrderPartNoId --AND wop.ID = @workOrderPartNoId 
		END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderSettlementDetailsAudit' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderSettlementDetailId, '') + ''
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