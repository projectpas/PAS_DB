/*************************************************************           
 ** File:   [GetPNTileWOMaterialHistoryList]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used get list of work orders where the given part is consumed in materials
 ** Purpose:         
 ** Date:      05/26/2023
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    05/26/2023   Vishal Suthar Created
	2    06/01/2023   Amit Ghediya  Added MPN & MPN desc.
	3    07/27/2023   Vishal Suthar Showing both issued and reserved qty WOM stockline
	4    12/06/2023   Jevik Raiyani add @statusValue 
**************************************************************/
CREATE  PROCEDURE [dbo].[GetPNTileWOMaterialHistoryList]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@StatusID int = 1,
	@Status varchar(50) = 'Open',
	@GlobalFilter varchar(50) = '',	
	@PartNumber varchar(50) = NULL,	
	@PartDescription varchar(max) = NULL,
	@Condition varchar(max) = NULL,
	@WorkOrderNum varchar(50) = NULL,
	@MPN varchar(50) = NULL,	
	@MPNDescription varchar(max) = NULL,
	@WorkScope varchar(50) = NULL,
	@StatusValue varchar(50) = NULL,
	@RequestedQty int = NULL,
	@ResQty int = NULL,
	@IssueQty int = NULL,
	@UnitCost decimal(18, 2) = NULL,
	@ExtendedUnitCost decimal(18, 2) = NULL,
	@StocklineNum varchar(50) = NULL,
	@ControlNum varchar(50) = NULL,
	@ControlID varchar(50) = NULL,
	@IsDeleted bit = 0,
	@ItemMasterId bigint=0,
	@MasterCompanyId bigint = 1,
	@ConditionId VARCHAR(250) = NULL
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
					WO.[WorkOrderId],
					IM.[PartNumber],
					IM.[PartDescription],
					(CASE WHEN WOMS.WOMStockLineId is null THEN WOM.ConditionCodeId ELSE WOMS.ConditionId END) AS ConditionId,
					(CASE WHEN WOMS.WOMStockLineId is null THEN matCon.Description ELSE Cond.Description END) AS Condition,
					WO.[WorkOrderNum],
					WPN.[WorkScope],
					WOM.Quantity AS ReqQty,
					(CASE WHEN WOMS.WOMStockLineId is null THEN WOM.TotalReserved ELSE WOMS.QtyReserved END) AS ResQty,
					(CASE WHEN WOMS.WOMStockLineId is null THEN WOM.TotalIssued ELSE WOMS.QtyIssued END) AS IssueQty,
					(CASE WHEN WOMS.WOMStockLineId is null THEN WOM.UnitCost ELSE WOMS.UnitCost END) AS UnitCost,
					(CASE WHEN WOMS.WOMStockLineId is null THEN WOM.ExtendedCost ELSE WOMS.ExtendedCost END) AS ExtendedUnitCost,
					Stk.StockLineNumber AS StocklineNum,
					Stk.ControlNumber AS ControlNum,
					Stk.IdNumber AS ControlID,					
					WO.[IsDeleted],					
					WO.[CreatedDate],
				    WO.[CreatedBy],					
				    WO.[IsActive],
					ISNULL(IM.ManufacturerName,'')ManufacturerName,
					IMP.[PartNumber] AS MPN,
					IMP.[PartDescription] AS MPNDescription,
					WS.[Description] AS StatusValue
			   FROM [dbo].[WorkOrderMaterials] WOM  WITH (NOLOCK)
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
			   INNER JOIN [dbo].[WorkOrderPartNumber] WPN WITH (NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
			   INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOM.ItemMasterId = IM.ItemMasterId
			   INNER JOIN [dbo].[ItemMaster] IMP WITH (NOLOCK) ON WPN.ItemMasterId = IMP.ItemMasterId
			   LEFT JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
			   LEFT JOIN [dbo].[Stockline] Stk WITH (NOLOCK) ON WOMS.StockLineId = Stk.StockLineId
			   LEFT JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON WOMS.ConditionId = Cond.ConditionId
			   LEFT JOIN [dbo].[Condition] matCon WITH (NOLOCK) ON WOM.ConditionCodeId = matCon.ConditionId
			   LEFT JOIN [dbo].[WorkOrderStatus] WS WITH (NOLOCK) ON WS.Id = WO.WorkOrderStatusId
			WHERE WO.MasterCompanyId = @MasterCompanyId	
			      AND WO.IsDeleted = 0
				  AND WO.IsActive = 1				  
				  AND WOM.ItemMasterId = @ItemMasterId	
				  --AND (WOMS.QtyIssued > 0 OR WOMS.QtyReserved > 0)
				  AND (@ConditionId IS NULL OR WPN.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))

			UNION ALL

			SELECT DISTINCT
					WO.[WorkOrderId],
					IM.[PartNumber],
					IM.[PartDescription],
					(CASE WHEN WOMS.WorkOrderMaterialStockLineKitId is null THEN WOM.ConditionCodeId ELSE WOMS.ConditionId END) AS ConditionId,
					(CASE WHEN WOMS.WorkOrderMaterialStockLineKitId is null THEN matCon.Code ELSE Cond.Code END) AS Condition,
					WO.[WorkOrderNum],
					WPN.[WorkScope],
					WOM.Quantity AS RequestedQty,

					(CASE WHEN WOMS.WorkOrderMaterialStockLineKitId is null THEN WOM.TotalReserved ELSE WOMS.QtyReserved END) AS ResQty,
					(CASE WHEN WOMS.WorkOrderMaterialStockLineKitId is null THEN WOM.TotalIssued ELSE WOMS.QtyIssued END) AS IssueQty,
					(CASE WHEN WOMS.WorkOrderMaterialStockLineKitId is null THEN WOM.UnitCost ELSE WOMS.UnitCost END) AS UnitCost,
					(CASE WHEN WOMS.WorkOrderMaterialStockLineKitId is null THEN WOM.ExtendedCost ELSE WOMS.ExtendedCost END) AS ExtendedUnitCost,
					Stk.StockLineNumber AS StocklineNum,
					Stk.ControlNumber AS ControlNum,
					Stk.IdNumber AS ControlID,					
					WO.[IsDeleted],					
					WO.[CreatedDate],
				    WO.[CreatedBy],					
				    WO.[IsActive],
					ISNULL(IM.ManufacturerName,'')ManufacturerName,
					IMP.[PartNumber] AS MPN,
					IMP.[PartDescription] AS MPNDescription,
					WS.[Description] AS StatusValue
			   FROM  [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
			   INNER JOIN [dbo].[WorkOrderPartNumber] WPN WITH (NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
			   INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOM.ItemMasterId = IM.ItemMasterId
			   INNER JOIN [dbo].[ItemMaster] IMP WITH (NOLOCK) ON WPN.ItemMasterId = IMP.ItemMasterId
			   LEFT JOIN [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH (NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId
			   LEFT JOIN [dbo].[Stockline] Stk WITH (NOLOCK) ON WOMS.StockLineId = Stk.StockLineId
			   LEFT JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON WOMS.ConditionId = Cond.ConditionId
			   LEFT JOIN [dbo].[Condition] matCon WITH (NOLOCK) ON WOM.ConditionCodeId = matCon.ConditionId
			   LEFT JOIN [dbo].[WorkOrderStatus] WS WITH (NOLOCK) ON WS.Id = WO.WorkOrderStatusId

			WHERE WO.MasterCompanyId = @MasterCompanyId	
			      AND WO.IsDeleted = 0
				  AND WO.IsActive = 1				  
				  AND WOM.ItemMasterId = @ItemMasterId	
				  --AND (WOMS.QtyIssued > 0 OR WOMS.QtyReserved > 0)
				  AND (@ConditionId IS NULL OR WPN.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))
			), ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' + @GlobalFilter +'%') OR
					(PartDescription LIKE '%' + @GlobalFilter +'%') OR
					(StatusValue LIKE '%' + @GlobalFilter +'%') OR
					(Condition LIKE '%' + @GlobalFilter +'%') OR
					(WorkOrderNum LIKE '%' + @GlobalFilter +'%') OR
					(MPN LIKE '%' + @GlobalFilter +'%') OR
					(MPNDescription LIKE '%' + @GlobalFilter +'%') OR
					(WorkScope LIKE '%' + @GlobalFilter +'%') OR
					(UnitCost LIKE '%' + @GlobalFilter +'%') OR
					(ReqQty LIKE '%' + @GlobalFilter +'%') OR
					(ExtendedUnitCost LIKE '%' + @GlobalFilter +'%') OR
					(StocklineNum LIKE '%' + @GlobalFilter +'%') OR
					(ControlNum LIKE '%' + @GlobalFilter +'%') OR
					(ControlID LIKE '%' + @GlobalFilter +'%'))
					OR 
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@StatusValue,'') ='' OR StatusValue LIKE '%' + @StatusValue + '%') AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@WorkOrderNum,'') ='' OR WorkOrderNum LIKE '%' + @WorkOrderNum + '%') AND
					(ISNULL(@MPN,'') ='' OR MPN LIKE '%' + @MPN + '%') AND
					(ISNULL(@MPNDescription,'') ='' OR MPNDescription LIKE '%' + @MPNDescription + '%') AND
					(ISNULL(@WorkScope,'') ='' OR WorkScope LIKE '%' + @WorkScope + '%') AND
					(ISNULL(CAST(@UnitCost AS VARCHAR(50)),'') ='' OR CAST(UnitCost AS VARCHAR(50)) LIKE '%' + CAST(@UnitCost AS VARCHAR(50)) + '%') AND
					(ISNULL(CAST(@ExtendedUnitCost AS VARCHAR(50)),'') ='' OR CAST(ExtendedUnitCost AS VARCHAR(50)) LIKE '%' + CAST(@ExtendedUnitCost AS VARCHAR(50)) + '%') AND
					(ISNULL(@StocklineNum,'') ='' OR StocklineNum LIKE '%' + @StocklineNum + '%') AND
					(ISNULL(@ControlNum,'') ='' OR ControlNum LIKE '%' + @ControlNum + '%') AND
					(IsNull(@RequestedQty, 0) = 0 OR CAST(ReqQty as VARCHAR(10)) like @RequestedQty) AND
					(ISNULL(@ControlID,'') ='' OR ControlID LIKE '%' + @ControlID + '%'))))	 	
			SELECT @Count = COUNT(WorkOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY 
			
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='StatusValue')  THEN StatusValue END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StatusValue')  THEN StatusValue END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkOrderNum')  THEN WorkOrderNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkOrderNum')  THEN WorkOrderNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='MPN')  THEN MPN END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MPN')  THEN MPN END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='MPNDescription')  THEN MPNDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MPNDescription')  THEN MPNDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScope')  THEN WorkScope END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScope')  THEN WorkScope END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='ExtendedUnitCost')  THEN ExtendedUnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ExtendedUnitCost')  THEN ExtendedUnitCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNum')  THEN StocklineNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNum')  THEN StocklineNum END DESC,		
			CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNum')  THEN ControlNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNum')  THEN ControlNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ControlID')  THEN ControlID END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlID')  THEN ControlID END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ReqQty')  THEN ReqQty END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ReqQty')  THEN ReqQty END DESC,
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
            , @AdhocComments     VARCHAR(150)    = 'GetPNTileWOMaterialHistoryList' 
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