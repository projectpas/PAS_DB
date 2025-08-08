/***************************************************************  
 ** File:   [USP_GetRFQSummarisedHistory]             
 ** Author: Amit Ghediya
 ** Description: Get RFQ Quote historical data. 
 ** Purpose:   
 ** Date:     01-08-2025  
            
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    01-08-2025		  Amit Ghediya				Created

	exec [USP_GetRFQSummarisedHistory] 1,31
*************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetRFQSummarisedHistory]
    @MasterCompanyId BIGINT,
	@CustomerRfqId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
    BEGIN TRY

		--Get AI price based on rfqId
		CREATE TABLE #TempRFQDetails
		(
			customerRfqId INT,
			rfqId BIGINT,
			partNumber VARCHAR(100),
			masterCompanyId INT,
			ilsPrice DECIMAL(18, 2)
		);

		INSERT INTO #TempRFQDetails
		EXEC [dbo].[usp_GetRFQPriceSuggestionDetails] @CustomerRfqId, @MasterCompanyId;
		

		SELECT RFQ.[CustomerRfqId],
					RFQ.[RfqId], 
					RFQ.[RfqCreatedDate] AS 'RfqcreatedDate',
					RFQ.[BuyerName] AS 'rfqFrom',
					RFQ.[BuyerCompanyName] AS 'companyName',
					RFQ.[BuyerCountry] AS 'country',
					RFQ.[LinePartNumber] AS 'partNumber',
					RFQ.[LineDescription] AS 'lineDescription',
					RFQ.[BuyerAddress] AS 'rfqAddress',
					RFQ.[BuyerCity] AS 'rfqCity',
					RFQ.[BuyerCountry] AS 'rfqCountry',
					RFQ.[BuyerState] AS 'rfqState',
					RFQ.[BuyerZip] AS 'rfqZip',
					RFQ.[IsQuote],
					RFQ.[Type] AS 'PortalType',
					RFQ.IntegrationPortalId AS IntegrationPortalId,
					RFQ.CreatedDate, RFQ.UpdatedDate, RFQ.CreatedBy, RFQ.UpdatedBy,
					RFQ.[AltPartNumber] AS 'AltPartNumber',
					RFQCD.[IlsPrice] AS 'IlsPrice',
					RFQCD.[IlsPrice] AS 'QuotedPrice',
					(SELECT ISNULL(ilsPrice,0) FROM #TempRFQDetails) AS 'AverageSuggestedPrice',
					RFQCD.[PercentId] AS 'PercentId',
					RFQCD.[PercentValue] AS 'PercentValue',
					RFQ.[Quantity] AS 'Quantity',
					CON.[Description] AS 'Condition',
					ISNULL(RFQ.[ModuleId],0) AS ModuleId,
					ISNULL(RFQ.[ReferenceId],0) AS ReferenceId,
					ISNULL(SOQ.SalesOrderQuoteNumber,'') AS RefrenceQuoteNumber,
					ISNULL(IMPS.SP_CalSPByPP_UnitSalePrice,0) AS PurchaseSalePrice
				FROM dbo.CustomerRfq RFQ WITH (NOLOCK)
				INNER JOIN dbo.CustomerRfqQuote RFQC WITH (NOLOCK) ON RFQC.[CustomerRfqId] = RFQ.[CustomerRfqId]
				INNER JOIN dbo.CustomerRfqQuoteDetails RFQCD WITH (NOLOCK) ON RFQCD.[CustomerRfqQuoteId] = RFQC.[CustomerRfqQuoteId]
				LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON RFQ.[LinePartNumber] = IM.[partnumber] AND RFQ.[MasterCompanyId] = IM.[MasterCompanyId] AND IM.IsDeleted = 0 AND IM.IsActive = 1
				LEFT JOIN dbo.ItemMasterPurchaseSale IMPS WITH(NOLOCK) ON RFQCD.[ConditionId] = IMPS.[ConditionId] AND IM.[ItemMasterId] = IMPS.[ItemMasterId] AND IMPS.IsDeleted = 0 AND IMPS.IsActive = 1
				LEFT JOIN dbo.Customer CU WITH(NOLOCK) ON RFQ.[BuyerCompanyName] = CU.[Name] AND RFQ.[MasterCompanyId] = CU.[MasterCompanyId]
				LEFT JOIN dbo.SalesOrderQuote SOQ WITH(NOLOCK) ON RFQ.[ReferenceId] = SOQ.[SalesOrderQuoteId] AND RFQ.[MasterCompanyId] = SOQ.[MasterCompanyId]
				LEFT JOIN dbo.Condition CON WITH(NOLOCK) ON RFQCD.[ConditionId] = CON.[ConditionId]
				WHERE RFQ.MasterCompanyId = @MasterCompanyId 
				AND RFQ.CustomerRfqId = @CustomerRfqId

				-- Droped the temp table when done
				DROP TABLE #TempRFQDetails;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------- 
                @AdhocComments VARCHAR(150) = 'USP_GetRFQSummarisedHistory',
                @ProcedureParameters VARCHAR(3000) = '@customerRfqId = ' + CAST(@customerRfqId AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';
 -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in USP_GetRFQSummarisedHistory. Error ID: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END