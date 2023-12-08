/*************************************************************           
 ** File:   [GetPNTileWOKitMaterialHistoryList]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used get list of work orders where the given part is consumed in KIT materials
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
	1    08/02/2023   Vishal Suthar Created
    2    12/06/202    Jevik Raiyani added @statusValue
**************************************************************/
CREATE     PROCEDURE [dbo].[GetPNTileWOKitMaterialHistoryList]
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
	@KitNumber varchar(50) = NULL,
	@StatusValue varchar(50) = NULL,
	@WorkOrderNum varchar(50) = NULL,
	@MPN varchar(50) = NULL,	
	@MPNDescription varchar(max) = NULL,
	@WorkScope varchar(50) = NULL,
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
					WOKM.KitNumber,
					IM.[PartNumber],
					IM.[PartDescription],
					WOMS.ConditionId,
					Cond.Code AS [Condition],
					WO.[WorkOrderNum],
					WPN.[WorkScope],
					WOMS.QtyReserved AS ResQty,
					WOMS.QtyIssued AS IssueQty,
					WOMS.UnitCost,
					WOMS.ExtendedCost AS ExtendedUnitCost,
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
					WOS.[Description] as StatusValue
			   FROM [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH (NOLOCK)
			   LEFT JOIN [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK) ON WOM.WorkOrderMaterialsKitId = WOMS.WorkOrderMaterialsKitId
			   LEFT JOIN [dbo].[WorkOrderMaterialsKitMapping] WOKM WITH (NOLOCK) ON WOM.WorkOrderMaterialsKitMappingId = WOKM.WorkOrderMaterialsKitMappingId
			   INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
			   INNER JOIN [dbo].[WorkOrderPartNumber] WPN WITH (NOLOCK) ON WO.WorkOrderId = WPN.WorkOrderId
			   INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOMS.ItemMasterId = IM.ItemMasterId
			   INNER JOIN [dbo].[ItemMaster] IMP WITH (NOLOCK) ON WPN.ItemMasterId = IMP.ItemMasterId
			   INNER JOIN [dbo].[Stockline] Stk WITH (NOLOCK) ON WOMS.StockLineId = Stk.StockLineId
			   LEFT JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON WOMS.ConditionId = Cond.ConditionId
			   LEFT JOIN [dbo].[WorkOrderStatus] WOS WITH (NOLOCK) ON WOS.Id = WO.WorkOrderStatusId
			WHERE WO.MasterCompanyId = @MasterCompanyId	
			      AND WO.IsDeleted = 0
				  AND WO.IsActive = 1				  
				  AND WOMS.ItemMasterId = @ItemMasterId	
				  AND (WOMS.QtyIssued > 0 OR WOMS.QtyReserved > 0)
				  AND (@ConditionId IS NULL OR WPN.ConditionId IN(SELECT * FROM STRING_SPLIT(@ConditionId , ',')))
			), ResultCount AS(SELECT COUNT(WorkOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' + @GlobalFilter +'%') OR
					(PartDescription LIKE '%' + @GlobalFilter +'%') OR
					(Condition LIKE '%' + @GlobalFilter +'%') OR
					(KitNumber LIKE '%' + @GlobalFilter +'%') OR
					(WorkOrderNum LIKE '%' + @GlobalFilter +'%') OR
					(StatusValue LIKE '%' + @GlobalFilter +'%') OR
					(MPN LIKE '%' + @GlobalFilter +'%') OR
					(MPNDescription LIKE '%' + @GlobalFilter +'%') OR
					(WorkScope LIKE '%' + @GlobalFilter +'%') OR
					(UnitCost LIKE '%' + @GlobalFilter +'%') OR
					(ExtendedUnitCost LIKE '%' + @GlobalFilter +'%') OR
					(StocklineNum LIKE '%' + @GlobalFilter +'%') OR
					(ControlNum LIKE '%' + @GlobalFilter +'%') OR
					(ControlID LIKE '%' + @GlobalFilter +'%'))
					OR 
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%') AND
					(ISNULL(@StatusValue,'') ='' OR StatusValue LIKE '%' + @StatusValue + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@WorkOrderNum,'') ='' OR WorkOrderNum LIKE '%' + @WorkOrderNum + '%') AND
					(ISNULL(@KitNumber,'') ='' OR KitNumber LIKE '%' + @KitNumber + '%') AND
					(ISNULL(@MPN,'') ='' OR MPN LIKE '%' + @MPN + '%') AND
					(ISNULL(@MPNDescription,'') ='' OR MPNDescription LIKE '%' + @MPNDescription + '%') AND
					(ISNULL(@WorkScope,'') ='' OR WorkScope LIKE '%' + @WorkScope + '%') AND
					(ISNULL(CAST(@UnitCost AS VARCHAR(50)),'') ='' OR CAST(UnitCost AS VARCHAR(50)) LIKE '%' + CAST(@UnitCost AS VARCHAR(50)) + '%') AND
					(ISNULL(CAST(@ExtendedUnitCost AS VARCHAR(50)),'') ='' OR CAST(ExtendedUnitCost AS VARCHAR(50)) LIKE '%' + CAST(@ExtendedUnitCost AS VARCHAR(50)) + '%') AND
					(ISNULL(@StocklineNum,'') ='' OR StocklineNum LIKE '%' + @StocklineNum + '%') AND
					(ISNULL(@ControlNum,'') ='' OR ControlNum LIKE '%' + @ControlNum + '%') AND
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
			CASE WHEN (@SortOrder=1  AND @SortColumn='KitNumber')  THEN KitNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='KitNumber')  THEN KitNumber END DESC,
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
            , @AdhocComments     VARCHAR(150)    = 'GetPNTileWOKitMaterialHistoryList' 
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