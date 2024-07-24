/*************************************************************           
 ** File:   [USP_SearchCustomerInvoices]           
 ** Author:  
 ** Description: Search CustomerInvoices 
 ** Purpose:         
 ** Date:          
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1								   	Created
	2	01/31/2024    Devendra Shekh	added isperforma Flage for WO
	3	01/02/2024	  AMIT GHEDIYA		added isperforma Flage for SO
	4   02/06/2024    Devendra Shekh	UPDATE isperforma
	5   08/02/2024	  Devendra Shekh    added IsInvoicePosted flage for WO
	6   14/02/2024	  Devendra Shekh    duplicate wo for multiple MPN issue resolved
	7   15/02/2024	  AMIT GHEDIYA      added IsBilling flage for SO
	8   15/02/2024	  AMIT GHEDIYA      added DBO & NO(LOCK)
	9   19/02/2024	  Devendra Shekh    email validation issue for wo resolved
	10  20/02/2024	  Devendra Shekh    added remainingamount condition
	11  04/03/2024	  AMIT GHEDIYA      Multiple data issue in SO.
	12  14/03/2024	  Moin Bloch        added AmountPaid
	13  18/03/2024	  Moin Bloch        added exchange details in pn view
	14  21/03/2024	  Moin Bloch        added ManagementStructureId 
	15  04/05/2024	  Moin Bloch        added condtion to removed posted and closed credit memo invoices from invoice list 
	16  06/13/2024	  Devendra Shekh    not getting SO Invoices data issue resolved
	17  06/26/2024	  Moin Bloch        added condtion to removed Refund and Refund Requested credit memo invoices from invoice list 
	18  07/23/2024	  Devendra Shekh    optimized SP and Removed unnecessary commented Data

exec dbo.USP_SearchCustomerInvoices 
@PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@StatusID=0,@GlobalFilter=N'',@InvoiceNo=NULL,@InvoiceStatus=NULL,@InvoiceDate=NULL,
@OrderNumber=NULL,@CustomerName=NULL,@CustomerType=NULL,@InvoiceAmt=NULL,@PN=NULL,@PNDescription=NULL,@VersionNo=NULL,@QuoteNumber=NULL,
@CustomerReference=NULL,@MasterCompanyId=1,@SerialNumber=NULL,@StockType=NULL,@ViewType=N'invoice',@EmployeeId=2,@RemainingAmount=NULL,@LastMSLevel=NULL,@Status=N''
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_SearchCustomerInvoices]
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
@Status varchar(50)=null
AS
BEGIN
	  DECLARE @RecordFrom INT; 
	  DECLARE @ModuleID VARCHAR(500) ='12'
	  DECLARE @SOModuleID VARCHAR(500) ='17'
	  DECLARE @ExchSOModuleID VARCHAR(500) ='19'
	  DECLARE @IsActive BIT = 1  
	  DECLARE @Count INT;  
	  SET @RecordFrom = (@PageNumber - 1) * @PageSize;

	  DECLARE @WOInvoiceTypeId INT;
	  DECLARE @SOInvoiceTypeId INT;
	  DECLARE @EXInvoiceTypeId INT;
	  DECLARE @CMPostedStatusId INT;
	  DECLARE @ClosedCreditMemoStatus INT;
	  DECLARE @RefundedCreditMemoStatus INT;
	  DECLARE @RefundRequestedCreditMemoStatus INT;

	  SELECT @WOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WHERE ModuleName='WorkOrder';
      SELECT @SOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WHERE ModuleName='SalesOrder';
      SELECT @EXInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WHERE ModuleName='Exchange';
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
				   WOBI.InvoiceDate [InvoiceDate],
				   WO.WorkOrderNum [OrderNumber],
				   C.Name [CustomerName],
				   CT.CustomerTypeName [CustomerType],
				   WOBI.GrandTotal [InvoiceAmt],
				   ISNULL(WOBI.RemainingAmount,0) RemainingAmount,
				   ISNULL(ISNULL(WOBI.GrandTotal,0) - ISNULL(WOBI.RemainingAmount,0),0) AmountPaid,
				   WQ.QuoteNumber,
				   IsWorkOrder=1,
				   IsExchange=0,
				   WOBI.WorkOrderId AS [ReferenceId],
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
				   	ELSE 'OEM' END) END) AS 'StockTypeType'
				FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
				LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOPN.ID and WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=WOBI.BillingInvoicingId and CRM.isWorkOrder=1
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId
				LEFT JOIN dbo.WorkorderManagementStructureDetails M WITH (NOLOCK) ON M.ReferenceID = WOPN.ID AND M.ModuleID = @ModuleID
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On WOBII.ItemMasterId=I.ItemMasterId  
			WHERE WOBI.MasterCompanyId=@MasterCompanyId AND WOBI.IsVersionIncrease=0
			AND ISNULL(WOBI.[IsInvoicePosted], 0) != 1 AND ISNULL(WOBI.RemainingAmount,0) > 0
			AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      
			GROUP BY	WOBI.BillingInvoicingId, WOBI.InvoiceNo, WOBI.InvoiceStatus, WOBI.InvoiceDate, WO.WorkOrderNum, C.[Name], CT.CustomerTypeName, WOBI.GrandTotal, WOBI.RemainingAmount, WQ.QuoteNumber, WOBI.WorkOrderId
						, C.CustomerId, CRM.RMAHeaderId, WOBI.IsPerformaInvoice, WOPN.ManagementStructureId
			),				
			WorkFlowData AS(  
				SELECT PC.BillingInvoicingId,WOFN.WorkFlowWorkOrderId, PC.WorkOrderId
				FROM dbo.WorkOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.WorkOrderWorkFlow WOFN WITH (NOLOCK) ON WOFN.WorkFlowWorkOrderId = PC.WorkFlowWorkOrderId
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease = 0 AND ISNULL(PC.[IsInvoicePosted], 0) != 1
				GROUP BY PC.WorkOrderId,PC.BillingInvoicingId,WOFN.WorkFlowWorkOrderId
				),
				Results AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,
				M.CustomerReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder,M.IsExchange,
				M.LastMSLevel,M.AllMSlevels, M.ReferenceId,M.CustomerId,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
				FROM Result M   
					LEFT JOIN WorkFlowData WOFD  on WOFD.BillingInvoicingId=M.InvoicingId
					GROUP BY 
				M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid,PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels	,
				M.CustomerReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder, M.ReferenceId,M.CustomerId,M.IsExchange,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId)
			,SOResult AS(
				SELECT DISTINCT 
				       SOBI.SOBillingInvoicingId [InvoicingId],
				       SOBI.InvoiceNo [InvoiceNo],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   SOBI.InvoiceDate [InvoiceDate],
					   SO.SalesOrderNumber [OrderNumber],
					   C.Name [CustomerName],
					   CT.CustomerTypeName [CustomerType],
					   SOBI.GrandTotal [InvoiceAmt],
					   ISNULL(SOBI.RemainingAmount,0) RemainingAmount,
					   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,
					   SQ.SalesOrderQuoteNumber [QuoteNumber],
					   IsWorkOrder=0,
					   IsExchange=0,
					   SMS.LastMSLevel,
					   SMS.AllMSlevels, 
					   SOBI.SalesOrderId AS [ReferenceId],
					   C.CustomerId,0 as WorkFlowWorkOrderId,
					   CASE WHEN CRM.RMAHeaderId > 1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsProforma, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SQ.VersionNumber) END) AS 'VersionNo'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SQ.VersionNumber) END) AS 'VersionNoType'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SOPN.CustomerReference) END) AS 'CustomerReference'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SOPN.CustomerReference) END) AS 'CustomerReferenceType'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumber'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumberType'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PN'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PartNumberType'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PNDescription'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PartDescriptionType'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						 WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
						 WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
						 ELSE 'OEM' END ) END) AS 'StockType'
					   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						 WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
						 WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
						 ELSE 'OEM' END ) END) AS 'StockTypeType'
			FROM dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId AND ISNULL(SOBII.[IsBilling], 0) != 1
				LEFT JOIN dbo.SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
				LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.SOBillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId  
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND SOBI.IsVersionIncrease=0 AND ISNULL(SOBI.[IsBilling], 0) != 1 AND ISNULL(SOBI.RemainingAmount,0) > 0
				AND SOBI.[SOBillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @SOInvoiceTypeId)
				GROUP BY	SOBI.SOBillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.SalesOrderNumber, C.[Name], CT.CustomerTypeName, SOBI.GrandTotal, SOBI.RemainingAmount, SQ.SalesOrderQuoteNumber
							, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.SalesOrderId, C.CustomerId, CRM.RMAHeaderId, SOBI.IsProforma, SMS.EntityMSID
						),
				SOResults AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount, M.AmountPaid, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
				FROM SOResult M   
				GROUP BY 
				M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
					),
				ExchSOResult AS(
			SELECT SOBI.SOBillingInvoicingId [InvoicingId],
			       SOBI.InvoiceNo [InvoiceNo],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   SOBI.InvoiceDate [InvoiceDate],
				   SO.ExchangeSalesOrderNumber [OrderNumber],
				   C.Name [CustomerName],
				   CT.CustomerTypeName [CustomerType],
				   SOBI.GrandTotal [InvoiceAmt],
				   ISNULL(SOBI.GrandTotal,0) RemainingAmount,
				   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,
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
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SO.VersionNumber) END) AS 'VersionNo'
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SO.VersionNumber) END) AS 'VersionNoType'
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumber'
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumberType'
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PN'
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PartNumberType'
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PNDescription'
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PartDescriptionType'
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
					WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
					WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
					ELSE 'OEM' END ) END) AS 'StockType'
				   ,(CASE WHEN COUNT(SOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
					WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
					WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
					ELSE 'OEM' END ) END) AS 'StockTypeType'
			FROM dbo.ExchangeSalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId
				LEFT JOIN dbo.ExchangeSalesOrderPart SOPN WITH (NOLOCK) ON SOPN.ExchangeSalesOrderId =SOBI.ExchangeSalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.ExchangeSalesOrder SO WITH (NOLOCK) ON SOBI.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
				--LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.ExchangeManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.ExchangeSalesOrderId AND SMS.ModuleID = @ExchSOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId  
			WHERE SOBI.MasterCompanyId=@MasterCompanyId	AND SOBII.IsDeleted=0 AND ISNULL(SOBI.GrandTotal,0) > 0	
			AND SOBI.[SOBillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @EXInvoiceTypeId)
			GROUP BY	SOBI.SOBillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.ExchangeSalesOrderNumber, C.[Name], CT.CustomerTypeName, SOBI.GrandTotal, SOBI.RemainingAmount
						, SO.CustomerReference, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.ExchangeSalesOrderId, C.CustomerId, SMS.EntityMSID
						),
				ExchSOResults AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid,M.PN as [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				'' as QuoteNumber,
				M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,'' as CustomerReferenceType,
				ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
				FROM ExchSOResult M   
				GROUP BY 
				M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
				)
			   , FinalResult AS(
					SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt, RemainingAmount, AmountPaid ,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
				FROM Results
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount, AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber ,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
					UNION ALL 
				SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
				FROM SOResults
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
					UNION ALL 
				SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
				FROM ExchSOResults
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
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
	  (IsNull(CAST( @AmountPaid as varchar),'') ='' OR Cast(AmountPaid as varchar) like '%' + CAST(@AmountPaid as varchar)+'%') AND 
	  (IsNull(CAST( @RemainingAmount as varchar),'') ='' OR Cast(RemainingAmount as varchar) like '%' + CAST(@RemainingAmount as varchar)+'%') AND 
      (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
      (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
      (IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND 
	  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND
      (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%' + @CustomerReference+'%') AND  
      (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND  
      (IsNull(@StockType,'') ='' OR StockType like '%' + @StockType+'%')  AND
	  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') AND
	  (IsNull(@Status,'') ='' OR InvoiceStatus like '%' + @Status+'%') 
      ))
				   SELECT @Count = COUNT(InvoicingId) from #TempResult     
  
				   SELECT *, @Count As NumberOfItems FROM #TempResult  
				   ORDER BY       
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='orderNumber')  THEN OrderNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='AmountPaid')  THEN AmountPaid END ASC,  				   
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
				   CASE WHEN (@SortOrder=-1 and @SortColumn='AmountPaid')  THEN AmountPaid END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PN')  THEN PN END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PNDescription')  THEN PNDescription END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='VersionNo')  THEN VersionNo END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerReference')  THEN CustomerReference END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC
  
				   OFFSET @RecordFrom ROWS   
				   FETCH NEXT @PageSize ROWS ONLY  
   END
   ELSE
   BEGIN
			;WITH Result AS(
				SELECT WOBI.BillingInvoicingId [InvoicingId],
				WOBI.InvoiceNo [InvoiceNo],
				WOBI.InvoiceStatus [InvoiceStatus],
				WOBI.InvoiceDate [InvoiceDate],
				WO.WorkOrderNum [OrderNumber],
				C.Name [CustomerName],
				CT.CustomerTypeName [CustomerType],
				WOBI.GrandTotal [InvoiceAmt], 
				ISNULL(WOBI.RemainingAmount, 0)  RemainingAmount,
				ISNULL(ISNULL(WOBI.GrandTotal,0) - ISNULL(WOBI.RemainingAmount,0),0) AmountPaid,				
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
					 WOBI.WorkOrderId AS [ReferenceId],WOWF.WorkFlowWorkOrderId,
			    CASE WHEN CRM.RMAHeaderId >1 then 1 else  0 end isRMACreate
					 ,ISNULL(WOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
				MSD.EntityMSID AS ManagementStructureId
				FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
				LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOBII.WorkOrderPartId and WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=WOBI.BillingInvoicingId and CRM.isWorkOrder=1
				LEFT JOIN dbo.WorkorderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = WOPN.ID AND MSD.ModuleID = @ModuleID
			Where WOBI.MasterCompanyId=@MasterCompanyId AND WOBI.IsVersionIncrease=0
			AND ISNULL(WOBI.[IsInvoicePosted], 0) != 1 AND ISNULL(WOBI.RemainingAmount,0) > 0
			AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      

			UNION ALL

			SELECT SOBI.SOBillingInvoicingId [InvoicingId],
			       SOBI.InvoiceNo [InvoiceNo],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   SOBI.InvoiceDate [InvoiceDate],
				   SO.SalesOrderNumber [OrderNumber],
				   C.Name [CustomerName],
				   CT.CustomerTypeName [CustomerType],
				   SOBI.GrandTotal [InvoiceAmt], 
				   ISNULL(SOBI.RemainingAmount, 0) RemainingAmount,
				   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,						
				   IM.partnumber [PN], 
				   IM.PartDescription [PNDescription],
				   SQ.VersionNumber [VersionNo],
				   SQ.SalesOrderQuoteNumber [QuoteNumber],
				   SOPN.CustomerReference [CustomerReference],
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
					   SOBI.SalesOrderId AS [ReferenceId],
					   0 as WorkFlowWorkOrderId,
					   CASE WHEN Max(CRM.RMAHeaderId) >1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsProforma, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId
			FROM dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId
				LEFT JOIN dbo.SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId AND SOPN.SalesOrderPartId = SOBII.SalesOrderPartId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
				LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON SOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.SOBillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND SOBII.IsVersionIncrease=0 AND ISNULL(SOBI.[IsBilling], 0) != 1 AND ISNULL(SOBI.RemainingAmount,0) > 0
			 AND SOBI.[SOBillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @SOInvoiceTypeId)
				GROUP BY SOBI.SOBillingInvoicingId,SOBI.InvoiceNo,
					SOBI.InvoiceStatus ,SOBI.InvoiceDate,SO.SalesOrderNumber,
					C.Name ,CT.CustomerTypeName , SOBI.RemainingAmount,
					SOBI.GrandTotal ,IM.partnumber , IM.PartDescription ,
					SQ.VersionNumber,SQ.SalesOrderQuoteNumber ,SOPN.CustomerReference ,ST.SerialNumber,ST.stocklineid ,
					IM.IsPma,IM.IsDER,SMS.LastMSLevel,SMS.AllMSlevels, SOBI.SalesOrderId, SOBI.IsProforma,SMS.EntityMSID

			UNION ALL

				SELECT SOBI.SOBillingInvoicingId [InvoicingId],
					   SOBI.InvoiceNo [InvoiceNo],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   SOBI.InvoiceDate [InvoiceDate],
					   SO.ExchangeSalesOrderNumber [OrderNumber],
					   C.Name [CustomerName],
					   CT.CustomerTypeName [CustomerType],
					   SOBI.GrandTotal [InvoiceAmt],
					   ISNULL(SOBI.GrandTotal,0) RemainingAmount,
					   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,		
					   IM.partnumber [PN], 
					   IM.PartDescription [PNDescription],
					   '' [VersionNo],
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
					   SMS.EntityMSID AS ManagementStructureId
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
						
			), ResultCount AS(SELECT COUNT(InvoicingId) AS totalItems FROM Result)  
			   SELECT * INTO #TempResults from  Result
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
				  (IsNull(CAST( @AmountPaid as varchar),'') ='' OR Cast(AmountPaid as varchar) like '%' + CAST(@AmountPaid as varchar)+'%') AND 
				  (IsNull(CAST( @RemainingAmount as varchar),'') ='' OR Cast(RemainingAmount as varchar) like '%' + CAST(@RemainingAmount as varchar)+'%') AND 
				  (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
				  (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
				  (IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND   
				  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND   
				  (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%' + @CustomerReference+'%') AND  
				  (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND
				  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') and
				  (IsNull(@StockType,'') ='' OR StockType like '%' + @StockType+'%')   AND
				  (IsNull(@Status,'') ='' OR InvoiceStatus like '%' + @Status+'%')
				  ))
				   SELECT @Count = COUNT(InvoicingId) from #TempResults     

				   SELECT *, @Count As NumberOfItems FROM #TempResults 
				   ORDER BY       
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='orderNumber')  THEN OrderNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='AmountPaid')  THEN AmountPaid END ASC,  
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
				   CASE WHEN (@SortOrder=-1 and @SortColumn='AmountPaid')  THEN AmountPaid END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PN')  THEN PN END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PNDescription')  THEN PNDescription END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='VersionNo')  THEN VersionNo END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerReference')  THEN CustomerReference END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC
  
				   OFFSET @RecordFrom ROWS   
				   FETCH NEXT @PageSize ROWS ONLY
   END
END