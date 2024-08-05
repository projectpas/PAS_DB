
-- EXEC [dbo].[GetSOConfirmationList] 1,20,'',-1,'',0,'',null,0,'','','','',0,null,'','','','pnview',1
CREATE   PROCEDURE [dbo].[GetSOConfirmationList]
@PageNumber int = 1,
@PageSize int = 20,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = '',
@SOConformationNumber bigint = NULL,
@SalesOrderNumber varchar(50) = NULL,
@OpenDate datetime = NULL,
@Qty int = NULL,
@PartNumber varchar(50) = NULL,
@PartDescription varchar(50) = NULL,
@SerialNumber varchar(50) = NULL,
@UOM varchar(50) = NULL,
@QtyReserved int = NULL,
@estimatedShipDate datetime = NULL,
@customerName varchar(50) = NULL,
@ConfirmedBy varchar(50) = NULL,
@CustomerMemo varchar(50) = NULL,
@Type varchar(50) = NULL,
@MasterCompanyId bigint = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('OpenDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	
		--BEGIN TRANSACTION
		--BEGIN
		IF(@Type = 'soview')
		BEGIN
			;WITH Result AS(
			
			SELECT 
			part.SalesOrderId AS SOConformationNumber,
			part.SalesOrderId,
			part.SalesOrderPartId,
			part.SalesOrderQuoteId,
			part.ItemMasterId,
			part.StockLineId,
			so.SalesOrderNumber,
			ISNULL(q.SalesOrderQuoteNumber, '') AS SalesOrderQuoteNumber,
			--CONVERT(VARCHAR, so.OpenDate, 101) AS OpenDate,
			so.OpenDate,
			ISNULL(cust.Name, '') AS CustomerName,
			ISNULL(qs.StockLineNumber, '') AS StockLineNumber,
			part.FxRate,
			part.Qty,
			part.CreatedBy,
			part.CreatedDate,
			part.UpdatedBy,
			part.UpdatedDate,
			part.EstimatedShipDate,
			itemMaster.PartNumber,
			itemMaster.PartDescription,
			CASE WHEN qs.IsSerialized IS NOT NULL THEN qs.IsSerialized ELSE 0 END AS IsSerialized,
			ISNULL(qs.SerialNumber, '') AS SerialNumber,
			ISNULL(qs.ControlNumber, '') AS ControlNumber,
			ISNULL(cp.Description, '') AS ConditionDescription,
			ISNULL(iu.ShortName, '') AS UOM,
			ISNULL(rPart.QtyToReserve, 0) AS QtyReserved,
			CASE WHEN soc.CustomerStatusId = 2 THEN 1 ELSE 0 END AS IsApproved,
			ISNULL(part.CustomerReference, '') AS CustomerReference,
			ISNULL(st.Name, '') AS StatusName,
			ISNULL(con.FirstName + ' ' + con.LastName, '') AS ConfirmedBy,
			ISNULL(soc.CustomerMemo, '') AS CustomerMemo,
			ISNULL(soc.InternalMemo, '') AS InternalMemo
    FROM
        [dbo].[SalesOrderPart] part WITH (NOLOCK)
		LEFT JOIN SalesOrderApproval soc ON part.SalesOrderPartId = soc.SalesOrderPartId
		INNER JOIN dbo.SalesOrder so WITH (NOLOCK) ON part.SalesOrderId = so.SalesOrderId
		LEFT JOIN dbo.Customer cust WITH (NOLOCK) ON so.CustomerId = cust.CustomerId
		LEFT JOIN dbo.StockLine qs WITH (NOLOCK) ON part.StockLineId = qs.StockLineId
		INNER JOIN dbo.ItemMaster itemMaster WITH (NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		LEFT JOIN dbo.Condition cp WITH (NOLOCK) ON part.ConditionId = cp.ConditionId
		LEFT JOIN dbo.SalesOrderQuote q WITH (NOLOCK) ON part.SalesOrderQuoteId = q.SalesOrderQuoteId
		LEFT JOIN dbo.UnitOfMeasure iu WITH (NOLOCK) ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
		LEFT JOIN dbo.SalesOrderReserveParts rPart WITH (NOLOCK) ON part.SalesOrderPartId = rPart.SalesOrderPartId
		LEFT JOIN dbo.UnitOfMeasure um WITH (NOLOCK) ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
		LEFT JOIN dbo.MasterSalesOrderQuoteStatus st WITH (NOLOCK) ON part.StatusId = st.Id
		LEFT JOIN dbo.Contact con WITH (NOLOCK) ON soc.CustomerApprovedById = con.ContactId
    WHERE 
        part.IsDeleted = 0 
        AND part.MasterCompanyId = @masterCompanyId

		   	 ), ResultCount AS(SELECT COUNT(SalesOrderId) AS totalItems FROM Result)
			
			
			SELECT * INTO #TempResult FROM  Result r
			
			 WHERE ((@GlobalFilter <>'' AND ((SOConformationNumber LIKE '%' +@GlobalFilter+'%') OR
			        (SalesOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
					(Qty LIKE '%' +@GlobalFilter+'%') OR					
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR						
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR						
					(SerialNumber LIKE '%' +@GlobalFilter+'%') OR										
					(UOM LIKE '%' +@GlobalFilter+'%') OR
					(QtyReserved LIKE '%' +@GlobalFilter+'%') OR
					(customerName LIKE '%' +@GlobalFilter+'%') OR
					(ConfirmedBy LIKE '%' +@GlobalFilter+'%') OR
					(CustomerMemo LIKE '%' +@GlobalFilter+'%')))	
					OR   
					(@GlobalFilter='' AND (ISNULL(@SOConformationNumber,'') ='' OR SOConformationNumber LIKE '%' + @SOConformationNumber+'%') AND
					(ISNULL(@SalesOrderNumber,'') ='' OR SalesOrderNumber LIKE '%' + @SalesOrderNumber + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date)=CAST(@OpenDate AS date)) AND
					(ISNULL(@Qty,'') ='' OR Qty LIKE '%' + @Qty + '%') AND
					(ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND				
					(ISNULL(@UOM,'') ='' OR UOM LIKE '%' + @UOM + '%') AND
					(ISNULL(@QtyReserved,'') ='' OR QtyReserved LIKE '%' + @QtyReserved + '%') AND
					(ISNULL(@estimatedShipDate,'') ='' OR CAST(estimatedShipDate AS Date)=CAST(@estimatedShipDate AS date)) AND
					(ISNULL(@customerName,'') ='' OR customerName LIKE '%' + @customerName + '%') AND
					(ISNULL(@ConfirmedBy,'') ='' OR ConfirmedBy LIKE '%' + @ConfirmedBy + '%') AND
					(ISNULL(@CustomerMemo,'') ='' OR CustomerMemo LIKE '%' + @CustomerMemo + '%'))
				   )

			SELECT @Count = COUNT(SalesOrderId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='SOConformationNumber')  THEN SOConformationNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SOConformationNumber')  THEN SOConformationNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SalesOrderNumber')  THEN SalesOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SalesOrderNumber')  THEN SalesOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='UOM')  THEN UOM END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UOM')  THEN UOM END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='QtyReserved')  THEN QtyReserved END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyReserved')  THEN QtyReserved END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='estimatedShipDate')  THEN estimatedShipDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='estimatedShipDate')  THEN estimatedShipDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='customerName')  THEN customerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='customerName')  THEN customerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConfirmedBy')  THEN ConfirmedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConfirmedBy')  THEN ConfirmedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerMemo')  THEN CustomerMemo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerMemo')  THEN CustomerMemo END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE
		BEGIN
			;WITH Result AS(
			
			SELECT
        part.SalesOrderId AS SOConformationNumber,
        part.SalesOrderId,
        part.SalesOrderPartId,
        part.SalesOrderQuoteId,
        part.ItemMasterId,
        part.StockLineId,
        so.SalesOrderNumber,
        CASE WHEN q.SalesOrderQuoteNumber IS NOT NULL THEN q.SalesOrderQuoteNumber ELSE '' END AS SalesOrderQuoteNumber,
        CONVERT(VARCHAR(10), so.OpenDate, 101) AS OpenDate,
        ISNULL(cust.Name, '') AS CustomerName,
        ISNULL(qs.StockLineNumber, '') AS StockLineNumber,
        part.FxRate,
        part.Qty,
        part.CreatedBy,
		part.EstimatedShipDate,
        CONVERT(VARCHAR(19), part.CreatedDate, 120) AS CreatedDate,
        part.UpdatedBy,
        CONVERT(VARCHAR(19), part.UpdatedDate, 120) AS UpdatedDate,
        itemMaster.PartNumber,
        itemMaster.PartDescription,
        CASE WHEN qs.IsSerialized IS NOT NULL THEN qs.IsSerialized ELSE 0 END AS IsSerialized,
        ISNULL(qs.SerialNumber, '') AS SerialNumber,
        ISNULL(qs.ControlNumber, '') AS ControlNumber,
        ISNULL(cp.Description, '') AS ConditionDescription,
        ISNULL(iu.ShortName, '') AS UOM,
        ISNULL(rPart.QtyToReserve, 0) AS QtyReserved,
        CASE WHEN soc.CustomerStatusId = 2 THEN 1 ELSE 0 END AS IsApproved, -- Assuming 2 is the ID for 'Approved'
        ISNULL(part.CustomerReference, '') AS CustomerReference,
        ISNULL(st.Name, '') AS StatusName,
        ISNULL(con.FirstName + ' ' + con.LastName, '') AS ConfirmedBy,
        ISNULL(soc.CustomerMemo, '') AS CustomerMemo,
        ISNULL(soc.InternalMemo, '') AS InternalMemo
    FROM
        SalesOrderPart part
        LEFT JOIN SalesOrderApproval soc ON part.SalesOrderPartId = soc.SalesOrderPartId
        INNER JOIN SalesOrder so ON part.SalesOrderId = so.SalesOrderId
        LEFT JOIN Customer cust ON so.CustomerId = cust.CustomerId
        LEFT JOIN StockLine qs ON part.StockLineId = qs.StockLineId
        LEFT JOIN ItemMaster itemMaster ON part.ItemMasterId = itemMaster.ItemMasterId
        LEFT JOIN Condition cp ON part.ConditionId = cp.ConditionId
        LEFT JOIN SalesOrderQuote q ON part.SalesOrderQuoteId = q.SalesOrderQuoteId
        LEFT JOIN UnitOfMeasure iu ON itemMaster.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
        LEFT JOIN SalesOrderReserveParts rPart ON part.SalesOrderPartId = rPart.SalesOrderPartId
        LEFT JOIN UnitOfMeasure um ON itemMaster.PurchaseUnitOfMeasureId = um.UnitOfMeasureId
        LEFT JOIN MasterSalesOrderQuoteStatus st ON part.StatusId = st.Id
        LEFT JOIN Contact con ON soc.CustomerApprovedById = con.ContactId
    WHERE
        part.IsDeleted = 0
        AND part.MasterCompanyId = @MasterCompanyId

		   	 ), ResultCount AS(SELECT COUNT(SalesOrderId) AS totalItems FROM Result)
			
			
			SELECT * INTO #TempResultPn FROM  Result r
			
			 WHERE ((@GlobalFilter <>'' AND (
					--(SOConformationNumber LIKE '%' +@GlobalFilter+'%') OR
					(CAST(SOConformationNumber AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
			        (SalesOrderNumber LIKE '%' +@GlobalFilter+'%') OR	
					--(Qty LIKE '%' +@GlobalFilter+'%') OR
					(CAST(Qty AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR						
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR						
					(SerialNumber LIKE '%' +@GlobalFilter+'%') OR										
					(UOM LIKE '%' +@GlobalFilter+'%') OR
					--(QtyReserved LIKE '%' +@GlobalFilter+'%') OR
					(CAST(QtyReserved AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(customerName LIKE '%' +@GlobalFilter+'%') OR
					(ConfirmedBy LIKE '%' +@GlobalFilter+'%') OR
					(CustomerMemo LIKE '%' +@GlobalFilter+'%')))	
					OR   
					(@GlobalFilter='' AND 
					--(ISNULL(@SOConformationNumber,'') ='' OR SOConformationNumber LIKE '%' + @SOConformationNumber+'%') AND
					(IsNull(@SOConformationNumber, 0) = 0 OR CAST(SOConformationNumber as VARCHAR(10)) like @SOConformationNumber) AND
					(ISNULL(@SalesOrderNumber,'') ='' OR SalesOrderNumber LIKE '%' + @SalesOrderNumber + '%') AND
					(ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS Date)=CAST(@OpenDate AS date)) AND
					--(ISNULL(@Qty,'') ='' OR Qty LIKE '%' + @Qty + '%') AND
					(IsNull(@Qty, 0) = 0 OR CAST(Qty as VARCHAR(10)) like @Qty) AND
					(ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND				
					(ISNULL(@UOM,'') ='' OR UOM LIKE '%' + @UOM + '%') AND
					--(ISNULL(@QtyReserved,'') ='' OR QtyReserved LIKE '%' + @QtyReserved + '%') AND
					(IsNull(@QtyReserved, 0) = 0 OR CAST(QtyReserved as VARCHAR(10)) like @QtyReserved) AND
					(ISNULL(@estimatedShipDate,'') ='' OR CAST(estimatedShipDate AS Date)=CAST(@estimatedShipDate AS date)) AND
					(ISNULL(@customerName,'') ='' OR customerName LIKE '%' + @customerName + '%') AND
					(ISNULL(@ConfirmedBy,'') ='' OR ConfirmedBy LIKE '%' + @ConfirmedBy + '%') AND
					(ISNULL(@CustomerMemo,'') ='' OR CustomerMemo LIKE '%' + @CustomerMemo + '%'))
				   )

			SELECT @Count = COUNT(SalesOrderId) FROM #TempResultPn			

			SELECT *, @Count AS NumberOfItems FROM #TempResultPn ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='SOConformationNumber')  THEN SOConformationNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SOConformationNumber')  THEN SOConformationNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='SalesOrderNumber')  THEN SalesOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SalesOrderNumber')  THEN SalesOrderNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='OpenDate')  THEN OpenDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='OpenDate')  THEN OpenDate END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='UOM')  THEN UOM END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UOM')  THEN UOM END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='QtyReserved')  THEN QtyReserved END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QtyReserved')  THEN QtyReserved END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='estimatedShipDate')  THEN estimatedShipDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='estimatedShipDate')  THEN estimatedShipDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='customerName')  THEN customerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='customerName')  THEN customerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ConfirmedBy')  THEN ConfirmedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ConfirmedBy')  THEN ConfirmedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerMemo')  THEN CustomerMemo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerMemo')  THEN CustomerMemo END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END

		

		--END

		--COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		--IF @@trancount > 0
			PRINT 'ROLLBACK'
            --ROLLBACK TRANSACTION;
            -- temp table drop
			SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;

			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ProceEmployeeList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@SOConformationNumber, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@SalesOrderNumber, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@OpenDate, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@PartNumber , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@PartDescription , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@SerialNumber, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@UOM, '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@QtyReserved, '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@estimatedShipDate, '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@customerName , '') AS varchar(100))		  
			  + '@Parameter16 = ''' + CAST(ISNULL(@ConfirmedBy , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@CustomerMemo , '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
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