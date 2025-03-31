/************************************************************************************           
 ** File:   [GetVendorScorcardInfo]           
 ** Author: 
 ** Description: This stored procedure is used to get Vendor Audit Info Data List.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR   Date					Author				Change Description            
 ** --   --------				 -------		  --------------------------------          
	 1    12-03-2025			Amit Ghediya		Created

	 EXEC [dbo].[GetVendorScorcardInfo] 1,225,4767
****************************************************************************************/
CREATE    PROCEDURE [dbo].[GetVendorScorcardInfo]
	@MasterCompanyId BIGINT,
	@EmployeeId BIGINT,
	@VendorId bigint = null
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
				
			DECLARE @POPartSum BIGINT = 0,
					@ROPartSum BIGINT = 0,
					@POROPartSum BIGINT = 0,
					@StocklineSum BIGINT = 0,
					@OnTimeAverage DECIMAL(18,2) = 0,
					@RatingId INT = 0,
					@StatusId INT = 0;
			--SELECT  
			--	@POPartSum = ISNULL(SUM(pop.[QuantityOrdered]),0)
			--FROM [DBO].[PurchaseOrderPart] POP WITH(NOLOCK)
			--INNER JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.[PurchaseOrderId] = PO.[PurchaseOrderId]
			--WHERE PO.VendorId = @VendorId
			--AND CAST(POP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND GETUTCDATE();

			--SELECT  
			--	@ROPartSum = ISNULL(SUM(ROP.[QuantityOrdered]),0)
			--FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
			--INNER JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.[RepairOrderId] = RO.[RepairOrderId]
			--WHERE RO.[VendorId] = @VendorId
			--AND CAST(ROP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND GETUTCDATE();

			--SELECT 
			--	@StocklineSum = ISNULL(SUM([Quantity]),0)
			--FROM [DBO].[Stockline] WITH(NOLOCK)
			--WHERE [vendorid] = @VendorId 
			--AND [IsParent] = 1
			--AND CAST([CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND GETUTCDATE();

			
			--IF(@StocklineSum > 0 AND (@POPartSum + @ROPartSum) > 0)
			--BEGIN
			--	SET @OnTimeAverage =  ROUND((@StocklineSum * 100 / (@POPartSum + @ROPartSum)),2);
			--END
			--ELSE
			--BEGIN
			--	SET @OnTimeAverage = 0;
			--END

			DECLARE 
			--@VendorId BIGINT = 1293,
		   @POPartTotalQty DECIMAL(18,2),
		   @POStkPartTotalQty DECIMAL(18,2),
		   @StkOnTimeQty DECIMAL(18,2),
		   @POOnTimeQty DECIMAL(18,2),
		   @PODelayedQty DECIMAL(18,2);

			IF OBJECT_ID(N'tempdb..#tmpdata') IS NOT NULL
			BEGIN
					DROP TABLE #tmpdata
			END
		
			CREATE TABLE #tmpdata (
				ID BIGINT NOT NULL IDENTITY,
				VendorId BIGINT NULL,
				PurchaseOrderPartRecordId BIGINT NULL,
				TotalQty BIGINT NULL,
				OnTimeQty BIGINT NULL
			)

			-- Insert PO data into temp
			INSERT INTO #tmpdata(VendorId,PurchaseOrderPartRecordId,TotalQty,OnTimeQty)
			SELECT	PO.VendorId,
					POP.PurchaseOrderPartRecordId,
					ISNULL(SUM(POP.QuantityOrdered),0),
    				CASE WHEN MAX(CAST(GETUTCDATE() AS DATE)) <= MAX(POP.EstDeliveryDate) THEN ISNULL(SUM(POP.QuantityOrdered),0) ELSE 0 END --STL OnTimeQty
    		FROM  [DBO].[PurchaseOrderPart] POP WITH(NOLOCK) 
    		INNER JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.[PurchaseOrderId] = PO.[PurchaseOrderId]
    		WHERE PO.[vendorid] = @VendorId 			
    		AND CAST(POP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND GETUTCDATE()
			GROUP BY VendorId,POP.PurchaseOrderPartRecordId;

			-- Insert RO data into temp
			INSERT INTO #tmpdata(VendorId,PurchaseOrderPartRecordId,TotalQty,OnTimeQty)
			SELECT	RO.VendorId,
					ROP.RepairOrderPartRecordId,
					ISNULL(SUM(ROP.QuantityOrdered),0),
    				CASE WHEN MAX(CAST(GETUTCDATE() AS DATE)) <= MAX(ROP.EstRecordDate) THEN ISNULL(SUM(ROP.QuantityOrdered),0) ELSE 0 END --STL OnTimeQty
    		FROM  [DBO].[RepairOrderPart] ROP WITH(NOLOCK) 
    		INNER JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.[RepairOrderId] = RO.[RepairOrderId] AND ROP.IsActive = 1 AND ROP.IsDeleted = 0
    		WHERE RO.[vendorid] = @VendorId 
    		AND CAST(ROP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND GETUTCDATE()
			AND RO.IsActive = 1 AND RO.IsDeleted = 0
			GROUP BY VendorId,ROP.RepairOrderPartRecordId;

			;WITH CTE As(SELECT	
					SL.[vendorid],
					SL.PurchaseOrderPartRecordId,
					CASE WHEN MAX(CAST(SL.ReceivedDate AS DATE)) <= MAX(POP.EstDeliveryDate) THEN ISNULL(tmp.[TotalQty],0) - ISNULL(SUM(SL.[Quantity]),0) ELSE 0 END PartOnTimeQtys,
					CASE WHEN MAX(CAST(SL.ReceivedDate AS DATE)) <= MAX(POP.EstDeliveryDate) THEN ISNULL(SUM(SL.[Quantity]),0) ELSE 0 END OnTimeQtys
    				FROM  [DBO].[Stockline] SL WITH(NOLOCK) 
    				JOIN [DBO].[PurchaseOrderPart] POP WITH(NOLOCK) ON POP.PurchaseOrderPartRecordId = SL.PurchaseOrderPartRecordId
					INNER JOIN #tmpdata tmp ON POP.PurchaseOrderPartRecordId = tmp.PurchaseOrderPartRecordId
    				WHERE SL.[vendorid] = @VendorId 
    				AND SL.[IsParent] = 1
    				AND CAST(SL.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND GETUTCDATE()
					GROUP BY SL.PurchaseOrderPartRecordId,SL.[vendorid],tmp.[TotalQty]
					),

			CTE1 As(
					SELECT 
						tmp.PurchaseOrderPartRecordId,
						tmp.TotalQty AS total,
						CASE WHEN 
								ISNULL(ct.PartOnTimeQtys,0) > 0 
								THEN 
									CASE WHEN 
										ISNULL(tmp.OnTimeQty,0) > 0 
									THEN 
										ISNULL(ct.PartOnTimeQtys,0)
									ELSE
										0
									END
								ELSE 
									CASE WHEN ISNULL(ct.PartOnTimeQtys,0) = 0 THEN 0 ELSE tmp.OnTimeQty END
						 END AS OnTimefinal,
						ISNULL(ct.PartOnTimeQtys,0) AS OnTimeQtys,
						ISNULL(ct.OnTimeQtys,0) AS stktotal
					FROM 
					#tmpdata tmp
					LEFT join CTE ct on tmp.PurchaseOrderPartRecordId = ct.PurchaseOrderPartRecordId
				)

				select 
					@POPartTotalQty = ISNULL(SUM(total),0),
					@POOnTimeQty = ISNULL(SUM(OnTimefinal) + SUM(stktotal) ,0)
				from CTE1;

			
			SET @OnTimeAverage = ISNULL((SELECT (NULLIF(ISNULL(@POOnTimeQty,0),0) / NULLIF(ISNULL(@POPartTotalQty,0),0)) * 100),0)

			--Get status & rating
			SELECT @RatingId = [VendorScoreCardSettingsId] 
				FROM [DBO].[VendorScoreCardSettings] WITH(NOLOCK)
			WHERE @OnTimeAverage BETWEEN 
				  CAST(PARSENAME(REPLACE([OnTimeDelivery], '-', '.'), 2) AS INT) 
				  AND 
				  CAST(PARSENAME(REPLACE([OnTimeDelivery], '-', '.'), 1) AS INT);

			/*================Vendor Details =================*/
					SELECT 
						V.VendorId,
						V.VendorName,
						V.VendorCode,
						V.VendorEmail,
						V.VendorPhone,
						V.CreatedDate,
						AD.Line1,
						AD.Line2,
						@POPartTotalQty AS POTotal,
						@ROPartSum AS ROTotal,
						@POOnTimeQty AS StockTotal,
						@OnTimeAverage AS TotalAverage,
						--CASE WHEN @OnTimeAverage > 0 THEN @RatingId ELSE 0 END AS RatingId,
						--CASE WHEN @OnTimeAverage > 0 THEN @StatusId ELSE 0 END AS StatusId
						@RatingId AS RatingId,
						@RatingId AS StatusId
					FROM [DBO].[Vendor] V WITH(NOLOCK)
					INNER JOIN [DBO].[Address] AD WITH(NOLOCK) on V.AddressId = AD.AddressId
					where VendorId = @VendorId

			/*================END Vendor Details =================*/

			

			/*====================Top 10 PO 2 Year Prior=============================*/
					IF OBJECT_ID(N'tempdb..#tmpTop202YearPOPart') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop202YearPOPart
					END

					CREATE TABLE #tmpTop202YearPOPart (
						ID BIGINT NOT NULL IDENTITY,
						PartNumber VARCHAR(100)  NULL,
						TotalSalesCount INT
					)

					;WITH tmpTop202YearSalesOrderPOPart as (
						SELECT
							POP.partnumber,
							POP.ItemMasterId,
							COUNT(POP.QuantityOrdered) AS TotalSalesCount
						FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
						INNER JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.[PurchaseOrderId] = PO.[PurchaseOrderId]
						WHERE  PO.VendorId = @VendorId
						AND CAST(POP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND DATEADD(YEAR, -2, convert(DATE, GETDATE(), 112))
						GROUP BY
							POP.partnumber, 
							POP.ItemMasterId
					)
					INSERT INTO #tmpTop202YearPOPart (PartNumber, TotalSalesCount)
					SELECT
						partnumber,         
						TotalSalesCount 
					FROM tmpTop202YearSalesOrderPOPart
					ORDER BY TotalSalesCount DESC
					OFFSET 0 ROWS
					FETCH FIRST 10 ROWS ONLY;

					select * from #tmpTop202YearPOPart;
			/*==================END Top 10 PO 2 Year Prior==============================*/

			/*============ Top 10 RO 2 Year Prior====================*/

				    IF OBJECT_ID(N'tempdb..#tmpTop202YearPart') IS NOT NULL
				    BEGIN
				    	DROP TABLE #tmpTop202YearPart
				    END
				    
				    CREATE TABLE #tmpTop202YearPart (
				    	ID BIGINT NOT NULL IDENTITY,
				    	PartNumber VARCHAR(100)  NULL,
				    	TotalSalesCount INT
				    )
				    
				    ;WITH tmpTop202YearSalesOrderPart as (
				    	SELECT
				    		ROP.partnumber,
				    		ROP.ItemMasterId,
				    		COUNT(ROP.QuantityOrdered) AS TotalSalesCount
				    	FROM DBO.RepairOrderPart ROP WITH (NOLOCK)
				    	INNER JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.[RepairOrderId] = RO.[RepairOrderId]
				    	WHERE  RO.VendorId = @VendorId
				    	AND CAST(ROP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND DATEADD(YEAR, -2, convert(DATE, GETDATE(), 112))
				    	GROUP BY
				    		ROP.partnumber, 
				    		ROP.ItemMasterId
				    )
				    INSERT INTO #tmpTop202YearPart (PartNumber, TotalSalesCount)
				    SELECT
				    	partnumber,         
				    	TotalSalesCount 
				    FROM tmpTop202YearSalesOrderPart
				    ORDER BY TotalSalesCount DESC
				    OFFSET 0 ROWS
				    FETCH FIRST 10 ROWS ONLY;
				    
				    select * from #tmpTop202YearPart;				    
				    
			/*===================End Top 10 RO 2 Year Prior===========================*/					
			

			/*====================Top 10 PO 1 Year Prior=============================*/
					IF OBJECT_ID(N'tempdb..#tmpTop201YearPOPart') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop201YearPOPart
					END

					CREATE TABLE #tmpTop201YearPOPart (
						ID BIGINT NOT NULL IDENTITY,
						PartNumber VARCHAR(100)  NULL,
						TotalSalesCount INT
					)

					;WITH tmpTop201YearSalesOrderPOPart as (
						SELECT
							POP.partnumber,
							POP.ItemMasterId,
							COUNT(POP.QuantityOrdered) AS TotalSalesCount
						FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
						INNER JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.[PurchaseOrderId] = PO.[PurchaseOrderId]
						WHERE  PO.VendorId = @VendorId
						AND CAST(POP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -1, GETUTCDATE())), 0) AND DATEADD(YEAR, -1, convert(DATE, GETDATE(), 112))
						GROUP BY
							POP.partnumber, 
							POP.ItemMasterId
					)
					INSERT INTO #tmpTop201YearPOPart (PartNumber, TotalSalesCount)
					SELECT
						partnumber,         
						TotalSalesCount 
					FROM tmpTop201YearSalesOrderPOPart
					ORDER BY TotalSalesCount DESC
					OFFSET 0 ROWS
					FETCH FIRST 10 ROWS ONLY;

					select * from #tmpTop201YearPOPart;
			/*==================END Top 10 PO 1 Year Prior==============================*/

			/*================== Top 10 RO 1 Year Prior===========================*/

					IF OBJECT_ID(N'tempdb..#tmpTop201YearPart') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop201YearPart
					END

					CREATE TABLE #tmpTop201YearPart (
						ID BIGINT NOT NULL IDENTITY,
						PartNumber VARCHAR(100)  NULL,
						TotalSalesCount INT
					)

					;WITH tmpTop201YearSalesOrderPart as (
						SELECT
							ROP.partnumber,
							ROP.ItemMasterId,
							COUNT(ROP.QuantityOrdered) AS TotalSalesCount
						FROM DBO.RepairOrderPart ROP WITH (NOLOCK)
						INNER JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.[RepairOrderId] = RO.[RepairOrderId]
						WHERE  RO.VendorId = @VendorId
						AND CAST(ROP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -1, GETUTCDATE())), 0) AND DATEADD(YEAR, -1, convert(DATE, GETDATE(), 112))
						GROUP BY
							ROP.partnumber, 
							ROP.ItemMasterId
					)
					INSERT INTO #tmpTop201YearPart (PartNumber, TotalSalesCount)
					SELECT
						partnumber,         
						TotalSalesCount 
					FROM tmpTop201YearSalesOrderPart
					ORDER BY TotalSalesCount DESC
					OFFSET 0 ROWS
					FETCH FIRST 10 ROWS ONLY;

					select * from #tmpTop201YearPart;
					
			/*===================End Top 10 RO 1 Year Prior===========================*/
					
			

			/*====================Top 10 PO Currunt Year Prior=============================*/
					IF OBJECT_ID(N'tempdb..#tmpTop20YearPOPart') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop20YearPOPart
					END

					CREATE TABLE #tmpTop20YearPOPart (
						ID BIGINT NOT NULL IDENTITY,
						PartNumber VARCHAR(100)  NULL,
						TotalSalesCount INT
					)

					;WITH tmpTop20YearSalesOrderPOPart as (
						SELECT
							POP.partnumber,
							POP.ItemMasterId,
							COUNT(POP.QuantityOrdered) AS TotalSalesCount
						FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
						INNER JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.[PurchaseOrderId] = PO.[PurchaseOrderId]
						WHERE  PO.VendorId = @VendorId
						AND CAST(POP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, 0, GETUTCDATE())), 0) AND CAST(GETUTCDATE() AS DATE)
						GROUP BY
							POP.partnumber, 
							POP.ItemMasterId
					)
					INSERT INTO #tmpTop20YearPOPart (PartNumber, TotalSalesCount)
					SELECT
						partnumber,         
						TotalSalesCount 
					FROM tmpTop20YearSalesOrderPOPart
					ORDER BY TotalSalesCount DESC
					OFFSET 0 ROWS
					FETCH FIRST 10 ROWS ONLY;

					select * from #tmpTop20YearPOPart;
			/*==================END Top 10 PO Currunt Year Prior==============================*/

			/*============ Top 10 RO Currunt Year Prior====================*/

					IF OBJECT_ID(N'tempdb..#tmpTop20YearPart') IS NOT NULL
					BEGIN
						DROP TABLE #tmpTop20YearPart
					END

					CREATE TABLE #tmpTop20YearPart (
						ID BIGINT NOT NULL IDENTITY,
						PartNumber VARCHAR(100)  NULL,
						TotalSalesCount INT
					)

					;WITH tmpTop20YearSalesOrderPart as (
						SELECT
							ROP.partnumber,
							ROP.ItemMasterId,
							COUNT(ROP.QuantityOrdered) AS TotalSalesCount
						FROM DBO.RepairOrderPart ROP WITH (NOLOCK)
						INNER JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.[RepairOrderId] = RO.[RepairOrderId]
						WHERE  RO.VendorId = @VendorId
						AND CAST(ROP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, 0, GETUTCDATE())), 0) AND CAST(GETUTCDATE() AS DATE)
						GROUP BY
							ROP.partnumber, 
							ROP.ItemMasterId
					)
					INSERT INTO #tmpTop20YearPart (PartNumber, TotalSalesCount)
					SELECT
						partnumber,         
						TotalSalesCount 
					FROM tmpTop20YearSalesOrderPart
					ORDER BY TotalSalesCount DESC
					OFFSET 0 ROWS
					FETCH FIRST 10 ROWS ONLY;

					select * from #tmpTop20YearPart;					
			/*===================End Top 10 RO Currunt Year Prior===========================*/

			/*==================Yearly No of order & Spend==============================*/
				DECLARE @ROTotalOrder2Year BIGINT = 0,
						@ROTotalSpend2Year BIGINT = 0,
						@POTotalOrder2Year BIGINT = 0,
						@POTotalSpend2Year BIGINT = 0,
						@ROPOTotalOrder2Year BIGINT = 0,
						@ROPOTotalSpend2Year BIGINT = 0,
						
						@ROTotalOrder1Year BIGINT = 0,
						@ROTotalSpend1Year BIGINT = 0,
						@POTotalOrder1Year BIGINT = 0,
						@POTotalSpend1Year BIGINT = 0,
						@ROPOTotalOrder1Year BIGINT = 0,
						@ROPOTotalSpend1Year BIGINT = 0,

						@ROTotalOrderYear BIGINT = 0,
						@ROTotalSpendYear BIGINT = 0,
						@POTotalOrderYear BIGINT = 0,
						@POTotalSpendYear BIGINT = 0,
						@ROPOTotalOrderYear BIGINT = 0,
						@ROPOTotalSpendYear BIGINT = 0;
				/*----RO 2 Year----*/
					SELECT @ROTotalSpend2Year = ISNULL(SUM(ROP.ExtendedCost),0), @ROTotalOrder2Year = COUNT(RO.[RepairOrderId])
				    FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
				    INNER JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.[RepairOrderId] = RO.[RepairOrderId]
				    WHERE RO.VendorId = @VendorId
				    AND CAST(ROP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND DATEADD(YEAR, -2, convert(DATE, GETDATE(), 112))
					
				/*----PO 2 Year----*/
					SELECT @POTotalSpend2Year = ISNULL(SUM(POP.ExtendedCost),0), @POTotalOrder2Year = COUNT(PO.[PurchaseOrderId])
				    FROM [DBO].[PurchaseOrderPart] POP WITH(NOLOCK)
				    INNER JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.[PurchaseOrderId] = PO.[PurchaseOrderId]
				    WHERE PO.VendorId = @VendorId
				    AND CAST(POP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -2, GETUTCDATE())), 0) AND DATEADD(YEAR, -2, convert(DATE, GETDATE(), 112))
				
				/*----RO/PO 2 Year SUM----*/
					SET @ROPOTotalOrder2Year = ISNULL(@ROTotalOrder2Year,0) + ISNULL(@POTotalOrder2Year,0);
					SET @ROPOTotalSpend2Year = ISNULL(@ROTotalSpend2Year,0) + ISNULL(@POTotalSpend2Year,0);
					SELECT @ROPOTotalOrder2Year AS TotalOrder,@ROPOTotalSpend2Year AS TotalSpend,2 AS Years

				/*----RO 1 Year----*/
					SELECT @ROTotalSpend1Year = ISNULL(SUM(ROP.ExtendedCost),0),@ROTotalOrder1Year = COUNT(RO.[RepairOrderId])
					FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
					INNER JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.[RepairOrderId] = RO.[RepairOrderId]
					WHERE RO.VendorId = @VendorId
					AND CAST(ROP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -1, GETUTCDATE())), 0) AND DATEADD(YEAR, -1, convert(DATE, GETDATE(), 112))

				/*----PO 1 Year----*/
					SELECT @POTotalSpend1Year = ISNULL(SUM(POP.ExtendedCost),0),@POTotalOrder1Year = COUNT(PO.[PurchaseOrderId]) 
				    FROM [DBO].[PurchaseOrderPart] POP WITH(NOLOCK)
				    INNER JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.[PurchaseOrderId] = PO.[PurchaseOrderId]
				    WHERE PO.VendorId = @VendorId
					AND CAST(POP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, -1, GETUTCDATE())), 0) AND DATEADD(YEAR, -1, convert(DATE, GETDATE(), 112))

				/*----RO/PO 1 Year SUM----*/
					SET @ROPOTotalOrder1Year = ISNULL(@ROTotalOrder1Year,0) + ISNULL(@POTotalOrder1Year,0);
					SET @ROPOTotalSpend1Year = ISNULL(@ROTotalSpend1Year,0) + ISNULL(@POTotalSpend1Year,0);
					SELECT @ROPOTotalOrder1Year AS TotalOrder,@ROPOTotalSpend1Year AS TotalSpend,1 AS Years


				/*----RO Currunt Year----*/
					SELECT @ROTotalSpendYear = ISNULL(SUM(ROP.ExtendedCost),0),@ROTotalOrderYear = COUNT(RO.[RepairOrderId])
					FROM [DBO].[RepairOrderPart] ROP WITH(NOLOCK)
					INNER JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON ROP.[RepairOrderId] = RO.[RepairOrderId]
					WHERE RO.VendorId = @VendorId
					AND CAST(ROP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, 0, GETUTCDATE())), 0) AND CAST(GETUTCDATE() AS DATE);

				/*----PO Currunt Year----*/
					SELECT @POTotalSpendYear = ISNULL(SUM(POP.ExtendedCost),0), @POTotalOrderYear = COUNT(PO.[PurchaseOrderId]) 
				    FROM [DBO].[PurchaseOrderPart] POP WITH(NOLOCK)
				    INNER JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON POP.[PurchaseOrderId] = PO.[PurchaseOrderId]
				    WHERE PO.VendorId = @VendorId
					AND CAST(POP.[CreatedDate] AS DATE) BETWEEN DATEADD(yy, DATEDIFF(yy, 0, DATEADD(yy, 0, GETUTCDATE())), 0) AND CAST(GETUTCDATE() AS DATE);

				/*----RO/PO Currunt Year SUM----*/
					SET @ROPOTotalOrderYear = ISNULL(@ROTotalOrderYear,0) + ISNULL(@POTotalOrderYear,0);
					SET @ROPOTotalSpendYear = ISNULL(@ROTotalSpendYear,0) + ISNULL(@POTotalSpendYear,0);
					SELECT @ROPOTotalOrderYear AS TotalOrder,@ROPOTotalSpendYear AS TotalSpend,0 AS Years
			/*==================END Yearly No of order & Spend==============================*/


		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetVendorScorcardInfo' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END