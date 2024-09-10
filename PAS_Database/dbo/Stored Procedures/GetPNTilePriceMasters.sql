
-- Author:		Ekta Chandegra
-- Description:	Get Search Data for Price Masters List

/***************************************************************************************************************************************             
  ** Change History             
 ***************************************************************************************************************************************             
 ** PR   Date						 Author							Change Description              
 ** --   --------					 -------						-------------------------------            
    1   30-AUG-2024				  Ekta Chandegra					Created
    2   10-SEPT-2024			  Ekta Chandegra					If Value is -ve then return 0
****************************************************************************************************************************************/ 
CREATE      PROCEDURE [dbo].[GetPNTilePriceMasters]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@PartNumber varchar(200) = NULL,
	@GlobalFilter varchar(50) = '',
	@ConditionName varchar(200) = NULL,
	@PP_UOMName varchar(200) = NULL,
	@PP_CurrencyName varchar(200) = NULL,
	@PP_VendorListPrice varchar(50) = NULL,
	@PP_PurchaseDiscPerc varchar(50) = NULL,
	@PP_PurchaseDiscAmount varchar(50) = NULL,
	@PP_LastPurchaseDiscDate datetime = NULL,
	@PP_UnitPurchasePrice varchar(50) = NULL,
	@Name varchar(100) = NULL,
	@SP_FSP_UOMName varchar(200) = NULL,
	@SP_FSP_CurrencyName varchar(200) = NULL,
	@SP_FSP_FlatPriceAmount varchar(50) = NULL,
	@SP_CalSPByPP_MarkUpPercOnListPrice varchar(50) = NULL,
	@SP_CalSPByPP_MarkUpAmount varchar(50) = NULL,
	@SP_CalSPByPP_LastSalesDiscDate datetime = NULL,
	@SP_CalSPByPP_UnitSalePrice varchar(50) = NULL,
	@ItemMasterId bigint = 0,
	@IsDeleted bit = 0,
	@MasterCompanyId int = 1,
	@ConditionIds varchar(max) = NULL

AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @RecordFrom int;
	DECLARE @Count Int;				
	SET @RecordFrom = (@PageNumber-1)*@PageSize;

	IF @IsDeleted IS NULL
	BEGIN
		SET @IsDeleted=0
	END

	IF @SortColumn IS NULL
	BEGIN
		SET @SortColumn=UPPER('CreatedDate')
	END 
	ELSE
	BEGIN 
		SET @SortColumn=UPPER(@SortColumn)
	END

	BEGIN TRY		
		BEGIN
		;WITH Result AS(
		SELECT DISTINCT
		IMPS.ItemMasterId,
		IMPS.ConditionId,
		IMPS.ConditionName,
		IMPS.ItemMasterPurchaseSaleId,
		IMPS.PartNumber,
		IM.ManufacturerName,
		IM.PartDescription,
		IM.ItemClassificationName,
		IMPS.PP_CurrencyId,
		IMPS.PP_CurrencyName,
		ISNULL(IMPS.PP_FXRatePerc,0) AS PP_FXRatePerc,
		IMPS.PP_LastListPriceDate,
		IMPS.PP_LastPurchaseDiscDate,
		--ISNULL(IMPS.PP_PurchaseDiscPerc,0) AS PP_PurchaseDiscPerc,
		CASE
			WHEN IMPS.PP_PurchaseDiscPerc < 0
			THEN 
				0
			ELSE
				IMPS.PP_PurchaseDiscPerc
		END AS 'PP_PurchaseDiscPerc',
		ISNULL(IMPS.PP_PurchaseDiscAmount,0) AS PP_PurchaseDiscAmount,
		ISNULL(IMPS.PP_UnitPurchasePrice,0) AS PP_UnitPurchasePrice,
		IMPSM.ItemMasterPurchaseSaleMasterId,
		IMPSM.Name,
		IMPS.PP_UOMId,
		IMPS.PP_UOMName,
		ISNULL(IMPS.PP_VendorListPrice,0) AS PP_VendorListPrice,
		ISNULL(IMPS.SP_CalSPByPP_BaseSalePrice,0) AS SP_CalSPByPP_BaseSalePrice,
		IMPS.SP_CalSPByPP_LastMarkUpDate,
		IMPS.SP_CalSPByPP_LastSalesDiscDate,
		ISNULL(IMPS.SP_CalSPByPP_MarkUpAmount,0) AS SP_CalSPByPP_MarkUpAmount,
        --ISNULL(IMPS.SP_CalSPByPP_MarkUpPercOnListPrice,0) AS SP_CalSPByPP_MarkUpPercOnListPrice,
		CASE
			WHEN (IMPS.SP_CalSPByPP_MarkUpPercOnListPrice < 0)
			THEN 
					ISNULL(IMPS.SP_CalSPByPP_MarkUpPercOnListPrice,NULL) 
			ELSE
				IMPS.SP_CalSPByPP_MarkUpPercOnListPrice
		END AS 'SP_CalSPByPP_MarkUpPercOnListPrice',
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
		IMPS.UpdatedBy,
		IMPS.UpdatedDate,
		IMPS.IsActive,
		IMPS.IsDeleted,
		IMPS.CreatedBy,
		IMPS.CreatedDate,
		IMPS.MasterCompanyId
		FROM [DBO].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK)
		LEFT JOIN [DBO].[ItemMasterPurchaseSaleMaster] IMPSM WITH (NOLOCK) ON IMPS.SalePriceSelectId = IMPSM.ItemMasterPurchaseSaleMasterId
		LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IMPS.ItemMasterId = IM.ItemMasterId
		WHERE IMPS.MasterCompanyId = @MasterCompanyId
		AND IMPS.IsActive = 1
		AND IMPS.IsDeleted = 0
		AND IMPS.ItemMasterId = @ItemMasterId
		AND (@ConditionIds IS NULL OR IMPS.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionIds , ',')))
		),ResultCount AS (SELECT COUNT(ItemMasterId) AS totalItems FROM Result) 
		SELECT * INTO #TempResult FROM Result
			WHERE ((@GlobalFilter <> '' AND ((ConditionName LIKE '%' + @GlobalFilter + '%') OR
					(PartNumber LIKE '%' + @GlobalFilter + '%') OR
					(PP_UOMName LIKE '%' + @GlobalFilter + '%') OR
					(PP_CurrencyName LIKE '%' + @GlobalFilter + '%') OR
					(CAST(PP_VendorListPrice AS VARCHAR(20)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(PP_PurchaseDiscPerc AS VARCHAR(20)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(PP_PurchaseDiscAmount AS VARCHAR(20)) LIKE '%' + @GlobalFilter + '	%') OR
					(PP_LastPurchaseDiscDate LIKE '%' + @GlobalFilter + '	%') OR
					(CAST(PP_UnitPurchasePrice AS VARCHAR(20)) LIKE '%' + @GlobalFilter + '%') OR
					(Name LIKE '%' + @GlobalFilter + '%') OR
					(SP_FSP_UOMName LIKE '%' + @GlobalFilter + '%') OR
					(SP_FSP_CurrencyName LIKE '%' + @GlobalFilter + '%') OR
					(CAST(SP_FSP_FlatPriceAmount AS VARCHAR(20)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(SP_CalSPByPP_MarkUpPercOnListPrice AS VARCHAR(20)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(SP_CalSPByPP_MarkUpAmount AS VARCHAR(20)) LIKE '%' + @GlobalFilter + '%') OR
					(SP_CalSPByPP_LastSalesDiscDate LIKE '%' + @GlobalFilter + '%') OR
					(CAST(SP_CalSPByPP_UnitSalePrice AS VARCHAR(20)) LIKE '%' + @GlobalFilter + '%'))
					OR
					(@GlobalFilter='' AND (ISNULL(@ConditionName,'') = '' OR ConditionName LIKE '%' + @ConditionName + '%')AND
					(ISNULL(@PartNumber,'') = '' OR PartNumber LIKE '%' + @PartNumber + '%') AND
					(ISNULL(@PP_UOMName,'') = '' OR PP_UOMName LIKE '%' + @PP_UOMName + '%') AND
					(ISNULL(@PP_CurrencyName,'') = '' OR PP_CurrencyName LIKE '%' + @PP_CurrencyName + '%') AND
					(ISNULL(@PP_VendorListPrice,'') = '' OR CAST(PP_VendorListPrice AS NVARCHAR(10)) LIKE '%' + @PP_VendorListPrice + '%') AND
					(ISNULL(@PP_PurchaseDiscPerc,'') = '' OR CAST(PP_PurchaseDiscPerc AS NVARCHAR(10)) LIKE '%' + @PP_PurchaseDiscPerc + '%') AND
					(ISNULL(@PP_PurchaseDiscAmount,'') = '' OR CAST(PP_PurchaseDiscAmount AS NVARCHAR(10)) LIKE '%' + @PP_PurchaseDiscAmount + '%') AND
					(ISNULL(@PP_LastPurchaseDiscDate,'') = '' OR CAST(PP_LastPurchaseDiscDate AS DATE) = CAST(@PP_LastPurchaseDiscDate AS DATE)) AND
					(ISNULL(@PP_UnitPurchasePrice,'') = '' OR CAST(PP_UnitPurchasePrice AS NVARCHAR(10)) LIKE '%' + @PP_UnitPurchasePrice + '%') AND
					(ISNULL(@Name,'') = '' OR Name LIKE '%' + @Name + '%') AND
					(ISNULL(@SP_FSP_UOMName,'') = '' OR SP_FSP_UOMName LIKE '%' + @SP_FSP_UOMName + '%') AND
					(ISNULL(@SP_FSP_CurrencyName,'') = '' OR SP_FSP_CurrencyName LIKE '%' + @SP_FSP_CurrencyName + '%') AND
					(ISNULL(@SP_FSP_FlatPriceAmount,'') = '' OR CAST(SP_FSP_FlatPriceAmount AS NVARCHAR(10)) LIKE '%' + @SP_FSP_FlatPriceAmount + '%') AND
					(ISNULL(@SP_CalSPByPP_MarkUpPercOnListPrice,'') = '' OR CAST(SP_CalSPByPP_MarkUpPercOnListPrice AS NVARCHAR(10)) LIKE '%' + @SP_CalSPByPP_MarkUpPercOnListPrice + '%') AND
					(ISNULL(@SP_CalSPByPP_MarkUpAmount,'') = '' OR CAST(SP_CalSPByPP_MarkUpAmount AS NVARCHAR(10)) LIKE '%' + @SP_CalSPByPP_MarkUpAmount + '%') AND
					(ISNULL(@SP_CalSPByPP_LastSalesDiscDate,'') = '' OR CAST(SP_CalSPByPP_LastSalesDiscDate AS DATE) = CAST(@SP_CalSPByPP_LastSalesDiscDate AS DATE)) AND
					(ISNULL(@SP_CalSPByPP_UnitSalePrice,'') = '' OR CAST(SP_CalSPByPP_UnitSalePrice AS NVARCHAR(10)) LIKE '%' + @SP_CalSPByPP_UnitSalePrice + '%'))))
					SELECT @Count = COUNT(ItemMasterId) FROM #TempResult

					SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY
					CASE WHEN (@SortOrder=1 AND @SortColumn='PartNumber') THEN ConditionName END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='ConditionName') THEN ConditionName END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PP_UOMName') THEN PP_UOMName END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PP_CurrencyName') THEN PP_CurrencyName END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PP_VendorListPrice') THEN PP_VendorListPrice END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PP_PurchaseDiscPerc') THEN PP_PurchaseDiscPerc END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PP_PurchaseDiscAmount') THEN PP_PurchaseDiscAmount END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PP_LastPurchaseDiscDate') THEN PP_LastPurchaseDiscDate END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PP_UnitPurchasePrice') THEN PP_UnitPurchasePrice END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='Name') THEN Name END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SP_FSP_UOMName') THEN SP_FSP_UOMName END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SP_FSP_CurrencyName') THEN SP_FSP_CurrencyName END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SP_FSP_FlatPriceAmount') THEN SP_FSP_FlatPriceAmount END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SP_CalSPByPP_MarkUpPercOnListPrice') THEN SP_CalSPByPP_MarkUpPercOnListPrice END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SP_CalSPByPP_MarkUpAmount') THEN SP_CalSPByPP_MarkUpAmount END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SP_CalSPByPP_LastSalesDiscDate') THEN SP_CalSPByPP_LastSalesDiscDate END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='SP_CalSPByPP_UnitSalePrice') THEN SP_CalSPByPP_UnitSalePrice END ASC,


					CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber') THEN ConditionName END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='ConditionName') THEN ConditionName END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PP_UOMName') THEN PP_UOMName END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PP_CurrencyName') THEN PP_CurrencyName END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PP_VendorListPrice') THEN PP_VendorListPrice END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PP_PurchaseDiscPerc') THEN PP_PurchaseDiscPerc END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PP_PurchaseDiscAmount') THEN PP_PurchaseDiscAmount END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PP_LastPurchaseDiscDate') THEN PP_LastPurchaseDiscDate END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PP_UnitPurchasePrice') THEN PP_UnitPurchasePrice END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='Name') THEN Name END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SP_FSP_UOMName') THEN SP_FSP_UOMName END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SP_FSP_CurrencyName') THEN SP_FSP_CurrencyName END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SP_FSP_FlatPriceAmount') THEN SP_FSP_FlatPriceAmount END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SP_CalSPByPP_MarkUpPercOnListPrice') THEN SP_CalSPByPP_MarkUpPercOnListPrice END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SP_CalSPByPP_MarkUpAmount') THEN SP_CalSPByPP_MarkUpAmount END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SP_CalSPByPP_LastSalesDiscDate') THEN SP_CalSPByPP_LastSalesDiscDate END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='SP_CalSPByPP_UnitSalePrice') THEN SP_CalSPByPP_UnitSalePrice END DESC

					OFFSET @RecordFrom ROWS
					FETCH NEXT @PageSize ROWS ONLY
			END
		END TRY
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPNTilePriceMasters' 
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