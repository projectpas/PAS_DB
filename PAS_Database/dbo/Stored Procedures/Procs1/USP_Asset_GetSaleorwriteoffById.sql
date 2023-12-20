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
				@AssetLife = ISNULL(AI.AssetLife,0),@ResidualPercentage = ISNULL(AI.ResidualPercentage,0),
				@TotalInstallCost = ISNULL(SUM(UnitCost + Freight + Insurance + Taxes + InstallationCost),0),
				@CurrencyCode = CU.Code
			FROM [DBO].[AssetInventory] AI WITH(NOLOCK)
			LEFT JOIN [DBO].[Currency] CU WITH(NOLOCK) ON AI.CurrencyId = CU.CurrencyId
			WHERE AssetInventoryId = @AssetInventoryId
			GROUP BY AI.AssetId,AI.Name,AI.DepreciationFrequencyName ,AI.EntryDate,AI.AssetLife,AI.ResidualPercentage,CU.Code;
			
			SET @PercentageAmount = ISNULL((ISNULL(@ResidualPercentage,0) * ISNULL(@TotalInstallCost,0) /100),0);
			
			IF(@AssetLife > 0)
			BEGIN 
				SET @MonthlyDepAmount = ISNULL((ISNULL(@TotalInstallCost,0)-ISNULL(@PercentageAmount,0)) / ISNULL(@AssetLife,0),0)
			END
			ELSE
			BEGIN 
				SET @MonthlyDepAmount = ISNULL((ISNULL(@TotalInstallCost,0)-ISNULL(@PercentageAmount,0)),0)
			END

			IF(UPPER(@DeprFrequency)='MTHLY' OR UPPER(@DeprFrequency)='MONTHLY')
            BEGIN 
             	 SET @DATEDIFF= DATEDIFF(DAY, CAST(@AssetCreateDate AS DATE),CAST(GETUTCDATE() AS DATE));
             	 SET @MonthDIFF= DATEDIFF(MONTH, CAST(@AssetCreateDate AS DATE),CAST(GETUTCDATE() AS DATE));
             	 SET @DividedDaysDIFF=ISNULL((ISNULL(@DATEDIFF,1)/30),0);
             	 SET @ExistStatus = CASE WHEN (@DividedDaysDIFF%1)= 0 THEN 'Even' ELSE 'Odd' END
				 IF (@MonthDIFF <= @AssetLife)
             	 BEGIN
				   SET @DepreciationAmount = ISNULL(@MonthlyDepAmount,0)
             	 END
			END
			IF(UPPER(@DeprFrequency)='QTLY' OR UPPER(@DeprFrequency)='QUATERLY')
            BEGIN 
                  SET @DATEDIFF= DATEDIFF(DAY, CAST(@AssetCreateDate AS DATE),CAST(GETUTCDATE() AS DATE))
             	  SET @MonthDIFF= DATEDIFF(MONTH, CAST(@AssetCreateDate AS DATE),CAST(GETUTCDATE() AS DATE))
             	  SET @DividedDaysDIFF = ISNULL((ISNULL(@DATEDIFF,1)/90),0)
             	  SET @ExistStatus = CASE WHEN (@DividedDaysDIFF%1)= 0 THEN 'Even' ELSE 'Odd' END
				  IF(@MonthDIFF <= @AssetLife)
             	  BEGIN
					  SET @DepreciationAmount = (ISNULL(@MonthlyDepAmount,0) * 3)
             	  END
             END
			 IF(UPPER(@DeprFrequency)='YRLY' OR UPPER(@DeprFrequency)='YEARLY')
             BEGIN 
                   SET @DATEDIFF = DATEDIFF(DAY, CAST(@AssetCreateDate AS DATE),CAST(GETUTCDATE() AS DATE))
             	   SET @MonthDIFF = DATEDIFF(MONTH, CAST(@AssetCreateDate AS DATE),CAST(GETUTCDATE() AS DATE))
             	   SET @DividedDaysDIFF = ISNULL((ISNULL(@DATEDIFF,1)/365),0)
             	   SET @ExistStatus = CASE WHEN (@DividedDaysDIFF%1)= 0 THEN 'Even' ELSE 'Odd' END
				   IF(@MonthDIFF <= @AssetLife)
             	   BEGIN
				     SET @DepreciationAmount = (ISNULL(@MonthlyDepAmount,0) * 12)
             	   END
             END

			 -- Get CurrentDate Day Part
			SET @CurDateDayPart =  DATEPART(DAY, CONVERT(date, GETUTCDATE()));
			
			-- Get CurrentDate Day Part
			SET @CreateDateDayPart =  DATEPART(DAY, CONVERT(date, @AssetCreateDate));
			
			IF(@CurDateDayPart >= @CreateDateDayPart)
			BEGIN 
				SET @MonthDIFF = @MonthDIFF;
			END
			ELSE
			BEGIN 
				SET @MonthDIFF = @MonthDIFF - 1; --For reduce 1 month
			END
			
			--GET Accumulated Depreciation.
			 SET @AD = @DepreciationAmount * @MonthDIFF;

			 --GET NBV (Net book Value).
			 SET @NBV = @TotalInstallCost - @AD;

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