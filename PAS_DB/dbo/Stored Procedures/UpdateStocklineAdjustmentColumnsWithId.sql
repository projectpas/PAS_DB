
/*************************************************************           
 ** File:   [UpdateStocklineColumnsWithId]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Update Stockline Details based on Stockline Id.    
 ** Purpose:         
 ** Date:    05/07/2021       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/07/2021   Subhash Saliya Created
	2    07/11/2021   Hemant Saliya  Update Warehouse Id Update Condition
     
--EXEC [UpdateStocklineColumnsWithId] 15, 1
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateStocklineAdjustmentColumnsWithId]
	@StocklineAdjustmentId bigint,
	@AdjustmentDataTypeId int

AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @ManagmnetStructureId as BIGINT
	DECLARE @ManagmnetStructureId1 as BIGINT

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
				IF(@AdjustmentDataTypeId =1)
				BEGIN			
					SELECT @ManagmnetStructureId = ISNULL(ChangedTo,0), @ManagmnetStructureId1 = ISNULL(ChangedFrom,0) FROM [dbo].[StocklineAdjustment] WITH(NOLOCK) WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId

					UPDATE dbo.[StocklineAdjustment] 
					 SET ChangedTo=(SELECT LastMSName FROM DBO.udfGetAllEntityMSLevelString(@ManagmnetStructureId)),
							ChangedFrom=(SELECT LastMSName FROM DBO.udfGetAllEntityMSLevelString(@ManagmnetStructureId1))
					 FROM [dbo].[StocklineAdjustment] WITH(NOLOCK) 
					 WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId
				END

				IF(@AdjustmentDataTypeId =2)
				BEGIN
					UPDATE SL SET 
						SL.ChangedTo = S.Name
					FROM [dbo].[StocklineAdjustment] SL WITH(NOLOCK)
						INNER JOIN dbo.Site S WITH(NOLOCK) ON S.SiteId =  CAST(ISNULL(SL.ChangedTo,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId

					UPDATE SL SET 
						SL.ChangedFrom = S.Name
					FROM [dbo].[StocklineAdjustment] SL WITH(NOLOCK)
						INNER JOIN dbo.Site S WITH(NOLOCK) ON S.SiteId =  CAST(ISNULL(SL.ChangedFrom,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId
				END

				IF(@AdjustmentDataTypeId =3)
				BEGIN
					UPDATE SL SET 
						SL.ChangedTo = W.Name
					FROM [dbo].[StocklineAdjustment] SL WITH(NOLOCK)
						INNER JOIN dbo.Warehouse W WITH(NOLOCK) ON W.WarehouseId = CAST(ISNULL(SL.ChangedTo,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId

					UPDATE SL SET 
						SL.ChangedFrom = W.Name
					FROM [dbo].[StocklineAdjustment] SL WITH(NOLOCK)
						INNER JOIN dbo.Warehouse W WITH(NOLOCK) ON W.WarehouseId = CAST(ISNULL(SL.ChangedFrom,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId
				END

				IF(@AdjustmentDataTypeId =4)
				BEGIN
					UPDATE SL SET 
						SL.ChangedTo = L.Name
					FROM [dbo].[StocklineAdjustment] SL
						INNER JOIN dbo.Location L ON L.LocationId =  CAST(ISNULL(SL.ChangedTo,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId

					UPDATE SL SET 
						SL.ChangedFrom = L.Name
					FROM [dbo].[StocklineAdjustment] SL WITH(NOLOCK)
						INNER JOIN dbo.Location L WITH(NOLOCK) ON L.LocationId =  CAST(ISNULL(SL.ChangedFrom,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId
				END

				IF(@AdjustmentDataTypeId =5)
					BEGIN
					UPDATE SL SET 
						SL.ChangedTo = S.Name
					FROM [dbo].[StocklineAdjustment] SL WITH(NOLOCK)
						INNER JOIN dbo.Shelf S WITH(NOLOCK) ON S.ShelfId =  CAST(ISNULL(SL.ChangedTo,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId

					UPDATE SL SET 
						SL.ChangedFrom = S.Name
					FROM [dbo].[StocklineAdjustment] SL WITH(NOLOCK)
						INNER JOIN dbo.Shelf S WITH(NOLOCK) ON S.ShelfId = CAST(ISNULL(SL.ChangedFrom,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId
				END

				IF(@AdjustmentDataTypeId =6)
				BEGIN
					UPDATE SL SET 
						SL.ChangedTo = B.Name
					FROM [dbo].[StocklineAdjustment] SL WITH(NOLOCK)
						INNER JOIN dbo.Bin B WITH(NOLOCK) ON B.BinId =  CAST(ISNULL(SL.ChangedTo,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId

					UPDATE SL SET 
						SL.ChangedFrom = B.Name
					FROM [dbo].[StocklineAdjustment] SL WITH(NOLOCK)
						INNER JOIN dbo.Bin B WITH(NOLOCK) ON B.BinId = CAST(ISNULL(SL.ChangedFrom,0) as bigint)
					WHERE StocklineAdjustmentId=@StocklineAdjustmentId AND StocklineAdjustmentDataTypeId=@AdjustmentDataTypeId
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
              , @AdhocComments     VARCHAR(150)    = 'UpdateStocklineAdjustmentColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@StocklineAdjustmentId, '') + ''',
			                                           @Parameter2 = ' + ISNULL(@AdjustmentDataTypeId,'') +''
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