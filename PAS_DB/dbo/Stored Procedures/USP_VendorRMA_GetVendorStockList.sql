/*************************************************************           
 ** File:   [USP_VendorRMA_GetVendorStockList]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Get Vendor Stock Listing 
 ** Date:   06/12/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date					Author  		Change Description            
 ** --   --------			-------		---------------------------     
    1    06/12/2023			Moin Bloch			Created
    1    12-July-2023		Devendra SHekh     added condition to for @IsVCMAdd
*******************************************************************************
*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_GetVendorStockList] 
@PageNumber INT = 1,
@PageSize INT = 10,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,
@GlobalFilter varchar(50) = '',	
@ReferenceNumber VARCHAR(50) = NULL,
@PartNumber VARCHAR(50) = NULL,
@SerialNumber VARCHAR(50) = NULL,
@VendorName VARCHAR(50) = NULL,
@StockLineNumber VARCHAR(50) = NULL,
@ReceivedDate DATETIME = NULL,
@MasterCompanyId BIGINT = NULL,
@EmployeeId BIGINT = NULL,
@VendorId BIGINT = NULL,
@IsVCMAdd BIT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY  
		DECLARE @Count INT;
		DECLARE @RecordFrom INT;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		DECLARE @POModuleId INT;
		DECLARE @ROModuleId INT;

		SELECT @POModuleId = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'PurchaseOrder');
		SELECT @ROModuleId = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'RepairOrder');
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = UPPER('CreatedDate')
			SET @SortOrder = -1
		END 
		ELSE
		BEGIN 
			SET @SortColumn = UPPER(@SortColumn)
		END

		IF(@VendorId IS NULL)
		BEGIN
			SET @VendorId = 0;
		END

		DECLARE @EmpLegalEntiyId BIGINT = 0;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

		SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
		SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
		WHERE LE.LegalEntityId = @EmpLegalEntiyId;

		IF @IsVCMAdd IS NULL OR @IsVCMAdd = 0
		BEGIN
			;WITH Result AS (	
			SELECT DISTINCT
				SL.[StockLineId]
			   ,SL.[VendorId]
			   ,SL.[PurchaseOrderId]
			   ,SL.[RepairOrderId]
			   ,CASE WHEN SL.[PurchaseOrderId] > 0 THEN PO.[PurchaseOrderNumber] WHEN SL.[RepairOrderId] > 0 THEN RO.[RepairOrderNumber] ELSE '' END 'ReferenceNumber' 
			   ,CASE WHEN SL.[PurchaseOrderId] > 0 THEN SL.[PurchaseOrderId] WHEN SL.[RepairOrderId] > 0 THEN SL.[RepairOrderId] ELSE 0 END 'ReferenceId' 
			   ,CASE WHEN SL.[PurchaseOrderId] > 0 THEN @POModuleId WHEN SL.[RepairOrderId] > 0 THEN @ROModuleId ELSE 0 END 'ModuleId'
			   ,SL.[ItemMasterId]
			   ,IM.[partnumber] 'PartNumber'
			   ,IM.[PartDescription]
			   ,SL.[SerialNumber]
			   ,SL.[QuantityAvailable]
			   ,SL.[UnitCost]
			   ,VO.[VendorName]
			   ,VO.[VendorCode]
			   ,SL.[StockLineNumber]
			   ,SL.[IdNumber]
			   ,SL.[ControlNumber]
			   ,CAST(SL.[ReceivedDate] AS DATE) AS [ReceivedDate]
			   ,SL.[CreatedDate]
			   ,0 AS [IsSelected]
		  FROM [dbo].[Stockline] SL WITH (NOLOCK)
		  INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.[ItemMasterId] = IM.[ItemMasterId]
		  LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON SL.[PurchaseOrderId] = PO.[PurchaseOrderId]
		  LEFT JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON SL.[RepairOrderId] = RO.[RepairOrderId]
		  LEFT JOIN [dbo].[Vendor] VO WITH (NOLOCK) ON SL.[VendorId] = VO.[VendorId]
			WHERE ISNULL(SL.[IsDeleted],0) = 0 AND ISNULL(SL.[IsActive],1) = 1 AND SL.[MasterCompanyId] = @MasterCompanyId AND SL.[IsParent] = 1
			AND SL.[QuantityOnHand] > 0 AND SL.[QuantityAvailable] > 0 AND (@VendorId = 0 OR SL.[VendorId] = @VendorId) AND (SL.[PurchaseOrderId] > 0 OR SL.[RepairOrderId] > 0) 
		), ResultCount AS(SELECT COUNT([StockLineId]) AS totalItems FROM Result) 
		
		SELECT * INTO #TempResult FROM  Result 
			WHERE 
			 ((@GlobalFilter <>'' AND (([ReferenceNumber] LIKE '%' + @GlobalFilter + '%') OR
					([PartNumber] LIKE '%' + @GlobalFilter + '%') OR
					([SerialNumber] LIKE '%' + @GlobalFilter + '%') OR
					([VendorName] LIKE '%' + @GlobalFilter + '%') OR
					([StockLineNumber] LIKE '%' + @GlobalFilter + '%')))					
					OR
					(@GlobalFilter = '' AND (ISNULL(@ReferenceNumber, '') = '' OR [ReferenceNumber] LIKE '%' + @ReferenceNumber + '%') AND
					(ISNULL(@PartNumber, '') = '' OR [PartNumber] LIKE '%' + @PartNumber + '%') AND
					(ISNULL(@SerialNumber, '') = '' OR [SerialNumber] LIKE '%' + @SerialNumber + '%') AND
					(ISNULL(@VendorName, '') = '' OR [VendorName] LIKE '%' + @VendorName + '%') AND
					(ISNULL(@StockLineNumber, '') = '' OR [StockLineNumber] LIKE '%' + @StockLineNumber + '%') AND
					(ISNULL(@ReceivedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal([ReceivedDate], @CurrntEmpTimeZoneDesc) AS DATE) = CAST(@ReceivedDate AS DATE)))   
				  --(ISNULL(@ReceivedDate,'') ='' OR CAST([ReceivedDate] AS DATE) = CAST(@ReceivedDate AS DATE)))
				  )

			SELECT @Count = COUNT([StockLineId]) FROM #TempResult			

			SELECT @Count AS NumberOfItems, [StockLineId],[VendorId],[PurchaseOrderId],[RepairOrderId],[ReferenceNumber],[ReferenceId],[ModuleId],[ItemMasterId],[PartNumber],[PartDescription],[SerialNumber],[QuantityAvailable],[UnitCost],[VendorName],[VendorCode],[StockLineNumber],[IdNumber],[ControlNumber],[ReceivedDate],[CreatedDate],[IsSelected], @Count AS NumberOfItems FROM #TempResult WHERE [ModuleId] > 0
			ORDER BY  
			CASE WHEN (@SortOrder = 1  AND @SortColumn='ReferenceNumber') THEN ReferenceNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='ReferenceNumber') THEN ReferenceNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='PartNumber') THEN PartNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber') THEN PartNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='SerialNumber') THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='SerialNumber') THEN SerialNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='VendorName') THEN VendorName END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='VendorName') THEN VendorName END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='StockLineNumber') THEN StockLineNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='StockLineNumber') THEN StockLineNumber END DESC,	
			CASE WHEN (@SortOrder = 1  AND @SortColumn='ReceivedDate') THEN ReceivedDate END ASC,
			CASE WHEN (@SortOrder = -1 and @SortColumn='ReceivedDate') THEN ReceivedDate END DESC,  
			CASE WHEN (@SortOrder = 1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder = -1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY	
		END
		ELSE 
		BEGIN
			;WITH Result AS (	
			SELECT DISTINCT
				SL.[StockLineId]
			   ,SL.[VendorId]
			   ,SL.[PurchaseOrderId]
			   ,SL.[RepairOrderId]
			   ,CASE WHEN SL.[PurchaseOrderId] > 0 THEN PO.[PurchaseOrderNumber] WHEN SL.[RepairOrderId] > 0 THEN RO.[RepairOrderNumber] ELSE '' END 'ReferenceNumber' 
			   ,CASE WHEN SL.[PurchaseOrderId] > 0 THEN SL.[PurchaseOrderId] WHEN SL.[RepairOrderId] > 0 THEN SL.[RepairOrderId] ELSE 0 END 'ReferenceId' 
			   ,CASE WHEN SL.[PurchaseOrderId] > 0 THEN @POModuleId WHEN SL.[RepairOrderId] > 0 THEN @ROModuleId ELSE 0 END 'ModuleId'
			   ,SL.[ItemMasterId]
			   ,IM.[partnumber] 'PartNumber'
			   ,IM.[PartDescription]
			   ,SL.[SerialNumber]
			   ,SL.[QuantityAvailable]
			   ,SL.[UnitCost]
			   ,VO.[VendorName]
			   ,VO.[VendorCode]
			   ,SL.[StockLineNumber]
			   ,SL.[IdNumber]
			   ,SL.[ControlNumber]
			   ,CAST(SL.[ReceivedDate] AS DATE) AS [ReceivedDate]
			   ,SL.[CreatedDate]
			   ,0 AS [IsSelected]
		  FROM [dbo].[Stockline] SL WITH (NOLOCK)
		  INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SL.[ItemMasterId] = IM.[ItemMasterId]
		  LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON SL.[PurchaseOrderId] = PO.[PurchaseOrderId]
		  LEFT JOIN [dbo].[RepairOrder] RO WITH (NOLOCK) ON SL.[RepairOrderId] = RO.[RepairOrderId]
		  LEFT JOIN [dbo].[Vendor] VO WITH (NOLOCK) ON SL.[VendorId] = VO.[VendorId]
			WHERE ISNULL(SL.[IsDeleted],0) = 0 AND ISNULL(SL.[IsActive],1) = 1 AND SL.[MasterCompanyId] = @MasterCompanyId AND SL.[IsParent] = 1
			AND SL.[QuantityOnHand] > 0 AND SL.[QuantityAvailable] > 0 AND (@VendorId = 0 OR SL.[VendorId] = @VendorId) AND (SL.[PurchaseOrderId] > 0 OR SL.[RepairOrderId] > 0) 
			AND SL.StockLineId NOT IN 
			(SELECT StockLineId FROM VendorCreditMemoDetail vcmd WITH(NOLOCK)
			LEFT JOIN [dbo].[VendorCreditMemo] vcm WITH(NOLOCK) ON vcmd.VendorCreditMemoId = vcm.VendorCreditMemoId 
			WHERE vcmd.VendorRMAId = 0 AND vcm.VendorCreditMemoStatusId != (SELECT Id FROM CreditMemoStatus WHERE [Name] = 'Closed'))
		), ResultCount AS(SELECT COUNT([StockLineId]) AS totalItems FROM Result) 
		
		SELECT * INTO #TempResultData FROM  Result 
			WHERE 
			 ((@GlobalFilter <>'' AND (([ReferenceNumber] LIKE '%' + @GlobalFilter + '%') OR
					([PartNumber] LIKE '%' + @GlobalFilter + '%') OR
					([SerialNumber] LIKE '%' + @GlobalFilter + '%') OR
					([VendorName] LIKE '%' + @GlobalFilter + '%') OR
					([StockLineNumber] LIKE '%' + @GlobalFilter + '%')))					
					OR
					(@GlobalFilter = '' AND (ISNULL(@ReferenceNumber, '') = '' OR [ReferenceNumber] LIKE '%' + @ReferenceNumber + '%') AND
					(ISNULL(@PartNumber, '') = '' OR [PartNumber] LIKE '%' + @PartNumber + '%') AND
					(ISNULL(@SerialNumber, '') = '' OR [SerialNumber] LIKE '%' + @SerialNumber + '%') AND
					(ISNULL(@VendorName, '') = '' OR [VendorName] LIKE '%' + @VendorName + '%') AND
					(ISNULL(@StockLineNumber, '') = '' OR [StockLineNumber] LIKE '%' + @StockLineNumber + '%') AND
					(ISNULL(@ReceivedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal([ReceivedDate], @CurrntEmpTimeZoneDesc) AS DATE) = CAST(@ReceivedDate AS DATE)))   
				  --(ISNULL(@ReceivedDate,'') ='' OR CAST([ReceivedDate] AS DATE) = CAST(@ReceivedDate AS DATE)))
				  )

			SELECT @Count = COUNT([StockLineId]) FROM #TempResultData			

			SELECT @Count AS NumberOfItems, [StockLineId],[VendorId],[PurchaseOrderId],[RepairOrderId],[ReferenceNumber],[ReferenceId],[ModuleId],[ItemMasterId],[PartNumber],[PartDescription],[SerialNumber],[QuantityAvailable],[UnitCost],[VendorName],[VendorCode],[StockLineNumber],[IdNumber],[ControlNumber],[ReceivedDate],[CreatedDate],[IsSelected] FROM #TempResultData WHERE [ModuleId] > 0
			ORDER BY  
			CASE WHEN (@SortOrder = 1  AND @SortColumn='ReferenceNumber') THEN ReferenceNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='ReferenceNumber') THEN ReferenceNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='PartNumber') THEN PartNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber') THEN PartNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='SerialNumber') THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='SerialNumber') THEN SerialNumber END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='VendorName') THEN VendorName END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='VendorName') THEN VendorName END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn='StockLineNumber') THEN StockLineNumber END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn='StockLineNumber') THEN StockLineNumber END DESC,	
			CASE WHEN (@SortOrder = 1  AND @SortColumn='ReceivedDate') THEN ReceivedDate END ASC,
			CASE WHEN (@SortOrder = -1 and @SortColumn='ReceivedDate') THEN ReceivedDate END DESC,  
			CASE WHEN (@SortOrder = 1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder = -1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY	
		END

  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
		    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_VendorRMA_GetVendorStockList]'
			,@ProcedureParameters VARCHAR(3000)  = '@PageNumber = '''+ ISNULL(@PageNumber, '') + ''',  
             @PageSize = ' + ISNULL(@PageSize,'') + ',   
             @SortColumn = ' + ISNULL(@SortColumn,'') + ',   
             @SortOrder = ' + ISNULL(@SortOrder,'') + ',   
             @GlobalFilter = ' + ISNULL(@GlobalFilter,'') + ',
			 @ReferenceNumber = ' + ISNULL(@ReferenceNumber,'') + ',
			 @PartNumber = ' + ISNULL(@PartNumber,'') + ',
			 @SerialNumber = ' + ISNULL(@SerialNumber,'') + ',
			 @VendorName = ' + ISNULL(@VendorName,'') + ',
			 @StockLineNumber = ' + ISNULL(@StockLineNumber,'') + ',
			 @MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(10)) ,'') +''
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