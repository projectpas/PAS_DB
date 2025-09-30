/*************************************************************           
 ** File:   [ItemMasterPriceListForBulkUpdate]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used ItemMasterPriceListForBulkUpdate
 ** Purpose:         
 ** Date:   30/08/2024      
          
 ** PARAMETERS: @ItemMasterId BIGINT, @MasterCompanyId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    30/08/2024  Ekta Chandegra     Created
    2    15/09/2025  Rajesh Gami		Getting only selected ItemMaster data if any
	3    23/09/2025  Rajesh Gami		Added SuggestedPrice 
--exec dbo.ItemMasterPriceListForBulkUpdate @ItemMasterId=0,@MasterCompanyId=1

************************************************************************/

CREATE      PROCEDURE [dbo].[ItemMasterPriceListForBulkUpdate]
(
	@ItemMasterId BIGINT,
	@MasterCompanyId BIGINT,
	@EmployeeId bigint,
	@IsDownload BIT = 0
)
AS
BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED        
	  SET NOCOUNT ON          
		  IF @ItemMasterId = 0      
		  BEGIN      
			SET @ItemMasterId = NULL      
		  END 
	BEGIN TRY 
	DECLARE @partNumber VARCHAR(120) = (SELECT Top 1 partnumber FROM DBO.ItemMaster WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId And MasterCompanyId = @MasterCompanyId)
	IF OBJECT_ID(N'tempdb..#RFQHistory') IS NOT NULL
	BEGIN
		DROP TABLE #RFQHistory
	END

	CREATE TABLE #RFQHistory
		(
			ID INT,
			PartNumber NVARCHAR(100),
			Condition NVARCHAR(50),
			PurchaseSalePrice DECIMAL(18,2),
			SOUnitPrice DECIMAL(18,2),
			SOQUnitPrice DECIMAL(18,2),
			IlsPrice DECIMAL(18,2),
			MarkUpPercentValue DECIMAL(18,2),
			CostPlusPrice DECIMAL(18,2),
			RecommendedPrice DECIMAL(18,2),
			POUnitPrice DECIMAL(18,2),
			POMarkUpPercentValue DECIMAL(18,2),
			POUnitPriceCostPlus DECIMAL(18,2),
			POPricePercentId BIGINT,
			POQuotePercentId BIGINT
		);

	INSERT INTO #RFQHistory
		EXEC dbo.USP_GetRFQHistoryByPartNumber 
			@PartNumber = @partNumber, 
			@ConditionId = NULL, 
			@MasterCompanyId = @MasterCompanyId;


		SELECT DISTINCT 
		IM.ItemMasterId,
		IM.PartNumber,
		IM.PartDescription,
		IM.ManufacturerId,
		IM.ManufacturerName,
		IM.MasterCompanyId,
		IM.UpdatedBy,
		IM.UpdatedDate,
		IM.IsActive,
		IM.IsDeleted,
		IM.CreatedBy,
		IM.CreatedDate
		FROM [DBO].[ItemMaster] IM WITH (NOLOCK)
		LEFT JOIN [DBO].ItemMasterPurchaseSale IMPS  WITH (NOLOCK)  ON IMPS.ItemMasterId = IM.ItemMasterId
		WHERE IM.MasterCompanyId = @MasterCompanyId
		AND (@ItemMasterId IS NULL OR IM.ItemMasterId = @ItemMasterId)
		AND IM.IsActive = 1
		AND IM.IsDeleted = 0

		IF(@ItemMasterId > 0)
		BEGIN
			SELECT
			IMPS.ItemMasterId,
			IMPS.PartNumber,
			IM.ManufacturerName,
			IMPS.ConditionId,
			IMPS.ConditionName,
			IMPS.ItemMasterPurchaseSaleId,
			IMPS.PP_CurrencyId,
			IMPS.PP_CurrencyName,
			ISNULL(IMPS.PP_FXRatePerc,0) AS PP_FXRatePerc,
			IMPS.PP_LastListPriceDate,
			IMPS.PP_LastPurchaseDiscDate,
			ISNULL(IMPS.PP_PurchaseDiscPerc,0) AS PP_PurchaseDiscPerc,
			ISNULL(IMPS.PP_PurchaseDiscAmount,0) AS PP_PurchaseDiscAmount,
			ISNULL(IMPS.PP_UnitPurchasePrice,0) AS PP_UnitPurchasePrice,
			IMPS.SalePriceSelectId,
			IMPS.SalePriceSelectName,
			IMPS.PP_UOMId,
			IMPS.PP_UOMName,
			ISNULL(IMPS.PP_VendorListPrice,0) AS PP_VendorListPrice,
			ISNULL(IMPS.SP_CalSPByPP_BaseSalePrice,0) AS SP_CalSPByPP_BaseSalePrice,
			IMPS.SP_CalSPByPP_LastMarkUpDate,
			IMPS.SP_CalSPByPP_LastSalesDiscDate,
			ISNULL(IMPS.SP_CalSPByPP_MarkUpAmount,0) AS SP_CalSPByPP_MarkUpAmount,
			ISNULL(IMPS.SP_CalSPByPP_MarkUpPercOnListPrice,0) AS SP_CalSPByPP_MarkUpPercOnListPrice,
			ISNULL(IMPS.SP_CalSPByPP_SaleDiscAmount,0) AS SP_CalSPByPP_SaleDiscAmount,
			ISNULL(IMPS.SP_CalSPByPP_SaleDiscPerc,0) AS SP_CalSPByPP_SaleDiscPerc,
			ISNULL(IMPS.SP_CalSPByPP_UnitSalePrice,0) AS SP_CalSPByPP_UnitSalePrice,
			IMPS.SP_FSP_CurrencyId,
			IMPS.SP_FSP_CurrencyName,
			ISNULL(IMPS.SP_FSP_FlatPriceAmount,0) AS SP_FSP_FlatPriceAmount,
			ISNULL(IMPS.SP_FSP_FXRatePerc,0) AS SP_FSP_FXRatePerc,
			IMPS.SP_FSP_LastFlatPriceDate,
			IMPS.SP_FSP_UOMId,
			IMPS.SP_FSP_UOMName,
			IMPS.IsActive,
			IMPS.IsDeleted
			,CAST(ISNULL(P.PercentValue,0) as INT) AS SP_CalSPByPP_MarkUpPercValueOnListPrice,
			 ISNULL(R.RecommendedPrice,0) AS SuggestedPrice
			FROM [DBO].ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
			LEFT JOIN [DBO].ItemMaster IM  WITH (NOLOCK)  ON IMPS.ItemMasterId = IM.ItemMasterId 
			LEFT JOIN [DBO].[Percent] P  WITH (NOLOCK)  ON ISNULL(IMPS.SP_CalSPByPP_MarkUpPercOnListPrice,0) = P.PercentId 
			LEFT JOIN #RFQHistory R ON R.PartNumber = IM.PartNumber AND R.Condition = IMPS.ConditionName
			WHERE IMPS.MasterCompanyId = @MasterCompanyId
			AND IMPS.IsActive = 1
			AND IMPS.IsDeleted = 0
			AND (@ItemMasterId IS NULL OR IM.ItemMasterId = @ItemMasterId)
		END
		ELSE 
		BEGIN

			IF OBJECT_ID(N'tempdb..#tmpPriceMaster') IS NOT NULL
			BEGIN
				DROP TABLE #tmpPriceMaster
			END
			PRINT 'Else'
			SELECT 
			IMPS.ItemMasterId,
			IMPS.PartNumber,
			IM.ManufacturerName,
			IMPS.ConditionId,
			IMPS.ConditionName,
			IMPS.ItemMasterPurchaseSaleId,
			IMPS.PP_CurrencyId,
			IMPS.PP_CurrencyName,
			ISNULL(IMPS.PP_FXRatePerc,0) AS PP_FXRatePerc,
			IMPS.PP_LastListPriceDate,
			IMPS.PP_LastPurchaseDiscDate,
			ISNULL(IMPS.PP_PurchaseDiscPerc,0) AS PP_PurchaseDiscPerc,
			ISNULL(IMPS.PP_PurchaseDiscAmount,0) AS PP_PurchaseDiscAmount,
			ISNULL(IMPS.PP_UnitPurchasePrice,0) AS PP_UnitPurchasePrice,
			IMPS.SalePriceSelectId,
			IMPS.SalePriceSelectName,
			IMPS.PP_UOMId,
			IMPS.PP_UOMName,
			ISNULL(IMPS.PP_VendorListPrice,0) AS PP_VendorListPrice,
			ISNULL(IMPS.SP_CalSPByPP_BaseSalePrice,0) AS SP_CalSPByPP_BaseSalePrice,
			IMPS.SP_CalSPByPP_LastMarkUpDate,
			IMPS.SP_CalSPByPP_LastSalesDiscDate,
			ISNULL(IMPS.SP_CalSPByPP_MarkUpAmount,0) AS SP_CalSPByPP_MarkUpAmount,
			ISNULL(IMPS.SP_CalSPByPP_MarkUpPercOnListPrice,0) AS SP_CalSPByPP_MarkUpPercOnListPrice,
			ISNULL(IMPS.SP_CalSPByPP_SaleDiscAmount,0) AS SP_CalSPByPP_SaleDiscAmount,
			ISNULL(IMPS.SP_CalSPByPP_SaleDiscPerc,0) AS SP_CalSPByPP_SaleDiscPerc,
			ISNULL(IMPS.SP_CalSPByPP_UnitSalePrice,0) AS SP_CalSPByPP_UnitSalePrice,
			IMPS.SP_FSP_CurrencyId,
			IMPS.SP_FSP_CurrencyName,
			ISNULL(IMPS.SP_FSP_FlatPriceAmount,0) AS SP_FSP_FlatPriceAmount,
			ISNULL(IMPS.SP_FSP_FXRatePerc,0) AS SP_FSP_FXRatePerc,
			IMPS.SP_FSP_LastFlatPriceDate,
			IMPS.SP_FSP_UOMId,
			IMPS.SP_FSP_UOMName,
			IMPS.IsActive,
			IMPS.IsDeleted
			,CAST(ISNULL(P.PercentValue,0) as INT) AS SP_CalSPByPP_MarkUpPercValueOnListPrice,
			 CAST(0 AS DECIMAL(18,2))  AS SuggestedPrice
			INTO #tmpPriceMaster FROM [DBO].ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
			LEFT JOIN [DBO].ItemMaster IM  WITH (NOLOCK)  ON IMPS.ItemMasterId = IM.ItemMasterId 
			LEFT JOIN [DBO].[Percent] P  WITH (NOLOCK)  ON ISNULL(IMPS.SP_CalSPByPP_MarkUpPercOnListPrice,0) = P.PercentId 
			--LEFT JOIN #RFQHistory R ON R.PartNumber = IM.PartNumber AND R.Condition = IMPS.ConditionName
			WHERE IMPS.MasterCompanyId = @MasterCompanyId
			AND IMPS.IsActive = 1
			AND IMPS.IsDeleted = 0
			AND (@ItemMasterId IS NULL OR IM.ItemMasterId = @ItemMasterId)


			IF(@IsDownload = 1)
			BEGIN
				
				IF OBJECT_ID('tempdb..#tmpRFQ') IS NOT NULL DROP TABLE #tmpRFQ;

				CREATE TABLE #tmpRFQ
				(
					ID BIGINT,
					PartNumber VARCHAR(50),
					[Condition] VARCHAR(50),
					PurchaseSalePrice DECIMAL(18,2),
					SOUnitPrice DECIMAL(18,2),
					SOQUnitPrice DECIMAL(18,2),
					IlsPrice DECIMAL(18,2),
					MarkUpPercentValue DECIMAL(18,2),
					CostPlusPrice DECIMAL(18,2),
					RecommendedPrice DECIMAL(18,2),
					POUnitPrice DECIMAL(18,2),
					POMarkUpPercentValue DECIMAL(18,2),
					POUnitPriceCostPlus DECIMAL(18,2),
					POPricePercentId BIGINT,
					POQuotePercentId BIGINT
				);

				DECLARE @loopPartNumber VARCHAR(50);

				
				DECLARE curPart CURSOR FOR
					SELECT DISTINCT PartNumber
					FROM #tmpPriceMaster  WHERE ISNULL(PartNumber, '') <> ''

				OPEN curPart;
				FETCH NEXT FROM curPart INTO @loopPartNumber;

				WHILE @@FETCH_STATUS = 0
				BEGIN
					
					INSERT INTO #tmpRFQ
					EXEC dbo.USP_GetRFQHistoryByPartNumber 
						@PartNumber = @loopPartNumber, 
						@ConditionId = NULL, 
						@MasterCompanyId = @MasterCompanyId;

					FETCH NEXT FROM curPart INTO @loopPartNumber;
				END

				CLOSE curPart;
				DEALLOCATE curPart;

				
				UPDATE TMP
				SET TMP.SuggestedPrice = RFQ.RecommendedPrice
				FROM #tmpPriceMaster TMP
				INNER JOIN #tmpRFQ RFQ
					ON TMP.PartNumber = RFQ.PartNumber AND TMP.ConditionName = RFQ.Condition;

				DROP TABLE #tmpRFQ;
			END
			SELECT * FROM #tmpPriceMaster
		END
		
		END TRY
		BEGIN CATCH
		 SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'ItemMasterPriceListForBulkUpdate' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			exec spLogException 
					  @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END