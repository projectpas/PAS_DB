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
	2	 12-08-2025       Devendra Shekh			changed @RfqId dataType to NVARCHAR(400)
	2	 13-08-2025       Amit Ghediya			    changed for get soq DATA FOR PART

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

		DECLARE @Status_Code VARCHAR(100) = 'Rejected,Open,Cancelled',
				@CompanyName VARCHAR(256),
				@PartNumber VARCHAR(256),
				@lineDescription VARCHAR(MAX),
				@ModuleId INT,
				@PercentId BIGINT,
				@PercentValue DECIMAL(18,2);
		
		SELECT TOP 1 @CompanyName = RFQ.[BuyerCompanyName],
				@PartNumber = RFQ.[LinePartNumber],
				@lineDescription = LineDescription,
				@ModuleId =ModuleId,
				@PercentId =RFQCD.PercentId,
				@PercentValue = RFQCD.PercentValue
		FROM dbo.CustomerRfq RFQ WITH (NOLOCK)
		INNER JOIN dbo.CustomerRfqQuote RFQC WITH (NOLOCK) ON RFQC.[CustomerRfqId] = RFQ.[CustomerRfqId]
		INNER JOIN dbo.CustomerRfqQuoteDetails RFQCD WITH (NOLOCK) ON RFQCD.[CustomerRfqQuoteId] = RFQC.[CustomerRfqQuoteId]
		WHERE  RFQ.CustomerRfqId = @CustomerRfqId
		AND RFQ.MasterCompanyId = @MasterCompanyId;

		SELECT		@CustomerRfqId AS 'CustomerRfqId',
					0 AS 'RfqId', 
					Sq.CreatedDate AS 'RfqcreatedDate',
					'' AS 'rfqFrom',
					@CompanyName AS 'companyName',
					'' AS 'country',
					@PartNumber AS 'partNumber',
					@lineDescription AS 'lineDescription',
					'' AS 'rfqAddress',
					'' AS 'rfqCity',
					'' AS 'rfqCountry',
					'' AS 'rfqState',
					'' AS 'rfqZip',
					0 AS 'IsQuote',
					'' AS 'PortalType',
					0 AS IntegrationPortalId,
					SOPC.UnitSalesPrice AS 'QuotedPrice',
					(SELECT dbo.GetAveragePriceById(SQ.[SalesOrderQuoteId],SQ.[MasterCompanyId])) AS 'AverageSuggestedPrice',
					@PercentId AS 'PercentId',
					@PercentValue AS 'PercentValue',
					SQP.QtyQuoted AS 'Quantity',
					CONS.[Description] AS 'Condition',
					@ModuleId AS ModuleId,
					@CustomerRfqId AS ReferenceId,
					ISNULL(SQ.SalesOrderQuoteNumber,'') AS RefrenceQuoteNumber,
					ISNULL(IMPS.PP_UnitPurchasePrice,0) AS PurchaseSalePrice,
					SQ.SalesOrderQuoteId,
					SQ.CustomerId
				FROM
				[DBO].[SalesOrderQuotePartV1] SQP WITH(NOLOCK) 
				INNER JOIN [DBO].[SalesOrderQuotePartCost] SOPC WITH(NOLOCK) ON SQP.[SalesOrderQuotePartId] = SOPC.[SalesOrderQuotePartId]
				INNER JOIN [DBO].[SalesOrderQuote] SQ WITH(NOLOCK) ON SQP.[SalesOrderQuoteId] = SQ.[SalesOrderQuoteId]
				LEFT JOIN [DBO].[MasterSalesOrderQuoteStatus] SQS WITH(NOLOCK) ON SQ.[StatusId] = SQS.[Id]
				LEFT JOIN [DBO].[ItemMasterPurchaseSale] IMPS WITH(NOLOCK) ON SQP.[ConditionId] = IMPS.[ConditionId] AND SQP.[ItemMasterId] = IMPS.[ItemMasterId] AND IMPS.IsDeleted = 0 AND IMPS.IsActive = 1
				LEFT JOIN [DBO].[Condition] CONS WITH(NOLOCK) ON SQP.[ConditionId] = CONS.[ConditionId]
				WHERE SQP.MasterCompanyId = @MasterCompanyId 
				AND SQS.[Name] NOT IN (SELECT item FROM SplitString(@Status_Code,','))
				AND LOWER(TRIM(SQP.PartNumber)) = LOWER(TRIM(@PartNumber))
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