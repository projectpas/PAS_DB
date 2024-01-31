/*************************************************************           
 ** File:   [USP_Lot_GetLotList]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get Lot Listing 
 ** Date:   03/04/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    03/04/2023   Rajesh Gami     Created
**************************************************************
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetLotList] 
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@LotStatusId int = 1,
	@StatusName varchar(50) = 'Open',
	@GlobalFilter varchar(50) = '',	
	@LotNumber varchar(50) = NULL,
	@LotName varchar(200) = NULL,
	@ReferenceNumber varchar(100) = NULL,
	@OpenDate datetime = NULL,
	@OriginalCost decimal(18,2) = NULL,
	@ConsignmentNumber varchar(100) = NULL,
	@ConsigneeName varchar(200) = NULL,
	@AcqusitionCost decimal(18,2) = NULL,
	@RemainingCost decimal(18,2) = NULL,
	@RemainingPercentage decimal(18,2) = NULL,
	@Revenue decimal(18,2) = NULL,
	@MarginAmount decimal(18,2) = NULL,
	@Margin decimal(18,2) = NULL,
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@UpdatedBy  varchar(50) = NULL,
	@UpdatedDate  datetime = NULL,
	@MasterCompanyId bigint = NULL	
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		DECLARE @Count Int;
		DECLARE @RecordFrom int;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = Upper('CreatedDate')
			SET @SortOrder = -1
		END 
		ELSE
		BEGIN 
			Set @SortColumn = Upper(@SortColumn)
		END

		-- LotId,LotNumber,LotName,VendorId,ReferenceNumber,OpenDate,OriginalCost,LotStatusId,StatusName,ConsignmentId,ConsignmentNumber,ConsigneeName,EmployeeId,ObtainFromId,ObtainFromTypeId,TraceableToId,TraceableToTypeId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,AcqusitionCost,RemainingCost,RemainingPercentage,Revenue,MarginAmount,Margin
		;WITH Result AS (	
			SELECT DISTINCT
				LT.[LotId] LotId
			   ,UPPER(LT.LotNumber) LotNumber
			   ,UPPER(LT.LotName) LotName
			   --,LT.VendorId VendorId
			   --,UPPER(LT.ReferenceNumber)ReferenceNumber
			   ,ISNULL((Select top 1 ISNULL(VendorId,0) from dbo.PurchaseOrder po WITH(NOLOCK) Where po.LotId = Lt.LotId AND ISNULL(po.IsDeleted,0) = 0),0) AS VendorId
			   ,(Select top 1 ISNULL(ven.VendorName,'') from dbo.PurchaseOrder po WITH(NOLOCK) INNER JOIN dbo.Vendor ven WITH(NOLOCK) on po.VendorId = ven.VendorId Where po.LotId = Lt.LotId AND ISNULL(po.IsDeleted,0) = 0) AS VendorName
			   ,ISNULL((Select top 1 ISNULL(PurchaseOrderNumber,'') from dbo.PurchaseOrder po WITH(NOLOCK) Where po.LotId = Lt.LotId AND ISNULL(po.IsDeleted,0) = 0),'') AS ReferenceNumber
			   ,LT.[CreatedDate] OpenDate
			   ,ISNULL(LT.OriginalCost,0.00)OriginalCost
			   ,LT.LotStatusId
			   ,S.StatusName
			   ,LT.ConsignmentId
			   ,UPPER(LC.ConsignmentNumber)ConsignmentNumber
			   ,UPPER(LC.ConsigneeName)ConsigneeName
			   ,LT.EmployeeId
			   ,LT.ObtainFromId
			   ,LT.ObtainFromTypeId
			   ,LT.TraceableToId
			   ,LT.TraceableToTypeId
			   ,LT.ManagementStructureId
			   ,LT.[MasterCompanyId]
			   ,LT.[CreatedBy]
			   ,LT.[UpdatedBy]
			   ,LT.[CreatedDate]
			   ,LT.[UpdatedDate]
			   ,(
				--ISNULL((SELECT ISNULL(SUM(POP.ExtendedCost),0) FROM dbo.PurchaseOrder PO WITH(NOLOCK) INNER JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) 
				--			  on PO.PurchaseOrderId = POP.PurchaseOrderId AND PO.LotId = POP.LotId AND po.LotId = LT.LotId
				--			  WHERE POP.LotId = LT.LotId AND PO.StatusId not in(1,2,3)),0)+
				ISNULL((SELECT ISNULL(SUM(POF.Amount),0) FROM dbo.PurchaseOrder PO WITH(NOLOCK) 
							  LEFT JOIN dbo.PurchaseOrderFreight POF WITH(NOLOCK) on PO.PurchaseOrderId = POF.PurchaseOrderId
							  WHERE po.LotId = LT.LotId AND PO.StatusId not in(1,2,3)),0)+
				ISNULL((SELECT ISNULL(SUM(POC.ExtendedCost),0)  FROM dbo.PurchaseOrder PO WITH(NOLOCK) 
							  LEFT JOIN dbo.PurchaseOrderCharges POC WITH(NOLOCK) on PO.PurchaseOrderId = POC.PurchaseOrderId
							  WHERE PO.LotId = LT.LotId AND PO.StatusId not in(1,2,3)),0)) 
							  + ISNULL((SELECT SUM(ISNULL(RepairCost,0)) FROM dbo.LotCalculationDetails LCD WITH(NOLOCK) WHERE LotId = LT.LotId AND ISNULL(LCD.IsFromPreCostStk,0) != 1 AND  UPPER(REPLACE(LCD.Type,' ','')) = UPPER(REPLACE('Trans In(RO)',' ',''))),0) 
							  + ISNULL((SELECT SUM(ISNULL(OtherCost,0)) FROM dbo.LotCalculationDetails LCD WITH(NOLOCK) WHERE LotId = LT.LotId AND ISNULL(LCD.IsFromPreCostStk,0) != 1 AND  UPPER(REPLACE(LCD.Type,' ','')) = UPPER(REPLACE('Trans In(RO)',' ',''))),0) 
							  + ISNULL((SELECT ISNULL(SUM(TransferredInCost),0) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = LT.LotId AND ISNULL(LCD.IsFromPreCostStk,0) != 1 AND (UPPER(ISNULL(REPLACE(LCD.Type,' ',''),'')) = UPPER(REPLACE('Trans In(Lot)',' ','')) OR UPPER(ISNULL(REPLACE(LCD.Type,' ',''),'')) = UPPER(REPLACE('Trans In(PO)',' ','')))),0)
							  AS AcqusitionCost
			    ,(((
				--ISNULL((SELECT ISNULL(SUM(POP.ExtendedCost),0) FROM dbo.PurchaseOrder PO WITH(NOLOCK) INNER JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) 
				--			  on PO.PurchaseOrderId = POP.PurchaseOrderId AND PO.LotId = POP.LotId AND po.LotId = LT.LotId
				--			  WHERE POP.LotId = LT.LotId AND PO.StatusId not in(1,2,3)),0)+
				ISNULL((SELECT ISNULL(SUM(POF.Amount),0) FROM dbo.PurchaseOrder PO WITH(NOLOCK) 
							  LEFT JOIN dbo.PurchaseOrderFreight POF WITH(NOLOCK) on PO.PurchaseOrderId = POF.PurchaseOrderId
							  WHERE po.LotId = LT.LotId AND PO.StatusId not in(1,2,3)),0)+
				ISNULL((SELECT ISNULL(SUM(POC.ExtendedCost),0)  FROM dbo.PurchaseOrder PO WITH(NOLOCK) 
							  LEFT JOIN dbo.PurchaseOrderCharges POC WITH(NOLOCK) on PO.PurchaseOrderId = POC.PurchaseOrderId
							  WHERE PO.LotId = LT.LotId AND PO.StatusId not in(1,2,3)),0)) 
							  + (SELECT SUM(ISNULL(sl.Adjustment,0)* ISNULL(sl.QuantityOnHand, 0)) from 
					DBO.LOT lot WITH(NOLOCK) 
					INNER JOIN DBO.LotTransInOutDetails ltin WITH(NOLOCK) on lot.LotId = ltin.LotId
					INNER JOIN DBO.Stockline sl WITH(NOLOCK) on ltin.StockLineId = sl.StockLineId
					Where  lot.LotId = LT.LotId)
							  + ISNULL((SELECT SUM(ISNULL(RepairCost,0)) FROM dbo.LotCalculationDetails LCD WITH(NOLOCK) WHERE LotId = LT.LotId AND ISNULL(LCD.IsFromPreCostStk,0) != 1 AND  UPPER(REPLACE(LCD.Type,' ','')) = UPPER(REPLACE('Trans In(RO)',' ',''))),0) 
							  + ISNULL((SELECT SUM(ISNULL(OtherCost,0)) FROM dbo.LotCalculationDetails LCD WITH(NOLOCK) WHERE LotId = LT.LotId AND ISNULL(LCD.IsFromPreCostStk,0) != 1 AND  UPPER(REPLACE(LCD.Type,' ','')) = UPPER(REPLACE('Trans In(RO)',' ',''))),0)
							  + ISNULL((SELECT ISNULL(SUM(TransferredInCost),0) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE  LCD.LotId = LT.LotId AND ISNULL(LCD.IsFromPreCostStk,0) != 1 AND (UPPER(ISNULL(REPLACE(LCD.Type,' ',''),'')) = UPPER(REPLACE('Trans In(Lot)',' ','')) OR UPPER(ISNULL(REPLACE(LCD.Type,' ',''),'')) = UPPER(REPLACE('Trans In(PO)',' ','')))),0) 							) 
							  - ((ISNULL((SELECT ISNULL(SUM(TransferredOutCost),0) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = LT.LotId AND ISNULL(LCD.IsFromPreCostStk,0) != 1 AND UPPER(REPLACE(LCD.[Type],' ','')) = UPPER(REPLACE('Trans Out(Lot)',' ','')) ),0)) + (ISNULL((SELECT ISNULL(SUM(ISNULL(SOP.UnitCost,0) * ISNULL(LCD.Qty,0)),0) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) INNER JOIN DBO.SalesOrder SO WITH(NOLOCK) on LCD.ReferenceId = SO.SalesOrderId INNER JOIN DBO.SalesOrderPart SOP WITH(NOLOCK) on So.SalesOrderId = SOP.SalesOrderId AND LCD.ChildId = SOP.SalesOrderPartId WHERE LCD.LotId = LT.LotId  AND UPPER(REPLACE(LCD.[Type],' ','')) = UPPER(REPLACE('Trans Out(SO)',' ','')) ),0)) ) ) AS RemainingCost
			   --,(ISNULL((SELECT ISNULL(SUM(POP.ExtendedCost),0) FROM dbo.PurchaseOrder PO WITH(NOLOCK) INNER JOIN dbo.PurchaseOrderPart POP WITH(NOLOCK) 
						--	  on PO.PurchaseOrderId = POP.PurchaseOrderId AND PO.LotId = POP.LotId
						--	  WHERE POP.LotId = LT.LotId),0) 
						--	  + ISNULL((SELECT TOP 1 ISNULL(SUM(TransferredInCost),0) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = LT.LotId ORDER BY 1 DESC),0) 
						--	  + ISNULL((SELECT TOP 1 ISNULL(SUM(RepairCost),0) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = LT.LotId ORDER BY 1 DESC ),0)) 
						--	  - ISNULL((SELECT TOP 1 ISNULL(SUM(TransferredOutCost),0) FROM DBO.LotCalculationDetails LCD WITH(NOLOCK) WHERE LCD.LotId = LT.LotId ORDER BY 1 DESC),0) AS RemainingCost
			   ,ISNULL((SELECT SUM(ISNULL(LOC.ExtSalesUnitPrice,0)) FROM DBo.LotCalculationDetails LOC WITH(NOLOCK) WHERE LOC.LotId = LT.LotId AND UPPER(REPLACE(LOC.Type,' ','')) = UPPER(REPLACE('Trans Out(SO)',' ',''))),0) AS Revenue
			   ,ISNULL((SELECT SUM(ISNULL(LOC.MarginAmount,0)) FROM DBo.LotCalculationDetails LOC WITH(NOLOCK) WHERE LOC.LotId = LT.LotId AND UPPER(REPLACE(LOC.Type,' ','')) = UPPER(REPLACE('Trans Out(SO)',' ',''))),0) MarginAmount
				FROM [dbo].[Lot] LT WITH(NOLOCK) 
				INNER JOIN dbo.LotDetail LD WITH(NOLOCK) on LT.LotId = LD.LotId
				INNER JOIN [dbo].[LotStatus] S WITH(NOLOCK) ON LT.[LotStatusId] = S.[LotStatusId]
				LEFT JOIN [dbo].[LotConsignment] LC WITH (NOLOCK) ON LT.ConsignmentId = LC.ConsignmentId
 			WHERE ISNULL(LT.IsDeleted,0) = 0 AND ISNULL(LT.IsActive,1) = 1 And Lt.MasterCompanyId = @MasterCompanyId
		  	) , ResultCount AS(Select COUNT(LotId) AS totalItems FROM Result) 
			SELECT *,CONVERT(DECIMAL(18,2),(CASE WHEN Revenue > 0 THEN  ((ISNULL(MarginAmount,0)/ISNULL(Revenue,0))*100) ELSE 0 END)) AS Margin,Convert(DECIMAL(18,2),(CASE WHEN ISNULL(AcqusitionCost,0) > 0 THEN ((ISNULL(RemainingCost,0)/ISNULL(AcqusitionCost,0))*100) ELSE 0 END)) AS RemainingPercentage INTO #TempTblLot FROM  Result 
		SELECT * INTO #TempResult FROM  #TempTblLot 
			WHERE 
			 ((@GlobalFilter <>'' AND ((LotNumber LIKE '%' + @GlobalFilter + '%') OR
					(LotName LIKE '%' + @GlobalFilter + '%') OR
					(ReferenceNumber LIKE '%' + @GlobalFilter + '%') OR
					(OpenDate LIKE '%' + @GlobalFilter + '%') OR
					(CAST(OriginalCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(ConsignmentNumber LIKE '%' + @GlobalFilter + '%') OR
					(ConsigneeName LIKE '%' + @GlobalFilter + '%') OR
					(CAST(AcqusitionCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(RemainingCost AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(RemainingPercentage AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(Revenue AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(MarginAmount AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CAST(Margin AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(CreatedBy like '%' + @GlobalFilter + '%') OR
					(CreatedDate like '%' + @GlobalFilter + '%') OR
					(UpdatedBy like '%' + @GlobalFilter + '%') OR
					(UpdatedBy like '%' + @GlobalFilter + '%') OR
					(UpdatedDate like '%' + @GlobalFilter + '%')))
					OR
					(@GlobalFilter = '' AND (ISNULL(@LotNumber, '') = '' OR LotNumber LIKE '%' + @LotNumber + '%') AND
					(ISNULL(@LotName, '') = '' OR LotName LIKE '%' + @LotName + '%') AND
					(ISNULL(@ReferenceNumber, '') = '' OR ReferenceNumber LIKE '%' + @ReferenceNumber + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date) = CAST(@OpenDate AS date)) AND
					(IsNull(@OriginalCost, 0) = 0 OR CAST(OriginalCost as VARCHAR(10)) like @OriginalCost) AND
					(ISNULL(@ConsignmentNumber, '') = '' OR ConsignmentNumber LIKE '%' + @ConsignmentNumber + '%') AND
					(ISNULL(@ConsigneeName, '') = '' OR ConsigneeName LIKE '%' + @ConsigneeName + '%') AND
					(ISNULL(@AcqusitionCost, 0) = 0 OR CAST(AcqusitionCost as VARCHAR(10)) LIKE @AcqusitionCost) AND
					(ISNULL(@RemainingCost, 0) = 0 OR CAST(RemainingCost as VARCHAR(10)) LIKE @RemainingCost) AND
					(ISNULL(@RemainingPercentage, 0) = 0 OR CAST(RemainingPercentage as VARCHAR(10)) = @RemainingPercentage) AND
					(ISNULL(@Revenue, 0) = 0 OR CAST(Revenue as VARCHAR(10)) = @Revenue) AND
					(ISNULL(@MarginAmount, 0) = 0 OR CAST(MarginAmount as VARCHAR(10)) = @MarginAmount) AND
					(ISNULL(@Margin, 0) = 0 OR CAST(Margin as VARCHAR(10)) = @Margin) AND
					(ISNULL(@CreatedBy, '') = '' OR CreatedBy  like '%'+ @CreatedBy + '%') AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date) = CAST(CreatedDate AS date)))
				  )

			SELECT @Count = COUNT(LotId) FROM #TempResult			

			--SELECT LotId,LotNumber,LotName,VendorId,ReferenceNumber,OpenDate,OriginalCost,LotStatusId,StatusName,ConsignmentId,ConsignmentNumber,ConsigneeName,EmployeeId,ObtainFromId,ObtainFromTypeId,TraceableToId,TraceableToTypeId,ManagementStructureId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,AcqusitionCost,RemainingCost,(CASE WHEN AcqusitionCost > 0 THEN (RemainingCost/AcqusitionCost) ELSE 0 END) AS RemainingPercentage,Revenue,MarginAmount,Margin, @Count AS NumberOfItems FROM #TempResult
			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='LotNumber')  THEN LotNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LotNumber')  THEN LotNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LotName')  THEN LotName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LotName')  THEN LotName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ReferenceNumber')  THEN ReferenceNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ReferenceNumber')  THEN ReferenceNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='OriginalCost')  THEN OriginalCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OriginalCost')  THEN OriginalCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConsignmentNumber')  THEN ConsignmentNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConsignmentNumber')  THEN ConsignmentNumber END DESC,           
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConsigneeName')  THEN ConsigneeName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConsigneeName')  THEN ConsigneeName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AcqusitionCost')  THEN AcqusitionCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AcqusitionCost')  THEN AcqusitionCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RemainingCost')  THEN RemainingCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RemainingCost')  THEN RemainingCost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RemainingPercentage')  THEN RemainingPercentage END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RemainingPercentage')  THEN RemainingPercentage END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Revenue')  THEN Revenue END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Revenue')  THEN Revenue END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='MarginAmount')  THEN MarginAmount END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='MarginAmount')  THEN MarginAmount END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Margin')  THEN Margin END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Margin')  THEN Margin END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='CreatedDate')  THEN CreatedDate END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_Lot_GetLotList]',
            @ProcedureParameters varchar(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
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