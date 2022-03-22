

/*************************************************************           
 ** File:   [GetWorkFlowAuditList]           
 ** Author:   Subhash Saliya
 ** Description: Get Search Data for GetWorkFlowAuditList  
 ** Purpose:         
 ** Date:   05/03/2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/03/2021   Subhash Saliya Created

     
 EXECUTE [GetWorkFlowAuditList] 131
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetWorkOrderAuditList]
-- Add the parameters for the stored procedure here	
	@WorkOrderId bigint = null

AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT	
					 WorkOrderId,
                     WorkOrderNum,
                     IsSinglePN,
                     OpenDate,
                     Memo,
                     Notes,
                     Status,
					CustomerName
                    ,ContactName
                    ,ContactPhone
                    ,CreditLimit
                    ,CreditTerms
                    ,SalesPerson
                    ,CSR
                    ,Employee,
                     wo.CreatedBy,
                     wo.CreatedDate,
                     wo.IsActive,
                     wo.IsDeleted,
                     wo.MasterCompanyId,
                     wo.UpdatedBy,
                     wo.UpdatedDate
				FROM dbo.WorkOrderAudit wo WITH(NOLOCK)				
				WHERE wo.WorkOrderId = @WorkOrderId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderAuditList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''
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