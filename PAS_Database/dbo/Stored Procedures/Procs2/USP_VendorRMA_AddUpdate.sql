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
 ** PR   Date         Author  			Change Description            
 ** --   --------     -------			---------------------------     
    1    06/15/2023   Moin Bloch		Created
    2    08/04/2023   Vishal Suthar		Added stockline history
	3    12/16/2024   AMIT GHEDIYA		Add RefrenceNumber in stocktable.
	4    07/23/2024   Vishal Suthar		Updating EnforcePickTicketConfirmation column from VendorRMASettings
	5    02-03-2026	  Amit Ghediya		UOM Conversion Changes [PN-15140]
	6    02-06-2026	  Ayushi Patel		UOM Conversion Changes [PN-16604]
	7	 19/06/2026	  Ayushi			[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
*******************************************************************************/
CREATE    PROCEDURE [dbo].[USP_VendorRMA_AddUpdate]
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
			[Qty] decimal (18, 6),
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
			[Qty] decimal (18, 6) ,
			[MasterCompanyId] INT
		)

		DECLARE @ModuleId INT;
		DECLARE @MasterLoopID AS INT;
		DECLARE @Qty [decimal](18, 6) = 0;
		DECLARE @StockLineId BIGINT,@IsDeleted BIT = 0, @IsTurned BIT = 0;
		DECLARE @StkReserveRefNumber VARCHAR(100) = 'Added Stock - ';
		DECLARE	@StkUnReserveRefNumber VARCHAR(100) = 'Update Stock - ';
		DECLARE	@PNNumber VARCHAR(100) = '';
		DECLARE @StockLineNumber VARCHAR(100) = '';
		DECLARE @StkVendorRMADetailId BIGINT;
		DECLARE	@RefNumber VARCHAR(100) = '';
		DECLARE @EnforcePickTicketConfirmation BIT;

		SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'VendorRMA'; -- For Return Authorization Module

		IF(@VendorRMAId = 0)
		BEGIN
			INSERT INTO [dbo].[VendorRMA]([RMANumber],[VendorId],[OpenDate],[VendorRMAStatusId],[RequestedById],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[Notes])
		    VALUES(@RMANumber,@VendorId,GETUTCDATE(),@VendorRMAStatusId,@RequestedById,@MasterCompanyId,@CreatedBy,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,@Notes);          
			
			SET  @VendorRMAId = @@IDENTITY;
				
			INSERT INTO [dbo].[VendorRMADetail]([VendorRMAId],[RMANum],[StockLineId],[ReferenceId],[ItemMasterId],[SerialNumber],[Qty],[UnitCost],[ExtendedCost]
				,[VendorRMAReturnReasonId],[VendorRMAStatusId],[VendorShippingAddressId],[Notes],[MasterCompanyId],[CreatedBy]
				,[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[QuantityBackOrdered],[QuantityRejected],[ModuleId],[QtyShipped]
				,[ReferenceNumber])
			SELECT @VendorRMAId,[RMANum],VR.[StockLineId],VR.[ReferenceId],VR.[ItemMasterId],VR.[SerialNumber],
			CASE WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'') THEN ISNULL(VR.[Qty],0) ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId]) END,
			CASE WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'') THEN ISNULL(VR.[UnitCost],0) ELSE dbo.fn_ConvertUOM(ISNULL(VR.[UnitCost],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],1,IM.[MasterCompanyId]) END,
			CASE WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'') THEN ISNULL(VR.[ExtendedCost],0) ELSE dbo.fn_ConvertUOM(ISNULL(VR.[ExtendedCost],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],1,IM.[MasterCompanyId]) END,
				 VR.[VendorRMAReturnReasonId],VR.[VendorRMAStatusId],VR.[VendorShippingAddressId],VR.[Notes],@MasterCompanyId,@CreatedBy
				,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
			CASE WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'') THEN ISNULL(VR.[Qty],0) ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId]) END,
			0,VR.[ModuleId],0,
				(@StkReserveRefNumber + ' PN -' + ST.PartNumber + ' StockId -' + ST.StockLineNumber)
			FROM @VendorRMADetail VR
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
			INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId];

			UPDATE [dbo].[Stockline]
			SET [QuantityAvailable] -= (
					CASE 
						WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'')
							THEN ISNULL(VR.[Qty],0)
						ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
					END
				),
				[QuantityReserved] += (
					CASE 
						WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'')
							THEN ISNULL(VR.[Qty],0)
						ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
					END
				),
				[Memo] = 'StockLine Added into RMA ' + VR.RMANum
			FROM @VendorRMADetail VR
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
			INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId]
					
			SELECT @EnforcePickTicketConfirmation = EnforcePickTicketConfirmation FROM DBO.VendorRMASettings WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId;

			UPDATE [dbo].[VendorRMA] SET EnforcePickTicketConfirmation = ISNULL(@EnforcePickTicketConfirmation, 0)
			WHERE VendorRMAId = @VendorRMAId;

			INSERT INTO #tmpReturnVendorRMAId ([VendorRMAId]) VALUES (@VendorRMAId);

			INSERT INTO #tmpReturnVendorRMACreate ([VendorRMADetailId],[Qty],[StockLineId],IsDeleted) 
			SELECT 
				VR.[VendorRMADetailId],
				CASE 
					WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'')
						THEN ISNULL(VR.[Qty],0)
					ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
				END,
				VR.[StockLineId],
				VR.IsDeleted
			FROM @VendorRMADetail VR
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
			INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId];

			SELECT  @MasterLoopID = MAX(ID) FROM #tmpReturnVendorRMACreate
			WHILE(@MasterLoopID > 0)
			BEGIN
				SELECT @StockLineId = [StockLineId], @Qty = [Qty], @StkVendorRMADetailId = [VendorRMADetailId] FROM #tmpReturnVendorRMACreate WHERE [ID] = @MasterLoopID;

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
			SELECT 
				t.[VendorRMADetailId],
				CASE 
					WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'')
						THEN ISNULL(t.[Qty],0)
					ELSE dbo.fn_ConvertUOM(ISNULL(t.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
				END
			FROM @VendorRMADetail t 
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = t.[StockLineId]
			INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId]
			WHERE t.[VendorRMADetailId] > 0 AND t.[IsDeleted] = 0;

			SELECT  @MasterLoopID = MAX(ID) FROM #tmpReturnVendorRMAUpdate
			WHILE(@MasterLoopID > 0)
			BEGIN		
				DECLARE @DiffrenceQty INT = 0;
				DECLARE @RMANum VARCHAR(100) ='';

				SELECT @VendorRMADetailId = [VendorRMADetailId], @Qty = [Qty] FROM #tmpReturnVendorRMAUpdate WHERE [ID] = @MasterLoopID;

				SELECT 
					@OldQty = CASE 
								  WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'')
									  THEN ISNULL(VR.[Qty],0)
								  ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
							  END,
					@StockLineId = VR.[StockLineId],
					@RMANum = [RMANum]
				FROM [dbo].[VendorRMADetail] VR WITH (NOLOCK)
				INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId]
				WHERE VR.[VendorRMADetailId] = @VendorRMADetailId;

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
				  ,[Qty] = CASE 
							  WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'')
								  THEN ISNULL(t.[Qty],0)
							  ELSE dbo.fn_ConvertUOM(ISNULL(t.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
						  END
				  ,[UnitCost] = CASE 
								   WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'')
									   THEN ISNULL(t.[UnitCost],0)
								   ELSE dbo.fn_ConvertUOM(ISNULL(t.[UnitCost],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],1,IM.[MasterCompanyId])
							   END
				  ,[ReferenceNumber] = (@StkUnReserveRefNumber + ' PN -' + ST.PartNumber + ' StockId -' + ST.StockLineNumber)
				  ,[ExtendedCost] = t.[ExtendedCost]
                  ,[UpdatedBy] = t.[UpdatedBy]
                  ,[UpdatedDate] = GETUTCDATE()                  
             FROM @VendorRMADetail t 
			 INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = t.[StockLineId]
			 INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId]
             WHERE t.[VendorRMADetailId] > 0;	

			INSERT INTO [dbo].[VendorRMADetail]([VendorRMAId],[RMANum],[StockLineId],[ReferenceId],[ItemMasterId],[SerialNumber],[Qty],[UnitCost],[ExtendedCost]
											   ,[VendorRMAReturnReasonId],[VendorRMAStatusId],[VendorShippingAddressId],[Notes],[MasterCompanyId],[CreatedBy]
											   ,[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[QuantityBackOrdered],[QuantityRejected],[ModuleId],[QtyShipped]
											   ,[ReferenceNumber])
										 SELECT @VendorRMAId,t.[RMANum],t.[StockLineId],t.[ReferenceId],t.[ItemMasterId],t.[SerialNumber],
											   CASE WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'') THEN ISNULL(t.[Qty],0) ELSE dbo.fn_ConvertUOM(ISNULL(t.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId]) END,
											   CASE WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'') THEN ISNULL(t.[UnitCost],0) ELSE dbo.fn_ConvertUOM(ISNULL(t.[UnitCost],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],1,IM.[MasterCompanyId]) END,
											   CASE WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'') THEN ISNULL(t.[ExtendedCost],0) ELSE dbo.fn_ConvertUOM(ISNULL(t.[ExtendedCost],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],1,IM.[MasterCompanyId]) END,
											   t.[VendorRMAReturnReasonId],t.[VendorRMAStatusId],t.[VendorShippingAddressId],t.[Notes],@MasterCompanyId,@CreatedBy
											   ,GETUTCDATE(),@UpdatedBy,GETUTCDATE(),1,0,
											   CASE WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'') THEN ISNULL([Qty],0) ELSE dbo.fn_ConvertUOM(ISNULL([Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId]) END,
											   0,[ModuleId],0
											   ,(@StkReserveRefNumber + ' PN -' + ST.PartNumber + ' StockId -' + ST.StockLineNumber)
					FROM @VendorRMADetail t 
					INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = t.[StockLineId]
					INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId]
					WHERE t.[VendorRMADetailId] = 0;

			-- Add New Part On Update
			UPDATE [dbo].[Stockline]
			SET [QuantityAvailable] -= (
					CASE 
						WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'')
							THEN ISNULL(VR.[Qty],0)
						ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
					END
				),
				[QuantityReserved] += (
					CASE 
						WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'')
							THEN ISNULL(VR.[Qty],0)
						ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
					END
				),
				[Memo] = 'StockLine Added into RMA ' + VR.RMANum
			FROM @VendorRMADetail VR
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
			INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId]
			WHERE VR.[VendorRMADetailId] = 0;

			-- DELETE PART
			UPDATE [dbo].[Stockline]
			SET [QuantityAvailable] += (
					CASE 
						WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'')
							THEN ISNULL(VR.[Qty],0)
						ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
					END
				),
				[QuantityReserved] -= (
					CASE 
						WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'')
							THEN ISNULL(VR.[Qty],0)
						ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
					END
				),
				[Memo] = 'StockLine DELETED FROM RMA ' + VR.RMANum
			FROM @VendorRMADetail VR
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
			INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId]
			WHERE VR.[VendorRMADetailId] > 0 AND VR.[IsDeleted] = 1;
			
			DELETE FROM #tmpReturnVendorRMACreate;

			INSERT INTO #tmpReturnVendorRMACreate ([VendorRMADetailId],[Qty],[StockLineId],IsDeleted)
			SELECT 
				VR.[VendorRMADetailId],
				CASE 
					WHEN ISNULL(IM.[PurchaseUnitOfMeasure],'') = ISNULL(IM.[StockUnitOfMeasure],'')
						THEN ISNULL(VR.[Qty],0)
					ELSE dbo.fn_ConvertUOM(ISNULL(VR.[Qty],0),IM.[PurchaseUnitOfMeasure],IM.[StockUnitOfMeasure],0,IM.[MasterCompanyId])
				END,
				VR.[StockLineId],
				VR.IsDeleted
			FROM @VendorRMADetail VR
			INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.[StockLineId] = VR.[StockLineId]
			INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON ST.[ItemMasterId] = IM.[ItemMasterId];

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