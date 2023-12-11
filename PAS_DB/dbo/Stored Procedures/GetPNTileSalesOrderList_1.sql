/*************************************************************           
 ** File:   [GetPNTileSalesOrderList]           
 ** Author:  
 ** Description: This stored procedure is used get list of sales order history date for dashboard
 ** Purpose:         
 ** Date:    
          
 ** PARAMETERS:           
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
	1    09/11/2023   Vishal Suthar			Added new column 'ConditionId'
	2    06/12/2023	  Ekta Chandegra		Added new column 'SerialNumber'
	3    08/12/2023   Jevik Raiyani		 add @statusValue

**************************************************************/
CREATE   PROCEDURE [dbo].[GetPNTileSalesOrderList]
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
	@SalesOrderNumber varchar(50) = NULL,
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
	@ConditionId VARCHAR(250) = NULL,
	@StatusValue varchar(50) = NULL,
	@SerialNumber varchar(50) = NULL

AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	    DECLARE @ItemTypeStock Int;		
		SELECT @ItemTypeStock = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [name] = 'Stock'
		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;		
		DECLARE @MSModuleID INT = 17; -- Sales Order Management Structure Module ID
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
		   	 SELECT DISTINCT SO.[SalesOrderId],
				SP.[SalesOrderPartId],
				SP.[ItemMasterId],
				IM.[PartNumber],
				IM.[PartDescription],
		        SO.[SalesOrderNumber],
				SO.[OpenDate],
				SO.[CustomerReference],
				STL.[SerialNumber],  
				ISNULL(SP.[UnitCost],0) AS [UnitCost],
				ISNULL(SP.[Qty],0) AS [Qty],
				ISNULL(SP.[UnitCostExtended],0) AS [UnitCostExtended],
				CO.[Description] AS [ConditionName],
				SO.[SalesPersonName],					
				CAST(SOS.[ShipDate] AS Date) AS ShipDate,							
				SO.[CustomerId],
				CU.[Name] AS [CustomerName],
				SP.ConditionId,
				SO.[IsDeleted],					
				SO.[CreatedDate],
				SO.[CreatedBy],					
				SO.[IsActive],					
				SO.[StatusId],
				ISNULL(IM.ManufacturerName,'')ManufacturerName,			
				MSOS.[Name] AS StatusValue
			   FROM [dbo].[SalesOrder] SO WITH (NOLOCK)	
			   INNER JOIN [dbo].[Customer] CU WITH (NOLOCK) ON CU.CustomerId = SO.CustomerId
			   INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SO.SalesOrderId
			   INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SO.ManagementStructureId = RMS.EntityStructureId
			   INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			   LEFT JOIN [dbo].[SalesOrderPart] SP WITH (NOLOCK) ON SO.SalesOrderId = SP.SalesOrderId and SP.IsDeleted = 0
			   LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = SP.ItemMasterId
			   LEFT JOIN [dbo].[Condition] CO WITH (NOLOCK) ON CO.ConditionId = SP.ConditionId
			   LEFT JOIN [dbo].[SalesOrderShippingItem] SOI WITH (NOLOCK) ON SOI.SalesOrderPartId = SP.SalesOrderPartId
			   LEFT JOIN [dbo].[SalesOrderShipping] SOS WITH (NOLOCK) ON SOI.SalesOrderShippingId = SOS.SalesOrderShippingId	
			   LEFT JOIN [dbo].[Stockline] STL WITH(NOLOCK) ON SP.StockLineId = STL.StockLineId	
			   LEFT JOIN [dbo].[MasterSalesOrderStatus] MSOS WITH (NOLOCK) ON SO.[StatusId] = MSOS.Id

			WHERE SO.MasterCompanyId = @MasterCompanyId	
				AND SP.ItemMasterId = @ItemMasterId
				AND SO.IsActive = 1
				AND SO.IsDeleted = 0
				AND (@ConditionId IS NULL OR SP.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))
			), ResultCount AS(SELECT COUNT(SalesOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
				(PartDescription LIKE '%' +@GlobalFilter+'%') OR
				(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR
				(StatusValue LIKE '%' +@GlobalFilter+'%') OR
				(SalesOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
				(CustomerReference LIKE '%' +@GlobalFilter+'%') OR
				(SerialNumber LIKE '%' +@GlobalFilter+'%') OR	
				(CAST(UnitCost AS VARCHAR(20)) LIKE '%' +@GlobalFilter+'%') OR	
				(CAST(Qty AS VARCHAR(20)) LIKE '%' +@GlobalFilter+'%') OR
				(CAST(UnitCostExtended AS VARCHAR(20)) LIKE '%' +@GlobalFilter+'%') OR					
				(ConditionName LIKE '%' +@GlobalFilter+'%') OR	
				(SalesPersonName LIKE '%' +@GlobalFilter+'%') OR
				(CustomerName LIKE '%' +@GlobalFilter+'%'))
				OR   
				(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND 
				(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
				(ISNULL(@StatusValue,'') ='' OR StatusValue LIKE '%' + @StatusValue + '%') AND
				(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
				(ISNULL(@SalesOrderNumber,'') ='' OR SalesOrderNumber LIKE '%' + @SalesOrderNumber + '%') AND
				(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND	
				(ISNULL(@CustomerReference,'') ='' OR CustomerReference LIKE '%' + @CustomerReference + '%') AND
				(ISNULL(@UnitCost,'') ='' OR CAST(UnitCost AS NVARCHAR(10)) LIKE '%'+ @UnitCost+'%') AND 
				(ISNULL(@Qty,'') ='' OR CAST(Qty AS NVARCHAR(10)) LIKE '%'+ @Qty+'%') AND 
				(ISNULL(@UnitCostExtended,'') ='' OR CAST(UnitCostExtended AS NVARCHAR(10)) LIKE '%'+ @UnitCostExtended+'%') AND 
				(ISNULL(@ConditionName,'') ='' OR ConditionName LIKE '%' + @ConditionName + '%') AND
				(ISNULL(@SalesPersonName,'') ='' OR SalesPersonName LIKE '%' + @SalesPersonName + '%') AND
				(ISNULL(@ShipDate,'') ='' OR CAST(ShipDate AS DATE) = CAST(@ShipDate AS DATE)) AND	
				(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND
				(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName + '%'))))		
					
			SELECT @Count = COUNT(SalesOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY 
			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SalesOrderNumber')  THEN SalesOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SalesOrderNumber')  THEN SalesOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerReference')  THEN CustomerReference END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerReference')  THEN CustomerReference END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,		
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCostExtended')  THEN UnitCostExtended END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCostExtended')  THEN UnitCostExtended END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConditionName')  THEN ConditionName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConditionName')  THEN ConditionName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SalesPersonName')  THEN SalesPersonName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SalesPersonName')  THEN SalesPersonName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ShipDate')  THEN ShipDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ShipDate')  THEN ShipDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='StatusValue')  THEN StatusValue END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StatusValue')  THEN StatusValue END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC
			
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
            , @AdhocComments     VARCHAR(150)    = 'GetPNTileSalesOrderList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderNumber, '') + ''
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