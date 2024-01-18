/*************************************************************           
 ** File:   [USP_GetSubWorkOrderList]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used retrieve Sub WorkOrder list with filters   
 ** Purpose:         
 ** Date:   12/25/2023      
          
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    12/25/2023   Devendra Shekh			Created
    2    01/08/2024   Devendra Shekh			added new columns
    3    01/09/2024   Devendra Shekh			added new column
	4    01/16/2024   Hemant Saliya				Updated For Reopen Sub WO
     
exec USP_GetSubWorkOrderList 
@PageNumber=1,@PageSize=10,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@StatusId=1,@SubWorkOrderNo=NULL,
@MasterPartNo=NULL,@MasterPartDescription=NULL,@Manufacturer=NULL,@RevisedPartNo=NULL,@SerialNumber=NULL,@CreatedBy=NULL,
@UpdatedBy=NULL,@CreatedDate=NULL,@UpdatedDate=NULL,@OpenDate=NULL,@IsDeleted=0,@WorkOrderId=3835,@MasterCompanyId=1

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetSubWorkOrderList]
@PageNumber INT = NULL,
@PageSize INT = NULL,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,
@GlobalFilter VARCHAR(50) = NULL,
@StatusId INT = NULL,
@SubWorkOrderNo VARCHAR(100) = NULL,
@MasterPartNo VARCHAR(100) = NULL,
@MasterPartDescription VARCHAR(300) = NULL,
@Manufacturer VARCHAR(100) = NULL,
@WorkScope VARCHAR(100) = NULL,
@RevisedPartNo VARCHAR(100) = NULL,
@SerialNumber VARCHAR(100) = NULL,
@SubWOStatus VARCHAR(100) = NULL,
@OriginalCondition VARCHAR(100) = NULL,
@UpdatedCondition VARCHAR(100) = NULL,
@IsTransferredToParentWO VARCHAR(100) = NULL,
@OriginalStockLineNumber VARCHAR(100) = NULL,
@UpdatedStockLineNumber VARCHAR(100) = NULL,
@CreatedBy  VARCHAR(100) = NULL,
@CreatedDate DATETIME = NULL,
@UpdatedBy  VARCHAR(100) = NULL,
@OpenDate DATETIME = NULL,
@UpdatedDate  DATETIME = NULL,
@IsDeleted BIT = NULL,
@WorkOrderId BIGINT = NULL,
@MasterCompanyId BIGINT = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom INT;		
		DECLARE @Count INT;
		DECLARE @IsActive bit;
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
			Set @SortColumn=UPPER(@SortColumn)
		END	
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive=NULL;
		END

		DECLARE @TotalRec BIGINT = 0, @TmpSubWOId BIGINT = 0;
		DECLARE @IsMaterial BIT = 0;
		DECLARE @IsLabor BIT = 0;
		DECLARE @IsCharges BIT = 0;
		DECLARE @IsFreight BIT = 0;
		DECLARE @Is8130 BIT = 0;
		DECLARE @IsSubWOClose BIT = 0;
		DECLARE @TotalLabor BIGINT = 0;
		DECLARE @TotalCompleteLabor BIGINT = 0;
		DECLARE @TotalLaborCost BIGINT = 0;
		DECLARE @SWOTaskStatusId BIGINT = 0;

		SET @SWOTaskStatusId = (SELECT [TaskStatusId] FROM [dbo].[TaskStatus] WITH(NOLOCK) WHERE UPPER([Description]) = 'COMPLETED' AND MasterCompanyId = @MasterCompanyId)
		
		IF OBJECT_ID('tempdb..#tempSubWO') IS NOT NULL
			DROP TABLE #tempSubWO

		CREATE TABLE #tempSubWO
		(
			ID INT IDENTITY(1,1) NOT NULL,
			SubWorkOrderId BIGINT NULL,
			WorkOrderId BIGINT NULL,
			IsAllowDelete BIT NULL,
			IsAllowReOpen BIT NULL,
			SubReleaseFromId BIGINT NULL,
		)

		INSERT INTO #tempSubWO(SubWorkOrderId, WorkOrderId, IsAllowDelete, SubReleaseFromId) 
		SELECT SubWorkOrderId,  WorkOrderId, 0, 0
		FROM [DBO].[SubWorkOrder] WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId

		SET @TotalRec = (SELECT COUNT(ID) FROM #tempSubWO)

		WHILE(ISNULL(@TotalRec, 0) > 0)
		BEGIN

			DECLARE @recCount BIGINT = 0;
			SET @TmpSubWOId = (SELECT SubWorkOrderId FROM #tempSubWO WHERE ID = @TotalRec)

			;WITH MaterialCount AS (
				SELECT COUNT(ISNULL(SubWorkOrderMaterialsId, 0)) AS totalRecord FROM [dbo].[SubWorkOrderMaterials] WITH(NOLOCK) WHERE SubWorkOrderId = @TmpSubWOId AND WorkOrderId = @WorkOrderId

				UNION

				SELECT COUNT(ISNULL(SubWorkOrderMaterialsKitId, 0)) AS totalRecord FROM [dbo].[SubWorkOrderMaterialsKit] WITH(NOLOCK) WHERE SubWorkOrderId = @TmpSubWOId AND WorkOrderId = @WorkOrderId
			)
			SELECT @recCount = SUM(ISNULL(totalRecord, 0)) FROM MaterialCount

			SET @IsMaterial = CASE WHEN ISNULL(@recCount, 0) > 0 THEN 1 ELSE 0 END 

			SELECT @TotalLabor = COUNT(SubWorkOrderLaborId), @TotalLaborCost = SUM(ISNULL(TotalCost, 0)) FROM [dbo].[SubWorkOrderLabor] SUBL WITH(NOLOCK)
						   LEFT JOIN [dbo].[SubWorkOrderLaborHeader] SUBH WITH(NOLOCK) ON SUBL.SubWorkOrderLaborHeaderId = SUBH.SubWorkOrderLaborHeaderId 
						   WHERE SUBH.SubWorkOrderId = @TmpSubWOId

			SELECT @TotalCompleteLabor = COUNT(SubWorkOrderLaborId) FROM [dbo].[SubWorkOrderLabor] SUBL WITH(NOLOCK)
						   LEFT JOIN [dbo].[SubWorkOrderLaborHeader] SUBH WITH(NOLOCK) ON SUBL.SubWorkOrderLaborHeaderId = SUBH.SubWorkOrderLaborHeaderId 
						   WHERE SUBH.SubWorkOrderId = @TmpSubWOId AND SUBL.TaskStatusId = @SWOTaskStatusId

			SET @IsLabor = CASE WHEN ISNULL(@TotalLabor, 0) > 0 THEN
								CASE WHEN @TotalLabor = @TotalCompleteLabor AND @TotalLaborCost = 0 THEN 0 ELSE 1 END 
								ELSE 0 END

			SET @IsCharges = CASE WHEN (SELECT COUNT(SubWorkOrderChargesId) FROM [dbo].[SubWorkOrderCharges] WITH(NOLOCK) WHERE SubWorkOrderId = @TmpSubWOId AND IsDeleted = 0) > 0 THEN 1 ELSE 0 END
			SET @IsFreight = CASE WHEN (SELECT COUNT(SubWorkOrderFreightId) FROM [dbo].[SubWorkOrderFreight] WITH(NOLOCK) WHERE SubWorkOrderId = @TmpSubWOId AND IsDeleted = 0) > 0 THEN 1 ELSE 0 END
			SET @Is8130 = CASE WHEN (SELECT COUNT(SubReleaseFromId) FROM [dbo].[SubWorkOrder_ReleaseFrom_8130] WITH(NOLOCK) WHERE SubWorkOrderId = @TmpSubWOId) > 0 THEN 1 ELSE 0 END
			SET @IsSubWOClose = CASE WHEN (SELECT COUNT(SubWOPartNoId) FROM [dbo].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE SubWorkOrderId = @TmpSubWOId) > 0 THEN 
								CASE WHEN (SELECT TOP 1 ISNULL(IsClosed, 0) FROM [dbo].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE SubWorkOrderId = @TmpSubWOId) = 1
									 THEN 1 ELSE 0 END
									 ELSE 0 END

			IF(@IsMaterial = 0 AND @IsLabor = 0 AND @IsCharges = 0 AND @IsFreight = 0 AND @Is8130 = 0 AND @IsSubWOClose = 0)
			BEGIN
				UPDATE #tempSubWO
				SET IsAllowDelete = 1
				WHERE SubWorkOrderId = @TmpSubWOId
			END

			UPDATE #tempSubWO
			SET SubReleaseFromId =	CASE WHEN @Is8130 = 1 
									THEN (SELECT SubReleaseFromId FROM [dbo].[SubWorkOrder_ReleaseFrom_8130] WITH(NOLOCK) WHERE SubWorkOrderId = @TmpSubWOId) ELSE 0 END
			WHERE SubWorkOrderId = @TmpSubWOId

			SET @TotalRec = @TotalRec - 1	
		END

		;WITH Result AS(
				SELECT DISTINCT
						SWO.SubWorkOrderId,
						SWPT.SubWOPartNoId,
						SWO.SubWorkOrderNo,
						IM.PartNumber AS 'MasterPartNo',
						IM.PartDescription AS 'MasterPartDescription',
						IM.ManufacturerName AS 'Manufacturer',
						ISNULL(SUBWOS.WorkScopeCode, '') AS 'WorkScope',
						SWO.OpenDate,
						SWO.WorkOrderId,
						WOM.WorkFlowWorkOrderId,
						IM.RevisedPart AS 'RevisedPartNo',
						SWO.WorkOrderMaterialsId,
						SWO.StockLineId,
						ISNULL(SL.SerialNumber, '') AS 'SerialNumber',
						SWO.IsActive,
						SWO.IsDeleted,
						SWO.CreatedDate,
						SWO.UpdatedDate,
						Upper(SWO.CreatedBy) CreatedBy,
						Upper(SWO.UpdatedBy) UpdatedBy,
						tmpSub.isAllowDelete as '	',
						STS.[Description] AS 'SubWOStatus',
						OCD.[Description] AS 'OriginalCondition',
						UCD.[Description] AS 'UpdatedCondition',
						CASE WHEN ISNULL(SWPT.IsTransferredToParentWO, 0) = 0 THEN 'NO' ELSE 'YES' END AS 'IsTransferredToParentWO',
						CASE WHEN (ISNULL(WOMS.QtyReserved , 0) + ISNULL(WOMS.QtyIssued , 0)) > 0 THEN 0 ELSE SWPT.IsClosed  END AS 'isAllowReOpen',
						SL.StockLineNumber AS 'OriginalStockLineNumber',
						SL.StockLineNumber AS 'UpdatedStockLineNumber',
						tmpSub.SubReleaseFromId
			   FROM [dbo].[SubWorkOrderPartNumber] SWPT WITH (NOLOCK)
				INNER JOIN [dbo].[SubWorkOrder] SWO WITH (NOLOCK) ON SWO.SubWorkOrderId = SWPT.SubWorkOrderId
				---INNER JOIN [dbo].[SubWorkOrderPartNumber] SWPT WITH (NOLOCK) 
				INNER JOIN [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK) ON SWO.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SWPT.ItemMasterId = IM.ItemMasterId
				INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SWO.StockLineId = SL.StockLineId
				INNER JOIN [dbo].[WorkScope] SUBWOS WITH (NOLOCK) ON SWPT.SubWorkOrderScopeId = SUBWOS.WorkScopeId
				LEFT JOIN [dbo].[Condition] OCD WITH (NOLOCK) ON SWPT.ConditionId = OCD.ConditionId
				LEFT JOIN [dbo].[Condition] UCD WITH (NOLOCK) ON SWPT.RevisedConditionId = UCD.ConditionId
				LEFT JOIN [dbo].[WorkOrderStatus] STS WITH (NOLOCK) ON SWPT.SubWorkOrderStatusId = STS.Id
				LEFT JOIN #tempSubWO tmpSub WITH (NOLOCK) ON SWO.SubWorkOrderId = tmpSub.SubWorkOrderId
				LEFT JOIN [dbo].[WorkOrderMaterialStockLine] WOMS WITH (NOLOCK) ON WOMS.StockLineId = SWPT.RevisedStockLineId 

		 	  WHERE ((SWO.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR SWO.IsActive=@IsActive))			     
					AND SWO.MasterCompanyId=@MasterCompanyId AND SWO.WorkOrderId = @WorkOrderId	
			), ResultCount AS(SELECT COUNT(SubWorkOrderId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND (([SubWorkOrderNo] LIKE '%' +@GlobalFilter+'%') OR
			        ([MasterPartNo] LIKE '%' + @GlobalFilter+'%') OR	
					([MasterPartDescription] LIKE '%' + @GlobalFilter+'%') OR
					([Manufacturer] LIKE '%' + @GlobalFilter+'%') OR
					([WorkScope] LIKE '%' + @GlobalFilter+'%') OR
					([RevisedPartNo] LIKE '%' + @GlobalFilter+'%') OR
					([SerialNumber] LIKE '%' + @GlobalFilter+'%') OR
					(SubWOStatus LIKE '%' + @GlobalFilter+'%') OR
					(OriginalCondition LIKE '%' + @GlobalFilter+'%') OR
					(UpdatedCondition LIKE '%' + @GlobalFilter+'%') OR
					(IsTransferredToParentWO LIKE '%' + @GlobalFilter+'%') OR
					(OriginalStockLineNumber LIKE '%' + @GlobalFilter+'%') OR
					(UpdatedStockLineNumber LIKE '%' + @GlobalFilter+'%') OR
					(CreatedBy LIKE '%' + @GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' + @GlobalFilter+'%'))) OR   
					(@GlobalFilter ='' AND (ISNULL(@SubWorkOrderNo,'') ='' OR [SubWorkOrderNo] LIKE '%' + @SubWorkOrderNo+'%') AND
					(ISNULL(@MasterPartNo,'') ='' OR [MasterPartNo] LIKE '%' + @MasterPartNo + '%') AND	
					(ISNULL(@MasterPartDescription,'') ='' OR [MasterPartDescription] LIKE '%' + @MasterPartDescription + '%') AND	
					(ISNULL(@Manufacturer,'') ='' OR [Manufacturer] LIKE '%' + @Manufacturer + '%') AND	
					(ISNULL(@WorkScope,'') ='' OR [WorkScope] LIKE '%' + @WorkScope + '%') AND	
					(ISNULL(@RevisedPartNo,'') ='' OR [RevisedPartNo] LIKE '%' + @RevisedPartNo + '%') AND	
					(ISNULL(@SerialNumber,'') ='' OR [SerialNumber] LIKE '%' + @SerialNumber + '%') AND	
					(ISNULL(@SubWOStatus,'') ='' OR SubWOStatus LIKE '%' + @SubWOStatus + '%') AND	
					(ISNULL(@OriginalCondition,'') ='' OR OriginalCondition LIKE '%' + @OriginalCondition + '%') AND	
					(ISNULL(@UpdatedCondition,'') ='' OR UpdatedCondition LIKE '%' + @UpdatedCondition + '%') AND	
					(ISNULL(@IsTransferredToParentWO,'') ='' OR IsTransferredToParentWO LIKE '%' + @IsTransferredToParentWO + '%') AND	
					(ISNULL(@OriginalStockLineNumber,'') ='' OR OriginalStockLineNumber LIKE '%' + @OriginalStockLineNumber + '%') AND	
					(ISNULL(@UpdatedStockLineNumber,'') ='' OR UpdatedStockLineNumber LIKE '%' + @UpdatedStockLineNumber + '%') AND	
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date)=CAST(@OpenDate AS date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(SubWorkOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='SubWorkOrderNo')  THEN [SubWorkOrderNo] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SubWorkOrderNo')  THEN [SubWorkOrderNo] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='MasterPartNo')  THEN [MasterPartNo] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MasterPartNo')  THEN [MasterPartNo] END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='MasterPartDescription')  THEN [MasterPartDescription] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='MasterPartDescription')  THEN [MasterPartDescription] END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN [Manufacturer] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN [Manufacturer] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScope')  THEN [WorkScope] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScope')  THEN [WorkScope] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPartNo')  THEN [RevisedPartNo] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPartNo')  THEN [RevisedPartNo] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN [SerialNumber] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN [SerialNumber] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SubWOStatus')  THEN SubWOStatus END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SubWOStatus')  THEN SubWOStatus END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OriginalCondition')  THEN OriginalCondition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OriginalCondition')  THEN OriginalCondition END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedCondition')  THEN UpdatedCondition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedCondition')  THEN UpdatedCondition END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsTransferredToParentWO')  THEN IsTransferredToParentWO END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTransferredToParentWO')  THEN IsTransferredToParentWO END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OriginalStockLineNumber')  THEN OriginalStockLineNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OriginalStockLineNumber')  THEN OriginalStockLineNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedStockLineNumber')  THEN UpdatedStockLineNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedStockLineNumber')  THEN UpdatedStockLineNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetSubWorkOrderList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS VARCHAR(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@SubWorkOrderNo, '') AS VARCHAR(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@MasterPartNo, '') AS VARCHAR(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@MasterPartDescription , '') AS VARCHAR(100))		  
			   + '@Parameter10 = ''' + CAST(ISNULL(@Manufacturer , '') AS VARCHAR(100))		  
			   + '@Parameter11 = ''' + CAST(ISNULL(@RevisedPartNo , '') AS VARCHAR(100))		  
			   + '@Parameter12 = ''' + CAST(ISNULL(@SerialNumber , '') AS VARCHAR(100))		  
			   + '@Parameter13 = ''' + CAST(ISNULL(@SubWOStatus , '') AS VARCHAR(100))		  
			   + '@Parameter14 = ''' + CAST(ISNULL(@OriginalCondition , '') AS VARCHAR(100))		  
			   + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedCondition , '') AS VARCHAR(100))		  
			   + '@Parameter16 = ''' + CAST(ISNULL(@IsTransferredToParentWO , '') AS VARCHAR(100))		  
			   + '@Parameter17 = ''' + CAST(ISNULL(@OriginalStockLineNumber , '') AS VARCHAR(100))		  
			   + '@Parameter18 = ''' + CAST(ISNULL(@CreatedBy , '') AS VARCHAR(100))
			   + '@Parameter19 = ''' + CAST(ISNULL(@CreatedDate , '') AS VARCHAR(100))
			   + '@Parameter20 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS VARCHAR(100))
			   + '@Parameter21 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS VARCHAR(100))
			   + '@Parameter22 = ''' + CAST(ISNULL(@OpenDate  , '') AS VARCHAR(100))
			   + '@Parameter23 = ''' + CAST(ISNULL(@IsDeleted , '') AS VARCHAR(100))
			   + '@Parameter24 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END