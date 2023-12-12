
/*************************************************************           
 ** File:   [UpdateWorkOrderQuoteColumnsWithId]           
 ** Author:   Subhash Saliya
 ** Description: This Stored Procedure is Used WOQ Details Based in WOQ Id.    
 ** Purpose:         
 ** Date:   12/30/2022       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/30/2022   subhash Saliya Created
     
-- EXEC [PROC_linkWOtoPOROData] 6
**************************************************************/

CREATE   PROCEDURE [dbo].[PROC_linkWOtoPOROData]
@Workorderid bigint,
@Module varchar(100),
@RefId bigint,
@UpdatedBy varchar(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			Declare @WorkOrderNum varchar(100)

			select @WorkOrderNum= WorkOrderNum from WorkOrder where WorkOrderId=@Workorderid
			
			if(@Module='PO')
			BEGIN
			Update PurchaseOrderPart set WorkOrderId=@Workorderid,WorkOrderNo=@WorkOrderNum,UpdatedBy=@UpdatedBy,UpdatedDate=GETDATE()  where PurchaseOrderPartRecordId=@RefId
			END

			if(@Module='RO')
			BEGIN
			Update RepairOrderPart set WorkOrderId=@Workorderid,WorkOrderNo=@WorkOrderNum,UpdatedBy=@UpdatedBy,UpdatedDate=GETDATE()  where RepairOrderPartRecordId=@RefId
			END

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROC_linkWOtoPOROData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@Workorderid, '') + ''
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