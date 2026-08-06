/*************************************************************           
 ** File:   [USP_SearchCustomerInvoicesQBExtract]           
 ** Author:  RAJESH GAMI
 ** Description: Search CustomerInvoices QuickBook Extract : Copied from USP_SearchCustomerInvoices for Extract the Quickbook
 ** Purpose:         
 ** Date: 19 May 2025         
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date           Author			Change Description            
 ** --   --------       -------			--------------------------------          
    1	 19 May 2025	RAJESH GAMI	   	Created
    2	 21 May 2025	RAJESH GAMI	   	Resolve the flat rate related issue
	3	 06 Jun 2025	RAJESH GAMI	   	Correct the rowNum issue (Due to duplicate the record)
	4	 13 Jun 2025	RAJESH GAMI	   	Replcae the new billing invoicing table with old one (WO, SO)
    5    17 Jun 2025    Moin Bloch       Added CustomerId
	6    26 Jun 2025   RAJESH GAMI       Resovled duplicate WO Invoice while Invoice VIEW filter selection due to WorkFlowWorkORderId
	7	 04 Jul 2025   RAJESH GAMI       Added IsStandardInvoicePosted In the Billing Invoicing
	8	 12 SEP 2025   RAJESH GAMI       DROP Temp table
	9	 06 May 2026   RAJESH GAMI       UOM Conversion Changes [PN-16330]
	1    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	2    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	3    20/July/2026			 RAJESH GAMI						[PN-17350] - Removed IsNonStock=0 filter(s) from SO and Exchange-SO branches so Non-Stock parts appear in QuickBooks invoice extract (WorkOrder branch untouched).
**************************************************************/ 
CREATE      PROCEDURE [dbo].[USP_SearchCustomerInvoicesQBExtract]
@PageSize int,  
@PageNumber int,  
@SortColumn varchar(50),  
@SortOrder int,  
@StatusID int,  
@GlobalFilter varchar(50),
@InvoiceNo	varchar(50),
@InvoiceStatus varchar(50),
@InvoiceDate datetime=null,
@OrderNumber varchar(50),
@CustomerName varchar(50),
@CustomerType varchar(50),
@InvoiceAmt decimal=null,
@PN		varchar(50),
@PNDescription varchar(50),
@VersionNo varchar(50),
@QuoteNumber	varchar(50),
@CustomerReference varchar(50),
@MasterCompanyId int,
@SerialNumber varchar(50),
@StockType varchar(50),
@ViewType varchar(10),
@EmployeeId bigint=1,
@RemainingAmount decimal=null,
@AmountPaid decimal=null,
@LastMSLevel varchar(50)=null,
@Status varchar(50)=null,
@IsUpdated BIT = NULL,
@FromDate datetime=null,
@ToDate datetime=null
AS
BEGIN

  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY

	  DECLARE @RecordFrom INT; 
	  DECLARE @ModuleID VARCHAR(500) = (SELECT ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) Where ModuleName = 'WorkOrderMPN')
	  DECLARE @SOModuleID VARCHAR(500) = (SELECT ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) Where ModuleName = 'SalesOrder')
	  DECLARE @ExchSOModuleID VARCHAR(500) = (SELECT ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) Where ModuleName = 'ExchangeSOHeader')
	  DECLARE @IsActive BIT = 1  
	  DECLARE @Count INT, @InvoiceTotalAmount [decimal](18, 6);  
	  SET @RecordFrom = (@PageNumber - 1) * @PageSize;

	  DECLARE @WOInvoiceTypeId INT;
	  DECLARE @SOInvoiceTypeId INT;
	  DECLARE @EXInvoiceTypeId INT;
	  DECLARE @CMPostedStatusId INT;
	  DECLARE @ClosedCreditMemoStatus INT;
	  DECLARE @RefundedCreditMemoStatus INT;
	  DECLARE @RefundRequestedCreditMemoStatus INT;
	  DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	  DECLARE @workOrderModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrder')
	  DECLARE @salesOrderModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
	  DECLARE @exchModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder')
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
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

	  SELECT @WOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='WorkOrder';
      SELECT @SOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='SalesOrder';
      SELECT @EXInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='Exchange';
	  SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED';  	  
      SELECT @ClosedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'CLOSED';
	  SELECT @RefundedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'REFUNDED';  
      SELECT @RefundRequestedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'REFUND REQUESTED';  
	  
	  IF @SortColumn IS NULL  
	  BEGIN  
	   SET @SortColumn = UPPER('InvoiceDate')  
	  END   
	  ELSE  
	  BEGIN   
	   SET @SortColumn = UPPER(@SortColumn)  
	  END

	  IF(@ViewType ='invoice')
	  BEGIN
		;WITH Result AS(
			SELECT WOBI.BillingInvoicingId [InvoicingId],
				   WOBI.InvoiceNo [InvoiceNo],
				   WOBI.InvoiceStatus [InvoiceStatus],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			       ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   WO.WorkOrderNum [OrderNumber],
				   C.Name [CustomerName],
				   CT.CustomerTypeName [CustomerType],
				   WOBI.GrandTotal [InvoiceAmt],

				   WQ.QuoteNumber,
				   IsWorkOrder=1,
				   IsExchange=0,
				   WOBI.ReferenceId AS [ReferenceId],
				   C.CustomerId,
				   CASE WHEN CRM.RMAHeaderId >1 then 1 else  0 end isRMACreate,
				   ISNULL(WOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
				   WOPN.ManagementStructureId
				   ,(CASE WHEN COUNT(WOPN.ManagementStructureId) > 1 Then 'Multiple' ELse MAX(M.LastMSLevel) END) AS 'LastMSLevel'
				   ,(CASE WHEN COUNT(WOPN.ManagementStructureId) > 1 Then 'Multiple' ELse MAX(M.AllMSlevels) END) AS 'AllMSlevels'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WQ.VersionNo) END) AS 'VersionNo'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WQ.VersionNo) END) AS 'VersionNoType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WOPN.CustomerReference) END) AS 'CustomerReference'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WOPN.CustomerReference) END) AS 'CustomerReferenceType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumber'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumberType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartNumber) END) AS 'PN'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartNumber) END) AS 'PartNumberType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PNDescription'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PartDescriptionType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
				   	WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
				   	WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
				   	ELSE 'OEM' END) END) AS 'StockType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
				   	WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
				   	WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
				   	ELSE 'OEM' END) END) AS 'StockTypeType',
					@workOrderModuleId as ModuleId,
					WOBI.RemainingAmount
				FROM dbo.BillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId --AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.ReferenceId AND WOPN.ID = WOBII.SubReferenceId
				LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
				LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WOBI.ReferenceId = WO.WorkOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
				LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOPN.ID and WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=WOBI.BillingInvoicingId and CRM.isWorkOrder=1
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ISNULL(ST.IsNonStock,0) = 0
				LEFT JOIN dbo.WorkorderManagementStructureDetails M WITH (NOLOCK) ON M.ReferenceID = WOPN.ID AND M.ModuleID = @ModuleID
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On WOBII.ItemMasterId=I.ItemMasterId  
			 AND ISNULL(I.IsNonStock,0) = 0
			WHERE WOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(WOBI.IsVersionIncrease,0)=0 AND WOBI.ModuleId =@workOrderModuleId
			AND ISNULL(WOBI.[IsStandardInvoicePosted], 0) != 1 
			AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      
			AND (ISNULL(@IsUpdated,0) <> 1 OR (ISNULL(WOBI.IsUpdated,0) = ISNULL(@IsUpdated,0) AND ISNULL(WOBI.IsPerformaInvoice,0) = 0))
			GROUP BY	WOBI.BillingInvoicingId, WOBI.InvoiceNo, WOBI.InvoiceStatus, WOBI.InvoiceDate, WO.WorkOrderNum, C.[Name], CT.CustomerTypeName, WOBI.GrandTotal, WQ.QuoteNumber, WOBI.ReferenceId
						, C.CustomerId, CRM.RMAHeaderId, WOBI.IsPerformaInvoice, WOPN.ManagementStructureId,WOBI.RemainingAmount
			),				
			WorkFlowData AS(  
				SELECT PC.BillingInvoicingId,MAX(WOFN.WorkFlowWorkOrderId)WorkFlowWorkOrderId, PC.ReferenceId
				FROM dbo.BillingInvoicing PC WITH (NOLOCK) 
				INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK)  ON PC.BillingInvoicingId = BII.BillingInvoicingId 
				LEFT JOIN dbo.WorkOrderWorkFlow WOFN WITH (NOLOCK) ON  BII.SubReferenceId = WOFN.WorkOrderPartNoId --WOFN.WorkFlowWorkOrderId = PC.WorkFlowWorkOrderId 
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease = 0 
				--AND ISNULL(PC.[IsInvoicePosted], 0) != 1 
				AND PC.ModuleId = @workOrderModuleId
				GROUP BY PC.ReferenceId,PC.BillingInvoicingId--,WOFN.WorkFlowWorkOrderId
				),
				Results AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,
				M.CustomerReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder,M.IsExchange,
				M.LastMSLevel,M.AllMSlevels, M.ReferenceId,M.CustomerId,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,RemainingAmount
				FROM Result M   
					LEFT JOIN WorkFlowData WOFD  on WOFD.BillingInvoicingId=M.InvoicingId
					GROUP BY 
				M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels	,
				M.CustomerReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder, M.ReferenceId,M.CustomerId,M.IsExchange,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,RemainingAmount)
			,SOResult AS(
				SELECT DISTINCT 
				       SOBI.BillingInvoicingId [InvoicingId],
				       SOBI.InvoiceNo [InvoiceNo],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
					   SO.SalesOrderNumber [OrderNumber],
					   C.Name [CustomerName],
					   CT.CustomerTypeName [CustomerType],
					   SOBI.GrandTotal [InvoiceAmt],
					   SQ.SalesOrderQuoteNumber [QuoteNumber],
					   IsWorkOrder=0,
					   IsExchange=0,
					   SMS.LastMSLevel,
					   SMS.AllMSlevels, 
					   SOBI.ReferenceId AS [ReferenceId],
					   C.CustomerId,0 as WorkFlowWorkOrderId,
					   CASE WHEN CRM.RMAHeaderId > 1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SQ.VersionNumber) END) AS 'VersionNo'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SQ.VersionNumber) END) AS 'VersionNoType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SO.CustomerReference) END) AS 'CustomerReference'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SO.CustomerReference) END) AS 'CustomerReferenceType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumber'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumberType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PN'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PartNumberType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PNDescription'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PartDescriptionType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						 WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
						 WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
						 ELSE 'OEM' END ) END) AS 'StockType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						 WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
						 WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
						 ELSE 'OEM' END ) END) AS 'StockTypeType',
						 @salesOrderModuleId as ModuleId,
						 SOBI.RemainingAmount
			FROM dbo.BillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId =SOBI.BillingInvoicingId --AND ISNULL(SOBI.[IsInvoicePosted], 0) != 1
				LEFT JOIN dbo.SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.ReferenceId
				LEFT JOIN dbo.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOPN.SalesOrderPartId
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPS.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.BillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId  
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(SOBI.IsVersionIncrease,0)=0 
			AND ISNULL(SOBI.[IsStandardInvoicePosted], 0) != 1 
			AND SOBI.ModuleId =@salesOrderModuleId
				AND SOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @SOInvoiceTypeId)
				AND (ISNULL(@IsUpdated,0) <> 1 OR (ISNULL(SOBI.IsUpdated,0) = ISNULL(@IsUpdated,0) AND ISNULL(SOBI.IsPerformaInvoice,0) = 0))
				GROUP BY	SOBI.BillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.SalesOrderNumber, C.[Name], CT.CustomerTypeName, SOBI.GrandTotal,  SQ.SalesOrderQuoteNumber
							, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.ReferenceId, C.CustomerId, CRM.RMAHeaderId, SOBI.IsPerformaInvoice, SMS.EntityMSID,	 SOBI.RemainingAmount 
						),
				SOResults AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,RemainingAmount
				FROM SOResult M   
				GROUP BY 
				M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,RemainingAmount
					),
				ExchSOResult AS(
			SELECT DISTINCT SOBI.SOBillingInvoicingId [InvoicingId],
			       SOBI.InvoiceNo [InvoiceNo],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   --SOBI.InvoiceDate [InvoiceDate],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   SO.ExchangeSalesOrderNumber [OrderNumber],
				   C.Name [CustomerName],
				   CT.CustomerTypeName [CustomerType],
				   SOBI.GrandTotal [InvoiceAmt],
				   '' as [QuoteNumber],
				   SO.CustomerReference as CustomerReference,
				   '' as CustomerReferenceType,
				   IsWorkOrder=0,IsExchange=1,
				   SMS.LastMSLevel,
				   SMS.AllMSlevels, 
				   SOBI.ExchangeSalesOrderId AS [ReferenceId],
				   C.CustomerId,0 as WorkFlowWorkOrderId,
				   1 as isRMACreate,
				   0 AS IsPerformaInvoice,
				   SMS.EntityMSID AS ManagementStructureId
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(SO.VersionNumber) END) AS 'VersionNo'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(SO.VersionNumber) END) AS 'VersionNoType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumber'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumberType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(I.partnumber) END) AS 'PN'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(I.partnumber) END) AS 'PartNumberType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(I.PartDescription) END) AS 'PNDescription'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(I.PartDescription) END) AS 'PartDescriptionType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
					WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
					WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
					ELSE 'OEM' END ) END) AS 'StockType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
					WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
					WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
					ELSE 'OEM' END ) END) AS 'StockTypeType',
					@exchModuleId as ModuleId,
					SOBI.RemainingAmount
			FROM dbo.ExchangeSalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId
				LEFT JOIN dbo.ExchangeSalesOrderPart SOPN WITH (NOLOCK) ON SOPN.ExchangeSalesOrderId =SOBI.ExchangeSalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.ExchangeSalesOrder SO WITH (NOLOCK) ON SOBI.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.ExchangeManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.ExchangeSalesOrderId AND SMS.ModuleID = @ExchSOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId  
			WHERE SOBI.MasterCompanyId=@MasterCompanyId	AND SOBII.IsDeleted=0 AND ISNULL(SOBI.GrandTotal,0) > 0	
			AND SOBI.[SOBillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @EXInvoiceTypeId)
			AND (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(SOBI.IsUpdated,0) = ISNULL(@IsUpdated,0))
			GROUP BY	SOBI.SOBillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.ExchangeSalesOrderNumber, C.[Name], CT.CustomerTypeName, SOBI.GrandTotal, SOBI.RemainingAmount
						, SO.CustomerReference, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.ExchangeSalesOrderId, C.CustomerId, SMS.EntityMSID,I.ItemMasterId
						),
				ExchSOResults AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.PN as [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				'' as QuoteNumber,
				M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,'' as CustomerReferenceType,
				ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,RemainingAmount
				FROM ExchSOResult M 
				GROUP BY 
				M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,RemainingAmount
				)
			   , FinalResult AS(
					SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,RemainingAmount
				FROM Results
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber ,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,RemainingAmount
					UNION ALL 
				SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,RemainingAmount
				FROM SOResults
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,RemainingAmount
					UNION ALL 
				SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,RemainingAmount
				FROM ExchSOResults
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,RemainingAmount
			), ResultCount AS(SELECT COUNT(InvoicingId) AS totalItems FROM FinalResult)  
   SELECT * INTO #TempResult from  FinalResult
   WHERE (  
    (@GlobalFilter <> '' AND (  
      (InvoiceNo like '%' +@GlobalFilter+'%') OR  
      (InvoiceStatus like '%' +@GlobalFilter+'%') OR  
      (InvoiceDate like '%' +@GlobalFilter+'%') OR  
      (OrderNumber like '%' +@GlobalFilter+'%') OR    
      (CustomerName like '%' +@GlobalFilter+'%') OR  
      (CustomerType like '%' +@GlobalFilter+'%') OR
      (PN like '%' +@GlobalFilter+'%') OR  
      (PNDescription like '%' +@GlobalFilter+'%') OR  
      (VersionNo like '%' +@GlobalFilter+'%') OR  
	  (QuoteNumber like '%' +@GlobalFilter+'%') OR  
      (CustomerReference like '%' +@GlobalFilter+'%') OR  
      (SerialNumber like '%' +@GlobalFilter+'%') OR  
      (StockType like '%' +@GlobalFilter+'%')  OR 
	  (LastMSLevel LIKE '%' +@GlobalFilter+'%') 
      ))  
     OR     
     (@GlobalFilter='' AND (IsNull(@InvoiceNo,'') ='' OR InvoiceNo like '%' + @InvoiceNo+'%') AND  
      (IsNull(@InvoiceStatus,'') ='' OR InvoiceStatus like '%' + @InvoiceStatus+'%') AND 
	  (IsNull(@InvoiceDate,'') ='' OR Cast(InvoiceDate as date)=Cast(@InvoiceDate as date)) and 
      (IsNull(@OrderNumber,'') ='' OR OrderNumber like '%' + @OrderNumber+'%') AND  
      (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
      (IsNull(@CustomerType,'') ='' OR CustomerType like '%' + @CustomerType+'%') AND  
      (IsNull(CAST( @InvoiceAmt as varchar),'') ='' OR Cast(InvoiceAmt as varchar) like '%' + CAST(@InvoiceAmt as varchar)+'%') AND  
      (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
      (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
      (IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND 
	  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND
      (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%' + @CustomerReference+'%') AND  
      (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND  
      (IsNull(@StockType,'') ='' OR StockType like '%' + @StockType+'%')  AND
	  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') AND
	  (@FromDate IS NULL OR CAST(InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND
	  (@ToDate IS NULL OR CAST(InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
	  (IsNull(@Status,'') ='' OR InvoiceStatus like '%' + @Status+'%') 
      ))
				   SELECT @Count = COUNT(InvoicingId),@InvoiceTotalAmount = SUM(ISNULL(InvoiceAmt,0)) from #TempResult
  
				   SELECT *, @Count As NumberOfItems ,ISNULL(@InvoiceTotalAmount,0) as InvoiceTotalAmount FROM #TempResult  
				   ORDER BY       
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='orderNumber')  THEN OrderNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PN')  THEN PN END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PNDescription')  THEN PNDescription END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='VersionNo')  THEN VersionNo END ASC, 
				   CASE WHEN (@SortOrder=1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerReference')  THEN CustomerReference END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='StockType')  THEN StockType END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,
  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='orderNumber')  THEN OrderNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerType')  THEN CustomerType END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PN')  THEN PN END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PNDescription')  THEN PNDescription END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='VersionNo')  THEN VersionNo END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerReference')  THEN CustomerReference END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC
  
				   OFFSET @RecordFrom ROWS   
				   FETCH NEXT @PageSize ROWS ONLY; 
				   
				   DROP TABLE #TempResult;
   END
   ELSE
   BEGIN
			;WITH Result AS(
				SELECT DISTINCT WOBI.BillingInvoicingId [InvoicingId],
				1 AS RowNum,
				WOBI.InvoiceNo [InvoiceNo],
				WOBI.InvoiceStatus [InvoiceStatus],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				WO.WorkOrderNum [OrderNumber],
				C.Name [CustomerName],
				C.CustomerId,
				CT.CustomerTypeName [CustomerType],
				ISNULL(WOBII.GrandTotal,0) AS InvoiceAmt,
				--CASE WHEN WOBI.CostPlusType = 'Flat Rate' THEN 
				--CASE WHEN 	ISNULL(WOBII.UnitPrice,0)  > 0 THEN ISNULL(WOBII.UnitPrice,0) ELSE ISNULL(WOBII.GrandTotal,0) END
				--ELSE ISNULL(WOBII.GrandTotal,0) END AS InvoiceAmt,
				IM.partnumber [PN], 
				IM.PartDescription [PNDescription],
				WQ.VersionNo [VersionNo],
				WQ.QuoteNumber,
				WOPN.CustomerReference [CustomerReference],
				ST.SerialNumber [SerialNumber],
				ST.stocklineid,				
				CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
					 WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
					 WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
					 ELSE 'OEM' END AS StockType,
					 IsWorkOrder=1,IsExchange=0,
					 MSD.LastMSLevel,
					 MSD.AllMSlevels,
					 WOBI.ReferenceId AS [ReferenceId],WOWF.WorkFlowWorkOrderId,
			    CASE WHEN CRM.RMAHeaderId >1 then 1 else  0 end isRMACreate
					 ,ISNULL(WOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
				MSD.EntityMSID AS ManagementStructureId,@workOrderModuleId as ModuleId,WOBII.RemainingAmount
				FROM dbo.BillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId --AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.ReferenceId AND WOPN.ID = WOBII.SubReferenceId
				LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
				LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WOBI.ReferenceId = WO.WorkOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
				LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOBII.SubReferenceId and WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId
				 AND ISNULL(IM.IsNonStock,0) = 0
				 LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ISNULL(ST.IsNonStock,0) = 0
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=WOBI.BillingInvoicingId and CRM.isWorkOrder=1
				LEFT JOIN dbo.WorkorderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = WOPN.ID AND MSD.ModuleID = @ModuleID
			Where WOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(WOBI.IsVersionIncrease,0)=0 AND WOBI.ModuleId =@workOrderModuleId
			AND ISNULL(WOBI.[IsStandardInvoicePosted], 0) != 1 
			AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      

			UNION ALL

			SELECT DISTINCT SOBI.BillingInvoicingId [InvoicingId],
					1 AS RowNum,
					--ROW_NUMBER() OVER (PARTITION BY SOBI.InvoiceNo,IM.ItemMasterId ORDER BY SOBI.SOBillingInvoicingId) as RowNum,
			       SOBI.InvoiceNo [InvoiceNo],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   SO.SalesOrderNumber [OrderNumber],
				   C.Name [CustomerName],
				   C.CustomerId,
				   CT.CustomerTypeName [CustomerType],
					SUM(ISNULL(SOBII.GrandTotal,0)) AS InvoiceAmt,
				   IM.partnumber [PN], 
				   IM.PartDescription [PNDescription],
				   SQ.VersionNumber [VersionNo],
				   SQ.SalesOrderQuoteNumber [QuoteNumber],
				   SO.CustomerReference [CustomerReference],
				   ST.SerialNumber [SerialNumber],
				   ST.stocklineid,
				   CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
					    WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
					    WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
					    ELSE 'OEM' END AS StockType,
					   IsWorkOrder=0,
					   IsExchange=0,
					   SMS.LastMSLevel,
					   SMS.AllMSlevels,
					   SOBI.ReferenceId AS [ReferenceId],
					   0 as WorkFlowWorkOrderId,
					   CASE WHEN Max(CRM.RMAHeaderId) >1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId,@salesOrderModuleId as ModuleId,SOBII.RemainingAmount
			FROM dbo.BillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId = SOBI.BillingInvoicingId
				LEFT JOIN dbo.SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.ReferenceId AND SOPN.SalesOrderPartId = SOBII.SubReferenceId
				LEFT JOIN dbo.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOPN.SalesOrderPartId AND SOPS.StocklineId = SOBII.StocklineId
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId				
				LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON SOBII.ItemMasterId=IM.ItemMasterId
				 LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPS.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.BillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(SOBII.IsVersionIncrease,0)=0 AND SOBI.ModuleId = @salesOrderModuleId  AND ISNULL(SOBI.[IsStandardInvoicePosted], 0) != 1
			 AND SOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @SOInvoiceTypeId)
				GROUP BY SOBI.BillingInvoicingId,SOBI.InvoiceNo,
					SOBI.InvoiceStatus ,SOBI.InvoiceDate,SO.SalesOrderNumber,
					C.Name ,CT.CustomerTypeName ,IM.partnumber , IM.PartDescription ,
					SQ.VersionNumber,SQ.SalesOrderQuoteNumber ,SO.CustomerReference ,ST.SerialNumber,ST.stocklineid ,
					IM.IsPma,IM.IsDER,SMS.LastMSLevel,SMS.AllMSlevels, SOBI.ReferenceId, SOBI.IsPerformaInvoice,SMS.EntityMSID,IM.ItemMasterId ,SOBII.RemainingAmount,C.CustomerId

			UNION ALL

				SELECT DISTINCT SOBI.SOBillingInvoicingId [InvoicingId],
					   ROW_NUMBER() OVER (PARTITION BY SOBI.InvoiceNo,IM.ItemMasterId ORDER BY SOBI.SOBillingInvoicingId) AS RowNum,
					   SOBI.InvoiceNo [InvoiceNo],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
					   SO.ExchangeSalesOrderNumber [OrderNumber],
					   C.Name [CustomerName],
					   C.CustomerId,
					   CT.CustomerTypeName [CustomerType],
					   (ISNULL(SOBII.GrandTotal,0)) as [InvoiceAmt],
					   IM.partnumber [PN], 
					   IM.PartDescription [PNDescription],
					   SO.VersionNumber [VersionNo],
					   SQ.ExchangeQuoteNumber [QuoteNumber],
					   SO.CustomerReference [CustomerReference],
					   ST.SerialNumber [SerialNumber],
					   ST.stocklineid,
					   CASE WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
						 WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
						 WHEN IM.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
						 ELSE 'OEM' END AS StockType,
					   IsWorkOrder=0,
					   IsExchange=1,
					   SMS.LastMSLevel,
					   SMS.AllMSlevels,
					   SOBI.ExchangeSalesOrderId AS [ReferenceId],
					   0 as WorkFlowWorkOrderId,
					   0 isRMACreate,
					   0 IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId, @exchModuleId as ModuleId,SOBII.GrandTotal RemainingAmount
				FROM [dbo].[ExchangeSalesOrderBillingInvoicing] SOBI WITH (NOLOCK)
				LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId
				LEFT JOIN [dbo].[ExchangeSalesOrderPart] SOPN WITH (NOLOCK) ON SOPN.ExchangeSalesOrderId =SOBI.ExchangeSalesOrderId
				LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN [dbo].[ExchangeSalesOrder] SO WITH (NOLOCK) ON SOBI.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
				LEFT JOIN [dbo].[ExchangeQuote] SQ WITH (NOLOCK) ON SQ.ExchangeQuoteId = SO.ExchangeQuoteId
				LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN [dbo].[ExchangeManagementStructureDetails] SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.ExchangeSalesOrderId AND SMS.ModuleID = @ExchSOModuleID 		
				LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SOBII.ItemMasterId = IM.ItemMasterId
				WHERE SOBI.MasterCompanyId=@MasterCompanyId	
				 AND SOBII.[IsDeleted] = 0 AND ISNULL(SOBI.[GrandTotal],0) > 0	
			     AND SOBI.[SOBillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @EXInvoiceTypeId)
						
			), ResultCount AS(SELECT COUNT(InvoicingId) AS totalItems FROM Result where  RowNum = 1)  
			   SELECT * INTO #TempResults from  Result
			   WHERE RowNum = 1 AND (  
			  
				(@GlobalFilter <> '' AND (  
				  (InvoiceNo like '%' +@GlobalFilter+'%') OR  
				  (InvoiceStatus like '%' +@GlobalFilter+'%') OR  
				  (InvoiceDate like '%' +@GlobalFilter+'%') OR  
				  (OrderNumber like '%' +@GlobalFilter+'%') OR    
				  (CustomerName like '%' +@GlobalFilter+'%') OR  
				  (CustomerType like '%' +@GlobalFilter+'%') OR 
				  (PN like '%' +@GlobalFilter+'%') OR  
				  (PNDescription like '%' +@GlobalFilter+'%') OR  
				  (VersionNo like '%' +@GlobalFilter+'%') OR 
				  (QuoteNumber like '%' +@GlobalFilter+'%') OR 
				  (CustomerReference like '%' +@GlobalFilter+'%') OR  
				  (SerialNumber like '%' +@GlobalFilter+'%') OR
				  (LastMSLevel LIKE '%' +@GlobalFilter+'%') OR
				  (StockType like '%' +@GlobalFilter+'%')))  
				 OR     
				 (@GlobalFilter='' AND (IsNull(@InvoiceNo,'') ='' OR InvoiceNo like '%' + @InvoiceNo+'%') AND  
				  (IsNull(@InvoiceStatus,'') ='' OR InvoiceStatus like '%' + @InvoiceStatus+'%') AND 
				  (IsNull(@InvoiceDate,'') ='' OR Cast(InvoiceDate as date)=Cast(@InvoiceDate as date)) and 
				  (IsNull(@OrderNumber,'') ='' OR OrderNumber like '%' + @OrderNumber+'%') AND  
				  (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
				  (IsNull(@CustomerType,'') ='' OR CustomerType like '%' + @CustomerType+'%') AND  
				  (IsNull(CAST( @InvoiceAmt as varchar),'') ='' OR Cast(InvoiceAmt as varchar) like '%' + CAST(@InvoiceAmt as varchar)+'%') AND  
				  (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
				  (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
				  (IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND   
				  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND   
				  (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%' + @CustomerReference+'%') AND  
				  (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND
				  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') and
				  (IsNull(@StockType,'') ='' OR StockType like '%' + @StockType+'%')   AND
				 (@FromDate IS NULL OR CAST(InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND
				 (@ToDate IS NULL OR CAST(InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
				  (IsNull(@Status,'') ='' OR InvoiceStatus like '%' + @Status+'%')
				  ))
				   SELECT @Count = COUNT(InvoicingId),@InvoiceTotalAmount = SUM(ISNULL(InvoiceAmt,0)) FROM #TempResults     
				   SELECT *, @Count As NumberOfItems ,ISNULL(@InvoiceTotalAmount,0) as InvoiceTotalAmount FROM #TempResults  
				   ORDER BY       
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='orderNumber')  THEN OrderNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PN')  THEN PN END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PNDescription')  THEN PNDescription END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='VersionNo')  THEN VersionNo END ASC, 
				   CASE WHEN (@SortOrder=1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerReference')  THEN CustomerReference END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='StockType')  THEN StockType END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,
						
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='orderNumber')  THEN OrderNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerType')  THEN CustomerType END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PN')  THEN PN END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PNDescription')  THEN PNDescription END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='VersionNo')  THEN VersionNo END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerReference')  THEN CustomerReference END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC
  
				   OFFSET @RecordFrom ROWS   
				   FETCH NEXT @PageSize ROWS ONLY;

				   DROP TABLE #TempResults;
		END
     END TRY
  BEGIN CATCH
		SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_SearchCustomerInvoicesQBExtract]',
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