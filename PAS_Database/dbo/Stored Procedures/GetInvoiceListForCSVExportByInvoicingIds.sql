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

** EXEC [dbo].[GetInvoiceListForCSVExportByInvoicingIds] 15,'3294,3295,3291,3297'
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
					 
					Select 
					   WOBI.InvoiceNo,
					   Wo.CustomerName Customer,
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
					   ELSE (CAST(WOBI.InvoiceDate AS DATE)) END InvoiceDate,
					   DATEADD(DAY, WO.NetDays, (CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
					   ELSE (CAST(WOBI.InvoiceDate AS DATE)) END)) AS DueDate,
					   WO.CreditTerms as Terms,
					   '' as [Location],
					   WO.Notes as Memo,
					   WOP.RevisedPartNumber as Item,
					   WOP.RevisedPartDescription as ItemDescription,
					   ISNULL(WOP.Quantity,0) as ItemQuantity,
					   ISNULL(WOBII.GrandTotal,0) as ItemRate,
					   (ISNULL(WOP.Quantity,0) * ISNULL(WOBII.GrandTotal,0)) as ItemAmount,
					   GETDATE() as ServiceDate,
					    WOBI.InvoiceStatus 
					FROM dbo.WorkOrderBillingInvoicing WOBI WITH(NOLOCK) 
						 INNER JOIN  dbo.WorkOrderBillingInvoicingItem WOBII WITH(NOLOCK) ON WOBI.BillingInvoicingId = WOBII.BillingInvoicingId
						 INNER JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
						 INNER JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId AND WOBII.ItemMasterId = WOP.ItemMasterId
					WHERE 
						WOBI.MasterCompanyId=@MasterCompanyId AND
						(@IsSelectAllInvoice = 1 AND 
							WOBI.IsVersionIncrease=0 AND
							(@FromDate IS NULL OR CAST(WOBI.InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND 
							(@ToDate IS NULL OR CAST(WOBI.InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
							(IsNull(@Status,'') ='' OR WOBI.InvoiceStatus like '%' + @Status+'%') 
							AND
							( (@ViewType ='invoice'AND ISNULL(WOBI.[IsInvoicePosted], 0) != 1 AND ISNULL(WOBI.RemainingAmount,0) > 0
								AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      
								AND (ISNULL(@IsUpdated,0) <> 1 OR (ISNULL(WOBI.IsUpdated,0) = ISNULL(@IsUpdated,0) AND ISNULL(WOBI.IsPerformaInvoice,0) = 0)))
							 OR
							 ( (@ViewType !='invoice' AND ISNULL(WOBI.[IsInvoicePosted], 0) != 1 AND ISNULL(WOBI.RemainingAmount,0) > 0
							AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      )
							) )
						  ) 
						OR 
						(@IsSelectAllInvoice = 0 AND WOBI.BillingInvoicingId IN (SELECT TRY_CAST(value AS BIGINT) FROM STRING_SPLIT(@InvoicingIds, ',')))
					
				
				
			END /******************* END: WORK ORDER MODULE *******************/
			ELSE IF(@ModuleId = @soModuleId) /******************* START: SALES ORDER MODULE *******************/
			BEGIN	
				PRINT 'Sales Order'
				--Select 
				--	   SOBI.InvoiceNo,
				--	   SO.CustomerName Customer,
				--	   SOBI.InvoiceDate,
				--	   DATEADD(DAY, SO.NetDays, SOBI.InvoiceDate) AS DueDate,
				--	   SO.CreditTerms as Terms,
				--	   '' as [Location],
				--	   SO.Notes as Memo,
				--	   SOP.RevisedPartNumber as Item,
				--	   SOP.RevisedPartDescription as ItemDescription,
				--	   ISNULL(SOP.Quantity,0) as ItemQuantity,
				--	   ISNULL(WOBII.GrandTotal,0) as ItemRate,
				--	   (ISNULL(SOP.Quantity,0) * ISNULL(WOBII.GrandTotal,0)) as ItemAmount,
				--	   GETDATE() as ServiceDate
				--	FROM dbo.SalesOrderBillingInvoicing SOBI WITH(NOLOCK) 
				--		 INNER JOIN  dbo.SalesOrderBillingInvoicingItem WOBII WITH(NOLOCK) ON SOBI.SOBillingInvoicingId = WOBII.SOBillingInvoicingId
				--		 INNER JOIN dbo.SalesOrder SO WITH(NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
				--		 INNER JOIN dbo.SalesOrderPartV1 SOP WITH(NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId AND WOBII.ItemMasterId = SOP.ItemMasterId
				--	WHERE SOBI.SOBillingInvoicingId IN( SELECT TRY_CAST(value AS BIGINT) FROM STRING_SPLIT(@InvoicingIds, ','))
			END  /******************* END: SALES ORDER MODULE *******************/
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