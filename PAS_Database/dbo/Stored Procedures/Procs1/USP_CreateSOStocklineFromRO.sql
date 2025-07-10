/*************************************************************           
 ** File:   [USP_CreateSOStocklineFromRO]          
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Crate A Stockline from SO Parts
 ** Purpose:         
 ** Date:   08/25/2021        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    08/25/2021   Vishal Suthar		Created
    2    12/09/2021   Vishal Suthar		Added a condition such that it will execute only if Sales Order Number is selected in the part
	3    06/12/2023   Amit Ghediya		Select a conditionId from STK for REVISED PART & Add into SOStk from RO.
	4    08/18/2023   Devendra Shekh	added UnitSalesPricePerUnit for salesorder part insert
	5    12/29/2023   Vishal Suthar		Fixed and issue with PN-6393 Requested Qty not increasing when RO stockline added into same part with condition
    6	 11/27/2024   Amit Ghediya		Update for get Eccn,Hscode & WLH for SoPart.
	7	 11/29/2024	  Abhishek Jirawla  Adding a condition where the QtyOrder is taken from Stockline.
	8    12/13/2024   AMIT GHEDIYA		Add RefrenceNumber in stocktable for SO.
	9	 05/05/2025	  Abhishek Jirawla  Updated the unit cost to the new stockline cost(including repair order).
	10	 05/30/2025	  Abhishek Jirawla  Updated the condition to the new stockline.
	11	 06/18/2025   AMIT GHEDIYA		Updated the sp USP_UpdateSOPartCostDetails for SalesOrderPartV1 table.
	12	 06/23/2025   Vishal Suthar		Handle the case of having the same stockline after repair
	13	 10/Jul/2025  Rajesh Gami		Fixed: Added the Stockline History while reserve the stockline in the SO (Create RO from the SO and then receive the RO that time history not inserted)
 EXECUTE USP_CreateSOStocklineFromRO 2667

**************************************************************/
CREATE    PROCEDURE [dbo].[USP_CreateSOStocklineFromRO] 
(
	@RepairOrderId bigint = NULL
)
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN
        DECLARE @RowCount int = 0;
        DECLARE @StocklineId bigint;
        DECLARE @Quantity int = 0;
        DECLARE @QtyFulfilled int = 0;
        DECLARE @SalesOrderPartId bigint = 0;
		DECLARE @SalesOrderStockLineId BIGINT = 0;
        DECLARE @ExSalesOrderPartId bigint;
        DECLARE @ExSalesOrderStocklineId bigint;
        DECLARE @MasterCompanyId int;
        DECLARE @SalesOrderId bigint;
        DECLARE @LoopID AS int;
		DECLARE @MasterLoopID AS INT;
		DECLARE @RepairOrderPartId BIGINT;
		DECLARE @StlQuantity BIGINT;
		DECLARE @soPartFulfilledStatusId INT = (SELECT SOPartStatusId FROM DBO.SOPartStatus WITH(NOLOCK) WHERE Description = 'Fulfilled');
		DECLARE @StkAutoReserveRefNumber VARCHAR(100) = 'Auto Reserve Stock - ';
		DECLARE @RPUpdatedBy VARCHAR(256) = '';
		DECLARE @RefNumber VARCHAR(100) = '';
		DECLARE @UpdatedConditionId BIGINT;
		DECLARE @SOModuleId INT = (SELECT TOP 1 ModuleId FROM Dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
        IF OBJECT_ID(N'tempdb..#ROStockLineSamePart') IS NOT NULL
        BEGIN
          DROP TABLE #ROStockLineSamePart
        END

        IF OBJECT_ID(N'tempdb..#ROStockLineRevisedPart') IS NOT NULL
        BEGIN
          DROP TABLE #ROStockLineRevisedPart
        END

        CREATE TABLE #ROStockLineSamePart (
          ID bigint NOT NULL IDENTITY,
          ItemMasterId bigint NULL,
          ConditionId bigint NULL,
          StockLineId bigint NULL,
          OldStockLineId bigint NULL,
          SalesOrderId bigint NULL,
          RepairOrderId bigint NULL,
          MasterCompanyId int NULL,
          RepairOrderNumber varchar(500) NULL
        )

        CREATE TABLE #ROStockLineRevisedPart (
          ID bigint NOT NULL IDENTITY,
          ItemMasterId bigint NULL,
          ConditionId bigint NULL,
          StockLineId bigint NULL,
          OldStockLineId bigint NULL,
          SalesOrderId bigint NULL,
          RepairOrderId bigint NULL,
          MasterCompanyId int NULL,
          RepairOrderNumber varchar(500) NULL
        )

		IF OBJECT_ID(N'tempdb..#RepairOrderPartData') IS NOT NULL
        BEGIN
			DROP TABLE #RepairOrderPartData
        END

        CREATE TABLE #RepairOrderPartData (
          ID int IDENTITY,
          RepairOrderPartID bigint
        )

		IF OBJECT_ID(N'tempdb..#SalesOrderPartDetails') IS NOT NULL
        BEGIN
          DROP TABLE #SalesOrderPartDetails
        END

        CREATE TABLE #SalesOrderPartDetails (
          ID bigint NOT NULL IDENTITY,
          SalesOrderPartId bigint NULL
        )

        INSERT INTO #RepairOrderPartData (RepairOrderPartID) SELECT RepairOrderPartRecordId FROM [dbo].[RepairOrderPart] RP WITH (NOLOCK) WHERE RP.RepairOrderId = @RepairOrderId and RP.ItemTypeId=1
        
		SELECT @MasterLoopID = MAX(ID) FROM #RepairOrderPartData
        
		WHILE (@MasterLoopID > 0)
        BEGIN
          IF OBJECT_ID(N'tempdb..#StockLine') IS NOT NULL
          BEGIN
            DROP TABLE #StockLine
          END

          IF OBJECT_ID(N'tempdb..#StockLineData') IS NOT NULL
          BEGIN
            DROP TABLE #StockLineData
          END

          CREATE TABLE #StockLineData (
            ID int IDENTITY,
            StockLineID bigint
          )

		  SELECT @RepairOrderPartId = RepairOrderPartID FROM #RepairOrderPartData WHERE ID  = @MasterLoopID
          
		  IF((SELECT COUNT(1) FROM [dbo].[Stockline] SL WITH(NOLOCK) WHERE SL.RepairOrderId = @RepairOrderId  AND IsParent = 1 
		  AND Sl.QuantityAvailable > 0 AND SL.RepairOrderPartRecordId = @RepairOrderPartId) > 0)
		  BEGIN
			SELECT * INTO #StockLine FROM [dbo].[Stockline] SL WITH (NOLOCK) WHERE SL.RepairOrderId = @RepairOrderId
			AND SL.RepairOrderPartRecordId = @RepairOrderPartId
            AND IsParent = 1 AND Sl.QuantityAvailable > 0

			INSERT INTO #StockLineData (StockLineID) SELECT StockLineID FROM #StockLine
		  END

		  SELECT TOP 1 @UpdatedConditionId = SD.ConditionId FROM [dbo].[StocklineDraft] SD WITH (NOLOCK)
			LEFT JOIN [dbo].[RepairOrderPart] RP WITH (NOLOCK) ON RP.RepairOrderId = SD.RepairOrderId
			WHERE RP.RepairOrderId = @RepairOrderId

		  SELECT @Quantity = SOPS.QtyOrder, @SalesOrderId = SOP.SalesOrderId, @MasterCompanyId = SOPS.MasterCompanyId, @RPUpdatedBy = RP.UpdatedBy
			FROM [dbo].[RepairOrderPart] RP WITH (NOLOCK)
			LEFT JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) ON RP.StockLineId = SOPS.StocklineId
			LEFT JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOP.SalesOrderPartId
			WHERE RP.RepairOrderId = @RepairOrderId
			AND RP.RepairOrderPartRecordId = @RepairOrderPartId  AND RP.ItemTypeId=1

		  SET @QtyFulfilled = @Quantity;

		  IF((SELECT COUNT(1) FROM [dbo].[RepairOrderPart] RP WITH(NOLOCK) WHERE RP.RepairOrderPartRecordId = @RepairOrderPartId AND RP.ItemTypeId=1 AND ISNULL(RP.SalesOrderId, 0) > 0) > 0)
		  BEGIN
		  
		  SELECT @LoopID = MAX(ID) FROM #StockLineData
		  WHILE (@LoopID > 0)
          BEGIN
            SELECT @StocklineId = StocklineId FROM #StockLineData WHERE ID = @LoopID;

            IF (@QtyFulfilled > 0)
            BEGIN
              IF ((SELECT COUNT(1) FROM [dbo].[RepairOrderPart] RP WITH (NOLOCK) JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId WHERE RP.ItemTypeId=1 AND ISNULL(RP.RevisedPartId, 0) > 0 AND SL.StockLineId = @StocklineId) > 0 )
              BEGIN
				DELETE FROM #ROStockLineRevisedPart
                --CASE 1 REVISED PART
				PRINT 'REVISED PART'
                INSERT INTO #ROStockLineRevisedPart (ItemMasterId, ConditionId, SalesOrderId, RepairOrderId, RepairOrderNumber, StockLineId, OldStockLineId)
                  SELECT DISTINCT TOP 1
                    RP.RevisedPartId,
                    SL.ConditionId,
                    RP.SalesOrderId,
                    RP.RepairOrderId,
                    RO.RepairOrderNumber,
                    SL.StockLineId,
                    RP.StockLineId
                  FROM [dbo].[RepairOrderPart] RP WITH (NOLOCK)
                  JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON RP.RevisedPartId = IM.ItemMasterId
                  JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON RO.RepairOrderId = RP.RepairOrderId
                  JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId
                  WHERE SL.StockLineId = @StocklineId and RP.ItemTypeId = 1

				SET @SalesOrderPartId = 0;

				SELECT @SalesOrderPartId = ISNULL(SalesOrderPartId, 0) FROM [dbo].[SalesOrderPartV1] SOP WITH(NOLOCK) 
						JOIN #ROStockLineRevisedPart ROS ON ROS.SalesOrderId = SOP.SalesOrderId
				WHERE ROS.ConditionId = SOP.ConditionId AND ROS.ItemMasterId = SOP.ItemMasterId

				SET @SalesOrderPartId = ISNULL(@SalesOrderPartId, 0);

                IF ((SELECT COUNT(1) FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE [SalesOrderPartId] = ISNULL(@SalesOrderPartId, 0)) = 0)
                BEGIN
					INSERT INTO [dbo].[SalesOrderPartV1] ([SalesOrderId],[ItemMasterId],[ConditionId],[QtyRequested],[QtyOrder],[QtyReserved],[CurrencyId],
					[PriorityId],[StatusId],[FxRate],[CustomerRequestDate],[PromisedDate],[EstimatedShipDate],[POId],[PONumber],[PONextDlvrDate],[Notes],
					[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[OldSalesOrderPartId],[PartNumber],[PartDescription],
					[ConditionName],[CurrencyName],[PriorityName],[StatusName],[SalesOrderQuotePartId],[LotId],[IsLotAssigned],
					[ECCN],[HSCODE],[Weight],[SizeLength],[SizeWidth],[SizeHeight])
					SELECT DISTINCT
                      ROS.SalesOrderId,
                      SL.ItemMasterId,
					  ROS.ConditionId,
					  @Quantity,
					  CASE
                        WHEN SL.QuantityAvailable > @Quantity THEN @Quantity
                        ELSE SL.QuantityAvailable
                      END,
					  CASE
                        WHEN SL.QuantityAvailable > @Quantity THEN @Quantity
                        ELSE SL.QuantityAvailable
                      END,
					  SOP.CurrencyId,
					  SOP.PriorityId,
                      @soPartFulfilledStatusId,
					  1.0000,
					  SOP.CustomerRequestDate,
                      SOP.PromisedDate,
                      SOP.EstimatedShipDate,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  SOP.MasterCompanyId,
                      SOP.CreatedBy,
                      GETUTCDATE(),
                      SOP.UpdatedBy,
                      GETUTCDATE(),
					  1,
					  0,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  NULL,
					  ime.[ExportECCN],
					  ime.[HSCODE],
					  ime.[ExportWeight],
					  ime.[ExportSizeLength],
					  ime.[ExportSizeWidth],
					  ime.[ExportSizeHeight]
                    FROM #ROStockLineRevisedPart ROS WITH (NOLOCK)
                    JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
                    JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.ItemMasterId = IM.ItemMasterId
                    JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) ON SOPS.StockLineId = ROS.OldStockLineId
                    JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId
					LEFT JOIN [dbo].[ItemMasterExportInfo] ime WITH (NOLOCK) ON ime.ItemMasterId = IM.ItemMasterId
					AND SL.IsParent = 1 AND SOP.SalesOrderId = @SalesOrderId
                    WHERE SL.StockLineId = @StocklineId;

					SELECT @SalesOrderPartId = SCOPE_IDENTITY()

					INSERT INTO #SalesOrderPartDetails (SalesOrderPartId) SELECT @SalesOrderPartId

					SELECT * FROM #SalesOrderPartDetails;

					INSERT INTO [dbo].[SalesOrderReserveParts]
								   ([SalesOrderId]
								   ,[StockLineId]
								   ,[ItemMasterId]
								   ,[PartStatusId]
								   ,[IsEquPart]
								   ,[EquPartMasterPartId]
								   ,[IsAltPart]
								   ,[AltPartMasterPartId]
								   ,[QtyToReserve]
								   ,[QtyToIssued]
								   ,[ReservedById]
								   ,[ReservedDate]
								   ,[IssuedById]
								   ,[IssuedDate]
								   ,[CreatedBy]
								   ,[CreatedDate]
								   ,[UpdatedBy]
								   ,[UpdatedDate]
								   ,[IsActive]
								   ,[IsDeleted]
								   ,[SalesOrderPartId]
								   ,[TotalReserved]
								   ,[TotalIssued]
								   ,[MasterCompanyId])
							 SELECT SOP.SalesOrderId, SOPS.StockLineId, SOP.ItemMasterId, 1,
							 0, NULL, 0, NULL, SOPS.QtyOrder, 0, 
							 (SELECT TOP 1 EmployeeId FROM [dbo].[Employee] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId ORDER BY EmployeeId),
							 GETDATE(), NULL, GETDATE(), SOP.CreatedBy, GETDATE(),SOP.UpdatedBy, GETDATE(), 1, 0, @SalesOrderPartId, 
							 SOP.QtyOrder, 0, @MasterCompanyId
							 FROM [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) 
							 LEFT JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId
							 WHERE SOPS.SalesOrderPartId = @SalesOrderPartId

					INSERT INTO [dbo].[SalesOrderReservedStock]
								([SalesOrderId]
								,[SalesOrderPartId]
								,[StockLIneId]
								,[ConditionId]
								,[ItemMasterId]
								,[Quantity]
								,[AltPartMasterPartId]
								,[EquPartMasterPartId]
								,[IsAltPart]
								,[IsEquPart]
								,[ReservedById]
								,[ReservedDate]
								,[MasterCompanyId]
								,[CreatedBy]
								,[UpdatedBy]
								,[CreatedDate]
								,[UpdatedDate]
								,[IsActive]
								,[IsDeleted])
						SELECT SOP.SalesOrderId, @SalesOrderPartId, SOPS.StockLineId, SOP.ConditionId,
						SOP.ItemMasterId, SOPS.QtyOrder, NULL, NULL, 0, 0,
						(SELECT TOP 1 EmployeeId FROM [dbo].[Employee] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId ORDER BY EmployeeId),
						GETDATE(), @MasterCompanyId, SOP.CreatedBy, SOP.UpdatedBy, GETDATE(), GETDATE(), 1, 0
						FROM [dbo].[SalesOrderStocklineV1] SOPS WITH(NOLOCK) 
						LEFT JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId
						WHERE SOP.SalesOrderPartId = @SalesOrderPartId

					INSERT INTO [dbo].[SalesOrderStockLine]
									([SalesOrderId]
									,[SalesOrderPartId]
									,[StockLIneId]
									,[ItemMasterId]
									,[ConditionId]
									,[Quantity]
									,[QtyReserved]
									,[QtyIssued]
									,[AltPartMasterPartId]
									,[EquPartMasterPartId]
									,[IsAltPart]
									,[IsEquPart]
									,[UnitCost]
									,[ExtendedCost]
									,[UnitPrice]
									,[ExtendedPrice]
									,[MasterCompanyId]
									,[CreatedBy]
									,[UpdatedBy]
									,[CreatedDate]
									,[UpdatedDate]
									,[IsActive]
									,[IsDeleted])
								SELECT SOP.SalesOrderId, @SalesOrderPartId, SOPS.StockLineId, SOP.ItemMasterId, COALESCE(@UpdatedConditionId, SOP.ConditionId),
								SOPS.QtyOrder, SOPS.QtyOrder, 0, NULL, NULL, 0, 0, 0.00, 0.00, 0.00, 0.00, @MasterCompanyId,
								SOP.CreatedBy, SOP.UpdatedBy, GETDATE(), GETDATE(), 1, 0
								FROM [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) 
								LEFT JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId
								Where SOP.SalesOrderPartId = @SalesOrderPartId

					SELECT @StlQuantity = SOP.QtyOrder FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderPartId = @SalesOrderPartId
					UPDATE [dbo].[Stockline] SET [QuantityAvailable] = QuantityAvailable - @StlQuantity, [QuantityReserved] = @StlQuantity WHERE StockLineId = @StocklineId

					UPDATE SD SET SOQty = @StlQuantity,ForStockQty =  SL.Quantity - @StlQuantity
				    FROM [dbo].[StocklineDraft] SD  LEFT JOIN [dbo].[Stockline] SL ON SD.StockLineId = SL.StockLineId WHERE SL.StockLineId = @StocklineId;

                END

                SELECT @QtyFulfilled SET @QtyFulfilled = @QtyFulfilled - (SELECT SUM(ISNULL(QtyOrder,0)) FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) 
				WHERE [SalesOrderPartId] IN (SELECT SalesOrderPartId FROM #SalesOrderPartDetails))

                SELECT @ExSalesOrderPartId = SOP.SalesOrderPartId 
				FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK)
                JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOP.SalesOrderPartId
                JOIN [dbo].[RepairOrderPart] RP WITH (NOLOCK) ON RP.StockLineId = SOPS.StocklineId
                WHERE RP.RepairOrderId = @RepairOrderId AND RP.RepairOrderPartRecordId = @RepairOrderPartId
				AND SOP.SalesOrderId = @SalesOrderId AND RP.ItemTypeId=1

				DECLARE @NewCndId BIGINT = 0,@NewItmId BIGINT = 0;

				SELECT @NewCndId = [ConditionId],@NewItmId = [ItemMasterId] FROM [dbo].[SalesOrderPartV1] WITH(NOLOCK) WHERE [SalesOrderPartId] = @SalesOrderPartId;

                IF (@QtyFulfilled <= 0)
                BEGIN
                  DELETE SOSTL FROM [dbo].[SalesOrderStockLineV1] SOSTL WHERE SOSTL.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOA   FROM [dbo].[SalesOrderApproval] SOA WHERE SOA.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SORS  FROM [dbo].[SalesOrderReservedStock] SORS WHERE SORS.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOPM  FROM [dbo].[SOPartsMapping] SOPM WHERE SOPM.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SORP  FROM [dbo].[SalesOrderReserveParts] SORP WHERE SORP.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOURP FROM [dbo].[SalesOrderUnReservedStock] SOURP WHERE SOURP.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOP   FROM [dbo].[SalesOrderPartV1] SOP WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId;
				  
				  -- UPDATE NEWLY CREATED [SalesOrderPartId] IN FREIGHT & CHARGES

				  UPDATE [dbo].[SalesOrderFreight] 
					 SET [SalesOrderPartId] = @SalesOrderPartId,
						 [ConditionId] = @NewCndId,
						 [ItemMasterId] = @NewItmId
				   WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;

				  UPDATE [dbo].[SalesOrderCharges] 
					 SET [SalesOrderPartId] = @SalesOrderPartId,
					     [ConditionId] = @NewCndId,
						 [ItemMasterId] = @NewItmId
				   WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;

                END

                IF ((SELECT COUNT(1) FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE [SalesOrderPartId] = @ExSalesOrderPartId) = 0)
                BEGIN
                  DELETE SOSTL FROM [dbo].[SalesOrderStockLineV1] SOSTL WHERE SOSTL.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOA   FROM [dbo].[SalesOrderApproval] SOA WHERE SOA.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SORS  FROM [dbo].[SalesOrderReservedStock] SORS WHERE SORS.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOPM  FROM [dbo].[SOPartsMapping] SOPM WHERE SOPM.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SORP  FROM [dbo].[SalesOrderReserveParts] SORP WHERE SORP.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOURP FROM [dbo].[SalesOrderUnReservedStock] SOURP WHERE SOURP.SalesOrderPartId = @ExSalesOrderPartId;
                  DELETE SOP   FROM [dbo].[SalesOrderPartV1] SOP WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId;

				  -- UPDATE NEWLY CREATED [SalesOrderPartId] IN FREIGHT & CHARGES

				  UPDATE [dbo].[SalesOrderFreight] 
					 SET [SalesOrderPartId] = @SalesOrderPartId,
					     [ConditionId] = @NewCndId,
						 [ItemMasterId] = @NewItmId
				   WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;

				  UPDATE [dbo].[SalesOrderCharges] 
					 SET [SalesOrderPartId] = @SalesOrderPartId,
					     [ConditionId] = @NewCndId,
						 [ItemMasterId] = @NewItmId
				   WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;
                END

              END
              ELSE
              BEGIN
                --CASE 2 SAME AS PART
				PRINT 'SAME AS PART'
                INSERT INTO #ROStockLineSamePart (ItemMasterId, ConditionId, StockLineId, OldStockLineId, SalesOrderId, RepairOrderId, MasterCompanyId, RepairOrderNumber)
                  SELECT DISTINCT TOP 1
                    RP.ItemMasterId,
                    RP.ConditionId,
                    SL.StockLineId,
                    RP.StockLineId,
                    RP.SalesOrderId,
                    RP.RepairOrderId,
                    RP.MasterCompanyId,
                    RO.RepairOrderNumber
                  FROM dbo.RepairOrderPart RP WITH (NOLOCK)
                  JOIN #StockLine SL ON RP.RepairOrderPartRecordId = SL.RepairOrderPartRecordId
                  JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON RP.ItemMasterId = IM.ItemMasterId --AND RP.ConditionId = SL.ConditionId
                  JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON RO.RepairOrderId = RP.RepairOrderId
                  WHERE SL.StockLineId = @StocklineId AND RP.ItemTypeId=1

                IF ((SELECT COUNT(1) FROM #ROStockLineSamePart WITH (NOLOCK) WHERE ISNULL(SalesOrderId, 0) > 0) > 0)
                BEGIN
				
					DECLARE @OldConditionId BIGINT = 0;
					DECLARE @NewConditionId BIGINT = 0;
					DECLARE @OldItemMasterId BIGINT = 0;
					DECLARE @NewItemMasterId BIGINT = 0;
					DECLARE @NewSalesOrderPartId BIGINT = 0;
					DECLARE @NewSalesOrderStocklineId BIGINT = 0;
					DECLARE @UnitCost DECIMAL(20, 2) = 0;
					DECLARE @NewQtyRequested INT = 0;
					DECLARE @SalesOrderNumber VARCHAR(100) = NULL;
					DECLARE @RepairOrderNumber VARCHAR(100) = NULL;

					--Get SalesOrderNumber for RefrenceNumber
					SELECT @SalesOrderNumber = [SalesOrderNumber] FROM [DBO].[SalesOrder] WITH(NOLOCK) WHERE [SalesOrderId] = @SalesOrderId;	

					--Get RepairOrderNumber for RefrenceNumber
					SELECT TOP 1 @RepairOrderNumber = RepairOrderNumber FROM #ROStockLineSamePart;

					--Set RefrenceNumber
					SET @RefNumber = @StkAutoReserveRefNumber + @RepairOrderNumber + ' To ' + @SalesOrderNumber;

					SELECT @ExSalesOrderPartId = SOP.SalesOrderPartId,
					@ExSalesOrderStocklineId = SOS.SalesOrderStocklineId
					FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK)
					LEFT JOIN [dbo].[SalesOrderStocklineV1] SOS WITH (NOLOCK) ON SOS.SalesOrderPartId = SOP.SalesOrderPartId
					JOIN [dbo].[RepairOrderPart] RP WITH (NOLOCK) ON RP.StockLineId = SOS.StocklineId
					WHERE RP.RepairOrderId = @RepairOrderId AND RP.RepairOrderPartRecordId = @RepairOrderPartId 
					AND SOP.SalesOrderId = @SalesOrderId AND RP.ItemTypeId=1
					
					DECLARE @TotalQty INT,@SoId BIGINT,@RevQty INT

					IF NOT EXISTS (SELECT TOP 1 1 FROM DBO.SalesOrderStocklineV1 WITH (NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId AND StockLineId = @StockLineId)
					BEGIN
						INSERT INTO DBO.SalesOrderStocklineV1 (SalesOrderPartId,StockLineId,ConditionId,QtyOrder,QtyReserved,QtyAvailable,QtyOH,
						CustomerRequestDate,PromisedDate,EstimatedShipDate,StatusId,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,
						IsDeleted,StocklineNumber,ConditionName,StatusName,Notes,ECCN,HSCODE,Weight,SizeLength,SizeWidth,SizeHeight,ReferenceNumber)
						SELECT DISTINCT
						  @ExSalesOrderPartId,
						  @StockLineId,
						  COALESCE(@UpdatedConditionId, ROS.ConditionId),
						  @Quantity,
						  CASE
							WHEN SL.QuantityAvailable > @Quantity THEN @Quantity
							ELSE SL.QuantityAvailable
						  END,
						  SL.QuantityAvailable,
						  SL.QuantityOnHand,
						  SOP.CustomerRequestDate,
						  SOP.PromisedDate,
						  SOP.EstimatedShipDate,
						  @soPartFulfilledStatusId,
						  SOP.MasterCompanyId,
						  SOP.CreatedBy,
						  GETUTCDATE(),
						  SOP.UpdatedBy,
						  GETUTCDATE(),
						  1,
						  0,
						  NULL,
						  NULL,
						  NULL,
						  'Created from RO',
						  ime.[ExportECCN],
						  ime.[HSCODE],
						  ime.[ExportWeight],
						  ime.[ExportSizeLength],
						  ime.[ExportSizeWidth],
						  ime.[ExportSizeHeight],
						  @RefNumber
							FROM #ROStockLineSamePart ROS WITH (NOLOCK)
							JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
							JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.ItemMasterId = IM.ItemMasterId
							JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) ON SOPS.StockLineId = ROS.OldStockLineId
							JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId AND SOP.SalesOrderId = @SalesOrderId
							LEFT JOIN [dbo].[ItemMasterExportInfo] ime WITH (NOLOCK) ON ime.ItemMasterId = IM.ItemMasterId
							WHERE SOP.SalesOrderId = @SalesOrderId AND SL.StockLineId = @StocklineId
							AND SL.StockLineId NOT IN (
								SELECT SOPS.StockLineId 
								FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) 
								LEFT JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId
								WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId);

						SELECT @NewSalesOrderStocklineId = SCOPE_IDENTITY()

						INSERT INTO DBO.SalesOrderStockLineCost (SalesOrderId,SalesOrderPartId,SalesOrderStocklineId,UnitSalesPrice,UnitSalesPriceExtended,
						UnitCost,UnitCostExtended,MarkUpPercentage,MarkUpAmount,DiscountPercentage,DiscountAmount,MarginAmount,MarginPercentage,NetSaleAmount,
						MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
						SELECT 
						ROS.SalesOrderId,
						@ExSalesOrderPartId,
						@NewSalesOrderStocklineId,
						SOPSC.UnitSalesPrice,
						SOPSC.UnitSalesPriceExtended,
						SL.UnitCost,
						SOPSC.UnitCostExtended,
						SOPSC.MarkUpPercentage,
						SOPSC.MarkUpAmount,
						SOPSC.DiscountPercentage,
						SOPSC.DiscountAmount,
						SOPSC.MarginAmount,
						SOPSC.MarginPercentage,
						SOPSC.NetSaleAmount,
						SOPSC.MasterCompanyId,
						SOPSC.CreatedBy,
						GETUTCDATE(),
						SOPSC.UpdatedBy,
						GETUTCDATE(),
						SOPSC.IsActive,
						SOPSC.IsDeleted
						FROM #ROStockLineSamePart ROS WITH (NOLOCK)
						JOIN #StockLine SL ON SL.StockLineId = ROS.StocklineId
						JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.ItemMasterId = IM.ItemMasterId
						JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) ON SOPS.StockLineId = ROS.OldStockLineId
						JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId AND SOP.SalesOrderId = @SalesOrderId
						JOIN [dbo].[SalesOrderStockLineCost] SOPSC WITH (NOLOCK) ON SOPSC.SalesOrderStocklineId = SOPS.SalesOrderStocklineId
						WHERE SOP.SalesOrderId = @SalesOrderId AND SL.StockLineId = @StocklineId
						AND SL.StockLineId NOT IN (
							SELECT SOPS.StockLineId 
							FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) 
							LEFT JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId
							WHERE SOPS.SalesOrderStocklineId = @ExSalesOrderStocklineId);

						EXEC USP_UpdateSOPartCostDetails
							@SalesOrderId,
							@ExSalesOrderPartId,
							@RPUpdatedBy,
							@MasterCompanyId,
							0,
							0,
							0,
							1

						INSERT INTO #SalesOrderPartDetails (SalesOrderPartId) SELECT @SalesOrderPartId

						INSERT INTO [dbo].[SalesOrderReserveParts]
									([SalesOrderId]
									,[StockLineId]
									,[ItemMasterId]
									,[PartStatusId]
									,[IsEquPart]
									,[EquPartMasterPartId]
									,[IsAltPart]
									,[AltPartMasterPartId]
									,[QtyToReserve]
									,[QtyToIssued]
									,[ReservedById]
									,[ReservedDate]
									,[IssuedById]
									,[IssuedDate]
									,[CreatedBy]
									,[CreatedDate]
									,[UpdatedBy]
									,[UpdatedDate]
									,[IsActive]
									,[IsDeleted]
									,[SalesOrderPartId]
									,[TotalReserved]
									,[TotalIssued]
									,[MasterCompanyId])
								SELECT SOP.SalesOrderId, SOPS.StockLineId, SOP.ItemMasterId, 1,
								0, NULL, 0, NULL, SOP.QtyOrder, 0, 
								(SELECT TOP 1 EmployeeId FROM [dbo].[Employee] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId ORDER BY EmployeeId),
								GETDATE(), NULL, GETDATE(), SOP.CreatedBy, GETDATE(),SOP.UpdatedBy, GETDATE(), 1, 0, SOPS.SalesOrderPartId, 
								SOPS.QtyOrder, 0, @MasterCompanyId
								FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) 
								LEFT JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId
								WHERE SOPS.SalesOrderStocklineId = @NewSalesOrderStocklineId

						SELECT @OldItemMasterId = ItemMasterId FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId;
						SELECT @OldConditionId = ConditionId FROM [dbo].[SalesOrderStocklineV1] WITH (NOLOCK) WHERE SalesOrderStocklineId = @ExSalesOrderStocklineId;
						SELECT @NewConditionId = ConditionId, @NewItemMasterId = ItemMasterId FROM [dbo].[Stockline] WITH (NOLOCK) WHERE StockLineId = @StockLineId;

						SELECT @SalesOrderStockLineId = SCOPE_IDENTITY()

						SELECT @NewQtyRequested = QtyRequested FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId;

						SELECT @StlQuantity = SOP.QtyOrder FROM [dbo].[SalesOrderStocklineV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId AND StockLineId = @StocklineId;

						UPDATE [dbo].[Stockline] SET [QuantityAvailable] = ISNULL(QuantityAvailable - @StlQuantity, 0), [QuantityReserved] = ISNULL(@StlQuantity, 0) WHERE StockLineId = @StocklineId

						UPDATE SD SET SOQty = @StlQuantity,ForStockQty =  SL.Quantity - @StlQuantity
						FROM [dbo].[StocklineDraft] SD LEFT JOIN [dbo].[Stockline] SL ON SD.StockLineId = SL.StockLineId WHERE SL.StockLineId = @StocklineId;

						UPDATE [dbo].[SalesOrderPartV1] 
						SET StatusId = @soPartFulfilledStatusId
						WHERE SalesOrderPartId = @SalesOrderPartId

						SELECT @QtyFulfilled = @QtyFulfilled - (SELECT SUM(ISNULL(QtyOrder,0)) FROM [dbo].[SalesOrderStocklineV1] WITH (NOLOCK) 
						WHERE SalesOrderStocklineId = @NewSalesOrderStocklineId)

						IF (@QtyFulfilled <= 0)
						BEGIN
							DELETE SOSTL FROM [dbo].[SalesOrderStocklineV1] SOSTL WHERE SOSTL.SalesOrderStocklineId = @ExSalesOrderStocklineId;
							DELETE SOA   FROM [dbo].[SalesOrderApproval] SOA WHERE SOA.SalesOrderPartId = @ExSalesOrderPartId;

							IF (@OldConditionId <> @NewConditionId)
							BEGIN
								UPDATE [dbo].[SalesOrderPartV1] SET ConditionId = @NewConditionId, 
								UpdatedDate = GETUTCDATE()
								WHERE SalesOrderPartId = @SalesOrderPartId;

								-- Increase Qty Requested if the stockline is added in the existing part with same condition
								UPDATE [dbo].[SalesOrderPartV1]
								SET QtyRequested = (QtyRequested + @NewQtyRequested)
								WHERE [SalesOrderId] = @SalesOrderId AND ItemMasterId = @NewItemMasterId AND ConditionId = @NewConditionId;

								-- UPDATE NEWLY CREATED [SalesOrderPartId] IN FREIGHT & CHARGES

								UPDATE [dbo].[SalesOrderFreight] 
									SET [SalesOrderPartId] = @SalesOrderPartId, 
										[ItemMasterId] = @NewItemMasterId,
										[ConditionId] = @NewConditionId
									WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;

								UPDATE [dbo].[SalesOrderCharges] 
									SET [SalesOrderPartId] = @SalesOrderPartId, 
										[ItemMasterId] = @NewItemMasterId,
										[ConditionId] = @NewConditionId
									WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;
							END
						END
						ELSE
						BEGIN
							UPDATE [dbo].[SalesOrderStockLine] SET Quantity = Quantity - @StlQuantity, ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity - @StlQuantity, 0) WHERE SalesOrderPartId = @ExSalesOrderPartId

							IF (@OldConditionId <> @NewConditionId)
							BEGIN
								INSERT INTO [dbo].[SalesOrderPartV1] (SalesOrderId,ItemMasterId,ConditionId,QtyRequested,QtyOrder,QtyReserved,CurrencyId,
								PriorityId,StatusId,FxRate,CustomerRequestDate,PromisedDate,EstimatedShipDate,POId,PONumber,PONextDlvrDate,Notes,MasterCompanyId,
								CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted,OldSalesOrderPartId,PartNumber,PartDescription,ConditionName,
								CurrencyName,PriorityName,StatusName,SalesOrderQuotePartId,LotId,IsLotAssigned,ECCN,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
								SELECT SalesOrderId,ItemMasterId,ConditionId,QtyRequested,QtyOrder,QtyReserved,CurrencyId,
								PriorityId,StatusId,FxRate,CustomerRequestDate,PromisedDate,EstimatedShipDate,POId,PONumber,PONextDlvrDate,Notes,MasterCompanyId,
								CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted,OldSalesOrderPartId,PartNumber,PartDescription,ConditionName,
								CurrencyName,PriorityName,StatusName,SalesOrderQuotePartId,LotId,IsLotAssigned,ECCN,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight
								FROM [dbo].[SalesOrderPartV1] WITH(NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId;

								SELECT @NewSalesOrderPartId = SCOPE_IDENTITY();

								INSERT INTO [dbo].[SalesOrderPartCost] (SalesOrderId,SalesOrderPartId,UnitSalesPrice,UnitSalesPriceExtended,UnitCost,
								UnitCostExtended,MarkUpPercentage,MarkUpAmount,MarginAmount,MarginPercentage,DiscountPercentage,DiscountAmount,TaxPercentage,
								TaxAmount,NetSaleAmount,MiscCharges,Freight,TotalRevenue,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
								SELECT SalesOrderId,@NewSalesOrderPartId,UnitSalesPrice,UnitSalesPriceExtended,UnitCost,
								UnitCostExtended,MarkUpPercentage,MarkUpAmount,MarginAmount,MarginPercentage,DiscountPercentage,DiscountAmount,TaxPercentage,
								TaxAmount,NetSaleAmount,MiscCharges,Freight,TotalRevenue,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted
								FROM [dbo].[SalesOrderPartCost] WITH(NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId;
							
								INSERT INTO DBO.SalesOrderStocklineV1 (SalesOrderPartId,StockLineId,ConditionId,QtyOrder,QtyReserved,QtyAvailable,QtyOH,
								CustomerRequestDate,PromisedDate,EstimatedShipDate,StatusId,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,
								IsDeleted,StocklineNumber,ConditionName,StatusName,Notes,ECCN,HSCODE,Weight,SizeLength,SizeWidth,SizeHeight,ReferenceNumber)
								SELECT SalesOrderPartId,StockLineId,ConditionId,QtyOrder,QtyReserved,QtyAvailable,QtyOH,
								CustomerRequestDate,PromisedDate,EstimatedShipDate,StatusId,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,
								IsDeleted,StocklineNumber,ConditionName,StatusName,Notes,ECCN,HSCODE,Weight,SizeLength,SizeWidth,SizeHeight,@RefNumber
								FROM [dbo].SalesOrderStocklineV1 WITH(NOLOCK) WHERE SalesOrderStocklineId = @ExSalesOrderStocklineId;

								SELECT @SalesOrderStockLineId = SCOPE_IDENTITY();

								INSERT INTO DBO.SalesOrderStockLineCost (SalesOrderId,SalesOrderPartId,SalesOrderStocklineId,UnitSalesPrice,UnitSalesPriceExtended,
								UnitCost,UnitCostExtended,MarkUpPercentage,MarkUpAmount,DiscountPercentage,DiscountAmount,MarginAmount,MarginPercentage,NetSaleAmount,
								MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
								SELECT SalesOrderId,@NewSalesOrderPartId,@SalesOrderStockLineId,UnitSalesPrice,UnitSalesPriceExtended,
								UnitCost,UnitCostExtended,MarkUpPercentage,MarkUpAmount,DiscountPercentage,DiscountAmount,MarginAmount,MarginPercentage,NetSaleAmount,
								MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted
								FROM DBO.SalesOrderStockLineCost WITH(NOLOCK) WHERE SalesOrderStocklineId = @ExSalesOrderStocklineId;

								UPDATE [dbo].[SalesOrderStocklineV1]
								SET SalesOrderPartId = @SalesOrderPartId,
								ConditionId = @NewConditionId
								WHERE SalesOrderStocklineId = @SalesOrderStockLineId;

								--SELECT @UnitCost = [UnitCost] FROM [dbo].[SalesOrderStockLine] WITH(NOLOCK) WHERE SOStockLineId = @SalesOrderStockLineId

								UPDATE [dbo].[SalesOrderPartV1]
								SET QtyOrder = QtyOrder - @StlQuantity,
								ConditionId = @NewConditionId,
								--UnitCostExtended = ISNULL(UnitCost, 0) * ISNULL(Qty - @StlQuantity, 0),
								UpdatedDate = GETDATE()
								WHERE [SalesOrderPartId] = @ExSalesOrderPartId;

								UPDATE [dbo].[SalesOrderPartV1]
								SET QtyOrder = @StlQuantity,
								--UnitCost = @UnitCost,
								--UnitCostExtended = ISNULL(@UnitCost, 0) * ISNULL(@StlQuantity, 0),
								UpdatedDate = GETDATE()
								WHERE [SalesOrderPartId] = @NewSalesOrderPartId

								SELECT @TotalQty = QtyOrder, @SoId = SalesOrderId FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE [SalesOrderPartId] = @ExSalesOrderPartId;

								SELECT @RevQty = SUM(ISNULL(QtyOrder,0)) FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE [SalesOrderId] = @SoId AND  [SalesOrderPartId] <> @ExSalesOrderPartId;
													
								IF(@TotalQty = @RevQty)
								BEGIN
									DELETE SOSTL FROM [dbo].[SalesOrderStockLineV1] SOSTL WHERE SOSTL.SalesOrderStocklineId = @ExSalesOrderStocklineId;
									DELETE SOA   FROM [dbo].[SalesOrderApproval] SOA WHERE SOA.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SORS  FROM [dbo].[SalesOrderReservedStock] SORS WHERE SORS.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SOPM  FROM [dbo].[SOPartsMapping] SOPM WHERE SOPM.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SORP  FROM [dbo].[SalesOrderReserveParts] SORP WHERE SORP.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SOURP FROM [dbo].[SalesOrderUnReservedStock] SOURP WHERE SOURP.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SOP   FROM [dbo].[SalesOrderPartV1] SOP WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId;

									IF (@OldConditionId <> @NewConditionId)
									BEGIN
										UPDATE [dbo].[SalesOrderPartV1] SET ConditionId = @NewConditionId,
										UpdatedDate = GETDATE()
										WHERE SalesOrderPartId = @SalesOrderPartId;

										UPDATE [dbo].[SalesOrderPartV1] SET QtyRequested = QtyOrder, StatusId = @soPartFulfilledStatusId WHERE [SalesOrderId] = @SoId;

										-- UPDATE NEWLY CREATED [SalesOrderPartId] IN FREIGHT & CHARGES

										UPDATE [dbo].[SalesOrderFreight] 
										   SET [SalesOrderPartId] = @SalesOrderPartId, 
											   [ItemMasterId] = @NewItemMasterId,
											   [ConditionId] = @NewConditionId
										 WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;

										 UPDATE [dbo].[SalesOrderCharges] 
											SET [SalesOrderPartId] = @SalesOrderPartId, 
												[ItemMasterId] = @NewItemMasterId,
												[ConditionId] = @NewConditionId
										  WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;
									END
								END
							END
						END
					END
					ELSE
					BEGIN
						SELECT @NewSalesOrderStocklineId = SalesOrderStocklineId FROM DBO.SalesOrderStocklineV1 WITH (NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId AND StockLineId = @StockLineId

						SELECT @OldItemMasterId = ItemMasterId FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId;
						SELECT @OldConditionId = ConditionId FROM [dbo].[SalesOrderStocklineV1] WITH (NOLOCK) WHERE SalesOrderStocklineId = @ExSalesOrderStocklineId;
						SELECT @NewConditionId = ConditionId, @NewItemMasterId = ItemMasterId FROM [dbo].[Stockline] WITH (NOLOCK) WHERE StockLineId = @StockLineId;

						SELECT @NewQtyRequested = QtyRequested FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId;

						SELECT @StlQuantity = SOP.QtyOrder FROM [dbo].[SalesOrderStocklineV1] SOP WITH (NOLOCK) WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId AND StockLineId = @StocklineId;

						UPDATE [dbo].[Stockline] SET [QuantityAvailable] = ISNULL(QuantityAvailable - @StlQuantity, 0), [QuantityReserved] = ISNULL(@StlQuantity, 0) WHERE StockLineId = @StocklineId

						UPDATE SD SET SOQty = @StlQuantity,ForStockQty =  SL.Quantity - @StlQuantity
						FROM [dbo].[StocklineDraft] SD LEFT JOIN [dbo].[Stockline] SL ON SD.StockLineId = SL.StockLineId WHERE SL.StockLineId = @StocklineId;

						UPDATE [dbo].[SalesOrderPartV1] 
						SET StatusId = @soPartFulfilledStatusId,
						QtyReserved = @Quantity
						WHERE SalesOrderPartId = @ExSalesOrderPartId

						UPDATE [dbo].[SalesOrderStocklineV1]
						SET QtyReserved = @Quantity
						WHERE SalesOrderStocklineId = @NewSalesOrderStocklineId;

						INSERT INTO [dbo].[SalesOrderReserveParts]
						([SalesOrderId],[StockLineId],[ItemMasterId],[PartStatusId],[IsEquPart],[EquPartMasterPartId],[IsAltPart],
						[AltPartMasterPartId],[QtyToReserve],[QtyToIssued],[ReservedById],[ReservedDate],[IssuedById],[IssuedDate],
						[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive],[IsDeleted],[SalesOrderPartId],
						[TotalReserved],[TotalIssued],[MasterCompanyId])
						SELECT SOP.SalesOrderId, SOPS.StockLineId, SOP.ItemMasterId, 1,
						0, NULL, 0, NULL, SOP.QtyOrder, 0, 
						(SELECT TOP 1 EmployeeId FROM [dbo].[Employee] WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId ORDER BY EmployeeId),
						GETDATE(), NULL, GETDATE(), SOP.CreatedBy, GETDATE(),SOP.UpdatedBy, GETDATE(), 1, 0, SOPS.SalesOrderPartId, 
						SOPS.QtyOrder, 0, @MasterCompanyId
						FROM [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) 
						LEFT JOIN [dbo].[SalesOrderStocklineV1] SOPS WITH (NOLOCK) ON SOP.SalesOrderPartId = SOPS.SalesOrderPartId
						WHERE SOPS.SalesOrderStocklineId = @NewSalesOrderStocklineId

						SELECT @QtyFulfilled = @QtyFulfilled - (SELECT SUM(ISNULL(QtyOrder,0)) FROM [dbo].[SalesOrderStocklineV1] WITH (NOLOCK) 
						WHERE SalesOrderStocklineId = @NewSalesOrderStocklineId)
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StockLineId, @ModuleId = @SOModuleId, @ReferenceId = @SalesOrderId, @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = 2, @Qty = @Quantity, @UpdatedBy = @RPUpdatedBy;
						IF (@QtyFulfilled <= 0)
						BEGIN
							IF (@OldConditionId <> @NewConditionId)
							BEGIN
								UPDATE [dbo].[SalesOrderPartV1] SET ConditionId = @NewConditionId, 
								UpdatedDate = GETUTCDATE()
								WHERE SalesOrderPartId = @ExSalesOrderPartId;

								UPDATE [dbo].[SalesOrderStocklineV1] SET ConditionId = @NewConditionId, 
								UpdatedDate = GETUTCDATE()
								WHERE SalesOrderStocklineId = @NewSalesOrderStocklineId;

								-- UPDATE NEWLY CREATED [SalesOrderPartId] IN FREIGHT & CHARGES

								UPDATE [dbo].[SalesOrderFreight] 
									SET [SalesOrderPartId] = @ExSalesOrderPartId, 
										[ItemMasterId] = @NewItemMasterId,
										[ConditionId] = @NewConditionId
									WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;

								UPDATE [dbo].[SalesOrderCharges] 
									SET [SalesOrderPartId] = @ExSalesOrderPartId, 
										[ItemMasterId] = @NewItemMasterId,
										[ConditionId] = @NewConditionId
									WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;
							END
						END
						ELSE
						BEGIN
							UPDATE [dbo].[SalesOrderStockLine] SET Quantity = Quantity - @StlQuantity, ExtendedCost = ISNULL(UnitCost, 0) * ISNULL(Quantity - @StlQuantity, 0) WHERE SalesOrderPartId = @ExSalesOrderPartId

							IF (@OldConditionId <> @NewConditionId)
							BEGIN
								INSERT INTO [dbo].[SalesOrderPartV1] (SalesOrderId,ItemMasterId,ConditionId,QtyRequested,QtyOrder,QtyReserved,CurrencyId,
								PriorityId,StatusId,FxRate,CustomerRequestDate,PromisedDate,EstimatedShipDate,POId,PONumber,PONextDlvrDate,Notes,MasterCompanyId,
								CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted,OldSalesOrderPartId,PartNumber,PartDescription,ConditionName,
								CurrencyName,PriorityName,StatusName,SalesOrderQuotePartId,LotId,IsLotAssigned,ECCN,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight)
								SELECT SalesOrderId,ItemMasterId,ConditionId,QtyRequested,QtyOrder,QtyReserved,CurrencyId,
								PriorityId,StatusId,FxRate,CustomerRequestDate,PromisedDate,EstimatedShipDate,POId,PONumber,PONextDlvrDate,Notes,MasterCompanyId,
								CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted,OldSalesOrderPartId,PartNumber,PartDescription,ConditionName,
								CurrencyName,PriorityName,StatusName,SalesOrderQuotePartId,LotId,IsLotAssigned,ECCN,HSCODE,[Weight],SizeLength,SizeWidth,SizeHeight
								FROM [dbo].[SalesOrderPartV1] WITH(NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId;

								SELECT @NewSalesOrderPartId = SCOPE_IDENTITY();

								INSERT INTO [dbo].[SalesOrderPartCost] (SalesOrderId,SalesOrderPartId,UnitSalesPrice,UnitSalesPriceExtended,UnitCost,
								UnitCostExtended,MarkUpPercentage,MarkUpAmount,MarginAmount,MarginPercentage,DiscountPercentage,DiscountAmount,TaxPercentage,
								TaxAmount,NetSaleAmount,MiscCharges,Freight,TotalRevenue,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
								SELECT SalesOrderId,@NewSalesOrderPartId,UnitSalesPrice,UnitSalesPriceExtended,UnitCost,
								UnitCostExtended,MarkUpPercentage,MarkUpAmount,MarginAmount,MarginPercentage,DiscountPercentage,DiscountAmount,TaxPercentage,
								TaxAmount,NetSaleAmount,MiscCharges,Freight,TotalRevenue,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted
								FROM [dbo].[SalesOrderPartCost] WITH(NOLOCK) WHERE SalesOrderPartId = @ExSalesOrderPartId;
							
								INSERT INTO DBO.SalesOrderStocklineV1 (SalesOrderPartId,StockLineId,ConditionId,QtyOrder,QtyReserved,QtyAvailable,QtyOH,
								CustomerRequestDate,PromisedDate,EstimatedShipDate,StatusId,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,
								IsDeleted,StocklineNumber,ConditionName,StatusName,Notes,ECCN,HSCODE,Weight,SizeLength,SizeWidth,SizeHeight,ReferenceNumber)
								SELECT SalesOrderPartId,StockLineId,ConditionId,QtyOrder,QtyReserved,QtyAvailable,QtyOH,
								CustomerRequestDate,PromisedDate,EstimatedShipDate,StatusId,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,
								IsDeleted,StocklineNumber,ConditionName,StatusName,Notes,ECCN,HSCODE,Weight,SizeLength,SizeWidth,SizeHeight,@RefNumber
								FROM [dbo].SalesOrderStocklineV1 WITH(NOLOCK) WHERE SalesOrderStocklineId = @ExSalesOrderStocklineId;

								SELECT @SalesOrderStockLineId = SCOPE_IDENTITY();

								INSERT INTO DBO.SalesOrderStockLineCost (SalesOrderId,SalesOrderPartId,SalesOrderStocklineId,UnitSalesPrice,UnitSalesPriceExtended,
								UnitCost,UnitCostExtended,MarkUpPercentage,MarkUpAmount,DiscountPercentage,DiscountAmount,MarginAmount,MarginPercentage,NetSaleAmount,
								MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)
								SELECT SalesOrderId,@NewSalesOrderPartId,@SalesOrderStockLineId,UnitSalesPrice,UnitSalesPriceExtended,
								UnitCost,UnitCostExtended,MarkUpPercentage,MarkUpAmount,DiscountPercentage,DiscountAmount,MarginAmount,MarginPercentage,NetSaleAmount,
								MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted
								FROM DBO.SalesOrderStockLineCost WITH(NOLOCK) WHERE SalesOrderStocklineId = @ExSalesOrderStocklineId;

								UPDATE [dbo].[SalesOrderStocklineV1]
								SET SalesOrderPartId = @ExSalesOrderPartId,
								ConditionId = @NewConditionId
								WHERE SalesOrderStocklineId = @SalesOrderStockLineId;

								--SELECT @UnitCost = [UnitCost] FROM [dbo].[SalesOrderStockLine] WITH(NOLOCK) WHERE SOStockLineId = @SalesOrderStockLineId

								UPDATE [dbo].[SalesOrderPartV1]
								SET QtyOrder = QtyOrder - @StlQuantity,
								ConditionId = @NewConditionId,
								--UnitCostExtended = ISNULL(UnitCost, 0) * ISNULL(Qty - @StlQuantity, 0),
								UpdatedDate = GETDATE()
								WHERE [SalesOrderPartId] = @ExSalesOrderPartId;

								UPDATE [dbo].[SalesOrderPartV1]
								SET QtyOrder = @StlQuantity,
								--UnitCost = @UnitCost,
								--UnitCostExtended = ISNULL(@UnitCost, 0) * ISNULL(@StlQuantity, 0),
								UpdatedDate = GETDATE()
								WHERE [SalesOrderPartId] = @NewSalesOrderPartId

								SELECT @TotalQty = QtyOrder, @SoId = SalesOrderId FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE [SalesOrderPartId] = @ExSalesOrderPartId;

								SELECT @RevQty = SUM(ISNULL(QtyOrder,0)) FROM [dbo].[SalesOrderPartV1] WITH (NOLOCK) WHERE [SalesOrderId] = @SoId AND  [SalesOrderPartId] <> @ExSalesOrderPartId;
													
								IF(@TotalQty = @RevQty)
								BEGIN
									DELETE SOSTL FROM [dbo].[SalesOrderStockLineV1] SOSTL WHERE SOSTL.SalesOrderStocklineId = @ExSalesOrderStocklineId;
									DELETE SOA   FROM [dbo].[SalesOrderApproval] SOA WHERE SOA.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SORS  FROM [dbo].[SalesOrderReservedStock] SORS WHERE SORS.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SOPM  FROM [dbo].[SOPartsMapping] SOPM WHERE SOPM.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SORP  FROM [dbo].[SalesOrderReserveParts] SORP WHERE SORP.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SOURP FROM [dbo].[SalesOrderUnReservedStock] SOURP WHERE SOURP.SalesOrderPartId = @ExSalesOrderPartId;
									DELETE SOP   FROM [dbo].[SalesOrderPartV1] SOP WHERE SOP.SalesOrderPartId = @ExSalesOrderPartId;

									IF (@OldConditionId <> @NewConditionId)
									BEGIN
										UPDATE [dbo].[SalesOrderPartV1] SET ConditionId = @NewConditionId,
										UpdatedDate = GETDATE()
										WHERE SalesOrderPartId = @ExSalesOrderPartId;

										UPDATE [dbo].[SalesOrderPartV1] SET QtyRequested = QtyOrder, StatusId = @soPartFulfilledStatusId WHERE [SalesOrderId] = @SoId;

										-- UPDATE NEWLY CREATED [SalesOrderPartId] IN FREIGHT & CHARGES

										UPDATE [dbo].[SalesOrderFreight] 
										   SET [SalesOrderPartId] = @ExSalesOrderPartId, 
											   [ItemMasterId] = @NewItemMasterId,
											   [ConditionId] = @NewConditionId
										 WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;

										 UPDATE [dbo].[SalesOrderCharges] 
											SET [SalesOrderPartId] = @ExSalesOrderPartId, 
												[ItemMasterId] = @NewItemMasterId,
												[ConditionId] = @NewConditionId
										  WHERE [SalesOrderPartId] = @ExSalesOrderPartId AND [SalesOrderId] = @SalesOrderId;
									END
								END
							END
						END
					END
				END
				END
			  END

			  SELECT @LoopID SET @LoopID = @LoopID - 1;
          END
		  END
          SET @MasterLoopID = @MasterLoopID - 1;
		  
        END
        IF OBJECT_ID(N'tempdb..#ROStockLineSamePart') IS NOT NULL
        BEGIN
          DROP TABLE #ROStockLineSamePart
        END

        IF OBJECT_ID(N'tempdb..#ROStockLineRevisedPart') IS NOT NULL
        BEGIN
          DROP TABLE #ROStockLineRevisedPart
        END

        IF OBJECT_ID(N'tempdb..#StockLine') IS NOT NULL
        BEGIN
          DROP TABLE #StockLine
        END

        IF OBJECT_ID(N'tempdb..#StockLineData') IS NOT NULL
        BEGIN
          DROP TABLE #StockLineData
        END

		IF OBJECT_ID(N'tempdb..#SalesOrderPartDetails') IS NOT NULL
        BEGIN
          DROP TABLE #SalesOrderPartDetails
        END
      END

    COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'USP_CreateSOStocklineFromRO'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = '''
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