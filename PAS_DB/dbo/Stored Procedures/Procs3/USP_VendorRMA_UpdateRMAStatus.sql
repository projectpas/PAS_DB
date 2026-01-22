/*************************************************************           
 ** File:   [USP_VendorRMA_UpdateRMAStatus]          
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to Update RMA Status After Receive RMA   
 ** Purpose:         
 ** Date:   07/03/2023
          
 ** PARAMETERS:  @VendorRMAId BIGINT   
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		   Change Description            
 ** --   --------     -------		   --------------------------------             
	1    07/03/2023   Moin Bloch       Created

  EXEC dbo.USP_VendorRMA_UpdateRMAStatus 60
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_UpdateRMAStatus]    
@VendorRMAId  BIGINT = NULL,
@UpdatedBy VARCHAR(100) = NULL
AS    
BEGIN 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @VendorRMADetailId BIGINT;
				DECLARE @MasterCompanyId INT;
				DECLARE @MasterLoopID AS INT;
				DECLARE @Qty INT = 0;
				DECLARE @StockQty INT = 0;
				DECLARE @ReplacedRMAStatusId INT = 0;
				DECLARE @ClosedRMAStatusId INT = 0;
				DECLARE @AllPartQty INT = 0;
				DECLARE @AllStockQty INT = 0;
				
				SELECT @ReplacedRMAStatusId = [VendorRMAStatusId] FROM [dbo].[VendorRMAStatus] WHERE UPPER([VendorRMAStatus]) = 'REPLACED';
				SELECT @ClosedRMAStatusId = [VendorRMAStatusId] FROM [dbo].[VendorRMAHeaderStatus] WHERE UPPER([StatusName]) = 'CLOSED';
				
				IF OBJECT_ID(N'tempdb..#RMAPartData') IS NOT NULL
				BEGIN
					DROP TABLE #RMAPartData
				END
				
				CREATE TABLE #RMAPartData
				(
					[ID] INT IDENTITY,
					[VendorRMADetailId] BIGINT,
					[Qty] INT,
					[MasterCompanyId] INT
				)
								
				INSERT INTO #RMAPartData ([VendorRMADetailId],[Qty],[MasterCompanyId]) SELECT [VendorRMADetailId],[Qty],[MasterCompanyId] FROM [dbo].[VendorRMADetail] VP WITH(NOLOCK) WHERE VP.[VendorRMAId] = @VendorRMAId AND VP.[IsDeleted] = 0

				SELECT  @MasterLoopID = MAX(ID) FROM #RMAPartData
				WHILE(@MasterLoopID > 0)
				BEGIN					
					SELECT @VendorRMADetailId = [VendorRMADetailId], @Qty = [Qty], @MasterCompanyId = [MasterCompanyId] FROM #RMAPartData WHERE ID  = @MasterLoopID
					
					IF(@VendorRMADetailId > 0)
					BEGIN
						SET @AllPartQty = @AllPartQty + @Qty;

						SELECT @StockQty = ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) FROM [dbo].[Stockline] SL WITH(NOLOCK) WHERE SL.[VendorRMAId] = @VendorRMAId AND SL.[VendorRMADetailId] = @VendorRMADetailId AND SL.[IsParent] = 1 AND SL.[IsDeleted] = 0
						IF(@StockQty > 0)
						BEGIN
							SET @AllStockQty = @AllStockQty + @StockQty;

							IF(@Qty = @StockQty)
							BEGIN
								UPDATE [dbo].[VendorRMADetail] 
								   SET [VendorRMAStatusId] = @ReplacedRMAStatusId,
									   [UpdatedBy] = @UpdatedBy,
									   [UpdatedDate] = GETUTCDATE()
								 WHERE [VendorRMADetailId] = @VendorRMADetailId;
							END							
						END
					END					
					SET @MasterLoopID = @MasterLoopID - 1;
				END		
				IF(@AllPartQty = @AllStockQty)
				BEGIN
					UPDATE [dbo].[VendorRMA] 
					   SET [VendorRMAStatusId] = @ClosedRMAStatusId, 
					       [UpdatedBy] = @UpdatedBy,
						   [UpdatedDate] = GETUTCDATE()						
					 WHERE [VendorRMAId] = @VendorRMAId;					   
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
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_UpdateRMAStatus' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@VendorRMAId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              --RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              --RETURN(1);
		END CATCH
END