/**************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			 Author				Change Description              
 ** --   --------		 -------			------------------------------            
    1    10/10/2023		 Ayesha Sultana		Implementing Searching, Sorting & Paging Functionality
	2    18/10/2023      Moin Bloch         Revert SP Changes For Implementing Searching, Sorting & Paging Functionality
	3    07/11/2023		 Moin Bloch  		Implementing Searching, Sorting & Paging Functionality
	4    21/12/2023		 Moin Bloch  		Added ReferenceNumber
	5	 19/12/2024		 Abhishek Jirawla	Switching between Po view and PN view
	
	EXEC GetReceivingReconciliationPopupData 1,10,NULL,-1,'',NULL,NULL,NULL,NULL,1,59
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetReceivingReconciliationPopupData]	
	@PageNumber int = NULL,
	@PageSize int = NULL,
	@SortColumn varchar(50) = NULL,
	@SortOrder int = -1,
	@GlobalFilter varchar(50) = NULL,
	@PartNumber varchar(50) = NULL,
	@PartDescription varchar(100) = NULL,
	@PORONum varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@MasterCompanyId int = NULL,
	@VendorId bigint = NULL,
	@ReferenceNumber VARCHAR(MAX) = NULL,
	@ViewType VARCHAR(50) = NULL -- 1 for PO View and 2 for PN View
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		IF @ViewType IS NULL
		BEGIN
			SET  @ViewType = 'poview' -- Show PO View
		END

		DECLARE @StockTypeId INT = 0;
		DECLARE @AssetTypeId INT =0;
		DECLARE @NonStockTypeId INT =0;

		SELECT @StockTypeId = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [Description] = 'Stock';
		SELECT @NonStockTypeId = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [Description] = 'Non-Stock';
		SELECT @AssetTypeId = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [Description] = 'Asset';

		DECLARE @RecordFrom INT;
		DECLARE @Count INT;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
					
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = UPPER('CreatedDate')
		END 
		Else
		BEGIN 
			SET @SortColumn = UPPER(@SortColumn)
		END

		IF(@ReferenceNumber IS NULL OR @ReferenceNumber = '')
		BEGIN
			SET @ReferenceNumber = NULL
		END

		IF OBJECT_ID(N'tempdb..#UpdatedTempTable') IS NOT NULL      
		BEGIN      
		  DROP TABLE #UpdatedTempTable      
		END 

		CREATE TABLE #UpdatedTempTable (       			   
		   [PurchaseOrderId] BIGINT NULL,    
		   [PurchaseOrderNumber] VARCHAR(50) NULL,  
		   [PartNumber] VARCHAR(250) NULL,  
		   [PartDescription] NVARCHAR(MAX) NULL,
		   [PurchaseOrderPartRecordId] VARCHAR(50) NULL,   
		   [CreatedDate] DATETIME2(7) NULL, 
		   [Type] INT NULL,
		   [IsSelected] BIT NULL,			
		)
				
		IF @ViewType = 'poview'
		BEGIN
			;WITH Result AS(		
				SELECT DISTINCT po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartNumber END) AS PartNumber,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartDescription END) AS PartDescription,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse CAST(partData.MaxPurchaseOrderPartRecordId AS VARCHAR(50)) END) AS PurchaseOrderPartRecordId,
								po.[CreatedDate],
								1 AS 'Type',		
								0 AS IsSelected
						   FROM [dbo].[PurchaseOrder] po WITH(NOLOCK)
								INNER JOIN [dbo].[PurchaseOrderPart] pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
								INNER JOIN [dbo].[Stockline] stk WITH(NOLOCK) ON po.PurchaseOrderId = stk.PurchaseOrderId  AND stk.IsParent=1 AND stk.RRQty > 0 --AND (pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId)
								OUTER APPLY (
									SELECT 
										COUNT(PurchaseOrderPartRecordId) AS PurchaseOrderPartRecordCount,
										MAX(PartNumber) AS MaxPartNumber,
										MAX(PartDescription) AS MaxPartDescription,
										MAX(PurchaseOrderPartRecordId) AS MaxPurchaseOrderPartRecordId
									FROM [dbo].[PurchaseOrderPart] pop WITH(NOLOCK)
									WHERE pop.PurchaseOrderId = po.PurchaseOrderId 
									  AND pop.isParent = 1
								) AS partData
							WHERE po.VendorId=@VendorId AND pop.ItemTypeId = @StockTypeId AND po.MasterCompanyId = @MasterCompanyId
							AND ISNULL((SELECT COUNT(POS.PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart POS  WITH(NOLOCK) WHERE POS.ParentId =stk.PurchaseOrderPartRecordId ),0) = 0
							GROUP BY po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								po.[CreatedDate],
								partData.[PurchaseOrderPartRecordCount],
								partData.[MaxPartNumber],
								partData.[MaxPartDescription],
								partData.[MaxPurchaseOrderPartRecordId]

				UNION

				SELECT DISTINCT po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartNumber END) AS PartNumber,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartDescription END) AS PartDescription,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse CAST(partData.MaxPurchaseOrderPartRecordId AS VARCHAR(50)) END) AS PurchaseOrderPartRecordId,
								po.[CreatedDate],
								1 AS 'Type',		
								0 AS IsSelected
							FROM [dbo].[PurchaseOrder] po WITH(NOLOCK)
								INNER JOIN [dbo].[PurchaseOrderPart] pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId --AND pop.ItemType='Stock'
								INNER JOIN [dbo].[Stockline] stk WITH(NOLOCK) ON po.PurchaseOrderId = stk.PurchaseOrderId AND (pop.ParentId = stk.PurchaseOrderPartRecordId) and stk.IsParent=1 AND stk.RRQty > 0
								OUTER APPLY (
									SELECT 
										COUNT(PurchaseOrderPartRecordId) AS PurchaseOrderPartRecordCount,
										MAX(PartNumber) AS MaxPartNumber,
										MAX(PartDescription) AS MaxPartDescription,
										MAX(PurchaseOrderPartRecordId) AS MaxPurchaseOrderPartRecordId
									FROM [dbo].[PurchaseOrderPart] pop WITH(NOLOCK)
									WHERE pop.PurchaseOrderId = po.PurchaseOrderId 
									  AND pop.isParent = 1
								) AS partData
							WHERE po.VendorId=@VendorId AND pop.ItemTypeId = @StockTypeId AND po.MasterCompanyId = @MasterCompanyId
							GROUP BY po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								po.[CreatedDate],
								partData.[PurchaseOrderPartRecordCount],
								partData.[MaxPartNumber],
								partData.[MaxPartDescription],
								partData.[MaxPurchaseOrderPartRecordId]
		
				UNION
		
				SELECT DISTINCT po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartNumber END) AS PartNumber,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartDescription END) AS PartDescription,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse CAST(partData.MaxPurchaseOrderPartRecordId AS VARCHAR(50)) END) AS PurchaseOrderPartRecordId,
								po.[CreatedDate],
								1 AS 'Type',		
								0 AS IsSelected
							FROM [dbo].[PurchaseOrder] po WITH(NOLOCK)
								INNER JOIN [dbo].[PurchaseOrderPart] pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
								INNER JOIN [dbo].[NonStockInventory] stk WITH(NOLOCK) ON po.PurchaseOrderId = stk.PurchaseOrderId AND pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0
								OUTER APPLY (
									SELECT 
										COUNT(PurchaseOrderPartRecordId) AS PurchaseOrderPartRecordCount,
										MAX(PartNumber) AS MaxPartNumber,
										MAX(PartDescription) AS MaxPartDescription,
										MAX(PurchaseOrderPartRecordId) AS MaxPurchaseOrderPartRecordId
									FROM [dbo].[PurchaseOrderPart] pop WITH(NOLOCK)
									WHERE pop.PurchaseOrderId = po.PurchaseOrderId 
									  AND pop.isParent = 1
								) AS partData
							WHERE po.VendorId=@VendorId AND pop.ItemTypeId = @NonStockTypeId AND po.MasterCompanyId = @MasterCompanyId
							GROUP BY po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								po.[CreatedDate],
								partData.[PurchaseOrderPartRecordCount],
								partData.[MaxPartNumber],
								partData.[MaxPartDescription],
								partData.[MaxPurchaseOrderPartRecordId]
		
				UNION
		
				SELECT DISTINCT po.PurchaseOrderId,
								po.PurchaseOrderNumber,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartNumber END) AS PartNumber,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartDescription END) AS PartDescription,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse CAST(partData.MaxPurchaseOrderPartRecordId AS VARCHAR(50)) END) AS PurchaseOrderPartRecordId,
								po.[CreatedDate],
								1 AS 'Type',		
								0 AS IsSelected
						   FROM [dbo].[PurchaseOrder] po WITH(NOLOCK)
								INNER JOIN [dbo].[PurchaseOrderPart] pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
								INNER JOIN [dbo].[AssetInventory] stk WITH(NOLOCK) ON po.PurchaseOrderId = stk.PurchaseOrderId AND pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId and stk.RRQty > 0
								OUTER APPLY (
									SELECT 
										COUNT(PurchaseOrderPartRecordId) AS PurchaseOrderPartRecordCount,
										MAX(PartNumber) AS MaxPartNumber,
										MAX(PartDescription) AS MaxPartDescription,
										MAX(PurchaseOrderPartRecordId) AS MaxPurchaseOrderPartRecordId
									FROM [dbo].[PurchaseOrderPart] pop WITH(NOLOCK)
									WHERE pop.PurchaseOrderId = po.PurchaseOrderId 
									  AND pop.isParent = 1
								) AS partData
							WHERE po.VendorId=@VendorId AND POP.ItemTypeId = @AssetTypeId AND po.MasterCompanyId = @MasterCompanyId
							GROUP BY po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								po.[CreatedDate],
								partData.[PurchaseOrderPartRecordCount],
								partData.[MaxPartNumber],
								partData.[MaxPartDescription],
								partData.[MaxPurchaseOrderPartRecordId]
		
				UNION
		
				SELECT DISTINCT po.RepairOrderId AS 'PurchaseOrderId',
								po.RepairOrderNumber AS 'PurchaseOrderNumber',
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartNumber END) AS PartNumber,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartDescription END) AS PartDescription,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse CAST(partData.MaxPurchaseOrderPartRecordId AS VARCHAR(50)) END) AS PurchaseOrderPartRecordId,
								po.CreatedDate,
								2 AS 'Type',		
								0 AS IsSelected 
						   FROM [dbo].[RepairOrder] po WITH(NOLOCK)
								INNER JOIN [dbo].[RepairOrderPart] pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
								INNER JOIN [dbo].[Stockline] stk WITH(NOLOCK) ON po.RepairOrderId = stk.RepairOrderId and stk.IsParent=1 AND stk.RRQty > 0 -- AND pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId
								OUTER APPLY (
									SELECT 
										COUNT(RepairOrderPartRecordId) AS PurchaseOrderPartRecordCount,
										MAX(PartNumber) AS MaxPartNumber,
										MAX(PartDescription) AS MaxPartDescription,
										MAX(RepairOrderPartRecordId) AS MaxPurchaseOrderPartRecordId
									FROM [dbo].[RepairOrderPart] pop WITH(NOLOCK)
									WHERE pop.RepairOrderId = po.RepairOrderId 
									  AND pop.isParent = 1
								) AS partData
							WHERE po.VendorId=@VendorId AND POP.ItemTypeId = @StockTypeId AND po.MasterCompanyId = @MasterCompanyId
							GROUP BY po.[RepairOrderId],
								po.[RepairOrderNumber],
								po.[CreatedDate],
								partData.[PurchaseOrderPartRecordCount],
								partData.[MaxPartNumber],
								partData.[MaxPartDescription],
								partData.[MaxPurchaseOrderPartRecordId]
		
				UNION

				SELECT DISTINCT po.RepairOrderId AS 'PurchaseOrderId',
								po.RepairOrderNumber AS 'PurchaseOrderNumber',
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartNumber END) AS PartNumber,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse partData.MaxPartDescription END) AS PartDescription,
								(CASE WHEN partData.PurchaseOrderPartRecordCount > 1 Then 'Multiple' ELse CAST(partData.MaxPurchaseOrderPartRecordId AS VARCHAR(50)) END) AS PurchaseOrderPartRecordId,
								po.CreatedDate,
								2 AS 'Type',		
								0 AS IsSelected 
						   FROM [dbo].[RepairOrder] po WITH(NOLOCK)
								INNER JOIN [dbo].[RepairOrderPart] pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
								INNER JOIN [dbo].[AssetInventory] stk WITH(NOLOCK) ON po.RepairOrderId = stk.RepairOrderId and pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId AND stk.RRQty > 0
								OUTER APPLY (
									SELECT 
										COUNT(RepairOrderPartRecordId) AS PurchaseOrderPartRecordCount,
										MAX(PartNumber) AS MaxPartNumber,
										MAX(PartDescription) AS MaxPartDescription,
										MAX(RepairOrderPartRecordId) AS MaxPurchaseOrderPartRecordId
									FROM [dbo].[RepairOrderPart] pop WITH(NOLOCK)
									WHERE pop.RepairOrderId = po.RepairOrderId 
									  AND pop.isParent = 1
								) AS partData
							WHERE po.VendorId=@VendorId AND POP.ItemTypeId = @AssetTypeId AND po.MasterCompanyId = @MasterCompanyId
							GROUP BY po.[RepairOrderId],
								po.[RepairOrderNumber],
								po.[CreatedDate],
								partData.[PurchaseOrderPartRecordCount],
								partData.[MaxPartNumber],
								partData.[MaxPartDescription],
								partData.[MaxPurchaseOrderPartRecordId]

			), ResultCount AS(SELECT COUNT(PurchaseOrderId) AS totalItems FROM Result)

			INSERT INTO #UpdatedTempTable SELECT * FROM Result;

			UPDATE tmp
			SET tmp.[IsSelected] = 1
			FROM #UpdatedTempTable tmp 
			WHERE [PurchaseOrderNumber] IN (SELECT Item FROM DBO.SPLITSTRING(@ReferenceNumber,','))
	
			;WITH Newresult AS (
				SELECT * FROM #UpdatedTempTable
				WHERE ((@GlobalFilter <>'' AND (([PurchaseOrderNumber] LIKE '%' +@GlobalFilter+'%' ) 
					OR ([PartNumber] LIKE '%' +@GlobalFilter+'%')
					OR ([PartDescription] LIKE '%' +@GlobalFilter+'%')))

					OR (@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR [PartNumber] LIKE '%' + @PartNumber+'%') 
					AND (ISNULL(@PartDescription,'') ='' OR [PartDescription] LIKE '%' + @PartDescription+'%') 
					AND	(ISNULL(@PORONum,'') ='' OR [PurchaseOrderNumber] LIKE '%' + @PORONum+'%') 
					AND	(ISNULL(@CreatedDate,'') ='' OR CAST([CreatedDate] AS DATE) = CAST(@CreatedDate AS DATE))))
			),FinalResult (CNT) AS (SELECT COUNT([PurchaseOrderId]) FROM Newresult)

			 SELECT *, (SELECT CNT FROM FinalResult) AS NumberOfItems FROM Newresult ORDER BY  
			
					CASE WHEN (@ReferenceNumber IS NOT NULL) THEN [IsSelected] END DESC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PURCHASEORDERNUMBER')  THEN PurchaseOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,			
					CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PURCHASEORDERNUMBER')  THEN PurchaseOrderNumber END DESC,	
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,			
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC

					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE IF @ViewType = 'pnview'
		BEGIN
			;WITH Result AS(		
				SELECT DISTINCT po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								pop.[PartNumber],
								pop.[PartDescription],
								pop.[PurchaseOrderPartRecordId],
								po.[CreatedDate],
								1 AS 'Type',		
								0 AS IsSelected
						   FROM [dbo].[PurchaseOrder] po WITH(NOLOCK)
				INNER JOIN [dbo].[PurchaseOrderPart] pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
				INNER JOIN [dbo].[Stockline] stk WITH(NOLOCK) ON po.PurchaseOrderId = stk.PurchaseOrderId  AND stk.IsParent=1 AND stk.RRQty > 0 --AND (pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId)
				WHERE po.VendorId=@VendorId AND pop.ItemTypeId = @StockTypeId AND po.MasterCompanyId = @MasterCompanyId
				AND ISNULL((SELECT COUNT(POS.PurchaseOrderPartRecordId) from dbo.PurchaseOrderPart POS  WITH(NOLOCK) 
				WHERE POS.ParentId =stk.PurchaseOrderPartRecordId ),0) = 0
		
				UNION

				SELECT DISTINCT po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								pop.[PartNumber],
								pop.[PartDescription],
								pop.[PurchaseOrderPartRecordId],
								po.[CreatedDate],
								1 AS 'Type',		
								0 AS IsSelected
						   FROM [dbo].[PurchaseOrder] po WITH(NOLOCK)
				INNER JOIN [dbo].[PurchaseOrderPart] pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId --AND pop.ItemType='Stock'
				INNER JOIN [dbo].[Stockline] stk WITH(NOLOCK) ON po.PurchaseOrderId = stk.PurchaseOrderId AND (pop.ParentId = stk.PurchaseOrderPartRecordId) and stk.IsParent=1 AND stk.RRQty > 0
				WHERE po.VendorId=@VendorId AND pop.ItemTypeId = @StockTypeId AND po.MasterCompanyId = @MasterCompanyId
		
				UNION
		
				SELECT DISTINCT po.[PurchaseOrderId],
								po.[PurchaseOrderNumber],
								pop.[PartNumber],
								pop.[PartDescription],
								pop.[PurchaseOrderPartRecordId],
								po.[CreatedDate],
								1 AS 'Type',		
								0 AS IsSelected 
							FROM [dbo].[PurchaseOrder] po WITH(NOLOCK)
				INNER JOIN [dbo].[PurchaseOrderPart] pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
				INNER JOIN [dbo].[NonStockInventory] stk WITH(NOLOCK) ON po.PurchaseOrderId = stk.PurchaseOrderId AND pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId and stk.IsParent=1 AND stk.RRQty > 0
				WHERE po.VendorId=@VendorId AND pop.ItemTypeId = @NonStockTypeId AND po.MasterCompanyId = @MasterCompanyId
		
				UNION
		
				SELECT DISTINCT po.PurchaseOrderId,
								po.PurchaseOrderNumber,
								pop.PartNumber,
								pop.PartDescription,
								pop.PurchaseOrderPartRecordId,
								po.CreatedDate,
								1 as 'Type',		
								0 AS IsSelected 
						   FROM [dbo].[PurchaseOrder] po WITH(NOLOCK)
				INNER JOIN [dbo].[PurchaseOrderPart] pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
				INNER JOIN [dbo].[AssetInventory] stk WITH(NOLOCK) ON po.PurchaseOrderId = stk.PurchaseOrderId AND pop.PurchaseOrderPartRecordId = stk.PurchaseOrderPartRecordId and stk.RRQty > 0
				WHERE po.VendorId=@VendorId AND POP.ItemTypeId = @AssetTypeId AND po.MasterCompanyId = @MasterCompanyId
		
				UNION
		
				SELECT DISTINCT po.RepairOrderId AS 'PurchaseOrderId',
								po.RepairOrderNumber AS 'PurchaseOrderNumber',
								pop.PartNumber,
								pop.PartDescription,
								pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
								po.CreatedDate,
								2 AS 'Type',		
								0 AS IsSelected 
						   FROM [dbo].[RepairOrder] po WITH(NOLOCK)
				INNER JOIN [dbo].[RepairOrderPart] pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
				INNER JOIN [dbo].[Stockline] stk WITH(NOLOCK) ON po.RepairOrderId = stk.RepairOrderId and stk.IsParent=1 AND stk.RRQty > 0 -- AND pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId
				WHERE po.VendorId=@VendorId AND POP.ItemTypeId = @StockTypeId AND po.MasterCompanyId = @MasterCompanyId
		
				UNION

				SELECT DISTINCT po.RepairOrderId AS 'PurchaseOrderId',
								po.RepairOrderNumber AS 'PurchaseOrderNumber',
								pop.PartNumber,
								pop.PartDescription,
								pop.RepairOrderPartRecordId AS 'PurchaseOrderPartRecordId',
								po.CreatedDate,
								2 AS 'Type',		
								0 AS IsSelected 
						   FROM [dbo].[RepairOrder] po WITH(NOLOCK)
				INNER JOIN [dbo].[RepairOrderPart] pop WITH(NOLOCK) ON po.RepairOrderId = pop.RepairOrderId AND pop.isParent=1 --AND pop.ItemType='Stock'
				INNER JOIN [dbo].[AssetInventory] stk WITH(NOLOCK) ON po.RepairOrderId = stk.RepairOrderId and pop.RepairOrderPartRecordId = stk.RepairOrderPartRecordId AND stk.RRQty > 0
				WHERE po.VendorId=@VendorId AND POP.ItemTypeId = @AssetTypeId AND po.MasterCompanyId = @MasterCompanyId
			), ResultCount AS(SELECT COUNT(PurchaseOrderId) AS totalItems FROM Result)

			INSERT INTO #UpdatedTempTable SELECT * FROM Result;

			UPDATE tmp
			SET tmp.[IsSelected] = 1
			FROM #UpdatedTempTable tmp 
			WHERE [PurchaseOrderNumber] IN (SELECT Item FROM DBO.SPLITSTRING(@ReferenceNumber,','))
	
			;WITH Newresult AS (
				SELECT * FROM #UpdatedTempTable
				WHERE ((@GlobalFilter <>'' AND (([PurchaseOrderNumber] LIKE '%' +@GlobalFilter+'%' ) 
					OR ([PartNumber] LIKE '%' +@GlobalFilter+'%')
					OR ([PartDescription] LIKE '%' +@GlobalFilter+'%')))

					OR (@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR [PartNumber] LIKE '%' + @PartNumber+'%') 
					AND (ISNULL(@PartDescription,'') ='' OR [PartDescription] LIKE '%' + @PartDescription+'%') 
					AND	(ISNULL(@PORONum,'') ='' OR [PurchaseOrderNumber] LIKE '%' + @PORONum+'%') 
					AND	(ISNULL(@CreatedDate,'') ='' OR CAST([CreatedDate] AS DATE) = CAST(@CreatedDate AS DATE))))
			),FinalResult (CNT) AS (SELECT COUNT([PurchaseOrderId]) FROM Newresult)

			 SELECT *, (SELECT CNT FROM FinalResult) AS NumberOfItems FROM Newresult ORDER BY  
			
					CASE WHEN (@ReferenceNumber IS NOT NULL) THEN [IsSelected] END DESC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PURCHASEORDERNUMBER')  THEN PurchaseOrderNumber END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBER')  THEN PartNumber END ASC,			
					CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC,
					CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PURCHASEORDERNUMBER')  THEN PurchaseOrderNumber END DESC,	
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER')  THEN PartNumber END DESC,			
					CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC

					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY
		END
		
			
	    
	
			      
   END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceivingReconciliationPopupData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END