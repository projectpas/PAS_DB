/*************************************************************           
 ** File:   [GetReserveStockPartsListBySOId]          
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get the stocklines to be reserved from SO Parts
 ** Purpose:         
 ** Date: 
         
 ** PARAMETERS:
         
 ** RETURN VALUE:           
 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/08/2021   Vishal Suthar Modified the logic
     
 EXEC [dbo].[GetReserveStockPartsListBySOId] 69
**************************************************************/
CREATE PROC [dbo].[GetReserveStockPartsListBySOId]
@SalesOrderId  bigint
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF OBJECT_ID(N'tempdb..#tmpUniqueSalesOrderPart') IS NOT NULL
		BEGIN
			DROP TABLE #tmpUniqueSalesOrderPart
		END

		IF OBJECT_ID(N'tempdb..#tmpReservedSalesOrderParts') IS NOT NULL
		BEGIN
			DROP TABLE #tmpReservedSalesOrderParts
		END

		CREATE TABLE #tmpUniqueSalesOrderPart
		(
			ID BIGINT IDENTITY,
			SalesOrderId BIGINT,
			SalesOrderPartid BIGINT,
			ItemMasterId BIGINT,
			ConditionId BIGINT,
			Qty INT,
			QtyRequested INT,
			StockLineId BIGINT,
			MethodType CHAR(1)
		)

		CREATE TABLE #tmpReservedSalesOrderParts 
		( 
			SalesOrderId BIGINT, ItemMasterId BIGINT, ConditionId BIGINT, Condition VARCHAR(256), SalesOrderPartId BIGINT, PartNumber VARCHAR(50), 
			PartDescription NVARCHAR(MAX), Quantity INT, ReservedById BIGINT, IssuedById BIGINT, PartStatusId CHAR(1), IsAltPart BIT,  IsEquPart BIT,
			AltPartMasterPartId BIGINT, EquPartMasterPartId BIGINT, QtyToReserve INT, QtyToBeReserved INT, QuantityReserved INT, QuantityAvailable INT,  QuantityOnHand INT, 
			QuantityOnOrder INT, StockLineId BIGINT, StockLineNumber VARCHAR(30), ControlNumber VARCHAR(50), StockType VARCHAR(50), MasterCompanyId INT
		)

		INSERT INTO #tmpUniqueSalesOrderPart (SalesOrderId, SalesOrderPartid, ItemMasterId, ConditionId, Qty, QtyRequested, StockLineId, MethodType)
			SELECT SalesOrderId, SalesOrderPartId, ItemMasterId, ConditionId, Qty, QtyRequested, StockLineId, MethodType
			FROM dbo.SalesOrderPart WITH (NOLOCK) WHERE SalesOrderId = @SalesOrderId AND IsDeleted = 0
			ORDER BY SalesOrderPartid DESC
		
		DECLARE @MasterLoopID AS BIGINT = 0;
		DECLARE @SalesOrderPartId AS BIGINT = 0;
		DECLARE @ConditionID AS BIGINT = 0;
		DECLARE @ItemMasterID AS BIGINT = 0;
		DECLARE @Qty AS INT = 0;
		DECLARE @StockLineId AS BIGINT = NULL;
		DECLARE @MethodType AS CHAR(1) = '';

		SELECT @MasterLoopID = MAX(ID) FROM #tmpUniqueSalesOrderPart
		WHILE (@MasterLoopID > 0)
		BEGIN
			SET @StockLineId = NULL;

			SELECT @SalesOrderPartId = SalesOrderPartId, @ConditionID = ConditionId, @ItemMasterID = ItemMasterId, @StockLineId = StockLineId, @Qty = Qty, @MethodType = MethodType 
			FROM #tmpUniqueSalesOrderPart WHERE ID = @MasterLoopID 
			
			IF (@MethodType = 'S' OR (@MethodType = 'I' AND @StockLineId IS NOT NULL))
			BEGIN
				IF OBJECT_ID(N'tempdb..#tmpa') IS NOT NULL
				BEGIN
					DROP TABLE #tmpa
				END

				CREATE TABLE #tmpa 
				( 
					SalesOrderId BIGINT, ItemMasterId BIGINT, ConditionId BIGINT, Condition VARCHAR(256), SalesOrderPartId BIGINT, PartNumber VARCHAR(50), 
					PartDescription NVARCHAR(MAX), Quantity INT, ReservedById BIGINT, IssuedById BIGINT, PartStatusId CHAR(1), IsAltPart BIT,  IsEquPart BIT,
					AltPartMasterPartId BIGINT, EquPartMasterPartId BIGINT, QtyToReserve INT, QtyToBeReserved INT, QuantityReserved INT, QuantityAvailable INT,  QuantityOnHand INT, 
					QuantityOnOrder INT, StockLineId BIGINT, StockLineNumber VARCHAR(30), ControlNumber VARCHAR(50), StockType VARCHAR(50), MasterCompanyId INT
				)

				INSERT INTO #tmpa SELECT DISTINCT so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description as Condition, 0 AS SalesOrderPartId,
				im.PartNumber, im.PartDescription, @Qty as Quantity
				, ISNULL(sor.ReservedById, 0) AS ReservedById
				, ISNULL(sor.IssuedById, 0) AS IssuedById
				, '1' as PartStatusId
				, IsAltPart = ISNULL(sor.IsAltPart, 0)
				, IsEquPart = ISNULL(sor.IsEquPart, 0)
				, sor.AltPartMasterPartId AS AltPartMasterPartId
				, sor.EquPartMasterPartId AS EquPartMasterPartId
				, 0 AS QtyToReserve
				, (ISNULL(SUM(sop.Qty), 0) - 
				(SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOR.StockLineId = @StockLineId AND SOR.SalesOrderId = @SalesOrderId)
				--- 
				--(SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId Where SOSI.SalesOrderPartId = SOP.SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)
				) AS QtyToBeReserved
				, ISNULL(SUM(sor.TotalReserved), 0) AS QuantityReserved
				, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
				, sl.StockLineNumber, sl.ControlNumber,
				CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' ELSE (CASE WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' ELSE (CASE WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER' ELSE 'OEM' END) END) END as StockType
				,SO.MasterCompanyId
				FROM DBO.SalesOrder SO WITH (NOLOCK)
				INNER JOIN #tmpUniqueSalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
				LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) on sop.ItemMasterId = im.ItemMasterId
				INNER JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				LEFT JOIN DBO.StockLine SL WITH (NOLOCK) ON sl.StockLineId = @StockLineId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
				LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) ON SOR.SalesOrderId = SO.SalesOrderId AND SOR.StockLineId = @StockLineId
				WHERE so.IsDeleted = 0 AND so.SalesOrderId = @SalesOrderId
				AND SL.QuantityAvailable > 0
				AND sop.ItemMasterId = @ItemMasterId
				AND sop.ConditionId = @ConditionId
				AND sop.StockLineId = @StockLineId
				AND SL.IsCustomerStock = 0
				AND SL.IsParent = 1				
				GROUP BY so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description,
				im.PartNumber, im.PartDescription
				, sl.QuantityAvailable
				, sl.QuantityOnHand
				, sl.QuantityOnOrder
				, sl.StockLineId
				, sl.StockLineNumber, sl.ControlNumber
				,SO.MasterCompanyId
				,im.IsPma
				,im.IsDER
				,sop.MethodType
				,SOP.StockLineId
				,SOR.ReservedById
				,SOR.IssuedById
				,SOR.IsAltPart
				,SOR.IsEquPart, SOR.AltPartMasterPartId, SOR.EquPartMasterPartId
				Having (ISNULL(SUM(sop.Qty), 0) - 
				(SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOR.StockLineId = @StockLineId AND SOR.SalesOrderId = @SalesOrderId)) > 0

				INSERT INTO #tmpReservedSalesOrderParts
				SELECT * FROM #tmpa Where StockLineId NOT IN (SELECT StockLineId FROM #tmpReservedSalesOrderParts) ORDER BY StockLineId 
			END

			SET @MasterLoopID = @MasterLoopID - 1;
		END

		SELECT @MasterLoopID = MAX(ID) FROM #tmpUniqueSalesOrderPart
		WHILE (@MasterLoopID > 0)
		BEGIN
			SET @StockLineId = NULL;

			SELECT @SalesOrderPartId = SalesOrderPartId, @ConditionID = ConditionId, @ItemMasterID = ItemMasterId, @StockLineId = StockLineId, @Qty = Qty, @MethodType = MethodType 
			FROM #tmpUniqueSalesOrderPart WHERE ID = @MasterLoopID 

			IF (@MethodType = 'I' AND @StockLineId IS NULL)
			BEGIN
				IF OBJECT_ID(N'tempdb..#tmpb') IS NOT NULL
				BEGIN
					DROP TABLE #tmpb
				END

				CREATE TABLE #tmpb 
				( 
					SalesOrderId BIGINT, ItemMasterId BIGINT, ConditionId BIGINT, Condition VARCHAR(256), SalesOrderPartId BIGINT, PartNumber VARCHAR(50), 
					PartDescription NVARCHAR(MAX), Quantity INT, ReservedById BIGINT, IssuedById BIGINT, PartStatusId CHAR(1), IsAltPart BIT,  IsEquPart BIT,
					AltPartMasterPartId BIGINT, EquPartMasterPartId BIGINT, QtyToReserve INT, QtyToBeReserved INT, QuantityReserved INT, QuantityAvailable INT,  QuantityOnHand INT, 
					QuantityOnOrder INT, StockLineId BIGINT, StockLineNumber VARCHAR(30), ControlNumber VARCHAR(50), StockType VARCHAR(50), MasterCompanyId INT
				)

				INSERT INTO #tmpb SELECT DISTINCT so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description as Condition, 0 AS SalesOrderPartId,
				im.PartNumber, im.PartDescription, ISNULL(sop.QtyRequested, 0) as Quantity
				, (SELECT ISNULL(sor.ReservedById, 0) FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS ReservedById
				, (SELECT ISNULL(sor.IssuedById, 0) FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS IssuedById
				, '1' as PartStatusId
				, IsAltPart = ISNULL((SELECT sor.IsAltPart FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId), 0)
				, IsEquPart = ISNULL((SELECT sor.IsEquPart FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId), 0)
				, (SELECT sor.AltPartMasterPartId FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS AltPartMasterPartId
				, (SELECT sor.EquPartMasterPartId FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS EquPartMasterPartId
				, 0 AS QtyToReserve
				, (ISNULL(sop.QtyRequested, 0) - 
				(SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOR.ItemMasterId = @ItemMasterID AND SOR.SalesOrderId = @SalesOrderId) - 
				(SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId Where SOSI.SalesOrderPartId = SOP.SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)) AS QtyToBeReserved
				, QuantityReserved = ISNULL((SELECT SUM(sor.TotalReserved) FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOR.ItemMasterId = @ItemMasterID AND SOR.SalesOrderId = @SalesOrderId), 0)
				, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
				, sl.StockLineNumber, sl.ControlNumber,
				CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' ELSE (CASE WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' ELSE (CASE WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER' ELSE 'OEM' END) END) END as StockType
				,SO.MasterCompanyId
				FROM DBO.SalesOrder SO WITH (NOLOCK)
				INNER JOIN #tmpUniqueSalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
				LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) on sop.ItemMasterId = im.ItemMasterId
				INNER JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				LEFT JOIN DBO.StockLine SL WITH (NOLOCK) ON sl.StockLineId = SOP.StockLineId --im.ItemMasterId = sl.ItemMasterId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
				WHERE so.IsDeleted = 0 AND so.SalesOrderId = @SalesOrderId
				AND SL.QuantityAvailable > 0
				AND SL.ItemMasterId = @ItemMasterID
				AND SL.ConditionId = @ConditionID
				AND SL.IsCustomerStock = 0
				AND SL.IsParent = 1
				GROUP BY so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description,
				im.PartNumber, im.PartDescription
				, sl.QuantityAvailable
				, sl.QuantityOnHand
				, sl.QuantityOnOrder
				, sl.StockLineId
				, sl.StockLineNumber, sl.ControlNumber
				,SO.MasterCompanyId
				,im.IsPma
				,im.IsDER
				,sop.QtyRequested
				,sop.Qty
				,sop.MethodType
				,sop.SalesOrderPartId
				,SOP.StockLineId
				Having (ISNULL(sop.QtyRequested, 0) - 
				(SELECT ISNULL(SUM(sor.TotalReserved), 0) FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOR.ItemMasterId = @ItemMasterID AND SOR.SalesOrderId = @SalesOrderId) -
				(SELECT ISNULL(SUM(SOSI.QtyShipped), 0) FROM DBO.SalesOrderShipping SOS WITH (NOLOCK) INNER JOIN DBO.SalesOrderShippingItem SOSI ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId Where SOSI.SalesOrderPartId = SOP.SalesOrderPartId AND SOS.SalesOrderId = @SalesOrderId)) > 0

				INSERT INTO #tmpReservedSalesOrderParts
				SELECT * FROM #tmpb Where StockLineId NOT IN (SELECT StockLineId FROM #tmpReservedSalesOrderParts) ORDER BY StockLineId 
			END

			SET @MasterLoopID = @MasterLoopID - 1;
		END

		--SELECT @MasterLoopID = MAX(ID) FROM #tmpUniqueSalesOrderPart
		--WHILE (@MasterLoopID > 0)
		--BEGIN
		--	SET @StockLineId = NULL;

		--	SELECT @SalesOrderPartId = SalesOrderPartId, @ConditionID = ConditionId, @ItemMasterID = ItemMasterId, @StockLineId = StockLineId, @Qty = Qty, @MethodType = MethodType 
		--	FROM #tmpUniqueSalesOrderPart WHERE ID = @MasterLoopID 

		--	IF (@MethodType = 'I' AND @StockLineId IS NOT NULL)
		--	BEGIN
				IF OBJECT_ID(N'tempdb..#tmpc') IS NOT NULL
				BEGIN
					DROP TABLE #tmpc
				END

				CREATE TABLE #tmpc 
				( 
					SalesOrderId BIGINT, ItemMasterId BIGINT, ConditionId BIGINT, Condition VARCHAR(256), SalesOrderPartId BIGINT, PartNumber VARCHAR(50), 
					PartDescription NVARCHAR(MAX), Quantity INT, ReservedById BIGINT, IssuedById BIGINT, PartStatusId CHAR(1), IsAltPart BIT,  IsEquPart BIT,
					AltPartMasterPartId BIGINT, EquPartMasterPartId BIGINT, QtyToReserve INT, QtyToBeReserved INT, QuantityReserved INT, QuantityAvailable INT,  QuantityOnHand INT, 
					QuantityOnOrder INT, StockLineId BIGINT, StockLineNumber VARCHAR(30), ControlNumber VARCHAR(50), StockType VARCHAR(50), MasterCompanyId INT
				)

				INSERT INTO #tmpc SELECT DISTINCT so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description as Condition, 0 AS SalesOrderPartId,
				im.PartNumber, im.PartDescription, ISNULL(sop.QtyRequested, 0) as Quantity
				, (SELECT ISNULL(sor.ReservedById, 0) FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS ReservedById
				, (SELECT ISNULL(sor.IssuedById, 0) FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS IssuedById
				, '1' as PartStatusId
				, IsAltPart = ISNULL((SELECT sor.IsAltPart FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId), 0)
				, IsEquPart = ISNULL((SELECT sor.IsEquPart FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId), 0)
				, (SELECT sor.AltPartMasterPartId FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS AltPartMasterPartId
				, (SELECT sor.EquPartMasterPartId FROM DBO.SalesOrderReserveParts SOR WITH (NOLOCK) WHERE SOP.SalesOrderPartId = SOR.SalesOrderPartId AND SOR.SalesOrderId = @SalesOrderId) AS EquPartMasterPartId
				, 0 AS QtyToReserve
				, (ISNULL(sop.QtyRequested, 0) - 
				(SELECT ISNULL(SUM(SalesP.Qty), 0) FROM DBO.SalesOrderPart SalesP WITH (NOLOCK) WHERE SalesP.ItemMasterId = SL.ItemMasterId AND SalesP.ConditionId = SL.ConditionId AND SalesP.MethodType = 'I' AND SalesP.StockLineId IS NOT NULL AND SalesP.SalesOrderId = @SalesOrderId)) AS QtyToBeReserved
				, QuantityReserved = 0
				, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
				, sl.StockLineNumber, sl.ControlNumber,
				CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' ELSE (CASE WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' ELSE (CASE WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER' ELSE 'OEM' END) END) END as StockType
				,SO.MasterCompanyId
				FROM DBO.SalesOrder SO WITH (NOLOCK)
				INNER JOIN #tmpUniqueSalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
				LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) on sop.ItemMasterId = im.ItemMasterId
				INNER JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				LEFT JOIN DBO.StockLine SL WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId
				LEFT JOIN DBO.Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
				WHERE so.IsDeleted = 0 AND so.SalesOrderId = @SalesOrderId
				AND SL.QuantityAvailable > 0
				AND (sop.MethodType = 'I' AND sl.ItemMasterId = sop.ItemMasterId AND sl.ConditionId = sop.ConditionId)
				AND SL.IsCustomerStock = 0
				AND SL.IsParent = 1
				AND SL.StockLineId NOT IN (SELECT StockLineId FROM #tmpUniqueSalesOrderPart Where MethodType = 'I' and StockLineId IS NOT NULL)
				GROUP BY so.SalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description,
				im.PartNumber, im.PartDescription
				, sl.QuantityAvailable
				, sl.QuantityOnHand
				, sl.QuantityOnOrder
				, sl.ItemMasterId
				, sl.ConditionId
				, sl.StockLineId
				, sl.StockLineNumber
				, sl.ControlNumber
				,SO.MasterCompanyId
				,im.IsPma
				,im.IsDER
				,sop.MethodType
				,SOP.StockLineId
				,SOP.QtyRequested,
				SOP.SalesOrderPartid
				Having (ISNULL(SUM(sop.QtyRequested), 0) -
				(SELECT ISNULL(SUM(SalesP.Qty), 0) FROM DBO.SalesOrderPart SalesP WITH (NOLOCK) WHERE SalesP.ItemMasterId = SL.ItemMasterId AND SalesP.ConditionId = SL.ConditionId AND SalesP.MethodType = 'I' AND SalesP.StockLineId IS NOT NULL AND SalesP.SalesOrderId = @SalesOrderId)) > 0

				INSERT INTO #tmpReservedSalesOrderParts
				SELECT * FROM #tmpc Where StockLineId NOT IN (SELECT StockLineId FROM #tmpReservedSalesOrderParts)
				ORDER BY StockLineId 
			
		--	END

		--	SET @MasterLoopID = @MasterLoopID - 1;
		--END
		
		SELECT DISTINCT SalesOrderId, ItemMasterId, ConditionId, Condition, SalesOrderPartId, PartNumber, 
			PartDescription, Quantity, ReservedById, IssuedById, PartStatusId, IsAltPart, IsEquPart,
			AltPartMasterPartId, EquPartMasterPartId, QtyToReserve, QtyToBeReserved, QuantityReserved, QuantityAvailable, QuantityOnHand, 
			QuantityOnOrder, StockLineId, StockLineNumber, ControlNumber, StockType, MasterCompanyId FROM #tmpReservedSalesOrderParts
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReserveStockPartsListBySOId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
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