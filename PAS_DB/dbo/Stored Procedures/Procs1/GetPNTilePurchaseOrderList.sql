/*************************************************************           
 ** File:   [dbo].[GetPNTilePurchaseOrderList]      
 ** Author:    
 ** Description: Get PNTile PurchaseOrderList
 ** Date:   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			-------------------------------- 
	2    07/25/2023   Devendra Shekh	changed NVARCHAR(10) to NVARCHAR(20)
	3    05/12/2023   Amit Ghediya      Modify(Added Traceable & Tagged fields)
	4    12/04/2023   Jevik Raiyani		add @statusValue
	5    02/07/2024   Amit Ghediya		Modify add VendorName set in Global Filter.

--   EXEC [GetPNTilePurchaseOrderList]
**************************************************************/ 
CREATE      PROCEDURE [dbo].[GetPNTilePurchaseOrderList]
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
@PurchaseOrderNumber varchar(50) = NULL,	
@OpenDate  datetime = NULL,
@ConditionName varchar(50) = NULL,	
@UnitCost varchar(50)= NULL,
@QuantityOrdered varchar(50)= NULL,
@ExtendedCost varchar(50)= NULL,
@ReceivedDate datetime = NULL,
@ReceiverNumber varchar(50)= NULL,
@VendorName varchar(50) = NULL,
@IsDeleted bit = 0,
@EmployeeId bigint=0,
@ItemMasterId bigint=0,
@MasterCompanyId bigint=1,
@ConditionId VARCHAR(250) = NULL,
@TraceableTo VARCHAR(250) = NULL,
@TagType VARCHAR(250) = NULL,
@TaggedBy VARCHAR(250) = NULL,
@TaggedDate datetime = NULL,
@StatusValue varchar(50) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	    DECLARE @ItemTypeStock Int;		
		SELECT @ItemTypeStock = ItemTypeId FROM dbo.ItemType WITH(NOLOCK) WHERE [name] = 'Stock'
		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @Count Int;
		DECLARE @MSModuleID INT = 4; -- Employee Management Structure Module ID
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
		   	 SELECT DISTINCT PO.PurchaseOrderId,
					POP.ItemMasterId,
					IM.PartNumber,
					IM.PartDescription,
		            PO.PurchaseOrderNumber,
					PO.OpenDate,
					POP.ConditionId,
					POP.Condition AS ConditionName,
					ISNULL(POP.UnitCost,0) AS UnitCost,
					ISNULL(POP.QuantityOrdered,0) AS QuantityOrdered,
					ISNULL(POP.ExtendedCost,0) AS ExtendedCost,
					CAST(STL.ReceivedDate AS Date) as ReceivedDate,
					STL.ReceiverNumber,
					PO.VendorId,
					PO.VendorName,
					PO.VendorCode,
					PO.IsDeleted,					
					PO.CreatedDate,
				    PO.CreatedBy,					
				    PO.IsActive,					
					PO.StatusId,
					ISNULL(IM.ManufacturerName,'')ManufacturerName,
					POP.TraceableToName AS 'TraceableTo',
					TAT.[Name] AS 'TagType',
					POP.TaggedByName AS 'TaggedBy',
					POP.TagDate AS 'taggedDate',
					PO.[Status] AS StatusValue
			  FROM [dbo].[PurchaseOrder] PO WITH (NOLOCK)
			  INNER JOIN [dbo].[PurchaseOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = PO.PurchaseOrderId
			  INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON PO.ManagementStructureId = RMS.EntityStructureId
			  INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			  INNER JOIN [dbo].[PurchaseOrderPart] POP WITH (NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND POP.isParent=1
			  INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = POP.ItemMasterId 
			  LEFT JOIN [dbo].[Stockline] STL WITH (NOLOCK) ON STL.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId AND STL.IsParent = 1 AND STL.isActive = 1 AND STL.isDeleted = 0 	
			  LEFT JOIN [dbo].[TagType] TAT WITH (NOLOCK) ON POP.TagTypeId = TAT.TagTypeId
		 	  WHERE PO.IsDeleted = 0
				  AND PO.IsActive = 1	 
				  AND PO.MasterCompanyId = @MasterCompanyId	
				  AND POP.ItemMasterId = @ItemMasterId
				  AND POP.ItemTypeId = @ItemTypeStock
				  AND (@ConditionId IS NULL OR POP.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))
			), ResultCount AS(Select COUNT(PurchaseOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR
					(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR
					(PurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
					(ConditionName LIKE '%' +@GlobalFilter+'%') OR	
					(StatusValue LIKE '%' +@GlobalFilter+'%') OR
					(CAST(UnitCost AS VARCHAR(20)) LIKE '%' +@GlobalFilter+'%') OR					
					(CAST(QuantityOrdered AS VARCHAR(20)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(ExtendedCost AS VARCHAR(20)) LIKE '%' +@GlobalFilter+'%') OR
					(ReceiverNumber LIKE '%' +@GlobalFilter+'%') OR
					(taggedDate LIKE '%' +@GlobalFilter+'%') OR
					(TraceableTo LIKE '%' +@GlobalFilter+'%') OR
					(TagType LIKE '%' +@GlobalFilter+'%') OR
					(TaggedBy LIKE '%' +@GlobalFilter+'%') OR
					(VendorName LIKE '%' +@GlobalFilter+'%'))
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND 
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@PurchaseOrderNumber,'') ='' OR PurchaseOrderNumber LIKE '%' + @PurchaseOrderNumber + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND	
					(ISNULL(@StatusValue,'') ='' OR StatusValue LIKE '%' + @StatusValue + '%') AND
					(ISNULL(@ConditionName,'') ='' OR ConditionName LIKE '%' + @ConditionName + '%') AND
					(ISNULL(@UnitCost,'') ='' OR CAST(UnitCost AS NVARCHAR(20)) LIKE '%'+ @UnitCost+'%') AND 
					(ISNULL(@QuantityOrdered,'') ='' OR CAST(QuantityOrdered AS NVARCHAR(20)) LIKE '%'+ @QuantityOrdered+'%') AND 
					(ISNULL(@ExtendedCost,'') ='' OR CAST(ExtendedCost AS NVARCHAR(20)) LIKE '%'+ @ExtendedCost+'%') AND 
					(ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS DATE) = CAST(@ReceivedDate AS DATE)) AND	
					(ISNULL(@ReceiverNumber,'') ='' OR ReceiverNumber LIKE '%' + @ReceiverNumber + '%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@TraceableTo,'') ='' OR TraceableTo LIKE '%' + @TraceableTo + '%') AND
					(ISNULL(@TagType,'') ='' OR TagType LIKE '%' + @TagType + '%') AND
					(ISNULL(@TaggedBy,'') ='' OR TaggedBy LIKE '%' + @TaggedBy + '%') AND
					(ISNULL(@taggedDate,'') ='' OR CAST(taggedDate AS DATE) = CAST(@ReceivedDate AS DATE))
					)))

			SELECT @Count = COUNT(PurchaseOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY 
			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PurchaseOrderNumber')  THEN PurchaseOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConditionName')  THEN ConditionName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConditionName')  THEN ConditionName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOrdered')  THEN QuantityOrdered END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOrdered')  THEN QuantityOrdered END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='ExtendedCost')  THEN ExtendedCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ExtendedCost')  THEN ExtendedCost END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceiverNumber')  THEN ReceiverNumber END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableTo')  THEN TraceableTo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableTo')  THEN TraceableTo END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='StatusValue')  THEN StatusValue END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StatusValue')  THEN StatusValue END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedBy')  THEN TaggedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedBy')  THEN TaggedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='taggedDate')  THEN taggedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='taggedDate')  THEN taggedDate END DESC
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
            , @AdhocComments     VARCHAR(150)    = 'GetPNTilePurchaseOrderList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PurchaseOrderNumber, '') + ''
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