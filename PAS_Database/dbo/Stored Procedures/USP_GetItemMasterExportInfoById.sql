/*************************************************************           
 ** File:		 [USP_GetItemMasterExportInfoById]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get ExportInfo of Item Master Data.
 ** Purpose:         
 ** Date:   09-Oct-2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    09-Oct-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetItemMasterExportInfoById] @ItemMasterId=96994
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetItemMasterExportInfoById]
@ItemMasterId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY		

		SELECT 
			imx.[ItemMasterId],
			imx.[ExportECCN],
			imx.[ITARNumber],
			imx.[ExportCountryId],
			imx.[ExportValue],
			imx.[ExportCurrencyId],
			imx.[ExportWeight],
			imx.[ExportWeightUnit],
			imx.[ExportUomId],
			imx.[ExportSizeLength],
			imx.[ExportSizeWidth],
			imx.[ExportSizeHeight],
			imx.[ExportSizeUnitOfMeasureId],
			imx.[ExportClassificationId],
			ISNULL(imx.[ExportCountryName], '') AS [ExportCountryName],
			ISNULL(imx.[ExportCurrencyName], '') AS [ExportCurrencyName],
			ISNULL(imx.[ExportWeightUnitName], '') AS [ExportWeightUnitName],
			ISNULL(imx.[ExportUomName], '') AS [ExportUomName],
			ISNULL(imx.[ExportSizeUnitOfMeasureName], '') AS [ExportSizeUnitOfMeasureName],
			ISNULL(imx.[ExportClassificationIdName], '') AS [ExportClassificationIdName],
			ISNULL(imx.[IsIATR], 0) AS [IsIATR],
			ISNULL(imx.[IsExportLicense], 0) AS [IsExportLicense],
			imx.[ScheduleB],
			imx.[HSCode],
			imx.[HTSCode],
			imx.[ECCNDeterminationSourceID],
			imx.[ECCNDeterminationSourceName]
		FROM [DBO].[ItemMasterExportInfo] imx WITH(NOLOCK)
		WHERE imx.[ItemMasterId] = @ItemMasterId;		  		 	   			   	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetItemMasterExportInfoById'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END