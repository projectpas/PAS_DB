/****** Object:  StoredProcedure [dbo].[GetPNTileExchangeQuoteList]    Script Date: 12/6/2023 3:30:21 PM ******/
/*************************************************************           
 ** File:   [GetPNTileSalesOrderQuoteList]           
 ** Author:   Bhargav Saliya
 ** Description: This stored procedure is used get list of Exchange Quote history data for dashboard
 ** Purpose:         
 ** Date:      16 Jan 2024
          
 ** PARAMETERS:           
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
	1    16 Jan 2024  Bhargav Saliya		Create
	
**************************************************************/
CREATE    PROCEDURE [dbo].GetPNTileExchangeQuoteList
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@StatusID int = 1,
	@Status varchar(50) = 'Open',
	@GlobalFilter varchar(50) = '',	
	@PartNumber varchar(50) = NULL,	
	@PartDescription varchar(max) = NULL,
	@ManufacturerName varchar(max) = NULL,
	@ExchangeQuoteNumber varchar(50) = NULL,
	@ExchangeSalesOrderNumber varchar(50) = NULL,
	@OpenDate  datetime = NULL,
	@CustomerReference varchar(50) = NULL,
	@UnitCost varchar(50)= NULL,
	@Qty varchar(50)= NULL,
	@UnitCostExtended varchar(50)= NULL,
	@ConditionName varchar(50) = NULL,	
	@SalesPersonName varchar(50)= NULL,
	@ShipDate datetime = NULL,
	@CustomerName varchar(50) = NULL,
	@IsDeleted bit = 0,
	@EmployeeId bigint=0,
	@ItemMasterId bigint=0,
	@MasterCompanyId bigint=1,
	@StatusValue varchar(50) = NULL,
	@ConditionId VARCHAR(250) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		    
		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;		
		-- Exchange Quote Management Structure Module ID
		DECLARE @MSModuleID INT = (SELECT ManagementStructureModuleId FROM [DBO].ManagementStructureModule WHERE [ModuleName] = 'ExchangeQuoteHeader'); 
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=Upper(@SortColumn)
		END	
		BEGIN TRY		
		BEGIN			
			;WITH Result AS(									
		   	 SELECT DISTINCT 
					EQ.[ExchangeQuoteId],
					EP.[ExchangeQuotePartId],
					EP.[ItemMasterId],
					IM.[PartNumber],
					IM.[PartDescription],
					EQ.[ExchangeQuoteNumber],
		            ESO.[ExchangeSalesOrderNumber],
					EQ.[OpenDate],
					EQ.[CustomerReference],
					--0 AS [UnitCost],
					--0 AS [Qty],
					--0 AS [UnitCostExtended],
					CO.[Description] AS [ConditionName],
					EP.ConditionId,
					EQ.[SalesPersonName],
					ESS.[ShipDate],
					EQ.[CustomerId],
					CU.[Name] AS [CustomerName],
					EQ.[IsDeleted],					
					EQ.[CreatedDate],
				    EQ.[CreatedBy],					
				    EQ.[IsActive],					
					EQ.[StatusId],				
					EQ.[StatusName] AS StatusValue,
					ISNULL(IM.ManufacturerName,'')ManufacturerName

			   FROM [dbo].[ExchangeQuote] EQ WITH (NOLOCK)	
			   INNER JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.CustomerId = EQ.CustomerId
			   INNER JOIN [dbo].[ExchangeManagementStructureDetails] ESD WITH (NOLOCK) ON ESD.ModuleID = @MSModuleID AND ESD.ReferenceID = EQ.ExchangeQuoteId
			   INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON EQ.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			   LEFT JOIN [dbo].[ExchangeQuotePart] EP WITH (NOLOCK) ON EQ.ExchangeQuoteId = EP.ExchangeQuoteId and EP.IsDeleted = 0
			   LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = EP.ItemMasterId
			   LEFT JOIN [dbo].[Condition] CO WITH (NOLOCK) ON CO.ConditionId = EP.ConditionId
			   LEFT JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) on ESO.ExchangeQuoteId = EQ.ExchangeQuoteId AND ESO.ExchangeQuoteId IS NOT NULL
			   LEFT JOIN [dbo].[ExchangeSalesOrderPart] ESOP WITH (NOLOCK) on ESOP.ExchangeQuotePartId = EP.ExchangeQuotePartId AND ESOP.ExchangeQuotePartId IS NOT NULL
			   LEFT JOIN [dbo].[ExchangeSalesOrderShippingItem] ESST WITH (NOLOCK) ON ESST.ExchangeSalesOrderPartId = ESOP.ExchangeQuotePartId
			   LEFT JOIN [dbo].[ExchangeSalesOrderShipping] ESS WITH (NOLOCK) ON ESST.ExchangeSalesOrderShippingId = ESS.ExchangeSalesOrderShippingId								
			WHERE EQ.MasterCompanyId = @MasterCompanyId
			      AND EQ.IsDeleted = 0
				  AND EP.ItemMasterId = @ItemMasterId	
				  AND (@ConditionId IS NULL OR EP.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))
			), ResultCount AS(SELECT COUNT(ExchangeQuoteId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR
					(StatusValue LIKE '%' +@GlobalFilter+'%') OR
					(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR
					(ExchangeQuoteNumber LIKE '%' +@GlobalFilter+'%') OR	
					(ExchangeSalesOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
					(CustomerReference LIKE '%' +@GlobalFilter+'%') OR
					(ConditionName LIKE '%' +@GlobalFilter+'%') OR	
					(SalesPersonName LIKE '%' +@GlobalFilter+'%') OR
					(CustomerName LIKE '%' +@GlobalFilter+'%'))
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND 
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@StatusValue,'') ='' OR StatusValue LIKE '%' + @StatusValue + '%') AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@ExchangeQuoteNumber,'') ='' OR ExchangeQuoteNumber LIKE '%' + @ExchangeQuoteNumber + '%') AND
					(ISNULL(@ExchangeSalesOrderNumber,'') ='' OR ExchangeSalesOrderNumber LIKE '%' + @ExchangeSalesOrderNumber + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND	
					(ISNULL(@CustomerReference,'') ='' OR CustomerReference LIKE '%' + @CustomerReference + '%') AND
					(ISNULL(@ConditionName,'') ='' OR ConditionName LIKE '%' + @ConditionName + '%') AND
					(ISNULL(@SalesPersonName,'') ='' OR SalesPersonName LIKE '%' + @SalesPersonName + '%') AND
					(ISNULL(@ShipDate,'') ='' OR CAST(ShipDate AS DATE) = CAST(@ShipDate AS DATE)) AND	
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%'))))		
					
			SELECT @Count = COUNT(ExchangeQuoteId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY 
			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='StatusValue')  THEN StatusValue END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StatusValue')  THEN StatusValue END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ExchangeQuoteNumber')  THEN ExchangeQuoteNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ExchangeQuoteNumber')  THEN ExchangeQuoteNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ExchangeSalesOrderNumber')  THEN ExchangeSalesOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ExchangeSalesOrderNumber')  THEN ExchangeSalesOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerReference')  THEN CustomerReference END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerReference')  THEN CustomerReference END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConditionName')  THEN ConditionName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConditionName')  THEN ConditionName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SalesPersonName')  THEN SalesPersonName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SalesPersonName')  THEN SalesPersonName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ShipDate')  THEN ShipDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ShipDate')  THEN ShipDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		
		END		
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPNTileExchangeQuoteList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeQuoteNumber, '') + ''
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