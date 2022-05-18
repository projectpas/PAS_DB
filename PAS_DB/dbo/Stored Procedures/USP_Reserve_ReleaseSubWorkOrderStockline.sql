
/*************************************************************           
 ** File:   [USP_Reserve_ReleaseSubWorkOrderStockline]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Reserve Or Release Stockline for Sub WO   
 ** Purpose:         
 ** Date:   08/12/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/12/2021   Hemant Saliya Created
     
 EXECUTE USP_Reserve_ReleaseSubWorkOrderStockline 409,73, 624,60,145,1,0,1

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_Reserve_ReleaseSubWorkOrderStockline]    
(    
@WorkOrderId  BIGINT  = NULL,
@SubWorkOrderId  BIGINT  = NULL,
@WorkOrderMaterialsId  BIGINT  = NULL,
@StocklineId  BIGINT  = NULL,
@SubWorkOrderPartNoId  BIGINT  = NULL,
@Quantity INT = NULL,
@IsCreate BIT = 0,
@UpdatedById BIGINT = NULL,
@IsMaterialStocklineCreate BIT = 0
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				DECLARE @SubWorkOrderStatusId BIGINT;
				DECLARE @UpdatedBy VARCHAR(200);
				DECLARE @SubWOPartQty INT;

				SELECT @UpdatedBy = FirstName + ' ' + LastName FROM dbo.Employee Where EmployeeId = @UpdatedById
				SET @SubWOPartQty = 1; -- It's Always Single QTY

				SELECT @SubWorkOrderStatusId  = Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE UPPER(StatusCode) = 'CLOSED'
				--SELECT @ProvisionId  = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE UPPER(StatusCode) = 'REPLACE'
				--SELECT @MasterCompanyId  = MasterCompanyId FROM dbo.SubWorkOrder WITH(NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId

				IF(@IsCreate = 1)
				BEGIN
					UPDATE dbo.Stockline SET QuantityAvailable = QuantityAvailable - @SubWOPartQty WHERE StockLineId = @StocklineId
				END
				--ELSE
				--BEGIN
				--	--IF((SELECT COUNT(1) FROM dbo.SubWorkOrderPartNumber WHERE SubWOPartNoId = @SubWorkOrderPartNoId AND SubWorkOrderStatusId = @SubWorkOrderStatusId ) > 0)
				--	--BEGIN
				--	--	UPDATE dbo.Stockline SET QuantityAvailable = QuantityAvailable  + @SubWOPartQty WHERE StockLineId = @StocklineId
				--	--END

				--	--EXEC USP_CloseSubWorkOrder @WorkOrderId, @SubWorkOrderId, @WorkOrderMaterialsId, @StocklineId, @UpdatedById;
				--	EXEC CreateStocklineForFinishGoodSubWOMPN @SubWorkOrderPartNoId, @UpdatedBy, @IsMaterialStocklineCreate
				--END
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Reserve_ReleaseSubWorkOrderStockline' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@WorkOrderId, '') + ',
													   @Parameter2 = ' + ISNULL(@SubWorkOrderId,'') + ', 
													   @Parameter3 = ' + ISNULL(@WorkOrderMaterialsId,'') + ', 
													   @Parameter4 = ' + ISNULL(@StocklineId,'') + ', 
													   @Parameter5 = ' + ISNULL(@SubWorkOrderPartNoId ,'') +''
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