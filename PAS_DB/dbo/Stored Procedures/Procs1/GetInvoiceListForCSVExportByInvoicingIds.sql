/*************************************************************           
 ** File:   [dbo].[GetInvoiceListForCSVExportByInvoicingIds]          
 ** Author:   RAJESH GAMI
 ** Description: Get Invoice List By Invoicing Ids.
 ** Date:   7 May 2025   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    7 May 2025   RAJESH GAMI	CREATED
	2   13 May 2025   RAJESH GAMI	Implemented SO and Exchange 
	3   15 May 2025   RAJESH GAMI	Added Taxable Column
	4   19 May 2025   RAJESH GAMI	Remove remaining amount condition
	5   28 May 2025   RAJESH GAMI   Corrected InvoiceAmount
	6	13 Jun 2025	  RAJESH GAMI	Change the new billing invoicing table with old one (WO, SO)
	8	04 Jul 2025   RAJESH GAMI   Fixed: Select All Not Working for WO
	9	09/July/2026 RAJESH GAMI   [PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
** EXEC [dbo].[GetInvoiceListForCSVExportByInvoicingIds] 15,'3659',1,NULL,NULL,180,20,'',''
**************************************************************/ 
CREATE       PROCEDURE [dbo].[GetInvoiceListForCSVExportByInvoicingIds]
	@ModuleId INT,
	@InvoicingIds NVARCHAR(MAX),
	@IsSelectAllInvoice BIT = 0,
	@FromDate datetime=null,
	@ToDate datetime=null,
	@EmployeeId bigint,
	@MasterCompanyId int,
	@ViewType varchar(10),
	@Status varchar(50)=null
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
	BEGIN TRY
			DECLARE @woModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrder')
			DECLARE @soModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
			DECLARE @exchModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder')
			DECLARE @WOInvoiceTypeId INT, @IsUpdated BIT = 0;
			DECLARE @SOInvoiceTypeId INT;
			DECLARE @EXInvoiceTypeId INT;
			DECLARE @CMPostedStatusId INT;
			DECLARE @ClosedCreditMemoStatus INT;
			DECLARE @RefundedCreditMemoStatus INT;
			DECLARE @RefundRequestedCreditMemoStatus INT;
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		  SELECT @WOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='WorkOrder';
		  SELECT @SOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='SalesOrder';
		  SELECT @EXInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='Exchange';
		  SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED';  	  
		  SELECT @ClosedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'CLOSED';
		  SELECT @RefundedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'REFUNDED';  
		  SELECT @RefundRequestedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'REFUND REQUESTED';  
			SELECT 
				@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId 
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId; 


			IF(@ModuleId = @woModuleId) /******************* START: WORK ORDER MODULE *******************/
			BEGIN
					 
					Select DISTINCT
					   WOBI.InvoiceNo,
					   Wo.CustomerName Customer,
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
					   ELSE (CAST(WOBI.InvoiceDate AS DATE)) END InvoiceDate,
					   DATEADD(DAY, ISNULL(WO.NetDays,0), (CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
					   ELSE (CAST(WOBI.InvoiceDate AS DATE)) END)) AS DueDate,
					   WO.CreditTerms as Terms,
					   '' as [Location],
					   REPLACE(REPLACE(ISNULL( WO.Memo,''), '<p>', ''),'</p>','') as Memo,
					   WOP.RevisedPartNumber as Item,
					   WOP.RevisedPartDescription as ItemDescription,
					   ISNULL(WOP.Quantity,0) as ItemQuantity,
					   --CASE WHEN WOBI.CostPlusType = 'Flat Rate' THEN ISNULL(WOBII.UnitPrice,0) ELSE ISNULL(WOBII.GrandTotal,0) END AS ItemRate,
					   --CASE WHEN WOBI.CostPlusType = 'Flat Rate' THEN ISNULL(WOBII.UnitPrice,0) ELSE ISNULL(WOBII.GrandTotal,0) END AS ItemAmount,
						--CASE WHEN WOBI.CostPlusType = 'Flat Rate' AND ISNULL(WOBII.GrandTotal,0) > 0 THEN ISNULL(WOBII.GrandTotal,0) ELSE CASE WHEN ISNULL(WOBII.GrandTotal,0) > 0 THEN ISNULL(WOBII.GrandTotal,0) WHEN ISNULL(WOBII.SubTotal,0) > 0 THEN ISNULL(WOBII.SubTotal,0) ELSE ISNULL(WOBII.UnitPrice,0) END END ItemRate,
						--CASE WHEN WOBI.CostPlusType = 'Flat Rate' AND ISNULL(WOBII.GrandTotal,0) > 0 THEN ISNULL(WOBII.GrandTotal,0) ELSE CASE WHEN ISNULL(WOBII.GrandTotal,0) > 0 THEN ISNULL(WOBII.GrandTotal,0) WHEN ISNULL(WOBII.SubTotal,0) > 0 THEN ISNULL(WOBII.SubTotal,0) ELSE ISNULL(WOBII.UnitPrice,0) END END ItemAmount,
					   ISNULL(WOBII.GrandTotal,0)ItemRate,
					   ISNULL(WOBII.GrandTotal,0)ItemAmount,
					   GETDATE() as ServiceDate,
					    WOBI.InvoiceStatus,
						WOBII.BillingInvoicingItemId,
						'N' as Taxable
					FROM dbo.BillingInvoicing WOBI WITH(NOLOCK) 
						 INNER JOIN  dbo.BillingInvoicingItems WOBII WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId
						 INNER JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOBI.ReferenceId = WO.WorkOrderId
						 INNER JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId AND WOBII.ItemMasterId = WOP.RevisedItemmasterid
					WHERE 
						WOBI.MasterCompanyId=@MasterCompanyId AND WOBI.ModuleId = @woModuleId 		AND ISNULL(WOBI.[IsStandardInvoicePosted], 0) != 1 AND 
						((@IsSelectAllInvoice = 1 AND 
							WOBI.IsVersionIncrease=0 AND
							(@FromDate IS NULL OR CAST(WOBI.InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND 
							(@ToDate IS NULL OR CAST(WOBI.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
							(IsNull(@Status,'') ='' OR WOBI.InvoiceStatus like '%' + @Status+'%') 
							AND
							( (@ViewType ='invoice' 
								AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      
								AND (ISNULL(@IsUpdated,0) <> 1 OR (ISNULL(WOBI.IsUpdated,0) = ISNULL(@IsUpdated,0) AND ISNULL(WOBI.IsPerformaInvoice,0) = 0)))
							 OR
							 ( (@ViewType !='invoice'
							AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      )
							) )
						  ) 
						OR 
						(@IsSelectAllInvoice = 0 AND WOBI.BillingInvoicingId IN (SELECT TRY_CAST(value AS BIGINT) FROM STRING_SPLIT(@InvoicingIds, ','))))
					
				
				
			END /******************* END: WORK ORDER MODULE *******************/
			ELSE IF(@ModuleId = @soModuleId) /******************* START: SALES ORDER MODULE *******************/
			BEGIN	
				Select DISTINCT 
					   SOBI.InvoiceNo,
					   SO.CustomerName Customer,
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					    	CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATE)) END InvoiceDate,
					   DATEADD(DAY, ISNULL(SO.NetDays,0), (CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATE)) END)) AS DueDate,
					   SO.CreditTermName as Terms,
					   '' as [Location],
					  REPLACE(REPLACE(ISNULL( SOP.Notes,''), '<p>', ''),'</p>','') as Memo,
					   SOP.PartNumber as Item,
					   SOP.PartDescription as ItemDescription,
					   ISNULL(SOBII.QtyBilled,0) as ItemQuantity,
					   (CASE WHEN ISNULL(SOBII.QtyBilled,0) > 0 THEN (CONVERT(DECIMAL(10,2),ISNULL(SOBII.GrandTotal,0)/ ISNULL(SOBII.QtyBilled,0))) ELSE  ISNULL(SOBII.GrandTotal,0) END) as ItemRate,
					   (ISNULL(SOBII.GrandTotal,0)) as ItemAmount,
					   GETDATE() as ServiceDate,
					   SOBII.BillingInvoicingItemId,
					   'N' as Taxable
					FROM dbo.BillingInvoicing SOBI WITH(NOLOCK) 
						 INNER JOIN  dbo.BillingInvoicingItems SOBII WITH(NOLOCK) ON SOBI.BillingInvoicingId = SOBII.BillingInvoicingId
						 INNER JOIN dbo.SalesOrder SO WITH(NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
						 INNER JOIN dbo.SalesOrderPartV1 SOP WITH(NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId AND SOBII.ItemMasterId = SOP.ItemMasterId
						 INNER JOIN dbo.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOP.SalesOrderPartId
						 INNER JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPS.StockLineId
					WHERE  SOBI.MasterCompanyId=@MasterCompanyId AND SOBI.ModuleId = @soModuleId AND ISNULL(SOBI.[IsStandardInvoicePosted], 0) != 1 
						AND
							((@IsSelectAllInvoice = 1 AND SOBI.IsVersionIncrease=0 --AND ISNULL(SOBI.[IsBilling], 0) != 1 
							AND	(@FromDate IS NULL OR CAST(SOBI.InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND 
							(@ToDate IS NULL OR CAST(SOBI.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
							(IsNull(@Status,'') ='' OR SOBI.InvoiceStatus like '%' + @Status+'%') 
							AND
							( (@ViewType ='invoice'
								AND SOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @SOInvoiceTypeId)
								AND (ISNULL(@IsUpdated,0) <> 1 OR (ISNULL(SOBI.IsUpdated,0) = ISNULL(@IsUpdated,0) AND ISNULL(SOBI.IsPerformaInvoice,0) = 0)) )
							 OR
							 ( (@ViewType !='invoice'
								AND SOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @SOInvoiceTypeId))
							) )
						  ) 
						OR 
						(@IsSelectAllInvoice = 0 AND SOBI.BillingInvoicingId IN( SELECT TRY_CAST(value AS BIGINT) FROM STRING_SPLIT(@InvoicingIds, ',')))) AND ISNULL(ST.IsNonStock,0) = 0
					--GROUP BY 
					--SOBI.InvoiceNo,
					--SO.CustomerName,
					--CASE 
					--    WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					--        CASE 
					--            WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) 
					--                THEN NULL 
					--                ELSE CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE) 
					--        END 
					--    ELSE CAST(SOBI.InvoiceDate AS DATE) 
					--END,
					--DATEADD(
					--    DAY, 
					--    ISNULL(SO.NetDays, 0), 
					--    CASE 
					--        WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					--            CASE 
					--                WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) 
					--                    THEN NULL 
					--                    ELSE CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE) 
					--            END 
					--        ELSE CAST(SOBI.InvoiceDate AS DATE) 
					--    END
					--),
					--SO.CreditTermName,
					--SOP.Notes,
					--SOP.PartNumber,
					--SOP.PartDescription,
					--ISNULL(SOBII.NoofPieces, 0),
					--CONVERT(DECIMAL(10, 2), ISNULL(SOBII.GrandTotal, 0) / ISNULL(SOBII.NoofPieces, 0)),
					--ISNULL(SOBII.GrandTotal, 0),
					--SOPS.StockLineId

			END  /******************* END: SALES ORDER MODULE *******************/

			ELSE IF(@ModuleId = @exchModuleId) /******************* START: EXCHANGE MODULE *******************/
			BEGIN	
				Select  
					   ESOBI.InvoiceNo,
					   ESO.CustomerName Customer,
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					    	CASE WHEN CAST(ESOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ESOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
					   ELSE (CAST(ESOBI.InvoiceDate AS DATE)) END InvoiceDate,
					   DATEADD(DAY, ISNULL(ESO.NetDays,0), (CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(ESOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ESOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
					   ELSE (CAST(ESOBI.InvoiceDate AS DATE)) END)) AS DueDate,
					   ESO.CreditTermName as Terms,
					   '' as [Location],
					   REPLACE(REPLACE(ISNULL( ESOP.Notes,''), '<p>', ''),'</p>','') as Memo,
					   ESOP.PartNumber as Item,
					   ESOP.PartDescription as ItemDescription,
					   1 as ItemQuantity,
					   SUM(ISNULL(ESOBII.GrandTotal,0)) as ItemRate,
					   SUM((ISNULL(ESOBII.GrandTotal,0))) as ItemAmount,
					   GETDATE() as ServiceDate,
					   'N' as Taxable
					FROM dbo.ExchangeSalesOrderBillingInvoicing ESOBI WITH(NOLOCK) 
						 INNER JOIN  dbo.ExchangeSalesOrderBillingInvoicingItem ESOBII WITH(NOLOCK) ON ESOBI.SOBillingInvoicingId = ESOBII.SOBillingInvoicingId
						 INNER JOIN dbo.ExchangeSalesOrder ESO WITH(NOLOCK) ON ESOBI.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId
						 INNER JOIN dbo.ExchangeSalesOrderPart ESOP WITH(NOLOCK) ON ESO.ExchangeSalesOrderId = ESOP.ExchangeSalesOrderId AND ESOBII.ItemMasterId = ESOP.ItemMasterId
					WHERE  ESOBI.MasterCompanyId=@MasterCompanyId  
						AND
							((@IsSelectAllInvoice = 1 AND ISNULL(ESOBII.[IsDeleted],0) = 0 AND ISNULL(ESOBI.[GrandTotal],0) > 0	 AND
							(@FromDate IS NULL OR CAST(ESOBI.InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND 
							(@ToDate IS NULL OR CAST(ESOBI.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
							(IsNull(@Status,'') ='' OR ESOBI.InvoiceStatus like '%' + @Status+'%') 
							AND
							( (@ViewType ='invoice'
								AND ESOBI.[SOBillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @EXInvoiceTypeId)
								AND (ISNULL(@IsUpdated,0) <> 1 OR (ISNULL(ESOBI.IsUpdated,0) = ISNULL(@IsUpdated,0) )) )
							 OR
							 ( (@ViewType !='invoice'
								AND ESOBI.[SOBillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @EXInvoiceTypeId)
							) ))
						  ) 
						OR 
						(@IsSelectAllInvoice = 0 AND ESOBI.SOBillingInvoicingId IN( SELECT TRY_CAST(value AS BIGINT) FROM STRING_SPLIT(@InvoicingIds, ','))))

						GROUP BY ESOBI.InvoiceNo, ESO.CustomerName,ESOBI.InvoiceDate,ISNULL(ESO.NetDays,0),ESO.CreditTermName,ESOP.Notes,ESOP.PartNumber,
						ESOP.PartDescription

			END  /******************* END: EXCHANGE MODULE *******************/
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'GetInvoiceListForCSVExportByInvoicingIds' 
			, @ProcedureParameters VARCHAR(3000)  = '@ModuleId = '''+ ISNULL(@ModuleId, '') + ''
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