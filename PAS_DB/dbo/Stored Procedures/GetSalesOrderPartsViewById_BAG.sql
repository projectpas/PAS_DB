/*************************************************************
 ** File:   [GetSalesOrderPartsViewById_BAG]
 ** Author:  Bhargav Saliya
 ** Description: Beach Aviation (BAG) variant of GetSalesOrderPartsViewById. Returns the same
 **              Sales Order parts view for the COC form, additionally exposing the sold stock
 **              line's Control # (StockLine.ControlNumber) and Cert # (StockLine.PartCertificationNumber)
 **              so they can be rendered on the COC_Form_BAG report.
 ** Purpose:
 ** Date:  25/08/2026

 ** PARAMETERS: @SalesOrderId bigint, @SoPartId bigint

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			 Author				Change Description
 ** --   --------		-------				--------------------------------
	1    25/08/2026		Bhargav Saliya		Created as BAG variant of GetSalesOrderPartsViewById; added ControlNumber and CertificateNumber (PartCertificationNumber) from StockLine.
-- exec [GetSalesOrderPartsViewById_BAG] 792,0
************************************************************************/
CREATE   PROCEDURE [dbo].[GetSalesOrderPartsViewById_BAG]
	@SalesOrderId BIGINT,
	@SoPartId BIGINT = 0
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON;
 BEGIN TRY
   BEGIN

		IF OBJECT_ID(N'tempdb..#tmprShipDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmprShipDetails
		END

		--Set SoPart null for all part for salesordor otherwise for perticular part only.
		IF(ISNULL(@SoPartId,0) = 0)
		BEGIN
			SET @SoPartId = NULL;
		END

		CREATE TABLE #tmprShipDetails
		(
			[Qty] DECIMAL(18,6) NULL,
			[StockLineNumber] VARCHAR(MAX) NULL,
			[SerialNumber] VARCHAR(MAX) NULL,
			[Condition] VARCHAR(MAX) NULL,
			[PartNumber] VARCHAR(MAX) NULL,
			[PartDescription] VARCHAR(MAX) NULL,
			[ShortName] VARCHAR(100) NULL,
			[Customer] VARCHAR(150) NULL,
			[ControlNumber] VARCHAR(50) NULL,
			[CertificateNumber] VARCHAR(50) NULL
		)

		INSERT INTO #tmprShipDetails ([Qty],[StockLineNumber],[SerialNumber],[Condition],[PartNumber],[PartDescription],[ShortName],[Customer],[ControlNumber],[CertificateNumber])
		SELECT
			rpart.QtyToReserve AS Qty,
			UPPER(qs.StockLineNumber) AS StockLineNumber,
			UPPER(qs.SerialNumber) AS SerialNumber,
			UPPER(ISNULL(cp.Description, '')) AS Condition,
			UPPER(itemMaster.PartNumber) AS PartNumber,
			UPPER(itemMaster.PartDescription) AS PartDescription,
			UPPER(ISNULL(uomConsume.ShortName,'')) AS ShortName,
			UPPER(CU.Name) AS Customer,
			UPPER(ISNULL(qs.ControlNumber,'')) AS ControlNumber,
			UPPER(ISNULL(qs.PartCertificationNumber,'')) AS CertificateNumber
		FROM  [dbo].[SalesOrderPartV1] part WITH(NOLOCK)
		        LEFT JOIN [dbo].[SalesOrderStocklineV1] Stk WITH(NOLOCK) ON part.SalesOrderPartId = Stk.SalesOrderPartId
				LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON Stk.StockLineId = qs.StockLineId
				LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
				LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
				INNER JOIN [dbo].[SalesOrderReserveParts] rPart WITH(NOLOCK) ON part.SalesOrderPartId = rPart.SalesOrderPartId
				AND rPart.SalesOrderId = @SalesOrderId AND rPart.QtyToReserve > 0
				LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = uomConsume.UnitOfMeasureId
				LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON itemMaster.StockUnitOfMeasureId = uomStock.UnitOfMeasureId
				LEFT JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON part.SalesOrderId = SO.SalesOrderId
				LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = SO.CustomerId
		WHERE part.SalesOrderId = @SalesOrderId  AND part.IsDeleted = 0
			  AND (@SoPartId IS NULL OR part.SalesOrderPartId = @SoPartId)

		UNION

		SELECT
			sos.QtyShipped AS Qty,
			UPPER(qs.StockLineNumber) AS StockLineNumber,
			UPPER(qs.SerialNumber) AS SerialNumber,
			UPPER(ISNULL(cp.Description, '')) AS Condition,
			UPPER(itemMaster.PartNumber) AS PartNumber,
			UPPER(itemMaster.PartDescription) AS PartDescription,
			UPPER(ISNULL(uomConsume.ShortName,'')) AS ShortName,
			UPPER(CU.Name) AS Customer,
			UPPER(ISNULL(qs.ControlNumber,'')) AS ControlNumber,
			UPPER(ISNULL(qs.PartCertificationNumber,'')) AS CertificateNumber
		FROM  [dbo].[SalesOrderPartV1] part WITH(NOLOCK)
		        LEFT JOIN [dbo].[SalesOrderStocklineV1] Stk WITH(NOLOCK) ON part.SalesOrderPartId = Stk.SalesOrderPartId
				LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON Stk.StockLineId = qs.StockLineId
				LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
				LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
				LEFT JOIN [dbo].[SOPickTicket] SOPICK WITH(NOLOCK) ON SOPICK.SalesOrderPartStocklineId = Stk.SalesOrderStocklineId
				INNER JOIN [dbo].[SalesOrderShippingItem] sos WITH(NOLOCK) ON sos.SOPickTicketId = SOPICK.SOPickTicketId
				AND sos.IsActive = 1 AND sos.IsDeleted = 0
				LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = uomConsume.UnitOfMeasureId
				LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON itemMaster.StockUnitOfMeasureId = uomStock.UnitOfMeasureId
				LEFT JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON part.SalesOrderId = SO.SalesOrderId
				LEFT JOIN [dbo].[Customer] CU WITH(NOLOCK) ON CU.CustomerId = SO.CustomerId
		WHERE part.SalesOrderId = @SalesOrderId  AND part.IsDeleted = 0
			  AND (@SoPartId IS NULL OR part.SalesOrderPartId = @SoPartId)

		SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS row_num,
				 SUM(Qty) AS Qty,StockLineNumber,SerialNumber,Condition,PartNumber,PartDescription,ShortName,Customer,ControlNumber,CertificateNumber
		FROM #tmprShipDetails
		GROUP BY PartNumber,StockLineNumber,SerialNumber,Condition,PartDescription,ShortName,Customer,ControlNumber,CertificateNumber
  END
  END TRY
 BEGIN CATCH
  IF @@trancount > 0
   PRINT 'ROLLBACK'
   ROLLBACK TRAN;
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderPartsViewById_BAG'
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