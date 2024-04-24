/*************************************************************           
 ** File:   [USP_Asset_GetSaleorwriteoffById]          
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to get Saleorwriteoff list for Sale.
 ** Purpose:         
 ** Date:   08/07/2023     
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author          Change Description            
 ** --   --------     -------		  --------------------------------          
    1    08/07/2023   Amit Ghediya    Created
	2    08/14/2023   Amit Ghediya    Updated Month calculation logic.
	3    04/23/2024   Abhishek Jirawla Instead of calculating here we are getting the value from Asset Depr History table.

EXEC [dbo].[USP_Asset_GetSaleorwriteoffById]  438
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_Asset_GetSaleorwriteoffById] 
(
	@AssetInventoryId BIGINT = NULL
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN
			DECLARE @DeprFrequency VARCHAR(50), @DATEDIFF INT=0,@MonthDIFF BIGINT=0,@DividedDaysDIFF INT=0,
					@ExistStatus VARCHAR(50),@AssetLife INT,@AssetCreateDate DATETIME2(7),@DepreciationAmount DECIMAL(18,2)=0,
					@MonthlyDepAmount DECIMAL(18,2)=0,@PercentageAmount DECIMAL(18,2)=0,@ResidualPercentage DECIMAL(18,2)=0,
					@AssetId VARCHAR(200),@Name VARCHAR(200),@TotalInstallCost DECIMAL(18,2)=0,@AD DECIMAL(18,2)=0,
					@NBV DECIMAL(18,2)=0,@CurrencyCode VARCHAR(50),@CurDateDayPart BIGINT=0,@CreateDateDayPart BIGINT=0;

			SELECT 
				@AssetId = AI.AssetId,
				@Name = AI.Name,
				@DeprFrequency = AI.DepreciationFrequencyName ,@AssetCreateDate = AI.EntryDate,
				@AssetLife = ISNULL(AI.AssetLife,0),
				@ResidualPercentage = ISNULL(AI.ResidualPercentage,0),
				@TotalInstallCost = ISNULL(SUM(UnitCost + Freight + Insurance + Taxes + InstallationCost),0),
				@CurrencyCode = CU.Code,
				@AD = ISNULL(ADH.AccumlatedDepr, 0),
				@NBV = ISNULL(ADH.NetBookValue, @TotalInstallCost)
			FROM [DBO].[AssetInventory] AI WITH(NOLOCK)
			LEFT JOIN [DBO].[Currency] CU WITH(NOLOCK) ON AI.CurrencyId = CU.CurrencyId
			LEFT JOIN [DBO].[AssetDepreciationHistory] ADH WITH(NOLOCK) ON AI.AssetInventoryId = ADH.AssetInventoryId 
				AND ADH.ID = (SELECT MAX(ID) FROM AssetDepreciationHistory WHERE IsActive = 1 AND IsDelete = 0 AND AssetInventoryId = ADH.AssetInventoryId)
 			WHERE AI.AssetInventoryId = @AssetInventoryId
			GROUP BY AI.AssetId,AI.Name,AI.DepreciationFrequencyName ,AI.EntryDate,AI.AssetLife,AI.ResidualPercentage,CU.Code, ADH.AccumlatedDepr, ADH.NetBookValue;

			 SELECT @AssetId AS 'AssetId',@Name AS 'Name',@TotalInstallCost AS 'TotalInstallCost',
					@AD AS 'AD',@NBV AS 'NBV',@CurrencyCode AS 'CurrencyCode';


	  END
    COMMIT TRANSACTION
	END TRY
    BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'USP_Asset_GetSaleorwriteoffById'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@AssetInventoryId, '') + ''
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