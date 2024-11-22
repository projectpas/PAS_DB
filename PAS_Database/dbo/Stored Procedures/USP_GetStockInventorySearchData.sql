
/*************************************************************   
** Author:  <BHARGAV SALIYA>  
** Create date: <20/11/2024>  [mm/dd/yyyy]
** Description: <Get The Stock/Inventory Search Data>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	20/11/2024		BHARGAV SALIYA			Created
**************************************************************/
-----------------------------------------------------------------------------
CREATE    PROCEDURE [dbo].[USP_GetStockInventorySearchData]   
	@PageNumber INT,
	@PageSize INT,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT,
	@GlobalFilter VARCHAR(50) = NULL,
	@StockLineId BIGINT NULL,
	@PartNumber VARCHAR(100) NULL,
	@PartDescription VARCHAR(MAX) NULL,
	@IsOemPmaType VARCHAR(100) NULL,
	@StockLineNumber VARCHAR(100) NULL,
	@SerialNumber VARCHAR(100) NULL,
	@Condition VARCHAR(100) NULL,
	@UnitCost DECIMAL(18,2) NULL,
	@UnitSalesPrice DECIMAL(18,2) NULL,
	@UnitOfMeasure VARCHAR(100) NULL,
	@Currency VARCHAR(20) NULL,
	@ControlNumber VARCHAR(100) NULL,
	@LotNumber VARCHAR(100) NULL,
	@VendorName VARCHAR(100) NULL,
	@ReceivedDate DATETIME2 NULL,
	@ReceiverNumber VARCHAR(100) NULL,
	@ExpirationDate VARCHAR(100) NULL,
	@level1 VARCHAR(500) = NULL,
	@level2 VARCHAR(500) = NULL,
	@level3 VARCHAR(500) = NULL,
	@level4 VARCHAR(500) = NULL,
	@level5 VARCHAR(500) = NULL,
	@level6 VARCHAR(500) = NULL,
	@level7 VARCHAR(500) = NULL,
	@level8 VARCHAR(500) = NULL,
	@level9 VARCHAR(500) = NULL,
	@level10 VARCHAR(500) = NULL,
	@MasterCompanyId BIGINT NULL,
	@FromReceivedDate DATETIME2 = NULL,
	@ToReceivedDate DATETIME2 = NULL,
	@FromStockLineId VARCHAR(500) = NULL,
	@ToStockLineId VARCHAR(500) = NULL,
	@FromUnitCost DECIMAL(18,2) NULL,
	@ToUnitCost DECIMAL(18,2) NULL,
	@ItemMasterId BIGINT = NULL,
	@VendorId BIGINT = NULL,
	@ConditionId BIGINT = NULL,
	@LotId BIGINT = NULL,
	@TraceableTo BIGINT = NULL,
	@SiteId BIGINT = NULL,
	@WarehouseId BIGINT = NULL,
	@LocationId BIGINT = NULL,
	@ShelfId BIGINT = NULL,
	@BinId BIGINT = NULL,
	@PoRoRefrences VARCHAR(500) = NULL,
	@PoRoNumber VARCHAR(500) = NULL

AS              
	BEGIN              
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
	 SET NOCOUNT ON;              
             
	  BEGIN TRY              

		     DECLARE @Total int;
			 DECLARE @RecordFrom int; 
			 DECLARE @SearchPartNumber VARCHAR(80) = '';
			 DECLARE @SearchVendorName VARCHAR(80) = '';
			 DECLARE @SearchCondition VARCHAR(80) = '';
			 DECLARE @SearchLotNum VARCHAR(80) = '';
			 DECLARE @TraceableToName VARCHAR(80) = '';
			 DECLARE @SearchSite VARCHAR(80) = '';
			 DECLARE @SearchWarehouse VARCHAR(80) = '';
			 DECLARE @SearchLocation VARCHAR(80) = '';
			 DECLARE @SearchShelf VARCHAR(80) = '';
			 DECLARE @SearchBin VARCHAR(80) = '';
			 DECLARE @ModuleID INT = 2


			   IF OBJECT_ID('tempdb..#TempJournalDetails') IS NOT NULL
			   BEGIN
				DROP TABLE #TempJournalDetails;
			   END

			   IF OBJECT_ID(N'tempdb..#finalResult') IS NOT NULL      
			   BEGIN      
			    DROP TABLE #finalResult    
			   END 

				CREATE TABLE #TempStockInventoryDetails
				(
					ID BIGINT NOT NULL IDENTITY,
					[StockLineId] BIGINT NULL,
					[PartNumber] VARCHAR(100) NULL,
					[PartDescription] VARCHAR(MAX) NULL,
					[IsOemPmaType] VARCHAR(100) NULL,
					[StockLineNumber] VARCHAR(100) NULL,
					[SerialNumber] VARCHAR(100) NULL,
					[Condition] VARCHAR(100) NULL,
					[UnitCost] DECIMAL(18,2) NULL,
					[UnitSalesPrice] DECIMAL(18,2) NULL,
					[UnitOfMeasure] VARCHAR(100) NULL,
					[Currency] VARCHAR(20) NULL,
					[PoRoNumber] VARCHAR(100) NULL,
					[ControlNumber] VARCHAR(100) NULL,
					[LotNumber] VARCHAR(100) NULL,
					[VendorName] VARCHAR(100) NULL,
					[ReceivedDate] DATETIME2 NULL,
					[ReceiverNumber] VARCHAR(100) NULL,
					[ExpirationDate] VARCHAR(100) NULL,
					[EmployeeName] VARCHAR(256) NULL,
					level1 VARCHAR(MAX)  NULL,
					level2 VARCHAR(MAX)  NULL,
					level3 VARCHAR(MAX)  NULL,
					level4 VARCHAR(MAX)  NULL,
					level5 VARCHAR(MAX)  NULL,
					level6 VARCHAR(MAX)  NULL,
					level7 VARCHAR(MAX)  NULL,
					level8 VARCHAR(MAX)  NULL,
					level9 VARCHAR(MAX)  NULL,
					level10 VARCHAR(MAX) NULL,
					[MastercompanyId] [int] NULL
				);

			 SET @RecordFrom = (@PageNumber - 1) * @PageSize; 

			 IF @SortColumn is null  
			 Begin  
			  Set @SortColumn = Upper('StockLineId')  
			 End   
			 Else  
			 Begin   
			  Set @SortColumn = Upper(@SortColumn)  
			 End 

			 SET @FromStockLineId = (SELECT ISNULL([StockLineNumber], '') FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @FromStockLineId);
			 SET @ToStockLineId = (SELECT ISNULL([StockLineNumber], '') FROM [dbo].[Stockline] WITH(NOLOCK) WHERE [StockLineId] = @ToStockLineId);

			 SET @FromStockLineId = SUBSTRING(@FromStockLineId, PATINDEX('%[0-9]%', @FromStockLineId), LEN(@FromStockLineId));
			 SET @ToStockLineId = SUBSTRING(@ToStockLineId, PATINDEX('%[0-9]%', @ToStockLineId), LEN(@ToStockLineId));
			 
			 SET @FromStockLineId = CASE WHEN ISNULL(@FromStockLineId, '') = '' THEN '0' ELSE @FromStockLineId END;
			 SET @ToStockLineId = CASE WHEN ISNULL(@ToStockLineId, '') = '' THEN '0' ELSE @ToStockLineId END;

			 SELECT @SearchPartNumber = PartNumber FROM [dbo].[Stockline] WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId;
			 SELECT @SearchVendorName = VendorName FROM [dbo].[Vendor] WITH(NOLOCK) WHERE VendorId = @VendorId;
			 SELECT @SearchCondition = Condition FROM [dbo].[Stockline] WITH(NOLOCK) WHERE ConditionId = @ConditionId;
			 SELECT @SearchLotNum = LotNumber FROM [dbo].[Stockline] WITH(NOLOCK) WHERE LotId = @LotId;
			 SELECT @TraceableToName = TraceableToName FROM [dbo].[Stockline] WITH(NOLOCK) WHERE TraceableTo = @TraceableTo;
			 SELECT @SearchSite = [Site] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE SiteId = @SiteId;
			 SELECT @SearchWarehouse = [Warehouse] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE WarehouseId = @WarehouseId;
			 SELECT @SearchLocation = [Location] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE LocationId = @LocationId;
			 SELECT @SearchShelf = [Shelf] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE ShelfId = @ShelfId;
			 SELECT @SearchBin = [Bin] FROM [dbo].[Stockline] WITH(NOLOCK) WHERE BinId = @BinId;
			 

				INSERT INTO #TempStockInventoryDetails([StockLineId],[PartNumber],[PartDescription],[IsOemPmaType],[StockLineNumber],[SerialNumber],Condition,UnitCost,UnitSalesPrice,
						 UnitOfMeasure,Currency,[PoRoNumber],[ControlNumber],[LotNumber],[VendorName],[ReceivedDate],[ReceiverNumber],[ExpirationDate],
						 EmployeeName,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10)
			           
					SELECT DISTINCT 
						 S.[StockLineId],
						 S.[PartNumber],
						 S.[PNDescription] AS [PartDescription],
						 CASE WHEN ISNULL(S.OEM, 0) > 0 THEN 'OEM' ELSE 'PMA' END AS IsOemPmaType,
						 S.[StockLineNumber],
						 S.[SerialNumber],
						 S.Condition,
						 S.UnitCost,
						 S.UnitSalesPrice,
						 S.UnitOfMeasure,
						 C.Code as Currency,
						 CASE WHEN ISNULL(S.RepairOrderId,0) > 0 THEN RO.RepairOrderNumber
							  WHEN ISNULL(S.PurchaseOrderId,0) > 0 THEN PO.PurchaseOrderNumber
							  ELSE '' END AS [PoRoNumber],
						 --S.RepairOrderNumber as [PoRoNumber],
						 S.[ControlNumber],
						 S.[LotNumber],
						 V.[VendorName],
						 S.[ReceivedDate],
						 S.[ReceiverNumber],
						 S.[ExpirationDate],
						'' AS 'EmployeeName',  
						UPPER(SLM.Level1Name) AS level1,  
						UPPER(SLM.Level2Name) AS level2, 
						UPPER(SLM.Level3Name) AS level3, 
						UPPER(SLM.Level4Name) AS level4, 
						UPPER(SLM.Level5Name) AS level5, 
						UPPER(SLM.Level6Name) AS level6, 
						UPPER(SLM.Level7Name) AS level7, 
						UPPER(SLM.Level8Name) AS level8, 
						UPPER(SLM.Level9Name) AS level9, 
						UPPER(SLM.Level10Name) AS level10


					FROM dbo.[Stockline] S WITH(NOLOCK) 
					INNER JOIN [dbo].[StocklineManagementStructureDetails] SLM WITH(NOLOCK) ON  SLM.ModuleID = @ModuleID AND SLM.ReferenceID = S.StockLineId
					INNER JOIN [DBO].[ItemMaster] IT WITH(NOLOCK) ON S.ItemMasterId = IT.ItemMasterId
					LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON S.VendorId = V.VendorId
					LEFT JOIN  [DBO].[Currency] C WITH(NOLOCK) ON IT.CurrencyId = C.CurrencyId
					LEFT JOIN  [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON S.PurchaseOrderId = po.PurchaseOrderId
					LEFT JOIN  [DBO].[RepairOrder] RO WITH(NOLOCK) ON S.RepairOrderId = Ro.RepairOrderId
					WHERE CAST(S.ReceivedDate AS date) BETWEEN CAST(@FromReceivedDate AS date) AND CAST(@ToReceivedDate AS date) AND S.MasterCompanyId = @MasterCompanyId 
					AND ((ISNULL(@FromStockLineId, '') = '0' OR ISNULL(@ToStockLineId, '') = '0') OR 
					SUBSTRING(S.[StockLineNumber], PATINDEX('%[0-9]%', S.[StockLineNumber]), LEN(S.[StockLineNumber])) BETWEEN CAST(@FromStockLineId AS numeric) AND CAST(@ToStockLineId AS numeric))
					AND (ISNULL(CAST(@FromUnitCost AS INT), 0) = 0 OR ISNULL(CAST(@ToUnitCost AS INT), 0) = 0 OR (S.UnitCost BETWEEN CAST(@FromUnitCost AS INT) AND CAST(@ToUnitCost AS INT)))
					AND (ISNULL(@FromUnitCost, 0) = 0 OR ISNULL(@ToUnitCost, 0) = 0 OR (S.UnitCost BETWEEN @FromUnitCost AND @ToUnitCost))
					AND (ISNULL(@ItemMasterId , 0) = 0 OR UPPER(S.[PartNumber]) = UPPER(@SearchPartNumber)) 
					AND (ISNULL(@VendorId , 0) = 0 OR UPPER(V.[VendorName]) = UPPER(@SearchVendorName)) 
					AND (ISNULL(@ConditionId , 0) = 0 OR UPPER([Condition]) = UPPER(@SearchCondition)) 
					AND (ISNULL(@LotId , 0) = 0 OR UPPER([LotNumber]) = UPPER(@SearchLotNum)) 
					AND (ISNULL(@TraceableTo , 0) = 0 OR UPPER([TraceableToName]) = UPPER(@TraceableToName)) 
					AND (ISNULL(@SiteId , 0) = 0 OR UPPER([Site]) = UPPER(@SearchSite)) 
					AND (ISNULL(@WarehouseId , 0) = 0 OR UPPER([Warehouse]) = UPPER(@SearchWarehouse)) 
					AND (ISNULL(@LocationId , 0) = 0 OR UPPER([Location]) = UPPER(@SearchLocation)) 
					AND (ISNULL(@ShelfId , 0) = 0 OR UPPER([Shelf]) = UPPER(@SearchShelf)) 
					AND (ISNULL(@BinId , 0) = 0 OR UPPER([Bin]) = UPPER(@SearchBin)) 
					AND (ISNULL(@PoRoRefrences,'') = '' OR (@PoRoRefrences = Po.PurchaseOrderNumber  OR @PoRoRefrences = RO.RepairOrderNumber)) 
					AND  (ISNULL(@Level1,'') ='' OR SLM.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))    
					AND  (ISNULL(@Level2,'') ='' OR SLM.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
					AND  (ISNULL(@Level3,'') ='' OR SLM.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
					AND  (ISNULL(@Level4,'') ='' OR SLM.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
					AND  (ISNULL(@Level5,'') ='' OR SLM.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
					AND  (ISNULL(@Level6,'') ='' OR SLM.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
					AND  (ISNULL(@Level7,'') ='' OR SLM.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
					AND  (ISNULL(@Level8,'') ='' OR SLM.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
					AND  (ISNULL(@Level9,'') ='' OR SLM.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
					AND  (ISNULL(@Level10,'') =''  OR SLM.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,','))
					)      
					
				SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
				SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END


		 select * into #finalResult
		 FROM #TempStockInventoryDetails
		 WHERE (
		 (ISNULL(@PartNumber,'') ='' OR [PartNumber] LIKE '%' + @PartNumber+'%') AND
		 (ISNULL(@PartDescription,'') ='' OR [PartDescription] LIKE '%' + @PartDescription+'%') AND
		 (ISNULL(@StockLineNumber,0) = 0 OR [StockLineNumber] = @StockLineNumber) AND
		 (ISNULL(@SerialNumber,0) = 0 OR [SerialNumber] = @SerialNumber) AND
		 (ISNULL(@Condition,'') ='' OR [Condition] LIKE '%' + @Condition+'%') AND
		 --(ISNULL(@UnitCost,'') ='' OR [UnitCost] LIKE '%' + @UnitCost+'%') AND
		 --(ISNULL(@UnitSalesPrice,'') ='' OR [UnitSalesPrice] LIKE '%' + @UnitSalesPrice+'%') AND
		 (ISNULL(@UnitOfMeasure,'') ='' OR [UnitOfMeasure] LIKE '%' + @UnitOfMeasure+'%') AND
		 (ISNULL(@Currency,'') ='' OR [Currency] LIKE '%' + @Currency+'%') AND
		 (ISNULL(@PoRoNumber,'') ='' OR [PoRoNumber] LIKE '%' + @PoRoNumber+'%') AND
		 (ISNULL(@ControlNumber,'') ='' OR [ControlNumber] LIKE '%' + @ControlNumber+'%') AND
		 (ISNULL(@LotNumber,'') ='' OR [LotNumber] LIKE '%' + @LotNumber+'%') AND
		 (ISNULL(@VendorName,'') ='' OR [VendorName] LIKE '%' + @VendorName+'%') AND
		 (ISNULL(@ReceivedDate,'') ='' OR CAST([ReceivedDate] AS DATE) = CAST(@ReceivedDate AS DATE)) AND
		 (ISNULL(@ReceiverNumber,'') ='' OR [ReceiverNumber]  LIKE '%' + @ReceiverNumber+'%') AND
		 (ISNULL(@ExpirationDate,'') ='' OR CAST([ExpirationDate] AS DATE) = CAST(@ExpirationDate AS DATE)))

		 SET @Total = (SELECT TOP 1 COUNT(1) OVER () AS TotalRecordsCount FROM #finalResult); 
		 select @Total as NumberOfItems, * from #finalResult

		 --Select @Total = COUNT(StocklineId) from #finalResult 
		 --SELECT *, @Total As NumberOfItems FROM #finalResult 
		 ORDER BY 
		 CASE WHEN (@SortOrder=1 and @SortColumn='PartNumber')  THEN [PartNumber] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='PartDescription')  THEN [PartDescription] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='StockLineNumber')  THEN [StockLineNumber] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN [SerialNumber] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='Condition')  THEN [Condition] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='UnitOfMeasure')  THEN [UnitOfMeasure] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='Currency')  THEN [Currency] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='PoRoNumber')  THEN [PoRoNumber] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='ControlNumber')  THEN [ControlNumber] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='LotNumber')  THEN [LotNumber] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='VendorName')  THEN [VendorName] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='ReceivedDate')  THEN [ReceivedDate] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='ReceiverNumber')  THEN [ReceiverNumber] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='ExpirationDate')  THEN [ExpirationDate] END ASC,  
		 CASE WHEN (@SortOrder=1 and @SortColumn='level1')  THEN [level1] END ASC, 
		 CASE WHEN (@SortOrder=1 and @SortColumn='level2')  THEN [level2] END ASC, 
		 CASE WHEN (@SortOrder=1 and @SortColumn='level3')  THEN [level3] END ASC, 
		 CASE WHEN (@SortOrder=1 and @SortColumn='level4')  THEN [level4] END ASC, 
		 CASE WHEN (@SortOrder=1 and @SortColumn='level5')  THEN [level5] END ASC, 
		 CASE WHEN (@SortOrder=1 and @SortColumn='level6')  THEN [level6] END ASC, 
		 CASE WHEN (@SortOrder=1 and @SortColumn='level7')  THEN [level7] END ASC, 
		 CASE WHEN (@SortOrder=1 and @SortColumn='level8')  THEN [level8] END ASC, 
		 CASE WHEN (@SortOrder=1 and @SortColumn='level9')  THEN [level9] END ASC, 
		 CASE WHEN (@SortOrder=1 and @SortColumn='level10')  THEN [level10] END ASC, 

		 CASE WHEN (@SortOrder=-1 and @SortColumn='PartNumber')  THEN [PartNumber] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='PartDescription')  THEN [PartDescription] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='StockLineNumber')  THEN [StockLineNumber] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN [SerialNumber] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='Condition')  THEN [Condition] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='UnitOfMeasure')  THEN [UnitOfMeasure] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='Currency')  THEN [Currency] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='PoRoNumber')  THEN [PoRoNumber] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='ControlNumber')  THEN [ControlNumber] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='LotNumber')  THEN [LotNumber] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='VendorName')  THEN [VendorName] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='ReceivedDate')  THEN [ReceivedDate] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='ReceiverNumber')  THEN [ReceiverNumber] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='ExpirationDate')  THEN [ExpirationDate] END Desc,  
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level1')  THEN [level1] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level2')  THEN [level2] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level3')  THEN [level3] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level4')  THEN [level4] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level5')  THEN [level5] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level6')  THEN [level6] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level7')  THEN [level7] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level8')  THEN [level8] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level9')  THEN [level9] END Desc, 
		 CASE WHEN (@SortOrder=-1 and @SortColumn='level10')  THEN [level10] END Desc

			OFFSET @RecordFrom ROWS   
			FETCH NEXT @PageSize ROWS ONLY
             
	 END TRY                  
  BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetStockInventorySearchData'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
			  + '@Parameter7 = ''' + CAST(ISNULL(@masterCompanyID, '') AS VARCHAR(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH       
END