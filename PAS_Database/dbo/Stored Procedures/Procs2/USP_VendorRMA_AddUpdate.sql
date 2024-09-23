/*************************************************************           
 ** File:   [USP_VendorRMA_AddUpdate]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Add & Update Vendor RMA Details
 ** Date:   06/15/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    06/15/2023   Moin Bloch     Created
    2    08/04/2023   Vishal Suthar  Added stockline history

*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_AddUpdate]
	@VendorRMAId BIGINT,
	@RMANumber VARCHAR(100),
	@VendorId BIGINT,
	@VendorRMAStatusId INT,
	@RequestedById BIGINT,
	@Notes NVARCHAR(MAX) = NULL,
	@CreatedBy VARCHAR(50),
	@UpdatedBy VARCHAR(50),
	@MasterCompanyId INT,
	@VendorRMADetail VendorRMADetailType READONLY
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY    
	BEGIN TRANSACTION
		IF OBJECT_ID(N'tempdb..#tmpReturnVendorRMACreate') IS NOT NULL
		BEGIN
			DROP TABLE #tmpReturnVendorRMACreate
		END
				
		CREATE TABLE #tmpReturnVendorRMACreate
		(
			[ID] INT IDENTITY,
			[VendorRMADetailId] BIGINT NULL,
			[Qty] INT,
			[StockLineId] BIGINT,
			[IsDeleted] BIT NULL,
		)

		IF OBJECT_ID(N'tempdb..#tmpReturnVendorRMAId') IS NOT NULL
		BEGIN
			DROP TABLE #tmpReturnVendorRMAId
		END

		CREATE TABLE #tmpReturnVendorRMAId
		(
			[VendorRMAId] [bigint] NULL
		)

		IF OBJECT_ID(N'tempdb..#tmpReturnVendorRMAUpdate') IS NOT NULL
		BEGIN
			DROP TABLE #tmpReturnVendorRMAUpdate
		END
				
		CREATE TABLE #tmpReturnVendorRMAUpdate
		(
			[ID] INT IDENTITY,
			[VendorRMADetailId] BIGINT NULL,
			[Qty] INT,
			[MasterCompanyId] INT
		)

		DECLARE @ModuleId INT;
		DECLARE @MasterLoopID AS INT;
		DECLARE @Qty INT = 0;
		DECLARE @StockLineId BIGINT,@IsDeleted BIT = 0, @IsTurned BIT = 0;
		SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'VendorRMA'; -- For Return Authorization Module

		IF(@VendorRMAId = 0)
		BEGIN
			INSERT INTO [dbo].[VendorRMA]([RMANumber],[VendorId],[OpenDate],[VendorRMAStatusId],[RequestedById],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[Notes])
		                       VALUES(@RMANumber,@VendorId,GETUTCDATE(),@VendorRMAStatusId,@RequestedById,@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,@Notes);          
			SET  @VendorRMAId = @@IDENTITY;
				
			INSERT INTO [dbo].[VendorRMADetail]([VendorRMAId],[RMANum],[StockLineId],[ReferenceId],[ItemMasterId],[SerialNumber],[Qty],[UnitCost],[ExtendedCost]
										   ,[VendorRMAReturnReasonId],[VendorRMAStatusId],[VendorShippingAddressId],[Notes],[MasterCompanyId],[CreatedBy]
                                           ,[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[QuantityBackOrdered],[QuantityRejected],[ModuleId],[QtyShipped])
							         SELECT @VendorRMAId,[RMANum],[StockLineId],[ReferenceId],[ItemMasterId],[SerialNumber],[Qty],[UnitCost],[ExtendedCost]
										   ,[VendorRMAReturnReasonId],[VendorRMAStatusId],[VendorShippingAddressId],[Notes],@MasterCompanyId,@CreatedBy
                                           ,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,[Qty],0,[ModuleId],0 FROM @VendorRMADetail;

			UPDATE  [dbo].[Stockline]
				SET [QuantityAvailable] -= VR.[Qty],
				    [QuantityReserved] += VR.[Qty]
				   ,[Memo] = 'StockLine Added into RMA ' + VR.RMANum				  
			FROM @VendorRMADetail VR
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
						
			INSERT INTO #tmpReturnVendorRMAId ([VendorRMAId]) VALUES (@VendorRMAId);

			INSERT INTO #tmpReturnVendorRMACreate ([VendorRMADetailId],[Qty],[StockLineId],IsDeleted) 
			SELECT [VendorRMADetailId],[Qty],[StockLineId],IsDeleted FROM @VendorRMADetail;

			SELECT  @MasterLoopID = MAX(ID) FROM #tmpReturnVendorRMACreate
			WHILE(@MasterLoopID > 0)
			BEGIN
				SELECT @StockLineId = [StockLineId], @Qty = [Qty] FROM #tmpReturnVendorRMACreate WHERE [ID] = @MasterLoopID;

				DECLARE @ActionId INT;
				SET @ActionId = 2; -- Reserve
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StockLineId, @ModuleId = @ModuleId, @ReferenceId = @VendorRMAId, @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @ActionId, @Qty = @Qty, @UpdatedBy = @CreatedBy;

				SET @MasterLoopID = @MasterLoopID - 1;
			END

			SELECT * FROM #tmpReturnVendorRMAId;
		END
		ELSE
		BEGIN	
			DECLARE @VendorRMADetailId BIGINT;			
			DECLARE @OldQty INT = 0;
						
			INSERT INTO #tmpReturnVendorRMAUpdate 
			([VendorRMADetailId],[Qty]) 
			SELECT [VendorRMADetailId],[Qty] FROM @VendorRMADetail t 
			WHERE t.[VendorRMADetailId] > 0 AND t.[IsDeleted] = 0;

			SELECT  @MasterLoopID = MAX(ID) FROM #tmpReturnVendorRMAUpdate
			WHILE(@MasterLoopID > 0)
			BEGIN		
				DECLARE @DiffrenceQty INT = 0;
				DECLARE @RMANum VARCHAR(100) ='';

				SELECT @VendorRMADetailId = [VendorRMADetailId], @Qty = [Qty] FROM #tmpReturnVendorRMAUpdate WHERE [ID] = @MasterLoopID;

				SELECT @OldQty = [Qty], @StockLineId = [StockLineId], @RMANum = [RMANum] FROM [dbo].[VendorRMADetail] WITH (NOLOCK) WHERE [VendorRMADetailId] = @VendorRMADetailId;

				IF((@Qty > @OldQty) AND @IsTurned = 0)
				BEGIN
				    SET @IsTurned  =1;
					SET @DiffrenceQty = @Qty - @OldQty ;
						UPDATE [dbo].[Stockline] 
						SET [QuantityAvailable] -= @DiffrenceQty,
						    [QuantityReserved]  += @DiffrenceQty,
							[Memo] = 'StockLine Qty Updated FROM RMA ' + @RMANum
						WHERE [StockLineId] = @StockLineId;

					   SET @ActionId = 2; -- Reserve
					   EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StockLineId, @ModuleId = @ModuleId, @ReferenceId = @VendorRMAId, @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @ActionId, @Qty = @DiffrenceQty, @UpdatedBy = @UpdatedBy;
				END
				ELSE IF((@Qty < @OldQty) AND @IsTurned = 0)
				BEGIN
						SET @IsTurned  =1;
						SET @DiffrenceQty = @OldQty - @Qty;

						UPDATE [dbo].[Stockline] 
						SET [QuantityAvailable] += @DiffrenceQty,
							[QuantityReserved]  -= @DiffrenceQty,
							[Memo] = 'StockLine Qty Updated FROM RMA ' + @RMANum
						WHERE [StockLineId] = @StockLineId;

					   SET @ActionId = 3; -- UnReserve
					   EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StockLineId, @ModuleId = @ModuleId, @ReferenceId = @VendorRMAId, @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @ActionId, @Qty = @DiffrenceQty, @UpdatedBy = @UpdatedBy;
				END

				SET @MasterLoopID = @MasterLoopID - 1;				
			END
			
			UPDATE [dbo].[VendorRMA] SET [RMANumber] = @RMANumber,[Notes] = @Notes WHERE [VendorRMAId] = @VendorRMAId;

			UPDATE [dbo].[VendorRMADetail]
			   SET [RMANum] = t.[RMANum]          
                  ,[VendorRMAReturnReasonId] = t.[VendorRMAReturnReasonId]              
                  ,[VendorShippingAddressId] = t.[VendorShippingAddressId]
                  ,[Notes] = t.[Notes]   
				  ,[Qty] = t.[Qty]
				  ,[UnitCost] = t.[UnitCost]
				  ,[ExtendedCost] = t.[ExtendedCost]
                  ,[UpdatedBy] = t.[UpdatedBy]
                  ,[UpdatedDate] = GETUTCDATE()                  
             FROM @VendorRMADetail t 
			 INNER JOIN [dbo].[VendorRMADetail] vc WITH (NOLOCK) ON vc.[VendorRMADetailId] = t.[VendorRMADetailId]
             WHERE t.[VendorRMADetailId] > 0;	

			INSERT INTO [dbo].[VendorRMADetail]([VendorRMAId],[RMANum],[StockLineId],[ReferenceId],[ItemMasterId],[SerialNumber],[Qty],[UnitCost],[ExtendedCost]
										   ,[VendorRMAReturnReasonId],[VendorRMAStatusId],[VendorShippingAddressId],[Notes],[MasterCompanyId],[CreatedBy]
                                           ,[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[QuantityBackOrdered],[QuantityRejected],[ModuleId],[QtyShipped])
							         SELECT @VendorRMAId,[RMANum],[StockLineId],[ReferenceId],[ItemMasterId],[SerialNumber],[Qty],[UnitCost],[ExtendedCost]
										   ,[VendorRMAReturnReasonId],[VendorRMAStatusId],[VendorShippingAddressId],[Notes],@MasterCompanyId,@CreatedBy
                                           ,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,[Qty],0,[ModuleId],0 FROM @VendorRMADetail t WHERE t.[VendorRMADetailId] = 0;
			-- Add New Part On Update
	        UPDATE  [dbo].[Stockline]
				SET [QuantityAvailable] -= VR.[Qty],
				    [QuantityReserved] += VR.[Qty]
				   ,[Memo] = 'StockLine Added into RMA ' + VR.RMANum				  
			FROM @VendorRMADetail VR
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
			WHERE VR.[VendorRMADetailId] = 0;

			-- DELETE PART
		    UPDATE  [dbo].[Stockline] 
				SET [QuantityAvailable] += VR.[Qty], 
				    [QuantityReserved] -= VR.[Qty]
				   ,[Memo] = 'StockLine DELETED FROM RMA ' + VR.RMANum	
			FROM @VendorRMADetail VR
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
			WHERE VR.[VendorRMADetailId] > 0 AND VR.[IsDeleted] = 1;
			
			DELETE FROM #tmpReturnVendorRMACreate;

			INSERT INTO #tmpReturnVendorRMACreate ([VendorRMADetailId],[Qty],[StockLineId],IsDeleted) 
			SELECT [VendorRMADetailId],[Qty],[StockLineId],IsDeleted FROM @VendorRMADetail;

			SELECT  @MasterLoopID = MAX(ID) FROM #tmpReturnVendorRMACreate
			WHILE(@MasterLoopID > 0)
			BEGIN
			IF(@IsTurned  =0)
				BEGIN
					SELECT @StockLineId = [StockLineId], @Qty = [Qty],@IsDeleted = ISNULL(IsDeleted,0) FROM #tmpReturnVendorRMACreate WHERE [ID] = @MasterLoopID;
					SET @ActionId = (CASE WHEN @IsDeleted = 1 THEN 3 ELSE 2 END); -- 2 = Reserve, 3= UnReserve
					EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StockLineId, @ModuleId = @ModuleId, @ReferenceId = @VendorRMAId, @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @ActionId, @Qty = @Qty, @UpdatedBy = @CreatedBy;

				END		
				SET @MasterLoopID = @MasterLoopID - 1;
			END

		    DELETE FROM [dbo].[VendorRMADetail] WHERE [VendorRMADetailId] IN (SELECT [VendorRMADetailId] FROM @VendorRMADetail t WHERE t.[VendorRMADetailId] > 0 AND t.[IsDeleted] = 1)			
		END
	COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRANSACTION;
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_VendorRMA_AddUpdate]'			
			,@ProcedureParameters VARCHAR(3000) = '@VendorRMAId = ''' + CAST(ISNULL(@VendorRMAId, '') AS varchar(100))				 
            ,@ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END