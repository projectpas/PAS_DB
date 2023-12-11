/*************************************************************           
 ** File:   [GetPNTileRepairOrderList]          
 ** Author:  
 ** Description: This stored procedure is used get list of repair order history date for dashboard
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
	3    11/12/2023   Ekta Chandegra		Apply Join on stocklineId instead of ROPartRecordId
**************************************************************/
CREATE   PROCEDURE [dbo].[GetPNTileRepairOrderList]
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
@RepairOrderNumber varchar(50) = NULL,	
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
		DECLARE @MSModuleID INT = 24; -- Repair Order Management Structure Module ID
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
		   	 SELECT DISTINCT RO.RepairOrderId,
					ROP.ItemMasterId,
					IM.PartNumber,
					IM.PartDescription,
		            RO.RepairOrderNumber,
					RO.OpenDate,
					ROP.WorkPerformedId,
					ROP.Condition AS ConditionName,
					ISNULL(ROP.UnitCost,0) AS UnitCost,
					ISNULL(ROP.QuantityOrdered,0) AS QuantityOrdered,
					ISNULL(ROP.ExtendedCost,0) AS ExtendedCost,
					CAST(STL.ReceivedDate AS Date) as ReceivedDate,
					STL.ReceiverNumber,
					STL.SerialNumber,  
					RO.VendorId,
					RO.VendorName,
					RO.VendorCode,
					RO.IsDeleted,					
					RO.CreatedDate,
				    RO.CreatedBy,					
				    RO.IsActive,					
					RO.StatusId,
					ISNULL(IM.ManufacturerName,'')ManufacturerName
			   FROM [dbo].[RepairOrder] RO WITH (NOLOCK)			          			  
			 INNER JOIN [dbo].[RepairOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = RO.RepairOrderId
			 INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RO.ManagementStructureId = RMS.EntityStructureId
			 INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
			 INNER JOIN [dbo].[RepairOrderPart] ROP WITH (NOLOCK) ON ROP.RepairOrderId = RO.RepairOrderId AND ROP.isParent=1
			 INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = ROP.ItemMasterId 
			 LEFT JOIN [dbo].[Stockline] STL WITH (NOLOCK) ON STL.StockLineId = ROP.StockLineId AND STL.IsParent = 1 AND STL.isActive = 1 AND STL.isDeleted = 0  	
		 	  WHERE RO.IsDeleted = 0
			      AND RO.IsActive = 1
				  AND RO.MasterCompanyId = @MasterCompanyId	
				  AND ROP.ItemMasterId = @ItemMasterId
				  AND ROP.ItemTypeId = @ItemTypeStock
				  AND (@ConditionId IS NULL OR ROP.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))
			), ResultCount AS(Select COUNT(RepairOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR
					(ManufacturerName LIKE '%' +@GlobalFilter+'%') OR
					(RepairOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(SerialNumber LIKE '%' +@GlobalFilter+'%') OR	
					(ConditionName LIKE '%' +@GlobalFilter+'%') OR	
					(CAST(UnitCost AS VARCHAR(20)) LIKE '%' +@GlobalFilter+'%') OR					
					(CAST(QuantityOrdered AS VARCHAR(20)) LIKE '%' +@GlobalFilter+'%') OR
					(CAST(ExtendedCost AS VARCHAR(20)) LIKE '%' +@GlobalFilter+'%') OR
					(ReceiverNumber LIKE '%' +@GlobalFilter+'%') OR
					(VendorName LIKE '%' +@GlobalFilter+'%'))
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND 
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@ManufacturerName,'') ='' OR ManufacturerName LIKE '%' + @ManufacturerName + '%') AND
					(ISNULL(@RepairOrderNumber,'') ='' OR RepairOrderNumber LIKE '%' + @RepairOrderNumber + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND	
					(ISNULL(@ConditionName,'') ='' OR ConditionName LIKE '%' + @ConditionName + '%') AND
					(ISNULL(@UnitCost,'') ='' OR CAST(UnitCost AS NVARCHAR(10)) LIKE '%'+ @UnitCost+'%') AND 
					(ISNULL(@QuantityOrdered,'') ='' OR CAST(QuantityOrdered AS NVARCHAR(10)) LIKE '%'+ @QuantityOrdered+'%') AND 
					(ISNULL(@ExtendedCost,'') ='' OR CAST(ExtendedCost AS NVARCHAR(10)) LIKE '%'+ @ExtendedCost+'%') AND 
					(ISNULL(@ReceivedDate,'') ='' OR CAST(ReceivedDate AS DATE) = CAST(@ReceivedDate AS DATE)) AND	
					(ISNULL(@ReceiverNumber,'') ='' OR ReceiverNumber LIKE '%' + @ReceiverNumber + '%') AND
					(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%'))))

			SELECT @Count = COUNT(RepairOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY 
			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ManufacturerName')  THEN ManufacturerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ManufacturerName')  THEN ManufacturerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RepairOrderNumber')  THEN RepairOrderNumber END DESC,
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
            , @AdhocComments     VARCHAR(150)    = 'GetPNTileRepairOrderList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderNumber, '') + ''
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